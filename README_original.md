# EA_120_Logika - Enhanced Multi-Strategy Trading System

## Overview

**Version:** 2.02 (AI-Enhanced)  
**Platform:** MetaTrader 5  
**Language:** MQL5  

EA_120_Logika is an advanced multi-symbol, multi-strategy Expert Advisor designed for 24/7 automated trading. This AI-enhanced version includes sophisticated market analysis, adaptive parameters, smart money flow detection, and machine learning-based signal validation.

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

## AI-Enhanced Features

Version 2.02 introduces advanced AI-like capabilities to make trading decisions smarter and more adaptive:

### 1. Adaptive SL/TP (Stop Loss / Take Profit)
**Dynamic risk management based on market volatility**

| Feature | Description |
|---------|-------------|
| Volatility Adjustment | SL/TP automatically adjusts based on current market volatility |
| ATR-Based Minimum | Ensures SL/TP never goes below ATR-based minimums |
| Smart Multiplier | Higher confidence signals get wider TP for more profit potential |

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

### 2. Breakout Strategy
**Range breakout with volume confirmation**

| Parameter | Default | Description |
|-----------|---------|-------------|
| Lookback | 20 bars | Analysis period for high/low |
| Threshold | 5 pips | Minimum breakout distance |
| Volume Filter | Optional | Confirms breakout strength |

### 3. Grid Trading
**Systematic position averaging at price intervals**

| Parameter | Default | Description |
|-----------|---------|-------------|
| Grid Step | 30 pips | Distance between grid levels |
| Max Levels | 10 | Maximum grid positions |
| Trailing Stop | Optional | Protect grid positions |

### 4. Martingale System
**Progressive position sizing for drawdown recovery**

| Parameter | Default | Description |
|-----------|---------|-------------|
| Multiplier | 1.5x | Lot size increase per level |
| Max Levels | 5 | Maximum martingale depth |
| Auto-Reset | Enabled | Reset on profitable close |

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

## Installation & Setup

1. Download the compiled .ex5 file
2. Place it in your MT5 Experts folder
3. Restart MetaTrader 5
4. Open the chart where you want to apply the EA (or use on any timeframe)
5. Drag and drop the EA onto the chart
6. Configure the input parameters according to your preferences
7. Allow automated trading in the MT5 settings

## Risk Warnings

⚠️ **IMPORTANT RISK DISCLOSURE**: Past performance does not guarantee future results. This trading system involves substantial risk and may not be suitable for all investors. You should carefully consider your financial situation and risk tolerance before using this system. The use of leverage and margin trading can work against you as well as for you, potentially leading to significant losses that exceed your initial deposit.

## Performance Optimization

- Use a VPS for 24/7 operation
- Monitor account balance and equity regularly
- Adjust parameters based on market conditions
- Keep spreads low by choosing appropriate brokers
- Regular monitoring and maintenance recommended

---

*This README provides an overview of the EA_120_Logika trading system. For detailed parameter descriptions and advanced configurations, please refer to the complete documentation.*