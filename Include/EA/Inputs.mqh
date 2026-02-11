//+------------------------------------------------------------------+
//|                                         EA_Inputs.mqh         |
//|                                    EA_120_Logika Includes        |
//|                                                                  |
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//| Input Parameters - Organized by Category                         |
//+------------------------------------------------------------------+

//=== General Settings ===
input group "=== General Settings ==="
input bool     InpTradeAllSymbols = true;        // Trade all available symbols
input string   InpSingleSymbol = "";             // Single symbol (if TradeAllSymbols=false)
input ENUM_TIMEFRAMES InpTimeframe = PERIOD_M6;  // Trading timeframe
input bool     InpEnforceTimeframe = true;       // Enforce specified timeframe only
input long     InpMagicNumberBase = 120000;      // Magic number base
input int      InpSlippage = 10;                 // Max slippage in points

//=== Risk Management ===
input group "=== Risk Management ==="
input double   InpBaseLotSize = 0.01;            // Base lot size (safer)
input double   InpMaxLot = 1.0;                  // Maximum lot per order
input int      InpMaxPositionsPerSymbol = 3;     // Max positions per symbol
input int      InpTotalMaxPositions = 10;        // Max total positions (all symbols)
input double   InpMaxDrawdownPct = 10.0;         // Max drawdown % (safer)
input double   InpDailyLossLimitPct = 3.0;       // Daily loss limit % (safer)
input double   InpMaxSpreadPips = 6.0;           // Max spread allowed (pips)
input double   InpMinAccountBalance = 500.0;     // Minimum account balance to trade

input group "=== Stop Loss & Take Profit ==="
input bool     InpUseFixedSLTP = true;           // Use fixed SL/TP (pips)
input double   InpStopLossPips = 20;             // Stop Loss in pips (safer)
input double   InpTakeProfitPips = 40;           // Take Profit in pips (safer)
input bool     InpUseTrailingStop = false;       // Enable trailing stop
input double   InpTrailingStartPips = 10;        // Trailing start (pips)
input double   InpTrailingStepPips = 5;          // Trailing step (pips)
input bool     InpUseBreakEven = false;          // Enable breakeven
input double   InpBreakEvenPips = 15;            // Breakeven trigger (pips)

input group "=== Money Management ==="
input bool     InpUseRiskPercent = true;         // Use risk % per trade (safer)
input double   InpRiskPercent = 0.5;             // Risk % per trade (safer)
input bool     InpUseKellyCriterion = false;     // Use Kelly criterion sizing

//=== Scalping Strategy ===
input group "=== Scalping Strategy (EMA/RSI) ==="
input bool     InpUseScalping = true;            // Enable scalping strategy
input int      InpEMAFast = 5;                   // Fast EMA period
input int      InpEMASlow = 20;                  // Slow EMA period
input int      InpRSIPeriod = 14;                // RSI period
input int      InpRSIOversold = 30;              // RSI oversold level
input int      InpRSIOverbought = 70;            // RSI overbought level
input bool     InpUseRSIMomentum = true;         // Use RSI momentum continuation
input bool     InpUseADXFilter = false;          // Use ADX trend filter
input int      InpADXPeriod = 14;                // ADX period
input double   InpADXMinimum = 25.0;             // Minimum ADX level

//=== Breakout Strategy ===
input group "=== Breakout Strategy ==="
input bool     InpUseBreakout = true;            // Enable breakout strategy
input int      InpBreakoutLookback = 20;         // Breakout lookback bars
input double   InpBreakoutThreshold = 5.0;       // Breakout threshold (pips)
input bool     InpUseVolumeConfirmation = false; // Use volume confirmation
input double   InpVolumeMultiplier = 1.5;        // Volume multiplier threshold

//=== Grid & Martingale ===
input group "=== Grid Trading ==="
input bool     InpUseGrid = false;               // Disable grid trading by default (safer)
input double   InpGridStepPips = 40;             // Grid step in pips (safer)
input int      InpMaxGridLevels = 3;             // Max grid levels (safer)
input bool     InpGridTrailingStop = true;       // Use trailing stop on grid (new)

input group "=== Martingale System ==="
input bool     InpUseMartingale = false;         // Disable martingale by default (safer)
input double   InpMartingaleFactor = 1.2;        // Lot multiplier (safer)
input int      InpMaxMartingaleLevel = 3;        // Max martingale levels (safer)
input bool     InpResetMartingaleOnProfit = true; // Reset after profitable close
input bool     InpMartingaleUseEquityRecovery = false; // Disable equity-based recovery (safer)

//=== Trading Hours & Filters ===
input group "=== Trading Sessions ==="
input bool     InpFilterBySession = true;        // Filter by trading session (enabled for safety)
input ENUM_TRADING_SESSION InpTradeSession = SESSION_ALL; // Trading session (changed from invalid SESSION_LONDON_NY)
input bool     InpTradeAsian = false;            // Don't trade Asian session by default
input bool     InpTradeLondon = true;            // Trade London session
input bool     InpTradeNewYork = true;           // Trade New York session

input group "=== Time Filters ==="
input bool     InpAvoidNewsHours = true;         // Avoid high-impact news hours (enabled for safety)
input int      InpNewsWindowMinutes = 30;        // News window (minutes before/after)
input bool     InpAvoidWeekend = true;           // Avoid trading on weekends
input bool     InpFridayClosePositions = true;   // Close positions Friday evening (enabled for safety)
input int      InpFridayCloseHour = 20;          // Friday close hour (server time)

input group "=== Signal Filters ==="
input bool     InpUseTrendFilter = true;         // Filter by higher timeframe trend (enabled for safety)
input ENUM_TIMEFRAMES InpTrendTimeframe = PERIOD_H1; // Trend filter timeframe
input int      InpMinSignalStrength = 2;         // Minimum signal strength (1-3, increased for safety)

//=== AI-Enhanced Features ===
input group "=== AI-Enhanced Features ==="
input bool     InpUseAdaptiveSLTP = false;       // Adjust SL/TP based on volatility (disabled for safety)
input bool     InpUseMarketSentiment = false;    // Analyze market sentiment (disabled for safety)
input bool     InpUseNewsFilter = true;          // Enhanced news filter
input bool     InpUseCorrelationFilter = false;  // Filter correlated symbols (disabled for safety)
input bool     InpUseVolatilityFilter = false;   // Trade only during optimal volatility (disabled for safety)
input bool     InpUseSmartMoneyFlow = false;     // Smart Money Flow analysis (disabled for safety)
input bool     InpUseMachineLearningFilter = false; // ML-based signal validation (disabled for safety)
input double   InpVolatilityThreshold = 1.5;     // Volatility filter threshold
input int      InpCorrelationThreshold = 0.7;    // Correlation threshold (0.0-1.0)
input double   InpSmartMoneyMultiplier = 1.3;    // Smart Money confidence multiplier