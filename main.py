from fastapi import FastAPI, Query, Header, HTTPException
from fastapi.middleware.cors import CORSMiddleware
import ccxt
import os
import threading
import time
from dotenv import load_dotenv
from contextlib import asynccontextmanager
from pydantic import BaseModel

load_dotenv()
API_KEY = os.getenv("API_KEY")
API_SECRET = os.getenv("API_SECRET")
API_TOKEN = os.getenv("API_TOKEN", "super_tajne_haslo_123")

# --- Ustawienia strategii ---
TRADE_SYMBOL = "BTC/USDT"
SHORT_EMA = 50
LONG_EMA = 200
RSI_PERIOD = 14
GRID_SPACING = 0.01
GRID_LEVELS = 5
STOP_LOSS_PCT = 0.015
TAKE_PROFIT_PCT = 0.02
SLEEP_INTERVAL = 60
MAX_CAPITAL_USAGE = 0.1

bot_thread = None
bot_running = False
last_buy_price = None

log = []  # logi działań bota

def add_log(msg: str):
    timestamp = time.strftime("%Y-%m-%d %H:%M:%S")
    log.append(f"[{timestamp}] {msg}")

# --- Bot logic ---
def create_exchange():
    ex = ccxt.binance({
        'apiKey': API_KEY,
        'secret': API_SECRET,
        'enableRateLimit': True,
    })
    ex.load_markets()
    return ex

def fetch_ohlcv(exchange, symbol: str, timeframe='5m', limit=None):
    return exchange.fetch_ohlcv(symbol, timeframe=timeframe, limit=limit or (LONG_EMA + 10))

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

def bot_loop():
    global bot_running, last_buy_price
    ex = create_exchange()
    add_log("Bot loop started")
    while bot_running:
        try:
            balance = ex.fetch_balance()
            free_usdt = balance['free'].get("USDT", 0)
            candles = fetch_ohlcv(ex, TRADE_SYMBOL)
            closes = [c[4] for c in candles]
            ema_short = calculate_ema(closes, SHORT_EMA)
            ema_long = calculate_ema(closes, LONG_EMA)
            rsi = calculate_rsi(closes, RSI_PERIOD)
            current_price = closes[-1]

            add_log(f"Price: {current_price}, EMA_S: {ema_short}, EMA_L: {ema_long}, RSI: {rsi}")

            if not last_buy_price:
                if ema_short and ema_long and ema_short > ema_long and rsi > 50:
                    grid_price = current_price * (1 - GRID_SPACING)
                    trade_amt = (free_usdt * MAX_CAPITAL_USAGE) / grid_price
                    ex.create_market_buy_order(TRADE_SYMBOL, trade_amt)
                    last_buy_price = grid_price
                    add_log(f"BUY order placed at {grid_price}, qty={trade_amt}")
            else:
                profit_pct = (current_price - last_buy_price) / last_buy_price
                loss_pct = (last_buy_price - current_price) / last_buy_price
                if profit_pct >= TAKE_PROFIT_PCT or loss_pct >= STOP_LOSS_PCT:
                    position = ex.fetch_balance()['total'].get(TRADE_SYMBOL.split('/')[0], 0)
                    ex.create_market_sell_order(TRADE_SYMBOL, position)
                    add_log(f"SELL order placed at {current_price}, PnL: {profit_pct*100:.2f}%")
                    last_buy_price = None

        except Exception as e:
            add_log(f"Bot ERROR: {str(e)}")

        time.sleep(SLEEP_INTERVAL)
    add_log("Bot loop ended")

# --- API + lifecycle ---
@asynccontextmanager
async def lifespan(app: FastAPI):
    global bot_thread, bot_running
    # opcjonalnie możesz uruchamiać bota automatycznie przy starcie serwisu:
    # if not bot_running:
    #     bot_running = True
    #     bot_thread = threading.Thread(target=bot_loop, daemon=True)
    #     bot_thread.start()
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

def check_token(x_token: str | None):
    if x_token != API_TOKEN:
        raise HTTPException(status_code=401, detail="Unauthorized")

@app.post("/start_bot")
def start_bot(x_token: str | None = Header(default=None)):
    global bot_running, bot_thread
    check_token(x_token)
    if bot_running:
        return {"status": "already running"}
    bot_running = True
    bot_thread = threading.Thread(target=bot_loop, daemon=True)
    bot_thread.start()
    add_log("API: /start_bot called")
    return {"status": "bot started"}

@app.post("/stop_bot")
def stop_bot(x_token: str | None = Header(default=None)):
    global bot_running
    check_token(x_token)
    bot_running = False
    add_log("API: /stop_bot called")
    return {"status": "bot stopped"}

@app.get("/status")
def status(x_token: str | None = Header(default=None)):
    check_token(x_token)
    return {"bot_running": bot_running}

@app.get("/log")
def get_log(x_token: str | None = Header(default=None)):
    check_token(x_token)
    return {"log": log[-100:]}  # ostatnie 100 wpisów

@app.get("/balance")
def get_balance(x_token: str | None = Header(default=None)):
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

@app.get("/positions")
def get_positions(x_token: str | None = Header(default=None)):
    check_token(x_token)
    ex = create_exchange()
    balance = ex.fetch_balance()
    positions = {}
    for symbol, amount in balance['total'].items():
        if amount and amount > 0:
            positions[symbol] = {
                "total": balance['total'][symbol],
                "free": balance['free'].get(symbol, 0),
                "used": balance['used'].get(symbol, 0),
            }
    return positions

class ConfigUpdate(BaseModel):
    symbol: str | None = None
    short_ema: int | None = None
    long_ema: int | None = None
    rsi_period: int | None = None
    take_profit_pct: float | None = None
    stop_loss_pct: float | None = None
    capital_usage: float | None = None

@app.post("/update_config")
def update_config(cfg: ConfigUpdate, x_token: str | None = Header(default=None)):
    check_token(x_token)
    global TRADE_SYMBOL, SHORT_EMA, LONG_EMA, RSI_PERIOD, TAKE_PROFIT_PCT, STOP_LOSS_PCT, MAX_CAPITAL_USAGE

    if cfg.symbol: TRADE_SYMBOL = cfg.symbol
    if cfg.short_ema: SHORT_EMA = cfg.short_ema
    if cfg.long_ema: LONG_EMA = cfg.long_ema
    if cfg.rsi_period: RSI_PERIOD = cfg.rsi_period
    if cfg.take_profit_pct: TAKE_PROFIT_PCT = cfg.take_profit_pct
    if cfg.stop_loss_pct: STOP_LOSS_PCT = cfg.stop_loss_pct
    if cfg.capital_usage: MAX_CAPITAL_USAGE = cfg.capital_usage

    add_log("API: /update_config called")
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
