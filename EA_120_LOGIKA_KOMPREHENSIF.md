# EA_120_Logika - Enhanced Multi-Strategy Trading System

## Overview

**Version:** 2.02 (AI-Enhanced)  
**Platform:** MetaTrader 5  
**Language:** MQL5  

EA_120_Logika is an advanced multi-symbol, multi-strategy Expert Advisor designed for 24/7 automated trading. This AI-enhanced version includes sophisticated market analysis, adaptive parameters, smart money flow detection, and machine learning-based signal validation.

## Table of Contents

1. [Key Features](#key-features)
2. [AI-Enhanced Features](#ai-enhanced-features)
3. [Strategy Components](#strategy-components)
4. [Risk Management](#risk-management)
5. [Multi-Symbol Trading](#multi-symbol-trading)
6. [Configuration Parameters](#configuration-parameters)
7. [Trading Logic Details](#trading-logic-details)
8. [New in Version 2.02](#new-in-version-202)
9. [Installation & Setup](#installation--setup)
10. [Risk Warnings](#risk-warnings)
11. [Performance Optimization](#performance-optimization)

---

## Key Features

### Core Capabilities
- ✅ **Multi-Symbol Trading** - Trade single symbol or scan all available symbols
- ✅ **Multi-Timeframe Support** - Configurable timeframe (default M6)
- ✅ **Four Combined Strategies** - Scalping, Breakout, Grid, Martingale (all enabled by default)
- ✅ **Advanced Risk Management** - Drawdown limits (35%), daily loss limits (12%), position caps
- ✅ **Trade Management** - Trailing stops, breakeven, grid trailing stop
- ✅ **Session Filtering** - Trade specific sessions (Asian, London, New York) - all enabled
- ✅ **Time Filters** - Weekend avoidance, news hour filtering (disabled by default for aggressive mode)
- ✅ **Signal Quality** - Multi-level signal strength with trend confirmation
- ✅ **Kelly Criterion** - Advanced position sizing option
- ✅ **Equity Recovery** - Martingale equity-based recovery system
- ✅ **Comprehensive Statistics** - Per-symbol tracking and reporting
- ✅ **AI-Enhanced Analysis** - Smart market analysis and adaptive trading

### Aggressive Trading Parameters (v2.02 Default)
| Parameter | Conservative | Aggressive (Default) |
|-----------|--------------|---------------------|
| Base Lot | 0.01 | 0.02 |
| Max Drawdown | 20% | 35% |
| Daily Loss Limit | 5% | 12% |
| Stop Loss | 60 pips | 40 pips |
| Take Profit | 120 pips | 80 pips |
| Grid Step | 40 pips | 25 pips |
| Max Grid Levels | 5 | 12 |
| Martingale Factor | 1.3 | 1.7 |
| Max Martingale Level | 3 | 7 |

---

## AI-Enhanced Features

Version 2.02 introduces advanced AI-like capabilities to make trading decisions smarter and more adaptive:

### 1. Adaptive SL/TP (Stop Loss / Take Profit)
**Dynamic risk management based on market volatility**

| Feature | Description |
|---------|-------------|
| Volatility Adjustment | SL/TP automatically adjusts based on current market volatility |
| ATR-Based Minimum | Ensures SL/TP never goes below ATR-based minimums |
| Smart Multiplier | Higher confidence signals get wider TP for more profit potential |

**How it works:**
- When volatility is HIGH (>1.5x average): Wider SL to avoid noise triggers
- When volatility is LOW (<0.8x average): Tighter SL for better risk/reward
- High ML confidence: Wider TP to capture more profit

### 2. Market Sentiment Analysis
**Multi-indicator sentiment scoring**

| Indicator | Weight | Bullish Signal | Bearish Signal |
|-----------|--------|----------------|----------------|
| RSI | 30% | < 30 (oversold) | > 70 (overbought) |
| EMA Trend | 20% | Fast > Slow | Fast < Slow |
| ADX Trend | 15% | DI+ > DI- | DI- > DI+ |

**Sentiment Score Range:** -1.0 (strongly bearish) to +1.0 (strongly bullish)

### 3. Smart Money Flow Analysis
**Detects institutional trading patterns**

Smart Money Flow = (Volume Ratio × Price Change) / Price Range

- High positive flow: Institutional buying detected
- High negative flow: Institutional selling detected
- Used to filter signals and boost confidence

### 4. Machine Learning Signal Validation
**Historical performance-based confidence scoring**

**ML Confidence Formula:**
```
Confidence = (WinRate × 0.3) + (SignalStrength × 0.4) + (MarketConditions × 0.3)
```

**Features considered:**
- Historical win rate per symbol
- Average profit per trade
- Current signal strength
- Volatility regime
- Trend alignment

**Filtering:** Signals with confidence < 40% are rejected

### 5. Volatility Filter
**Trade only during optimal market conditions**

| Volatility Ratio | Action |
|------------------|--------|
| < 0.5x | Skip - Too quiet |
| 0.8x - 1.5x | Optimal - Trade allowed |
| > 1.5x | Skip - Too volatile |

### 6. Correlation Filter
**Avoid over-exposure to correlated pairs**

| Check | Method |
|-------|--------|
| Currency Family | Same base currency (e.g., USD pairs) |
| Volatility Pattern | Similar volatility ratios |

**Benefit:** Prevents over-trading correlated pairs, reducing risk concentration

### 7. Enhanced News Filter
**Smart news avoidance during high-impact periods**

The system avoids trading during major economic events:
- Major central bank announcements
- NFP releases
- Key economic indicators

**Implementation:** Configurable news window (default: ±30 minutes from news events)

### Configuration Parameters (AI Features)

| Parameter | Default | Range | Description |
|----------|---------|-------|-------------|
| InpUseAdaptiveSLTP | true | true/false | Enable adaptive SL/TP |
| InpUseMarketSentiment | true | true/false | Enable sentiment analysis |
| InpUseNewsFilter | true | true/false | Enable news filter |
| InpUseCorrelationFilter | true | true/false | Enable correlation check |
| InpUseVolatilityFilter | true | true/false | Enable volatility filter |
| InpUseSmartMoneyFlow | true | true/false | Enable smart money detection |
| InpUseMachineLearningFilter | true | true/false | Enable ML signal validation |
| InpVolatilityThreshold | 1.5 | 0.5-3.0 | Volatility multiplier threshold |
| InpCorrelationThreshold | 0.7 | 0.0-1.0 | Correlation detection threshold |
| InpSmartMoneyMultiplier | 1.3 | 0.5-2.0 | Strong signal confidence multiplier |

---

## Strategy Components

### 1. Scalping Strategy (EMA/RSI)
**Precision short-term momentum trading with trend confirmation**

| Component | Default | Description |
|-----------|---------|-------------|
| Fast EMA | 5 periods | Quick response to price changes |
| Slow EMA | 20 periods | Trend direction filter |
| RSI Period | 14 | Momentum oscillator |
| RSI Oversold | 30 | Buy zone threshold |
| RSI Overbought | 70 | Sell zone threshold |

**Entry Logic:**

**Strong Buy Signal (Strength +2):**
- Fast EMA crosses above Slow EMA AND
- RSI < 30 (oversold)

**Momentum Buy (Strength +1):**
- Fast EMA > Slow EMA AND
- RSI between 50-70

**Strong Sell Signal (Strength +2):**
- Fast EMA crosses below Slow EMA AND
- RSI > 70 (overbought)

**Momentum Sell (Strength +1):**
- Fast EMA < Slow EMA AND
- RSI between 30-50

**ADX Filter (Optional):**
- ADX > 25 confirms trending market
- DI+ > DI- confirms bullish trend
- DI- > DI+ confirms bearish trend

### 2. Breakout Strategy
**Range breakout with volume confirmation**

| Parameter | Default | Description |
|-----------|---------|-------------|
| Lookback | 20 bars | Analysis period for high/low |
| Threshold | 5 pips | Minimum breakout distance |
| Volume Filter | Optional | Confirms breakout strength |

**Entry Logic:**
- **Buy**: Ask price > Highest High(20) + 5 pips
- **Sell**: Bid price < Lowest Low(20) - 5 pips

### 3. Grid Trading
**Systematic position averaging at price intervals**

| Parameter | Default | Description |
|-----------|---------|-------------|
| Grid Step | 30 pips | Distance between grid levels |
| Max Levels | 10 | Maximum grid positions |
| Trailing Stop | Optional | Protect grid positions |

**Grid Behavior:**
- Opens additional positions when price moves against existing trade by GridStep
- Tracks separate grid levels for buy and sell directions
- Resets when all positions in direction close

### 4. Martingale System
**Progressive position sizing for drawdown recovery**

| Parameter | Default | Description |
|-----------|---------|-------------|
| Multiplier | 1.5x | Lot size increase per level |
| Max Levels | 5 | Maximum martingale depth |
| Auto-Reset | Enabled | Reset on profitable close |

**Safety Features:**
- Respects MaxLot per order limit
- Respects MaxPositionsPerSymbol limit
- Can reset when grid becomes profitable

---

## Risk Management

### Multi-Layer Protection System

#### 1. Drawdown Protection
```
Trigger: (Balance - Equity) / Balance × 100% ≥ MaxDrawdown%
Action: Stop all trading, generate alert
Default: 30%
Range: 5% - 100%
```

#### 2. Daily Loss Limit
```
Trigger: Daily loss ≥ DailyLossLimit%
Action: Stop trading until next day
Reset: Automatic at midnight server time
Default: 10%
```

#### 3. Position Limits
| Limit | Default | Purpose |
|-------|---------|---------|
| Per Symbol | 10 | Prevent overexposure |
| Total | 100 | Portfolio-wide cap |
| Per Order | 10.0 | Single trade limit |

#### 4. Account Protection
- Minimum balance check
- Margin level monitoring
- Spread filtering (max 5 pips default)

### Trade Management

#### Fixed SL/TP Mode
- **Stop Loss**: 50 pips (default)
- **Take Profit**: 100 pips (default)
- Applied to every position automatically

#### Trailing Stop
```
Activation: Profit ≥ TrailingStart (50 pips)
Adjustment: Trail price by TrailingStep (20 pips)
Lock-in: Protects profits as price moves favorably
```

#### Breakeven
```
Trigger: Profit ≥ BreakevenTrigger (30 pips)
Action: Move SL to entry + 2 pips
Purpose: Risk-free trades
```

### Money Management Options

| Method | Description |
|--------|-------------|
| Fixed Lot | Constant lot size per trade |
| Risk Percent | Risk X% of balance per trade |
| Kelly Criterion | Optimal sizing based on win rate |
| Martingale | Increase after losses |

**Kelly Criterion Formula (Half-Kelly):**
```
K% = (WinRate - (1 - WinRate) / (AvgWin/AvgLoss)) / 2
Lot = BaseLot × K%
```

---

## Multi-Symbol Trading

### Symbol Selection Modes

#### Mode 1: All Symbols (Recommended for diversification)
```
TradeAllSymbols = true
- Automatically scans all Market Watch symbols
- Filters for tradeable pairs only
- Validates spread and data availability
- Maximum 1000 symbols
```

#### Mode 2: Single Symbol
```
TradeAllSymbols = false
SingleSymbol = "EURUSD"
- Focused trading on one instrument
- Falls back to chart symbol if empty
```

### Symbol Validation Criteria
1. ✓ Symbol exists in Market Watch
2. ✓ Trade mode is not DISABLED
3. ✓ Minimum 100 bars of historical data
4. ✓ Current spread ≤ MaxSpread × 2
5. ✓ Valid bid/ask prices

### Per-Symbol Tracking
Each symbol maintains independent:
- Indicator handles (EMA, RSI, ATR, ADX)
- Grid tracking variables
- Position statistics
- Magic number (base + index)
- Signal history
- Performance metrics

---

## Configuration Parameters

### General Settings
| Parameter | Default | Range | Description |
|-----------|---------|-------|-------------|
| TradeAllSymbols | true | bool | Trade all available symbols |
| SingleSymbol | "" | string | Specific symbol to trade |
| Timeframe | PERIOD_M6 | ENUM | Trading timeframe |
| EnforceTimeframe | true | bool | Warn if chart TF differs |
| MagicNumberBase | 120000 | long | Base magic number |
| Slippage | 10 | int | Max slippage in points |

### Risk Management
| Parameter | Default | Range | Description |
|-----------|---------|-------|-------------|
| BaseLotSize | 0.01 | > 0 | Starting lot size |
| MaxLot | 10.0 | ≥ BaseLot | Maximum per order |
| MaxPositionsPerSymbol | 10 | > 0 | Symbol position limit |
| TotalMaxPositions | 100 | ≥ PerSymbol | Portfolio limit |
| MaxDrawdownPct | 30.0 | 5-100 | Equity drawdown limit |
| DailyLossLimitPct | 10.0 | 0-100 | Daily loss limit |
| MaxSpreadPips | 5.0 | > 0 | Max allowed spread |
| MinAccountBalance | 100.0 | > 0 | Minimum to trade |

### Stop Loss & Take Profit
| Parameter | Default | Range | Description |
|-----------|---------|-------|-------------|
| UseFixedSLTP | true | bool | Enable fixed SL/TP |
| StopLossPips | 50 | > 0 | Stop loss distance |
| TakeProfitPips | 100 | > 0 | Take profit distance |
| UseTrailingStop | false | bool | Enable trailing |
| TrailingStartPips | 50 | > 0 | Trail activation |
| TrailingStepPips | 20 | > 0 | Trail adjustment |
| UseBreakEven | false | bool | Enable breakeven |
| BreakEvenPips | 30 | > 0 | BE trigger level |

### Money Management
| Parameter | Default | Range | Description |
|-----------|---------|-------|-------------|
| UseRiskPercent | false | bool | Risk % sizing |
| RiskPercent | 1.0 | > 0 | Risk per trade % |
| UseKellyCriterion | false | bool | Kelly sizing |

### Scalping Strategy
| Parameter | Default | Range | Description |
|-----------|---------|-------|-------------|
| UseScalping | true | bool | Enable strategy |
| EMAFast | 5 | ≥ 1 | Fast EMA period |
| EMASlow | 20 | > Fast | Slow EMA period |
| RSIPeriod | 14 | ≥ 2 | RSI period |
| RSIOversold | 30 | 0-100 | Oversold level |
| RSIOverbought | 70 | 0-100 | Overbought level |
| UseRSIMomentum | true | bool | RSI continuation |
| UseADXFilter | false | bool | Trend filter |
| ADXPeriod | 14 | ≥ 1 | ADX period |
| ADXMinimum | 25.0 | > 0 | Minimum ADX |

### Breakout Strategy
| Parameter | Default | Range | Description |
|-----------|---------|-------|-------------|
| UseBreakout | true | bool | Enable strategy |
| BreakoutLookback | 20 | ≥ 5 | Lookback bars |
| BreakoutThreshold | 5.0 | > 0 | Threshold pips |
| UseVolumeConfirmation | false | bool | Volume filter |
| VolumeMultiplier | 1.5 | > 0 | Volume threshold |

### Grid Trading
| Parameter | Default | Range | Description |
|-----------|---------|-------|-------------|
| UseGrid | true | bool | Enable grid |
| GridStepPips | 30 | ≥ 5 | Grid step |
| MaxGridLevels | 10 | ≥ 1 | Max levels |
| GridTrailingStop | false | bool | Trail grid |

### Martingale
| Parameter | Default | Range | Description |
|-----------|---------|-------|-------------|
| UseMartingale | true | bool | Enable martingale |
| MartingaleFactor | 1.5 | ≥ 1.0 | Lot multiplier |
| MaxMartingaleLevel | 5 | ≥ 0 | Max depth |
| ResetOnProfit | true | bool | Reset on win |
| UseEquityRecovery | false | bool | Equity-based reset |

### Trading Sessions
| Parameter | Default | Options | Description |
|-----------|---------|---------|-------------|
| FilterBySession | false | bool | Enable filtering |
| TradeSession | SESSION_ALL | ENUM | Primary session |
| TradeAsian | true | bool | Asian session |
| TradeLondon | true | bool | London session |
| TradeNewYork | true | bool | NY session |

### Time Filters
| Parameter | Default | Description |
|-----------|---------|-------------|
| AvoidNewsHours | false | Skip high-impact periods |
| NewsWindowMinutes | 30 | Buffer around news |
| AvoidWeekend | true | No weekend trading |
| FridayClosePositions | false | Close Friday evening |
| FridayCloseHour | 20 | Close hour (server) |

### Signal Filters
| Parameter | Default | Description |
|-----------|---------|-------------|
| UseTrendFilter | false | HTF trend confirmation |
| TrendTimeframe | PERIOD_H1 | Higher timeframe |
| MinSignalStrength | 1 | Minimum 1-3 strength |

---

## Trading Logic Details

### Initialization Sequence
```
1. Validate all input parameters
2. Check timeframe enforcement
3. Store initial balance/equity
4. Configure CTrade object
5. Build symbol list (scan/filter)
6. Initialize indicators per symbol
7. Set up timer (60-second interval)
8. Log configuration summary
```

### Per-Tick Execution Flow
```
OnTick()
├─ Check if trading enabled
├─ Validate trading conditions
│  ├─ Drawdown limit
│  ├─ Daily loss limit
│  ├─ Account balance
│  ├─ Total positions
│  ├─ Trading session
│  └─ Weekend check
│
├─ FOR each symbol:
│  ├─ Check spread filter
│  ├─ Update position info
│  ├─ Manage open positions (trail/BE)
│  ├─ Check martingale reset
│  ├─ Copy indicator buffers
│  ├─ Calculate breakout levels
│  │
│  ├─ Generate signals:
│  │  ├─ Scalping (EMA + RSI + ADX)
│  │  ├─ Breakout (range + volume)
│  │  ├─ Assign strength scores
│  │  ├─ Apply trend filter
│  │  └─ Combine with OR logic
│  │
│  ├─ IF no positions AND signal:
│  │  └─ Calculate lot size
│  │  └─ Open position
│  │
│  └─ IF positions exist AND < max:
│     └─ Check grid/martingale
│        ├─ Calculate grid distance
│        ├─ Compare to last grid price
│        └─ Open additional position
```

### Signal Strength System

| Score | Description |
|-------|-------------|
| 1 | Basic momentum signal |
| 2 | Strong crossover signal |
| 3+ | Combined strategy confirmation |

**Minimum Signal Strength Filter:**
- Level 1: Any signal accepted
- Level 2: Requires strong signal
- Level 3: Requires confirmation

### Lot Size Calculation Priority
1. **Kelly Criterion** (if enabled and sufficient history)
2. **Risk Percent** (if enabled)
3. **Martingale Multiplier** (if applicable)
4. **Base Lot Size** (default)

### Position Management Priority
1. Breakeven check
2. Trailing stop adjustment
3. Grid/martingale evaluation

---

## New in Version 2.02 (AI-Enhanced)

### Major AI-Like Enhancements

#### 1. **Adaptive SL/TP System**
- Dynamic Stop Loss/Take Profit based on market volatility
- ATR-based minimum SL/TP protection
- Smart multiplier for high-confidence signals
- Volatility-adjusted risk management (0.8x to 1.5x multiplier)

#### 2. **Market Sentiment Analysis**
- Multi-indicator sentiment scoring system
- RSI oversold/overbought analysis (+/- 0.3 weight)
- EMA trend confirmation (+/- 0.2 weight)
- ADX trend strength filter (+/- 0.15 weight)
- Normalized sentiment score: -1.0 to +1.0 range

#### 3. **Smart Money Flow Detection**
- Volume-based institutional trading pattern analysis
- Smart Money Flow calculation: (Volume Ratio × Price Change) / Price Range
- Institutional buying/selling detection
- Signal confidence boosting based on flow analysis

#### 4. **Machine Learning Signal Validation**
- Historical performance-based confidence scoring
- Win rate analysis per symbol
- Signal strength confidence assessment
- Market conditions evaluation
- Automatic filtering of signals with confidence < 40%

#### 5. **Enhanced Market Analysis**
- **Volatility Filter**: Trade only during optimal volatility (0.8x - 1.5x average)
- **Correlation Filter**: Avoid over-exposure to correlated pairs
- **Enhanced News Filter**: Smart avoidance during high-impact events
- **Real-time Volatility Tracking**: 20-period ATR analysis

#### 6. **AI-Enhanced Parameters**
- InpUseAdaptiveSLTP: Enable volatility-based SL/TP adjustment
- InpUseMarketSentiment: Multi-indicator sentiment analysis
- InpUseSmartMoneyFlow: Institutional flow detection
- InpUseMachineLearningFilter: ML-based signal validation
- InpVolatilityThreshold: 1.5x volatility multiplier threshold
- InpCorrelationThreshold: 0.7 correlation detection threshold

#### 7. **Performance Optimization**
- SymbolData structure enhancement with AI metrics
- Real-time sentiment and volatility tracking
- Smart correlation detection across currency families
- Enhanced logging for AI analysis results

#### 8. **Risk Management Improvements**
- Volatility-adjusted position sizing
- Market condition-based signal filtering
- Correlation-based exposure management
- Sentiment-driven trade timing optimization

### Technical Implementation

#### New Functions Added:
- `CalculateAdaptiveSLTP()` - Volatility-based SL/TP adjustment
- `AnalyzeMarketSentiment()` - Multi-indicator sentiment analysis
- `CalculateSmartMoneyFlow()` - Institutional flow detection
- `CalculateMLConfidence()` - ML-based confidence scoring
- `IsCorrelatedSymbol()` - Correlation analysis
- `IsOptimalVolatility()` - Volatility condition check

#### Enhanced Data Structures:
- Added AI metrics to SymbolData structure
- Real-time volatility tracking
- Sentiment score storage
- Smart money flow calculation
- ML confidence scoring
- Correlation flagging

---

## New in Version 2.01 (Aggressive Mode)

### Major Enhancements

#### 1. **Aggressive Multi-Strategy Combinations**
- Combined EMA/RSI scalping + breakout strategy signals
- Enhanced signal strength scoring (1-4+ for combined strategies)
- Aggressive momentum continuation signals (RSI zones 40-65, 35-60)
- Extreme RSI signals (RSI < 20, RSI > 80) for additional entries
- Signal combination bonus: Both strategies agree = +2 strength

#### 2. **Enhanced Grid & Martingale System**
- Increased max grid levels from 10 to 12
- Higher martingale factor: 1.7 (previously 1.5)
- Extended max martingale level: 7 (previously 5)
- Equity-based recovery system (new)
- Grid trailing stop functionality (new)
- Recovery grid levels when equity drawdown exceeds 1%

#### 3. **Aggressive Risk Parameters (Default)**
- Base lot increased: 0.02 (previously 0.01)
- Max drawdown: 35% (previously 30%)
- Daily loss limit: 12% (previously 10%)
- Reduced SL/TP: 40/80 pips (previously 50/100)
- Grid step: 25 pips (previously 30)
- Minimum account balance: $50 (previously $100)
- Max spread: 6 pips (previously 5)

#### 4. **Enhanced Order Management**
- ATR-based dynamic SL/TP adjustment
- Order retry logic with brief pause
- Enhanced strategy identification in order comments
- Grid trailing stop management
- Equity recovery grid entries

#### 5. **Aggressive Trading Hours**
- Session filtering disabled by default (trade 24/7)
- News hour avoidance disabled by default
- Friday position closing disabled by default
- All trading sessions enabled (Asian/London/NY)

#### 6. **Volume Confirmation**
- Volume indicator creation for breakout confirmation
- Average volume calculation for signal enhancement
- Volume multiplier threshold (1.5x)

#### 7. **Enhanced Error Handling & Logging**
- Retry mechanism for failed order placement
- Detailed grid level logging
- Recovery level tracking
- Strategy combination identification
- Enhanced position tracking per symbol

---

## New in Version 2.0

### Major Enhancements

#### 1. **Enhanced Risk Management**
- Daily loss limits with automatic reset
- Per-symbol position tracking
- Total position cap across all symbols
- Spread-based trade filtering
- Minimum account balance protection

#### 2. **Advanced Trade Management**
- Trailing stop with customizable step
- Breakeven functionality
- Partial close capability (framework)
- Position modification tracking

#### 3. **Session & Time Controls**
- Trading session filtering (Asian/London/NY)
- Configurable session hours
- Weekend trading controls
- Friday position closing option
- News hour avoidance (framework)

#### 4. **Signal Quality Improvements**
- Multi-level signal strength (1-3+)
- ADX trend filter for scalping
- Volume confirmation for breakouts
- Higher timeframe trend filter
- Minimum signal strength threshold

#### 5. **Money Management Options**
- Kelly criterion position sizing
- Risk percent per trade
- Win/loss tracking per symbol
- Performance statistics

#### 6. **Code Architecture**
- Structured SymbolData class
- Comprehensive constants file
- Error code definitions
- Timer-based operations
- Enhanced error handling

#### 7. **User Experience**
- Organized parameter groups
- Detailed initialization logging
- Per-symbol statistics
- Final performance report
- Comprehensive comments

---

## Installation & Setup

### Step 1: File Placement
```
MetaTrader 5/
├─ MQL5/
│  ├─ Experts/
│  │  └─ EA_120_Logika.mq5
│  └─ Include/
│     └─ EA_120_Logika/
│        └─ Include/
│           └─ Common/
│              └─ Constants.mqh
```

### Step 2: Compilation
1. Open MetaEditor
2. Load `EA_120_Logika.mq5`
3. Press F7 to compile
4. Fix any compilation errors

### Step 3: Chart Setup
1. Open desired chart (recommended: M6)
2. Attach EA to chart
3. Configure parameters in dialog
4. Enable "Allow DLL imports" if needed
5. Enable "Allow live trading"

### Step 4: Recommended Initial Settings
```
BaseLotSize = 0.01
MaxLot = 0.5
MaxPositionsPerSymbol = 3
MaxDrawdownPct = 15
UseMartingale = false (initially)
UseTrailingStop = true
```

---

## Risk Warnings

### ⚠️ HIGH RISK TRADING SYSTEM

**This EA employs aggressive strategies that can result in significant losses:**

1. **Martingale Risk**
   - Position sizes grow exponentially
   - Can consume entire account quickly
   - Recommended: Start with UseMartingale = false

2. **Grid Risk**
   - Multiple positions amplify losses
   - Requires significant margin
   - Monitor free margin closely

3. **Multi-Symbol Risk**
   - Simultaneous trading increases exposure
   - Correlated pairs can move together
   - Spread costs multiply with symbols

4. **High-Frequency Risk**
   - M6 timeframe generates many trades
   - Commission costs accumulate
   - Slippage impact increases

### Risk Mitigation Recommendations

| Risk Level | Settings |
|------------|----------|
| Conservative | BaseLot=0.01, MaxLot=0.1, MaxPos=3, Martingale=false, Grid=false |
| Moderate | BaseLot=0.01, MaxLot=0.5, MaxPos=5, Martingale=false, Grid=true |
| Aggressive | BaseLot=0.02, MaxLot=2.0, MaxPos=10, Martingale=true, Grid=true |

**Essential Practices:**
- ✅ Start with demo account for 3+ months
- ✅ Use VPS for 24/7 operation
- ✅ Monitor daily/weekly performance
- ✅ Set conservative initial parameters
- ✅ Keep sufficient free margin (50%+)
- ✅ Have stop-loss on broker side
- ✅ Regular withdrawal of profits
- ✅ Disable before major news events

---

## Performance Optimization

### Recommended VPS Specifications
- RAM: 2GB minimum, 4GB recommended
- CPU: 2+ cores
- OS: Windows Server 2019/2022
- Latency: < 10ms to broker

### Broker Requirements
- ECN/STP execution
- Low spreads (< 2 pips majors)
- No dealing desk intervention
- Supports ORDER_FILLING_FOK
- Minimum 1:100 leverage

### Symbol Recommendations
**High Priority (low spread, high liquidity):**
- EURUSD, GBPUSD, USDJPY
- XAUUSD (if spread allows)

**Medium Priority:**
- AUDUSD, USDCAD, USDCHF
- EURGBP, EURJPY

**Avoid:**
- Exotic pairs (high spread)
- Low volume CFDs
- Custom/synthetic indices

### Optimal Parameters by Account Size

| Account | BaseLot | MaxLot | MaxPos | MaxSymbols |
|---------|---------|--------|--------|------------|
| $500 | 0.01 | 0.05 | 3 | 5 |
| $1,000 | 0.01 | 0.1 | 5 | 10 |
| $5,000 | 0.02 | 0.5 | 7 | 20 |
| $10,000 | 0.05 | 1.0 | 10 | 50 |
| $50,000+ | 0.1 | 5.0 | 10 | 100 |

---

## Support & Troubleshooting

### Common Issues

**"Insufficient data" error:**
- Load more historical data
- Reduce BreakoutLookback parameter

**Orders not opening:**
- Check MaxSpreadPips setting
- Verify trading session hours
- Check MaxPositionsPerSymbol

**High drawdown:**
- Reduce BaseLotSize
- Disable Martingale
- Enable UseTrailingStop

**EA not trading:**
- Verify AutoTrading is enabled
- Check timeframe enforcement
- Review trading session settings

### Debug Information
Enable detailed logging in MT5:
```
Tools → Options → Expert Advisors → 
☑ Enable debug logging
```

---

## Legal Disclaimer

This software is provided "AS IS" without warranties. Trading forex involves substantial risk of loss. Past performance does not guarantee future results. The authors assume no liability for trading losses incurred using this EA.

**Use at your own risk.**

---

*Documentation Version 2.0*  
*Last Updated: 2024*
