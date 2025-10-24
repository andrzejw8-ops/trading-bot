from fastapi import FastAPI, Header, HTTPException
from fastapi.middleware.cors import CORSMiddleware
import ccxt
import os
import threading
import time
from dotenv import load_dotenv
from contextlib import asynccontextmanager
from pydantic import BaseModel
from collections import deque

logs = deque(maxlen=50)

load_dotenv()
API_KEY = os.getenv("API_KEY")
API_SECRET = os.getenv("API_SECRET")
ACCESS_TOKEN = os.getenv("X_TOKEN")

TRADE_SYMBOL = ["BTC/USDC", "ETH/USDC", "SOL/USDC"]

SHORT_EMA = 50
LONG_EMA = 200
RSI_PERIOD = 14
STOP_LOSS_PCT = 0.015
TAKE_PROFIT_PCT = 0.02
SLEEP_INTERVAL = 30
MAX_CAPITAL_USAGE = 0.1

bot_thread = None
bot_running = False
last_buy_price = {}

def check_token(x_token: str):
    if x_token != ACCESS_TOKEN:
        raise HTTPException(status_code=401, detail="Unauthorized")

def create_exchange():
    ex = ccxt.binance({
        'apiKey': API_KEY,
        'secret': API_SECRET,
        'enableRateLimit': True,
    })
    ex.load_markets()
    return ex

def fetch_ohlcv(exchange, symbol: str, timeframe='5m', limit=LONG_EMA + 10):
    return exchange.fetch_ohlcv(symbol, timeframe=timeframe, limit=limit)

def calculate_ema(prices_close: list, period: int):
    if len(prices_close) < period:
        return None
    return sum(prices_close[-period:]) / period

def calculate_rsi(prices_close: list, period: int):
    if len(prices_close) < period + 1:
        return None
    gains = []
    losses = []
    for i in range(1, period + 1):
        diff = prices_close[-i] - prices_close[-i - 1]
        if diff > 0:
            gains.append(diff)
        else:
            losses.append(abs(diff))
    avg_gain = sum(gains) / period
    avg_loss = sum(losses) / period if losses else 0.000001
    rs = avg_gain / avg_loss
    rsi = 100 - (100 / (1 + rs))
    return rsi

def get_base_currency(symbol):
    return symbol.split('/')[0]

def bot_loop():
    global bot_running, last_buy_price
    ex = create_exchange()

    while bot_running:
        symbols = TRADE_SYMBOL if isinstance(TRADE_SYMBOL, list) else [TRADE_SYMBOL]
        for symbol in symbols:
            try:
                logs.append(f"🔍 Sprawdzam parę {symbol}...")

                candles = fetch_ohlcv(ex, symbol, limit=LONG_EMA + 10)
                closes = [c[4] for c in candles]

                if len(closes) < LONG_EMA:
                    logs.append(f"⚠️ Zbyt mało danych dla {symbol}")
                    continue

                ema_short = calculate_ema(closes, SHORT_EMA)
                ema_long = calculate_ema(closes, LONG_EMA)
                rsi = calculate_rsi(closes, RSI_PERIOD)
                current_price = closes[-1]
                base_currency = get_base_currency(symbol)

                balance = ex.fetch_balance()
                position = balance['total'].get(base_currency, 0)
                usdc_balance = balance['free'].get("USDC", 0)
                allocation = usdc_balance * MAX_CAPITAL_USAGE

                logs.append(f"📊 {symbol} | Cena: {current_price:.2f}, EMA_S: {ema_short:.2f}, EMA_L: {ema_long:.2f}, RSI: {rsi:.2f}, Pozycja: {position:.6f}")

                if position > 0:
                    last_price = last_buy_price.get(symbol, current_price)
                    profit_pct = (current_price - last_price) / last_price
                    loss_pct = (last_price - current_price) / last_price

                    if profit_pct >= TAKE_PROFIT_PCT:
                        ex.create_market_sell_order(symbol, position)
                        logs.append(f"✅ SELL {symbol} z zyskiem {profit_pct*100:.2f}% @ {current_price:.2f}")
                        last_buy_price[symbol] = current_price
                    elif loss_pct >= STOP_LOSS_PCT:
                        ex.create_market_sell_order(symbol, position)
                        logs.append(f"🛑 SELL {symbol} ze stratą {loss_pct*100:.2f}% @ {current_price:.2f}")
                        last_buy_price[symbol] = current_price
                    else:
                        logs.append(f"⏸️ Trzymam pozycję na {symbol}, PnL: {profit_pct*100:.2f}%")
                else:
                    if ema_short > ema_long and rsi and rsi > 30:
                        try:
                            market_info = ex.markets[symbol]
                            min_notional = market_info['limits']['cost']['min']
                            lot_size_min = market_info['limits']['amount']['min']
                        except Exception as e:
                            logs.append(f"❌ Nie udało się pobrać limitów dla {symbol}: {str(e)}")
                            continue

                        if allocation >= min_notional:
                            amount_to_buy = allocation / current_price
                            if amount_to_buy >= lot_size_min:
                                try:
                                    ex.create_market_buy_order(symbol, amount_to_buy)
                                    last_buy_price[symbol] = current_price
                                    logs.append(f"🟢 BUY {symbol} za {allocation:.2f} USDC @ {current_price:.2f}")
                                except Exception as e:
                                    logs.append(f"❌ Błąd przy BUY {symbol}: {str(e)}")
                            else:
                                logs.append(f"❌ Zbyt mała ilość {amount_to_buy:.8f} < minimalna ({lot_size_min}) dla {symbol}")
                        else:
                            logs.append(f"❌ Kwota {allocation:.2f} < minimalna ({min_notional}) dla {symbol}")
            except Exception as e:
                logs.append(f"🔥 Błąd w symbolu {symbol}: {str(e)}")
        time.sleep(SLEEP_INTERVAL)

