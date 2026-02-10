# EA_120_Logika - Comprehensive Multi-Strategy Trading System

## Overview

EA_120_Logika is an aggressive multi-symbol, multi-strategy Expert Advisor designed to trade 24/7 on the M6 (6-minute) timeframe. It combines four powerful trading strategies with advanced risk management to maximize profit potential in volatile markets.

## Table of Contents  
1. [Strategy Components](#strategy-components)
2. [Risk Management](#risk-management)
3. [Multi-Symbol Trading](#multi-symbol-trading)
4. [Configuration Parameters](#configuration-parameters)
5. [Trading Logic Details](#trading-logic-details)

---

## Strategy Components

### 1. Scalping Strategy (EMA/RSI)
The scalping component uses moving average crossovers combined with RSI momentum to identify short-term trading opportunities:

- **Fast EMA (default: 5)**: Captures immediate price momentum
- **Slow EMA (default: 20)**: Provides trend direction filter
- **RSI (default: 14)**: Confirms oversold/overbought conditions

**Entry Logic:**
- **Buy Signal**: Fast EMA crosses above Slow EMA + RSI < 30 (oversold) OR Fast EMA > Slow EMA + RSI between 50-70
- **Sell Signal**: Fast EMA crosses below Slow EMA + RSI > 70 (overbought) OR Fast EMA < Slow EMA + RSI between 30-50

### 2. Breakout Strategy
Identifies price breakouts from recent ranges to capture momentum moves:

- **Lookback Period (default: 20 bars)**: Analyzes recent high/low range
- **Threshold (default: 5 pips)**: Minimum breakout distance to filter noise

**Entry Logic:**
- **Buy Signal**: Current Ask price breaks above the highest high of last 20 bars + threshold
- **Sell Signal**: Current Bid price breaks below the lowest low of last 20 bars - threshold

### 3. Grid Trading
Adds positions at regular price intervals to average entry prices:

- **Grid Step (default: 30 pips)**: Distance between grid levels
- **Direction**: Opens additional positions in the same direction as existing trades

**Grid Logic:**
- When price moves against a position by GridStep pips, open an additional position
- Tracks separate grid levels for buy and sell positions
- Limited by MaxPositionsPerSymbol parameter

### 4. Martingale System
Progressively increases position size after losses to recover drawdown:

- **Martingale Factor (default: 1.5)**: Lot size multiplier for each new level
- **Max Levels (default: 5)**: Maximum number of martingale layers

**Martingale Logic:**
- Each grid position uses lot size = previous total lots × MartingaleFactor
- Resets to base lot size when starting fresh positions
- Strictly controlled by MaxLot and MaxMartingaleLevel limits

---

## Risk Management

### Drawdown Protection
- **Max Drawdown %**: Stops all trading when equity drawdown exceeds specified percentage
- **Real-time Monitoring**: Checks on every tick
- **Alert System**: Generates alert when limit is reached

### Position Limits
- **Max Positions Per Symbol**: Prevents overexposure to single instrument
- **Max Lot Size**: Caps individual position size regardless of martingale level
- **Per-Symbol Tracking**: Independent position counting for each traded symbol

### Stop Loss & Take Profit
- **Fixed SL/TP in Pips**: Applied to every position
- **Normalized Prices**: Automatically adjusts to symbol's price precision
- **Grid-Compatible**: Each position has independent SL/TP levels

---

## Multi-Symbol Trading

### Symbol Selection
Two modes available:

1. **Trade All Symbols (default: true)**
   - Automatically scans all symbols in Market Watch
   - Filters for tradeable symbols only
   - Verifies sufficient M6 historical data
   - Excludes disabled trading modes

2. **Single Symbol Mode**
   - Set TradeAllSymbols = false
   - Specify symbol in SingleSymbol parameter
   - Falls back to chart symbol if empty

### Symbol Validation
Each symbol must meet the following criteria:
- Available in Market Watch
- Trade mode is not DISABLED
- Minimum 50 bars of M6 historical data available
- Valid bid/ask quotes available

### Per-Symbol Management
- Independent indicator calculations (EMA, RSI, ATR) for each symbol
- Separate grid tracking (lastGridPriceBuy, lastGridPriceSell)
- Individual position counters
- Isolated martingale level tracking

---

## Configuration Parameters

### Multi-Symbol & Timeframe
| Parameter | Default | Description |
|-----------|---------|-------------|
| TradeAllSymbols | true | Enable trading on all available symbols |
| SingleSymbol | "" | Specific symbol (when TradeAllSymbols=false) |
| EnforceM6 | true | Warning if not running on M6 timeframe |

### Risk Management
| Parameter | Default | Description |
|-----------|---------|-------------|
| BaseLotSize | 0.01 | Starting lot size for new positions |
| MaxLot | 10.0 | Maximum lot size per order |
| MaxPositionsPerSymbol | 10 | Position limit per symbol |
| MaxDrawdownPct | 30.0 | Maximum equity drawdown % before stopping |
| StopLossPips | 50 | Stop loss distance in pips |
| TakeProfitPips | 100 | Take profit distance in pips |

### Scalping Strategy
| Parameter | Default | Description |
|-----------|---------|-------------|
| UseScalping | true | Enable/disable scalping strategy |
| EMA_Fast | 5 | Fast EMA period |
| EMA_Slow | 20 | Slow EMA period |
| RSI_Period | 14 | RSI calculation period |
| RSI_Oversold | 30 | RSI oversold threshold |
| RSI_Overbought | 70 | RSI overbought threshold |

### Breakout Strategy
| Parameter | Default | Description |
|-----------|---------|-------------|
| UseBreakout | true | Enable/disable breakout strategy |
| BreakoutLookback | 20 | Number of bars for high/low range |
| BreakoutThreshold | 5.0 | Minimum breakout distance in pips |

### Grid & Martingale
| Parameter | Default | Description |
|-----------|---------|-------------|
| UseGrid | true | Enable/disable grid trading |
| GridStepPips | 30 | Distance between grid levels in pips |
| UseMartingale | true | Enable/disable martingale |
| MartingaleFactor | 1.5 | Lot multiplier for each level |
| MaxMartingaleLevel | 5 | Maximum martingale layers |

### Advanced
| Parameter | Default | Description |
|-----------|---------|-------------|
| MagicNumberBase | 120000 | Magic number for EA identification |
| Slippage | 10 | Maximum allowed slippage in points |

---

## Trading Logic Details

### Initialization Phase
1. Verify M6 timeframe (if EnforceM6 = true)
2. Store initial account balance for drawdown calculation
3. Configure CTrade object with magic number and slippage
4. Build list of tradeable symbols
5. Initialize indicators for each symbol:
   - Fast EMA handle
   - Slow EMA handle
   - RSI handle
   - ATR handle (for future enhancements)
6. Initialize grid tracking variables per symbol

### Per-Tick Execution Flow

```
OnTick()
├─ Check drawdown limit (equity vs balance)
│  └─ If exceeded, stop all trading and alert
│
├─ For each tradeable symbol:
│  ├─ Count current positions for symbol
│  ├─ Get current Ask/Bid prices
│  ├─ Copy indicator buffers (EMA fast/slow, RSI, ATR)
│  ├─ Calculate breakout levels (highest high, lowest low)
│  │
│  ├─ Generate signals:
│  │  ├─ Scalping signals (EMA cross + RSI)
│  │  ├─ Breakout signals (price vs range)
│  │  └─ Combine with OR logic (aggressive entry)
│  │
│  ├─ If no positions exist:
│  │  └─ Open new position on buy/sell signal
│  │
│  └─ If positions exist (< MaxPositionsPerSymbol):
│     └─ Check grid/martingale conditions:
│        ├─ Calculate grid step distance
│        ├─ Compare current price vs last grid price
│        └─ Open additional position with martingale lot size
```

### Signal Combination Logic
Signals from different strategies are combined using **OR logic** for aggressive entry:

```mql5
buySignal = (scalpingBuySignal OR breakoutBuySignal)
sellSignal = (scalpingSellSignal OR breakoutSellSignal)
```

This means a position will open if **any** enabled strategy generates a signal.

### Position Management

**New Position Opening:**
1. Check if position count = 0 for the symbol
2. Generate combined signal from all enabled strategies
3. Calculate normalized lot size (respecting SYMBOL_VOLUME_MIN/MAX/STEP)
4. Calculate SL/TP based on pip values (adjusted for 3/5 digit brokers)
5. Open position using CTrade.PositionOpen()
6. Store grid reference price (lastGridPriceBuy or lastGridPriceSell)
7. Reset martingale level counter to 0

**Grid/Martingale Addition:**
1. Check if existing positions < MaxPositionsPerSymbol
2. Calculate current price movement from last grid price
3. If movement >= GridStepPips (against position):
   - Calculate new lot size:
     - Grid only: Use BaseLotSize
     - Martingale enabled: Use (total current lots × MartingaleFactor)
   - Cap at MaxLot
   - Open additional position with same direction
   - Update lastGridPrice
   - Increment martingale level
4. Respect MaxMartingaleLevel limit

### Price Normalization

The EA handles different broker digit formats automatically:

```mql5
// Detect pip value
pipValue = (digits == 5 || digits == 3) ? point × 10 : point

// Calculate SL/TP
sl_buy = ask - (StopLossPips × pipValue)
tp_buy = ask + (TakeProfitPips × pipValue)
```

This ensures consistent pip calculations for both 4-digit (0.0001) and 5-digit (0.00001) quote precision.

---

## Risk Warnings

⚠️ **HIGH RISK TRADING SYSTEM**

This EA uses aggressive strategies with the following risk factors:

1. **Martingale Risk**: Position sizes can grow exponentially, leading to large drawdowns
2. **Grid Risk**: Multiple positions in same direction amplify losses during adverse moves
3. **Multi-Symbol Risk**: Trading many symbols simultaneously increases margin requirements
4. **High Frequency**: M6 timeframe generates frequent trades and commission costs
5. **Drawdown Risk**: Default 30% drawdown limit allows significant account reduction

**Recommendations:**
- Start with demo account testing
- Use conservative parameters initially
- Monitor margin levels closely
- Reduce MaxPositionsPerSymbol and MaxMartingaleLevel for lower risk
- Consider disabling martingale (UseMartingale = false) for safer operation
- Test with limited symbol count before enabling TradeAllSymbols

---

## Technical Implementation Notes

### MQL5 Features Used
- **CTrade Class**: Modern trade execution with result checking
- **Multiple Indicators**: Simultaneous indicator handles per symbol
- **Position Management**: POSITION_* functions for tracking open trades
- **Symbol Information**: Dynamic symbol property queries
- **Array Management**: Dynamic resizing for symbol lists and data structures

### Performance Considerations
- Indicator calculations cached using handles (efficient buffer copying)
- Per-symbol data structure avoids redundant lookups
- Position counting optimized with single loop
- Early returns for invalid data prevent unnecessary calculations

### Compatibility
- **MT5 Build**: Requires recent MT5 build supporting CTrade class
- **Broker Requirements**: ECN/STP brokers recommended (supports ORDER_FILLING_FOK)
- **Symbol Types**: Works with Forex, CFDs, and other instruments with valid M6 data
- **Timeframe**: Designed for M6 but will execute on any timeframe (warning displayed)

---

## Conclusion

EA_120_Logika implements a sophisticated multi-strategy trading system that combines short-term scalping with breakout detection, position averaging via grid trading, and loss recovery through martingale. The aggressive parameter defaults are designed for experienced traders seeking maximum profit potential with acceptance of substantial risk.

The multi-symbol capability allows portfolio diversification and 24/7 trading across different markets and sessions. Comprehensive risk management features (drawdown limits, position caps, fixed SL/TP) provide essential safeguards against catastrophic losses.

**Success with this EA requires:**
- Thorough testing and parameter optimization
- Understanding of martingale and grid risks
- Adequate account capitalization
- Active monitoring during live operation
- Disciplined risk management practices

For support and updates, refer to the source code comments and parameter descriptions in the EA interface.