@asynccontextmanager
async def lifespan(app: FastAPI):
    yield

app = FastAPI(lifespan=lifespan)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

@app.get("/")
def root():
    return {"message": "Bot działa globalnie na Render"}

@app.post("/start_bot")
def start_bot(x_token: str = Header(default=None)):
    check_token(x_token)
    global bot_running, bot_thread
    if bot_running:
        return {"status": "already running"}
    bot_running = True
    bot_thread = threading.Thread(target=bot_loop, daemon=True)
    bot_thread.start()
    return {"status": "bot started"}

@app.post("/stop_bot")
def stop_bot(x_token: str = Header(default=None)):
    check_token(x_token)
    global bot_running
    bot_running = False
    return {"status": "bot stopped"}

@app.get("/status")
def status(x_token: str = Header(default=None)):
    check_token(x_token)
    return {"bot_running": bot_running}

@app.get("/log")
def get_logs(x_token: str = Header(default=None)):
    check_token(x_token)
    return {"logs": list(logs)}

class ConfigUpdate(BaseModel):
    symbol: str = None
    short_ema: int = None
    long_ema: int = None
    rsi_period: int = None
    take_profit_pct: float = None
    stop_loss_pct: float = None
    capital_usage: float = None

@app.post("/update_config")
def update_config(cfg: ConfigUpdate, x_token: str = Header(default=None)):
    check_token(x_token)
    global TRADE_SYMBOL, SHORT_EMA, LONG_EMA, RSI_PERIOD, TAKE_PROFIT_PCT, STOP_LOSS_PCT, MAX_CAPITAL_USAGE

    if cfg.symbol:
        TRADE_SYMBOL = [cfg.symbol] if isinstance(cfg.symbol, str) else cfg.symbol
    if cfg.short_ema: SHORT_EMA = cfg.short_ema
    if cfg.long_ema: LONG_EMA = cfg.long_ema
    if cfg.rsi_period: RSI_PERIOD = cfg.rsi_period
    if cfg.take_profit_pct: TAKE_PROFIT_PCT = cfg.take_profit_pct
    if cfg.stop_loss_pct: STOP_LOSS_PCT = cfg.stop_loss_pct
    if cfg.capital_usage: MAX_CAPITAL_USAGE = cfg.capital_usage

    return {
        "message": "Config updated",
        "new_config": {
            "symbol": TRADE_SYMBOL,
            "short_ema": SHORT_EMA,
            "long_ema": LONG_EMA,
            "rsi_period": RSI_PERIOD,
            "take_profit_pct": TAKE_PROFIT_PCT,
            "stop_loss_pct": STOP_LOSS_PCT,
            "capital_usage": MAX_CAPITAL_USAGE,
        }
    }

@app.get("/balance")
def get_balance(x_token: str = Header(default=None)):
    check_token(x_token)
    try:
        ex = create_exchange()
        balance = ex.fetch_balance()
        return {
            "total": balance.get("total", {}),
            "free": balance.get("free", {}),
            "used": balance.get("used", {})
        }
    except Exception as e:
        return {"error": str(e)}

