//+------------------------------------------------------------------+
//|                                           dlregesign_recode.mq5 |
//|                        Enhanced Multi-Symbol Multi-Strategy EA   |
//|                                    Redesigned & Reoptimized 1.0  |
//+------------------------------------------------------------------+
#property copyright "DLRegesign Team"
#property link      ""
#property version   "1.00"
#property strict

#include <Trade\\Trade.mqh>
#include <Arrays\\ArrayLong.mqh>

//+------------------------------------------------------------------+
//| Input Parameters - Organized by Category                         |
//+------------------------------------------------------------------

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
input ENUM_TRADING_SESSION InpTradeSession = SESSION_LONDON_NY; // Trading session (default to active sessions)
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

//+------------------------------------------------------------------+
//| Enums and Constants                                              |
//+------------------------------------------------------------------+

// Trading Session
enum ENUM_TRADING_SESSION
{
   SESSION_ASIAN,      // Asian session (Tokyo)
   SESSION_LONDON,     // London session
   SESSION_NEWYORK,    // New York session
   SESSION_ALL,        // All sessions (24/7)
   SESSION_LONDON_NY   // London and New York sessions only
};

// Strategy Type
enum ENUM_STRATEGY_TYPE
{
   STRATEGY_SCALPING,     // EMA + RSI scalping
   STRATEGY_BREAKOUT,     // Breakout trading
   STRATEGY_GRID,         // Grid trading
   STRATEGY_MARTINGALE,   // Martingale
   STRATEGY_COMBINED      // All strategies combined
};

// Signal Type
enum ENUM_SIGNAL_TYPE
{
   SIGNAL_NONE,           // No signal
   SIGNAL_BUY,            // Buy signal
   SIGNAL_SELL,           // Sell signal
   SIGNAL_BUY_STRONG,     // Strong buy signal
   SIGNAL_SELL_STRONG     // Strong sell signal
};

// Trade Result
enum ENUM_TRADE_RESULT
{
   TRADE_SUCCESS,         // Trade executed successfully
   TRADE_ERROR_INVALID_PARAMETER,  // Invalid input parameter
   TRADE_ERROR_MARKET_CLOSED,      // Market closed
   TRADE_ERROR_INSUFFICIENT_MARGIN, // Not enough margin
   TRADE_ERROR_TOO_MANY_ORDERS,    // Too many orders
   TRADE_ERROR_SERVER_REJECT,      // Server rejected
   TRADE_ERROR_CONNECTION,         // Connection error
   TRADE_ERROR_UNKNOWN             // Unknown error
};

// Grid Status
enum ENUM_GRID_STATUS
{
   GRID_STATUS_NONE,      // No grid active
   GRID_STATUS_BUY,       // Grid buy active
   GRID_STATUS_SELL,      // Grid sell active
   GRID_STATUS_BOTH       // Both directions active
};

// Error Code Definitions
enum ENUM_EA_ERROR_CODE
{
   ERR_EA_NONE = 0,                    // No error
   ERR_EA_INIT_FAILED = 1001,          // Initialization failed
   ERR_EA_INVALID_SYMBOL = 1002,       // Invalid symbol
   ERR_EA_INSUFFICIENT_DATA = 1003,    // Insufficient historical data
   ERR_EA_INDICATOR_FAILED = 1004,     // Indicator creation failed
   ERR_EA_DRAWDOWN_LIMIT = 1005,       // Drawdown limit reached
   ERR_EA_MARGIN_CALL = 1006,          // Margin call level reached
   ERR_EA_TRADE_DISABLED = 1007,       // Trading disabled
   ERR_EA_SYMBOL_NOT_TRADEABLE = 1008, // Symbol not tradeable
   ERR_EA_INVALID_TIMEFRAME = 1009,    // Invalid timeframe
   ERR_EA_POSITION_LIMIT = 1010,       // Position limit reached
   ERR_EA_SPREAD_TOO_HIGH = 1011,      // Spread too high
   ERR_EA_OFF_HOURS = 1012,            // Outside trading hours
   ERR_EA_UNKNOWN = 9999               // Unknown error
};

//+------------------------------------------------------------------+
//| Global Variables                                                 |
//+------------------------------------------------------------------+
CTrade         g_trade;
string         g_symbolList[];
int            g_symbolCount = 0;
double         g_initialBalance = 0;
double         g_dailyStartingEquity = 0;
datetime       g_lastDailyReset = 0;
bool           g_drawdownLimitReached = false;
bool           g_dailyLimitReached = false;
bool           g_tradingEnabled = true;
datetime       g_lastTickTime = 0;

//+------------------------------------------------------------------+
//| Symbol Data Structure                                            |
//+------------------------------------------------------------------+
struct SymbolData
{
   // Symbol info
   string            name;
   int               digits;
   double            point;
   double            pipValue;
   double            minLot;
   double            maxLot;
   double            lotStep;
   double            tickSize;
   double            tickValue;
   long              magicNumber;
   
   // Indicator handles
   int               handleEmaFast;
   int               handleEmaSlow;
   int               handleRsi;
   int               handleAtr;
   int               handleAdx;
   int               handleVolume;
   
   // Grid tracking
   double            lastGridPriceBuy;
   double            lastGridPriceSell;
   int               martingaleLevelBuy;
   int               martingaleLevelSell;
   ENUM_GRID_STATUS  gridStatus;
   
   // Position tracking
   int               positionsCount;
   double            totalLotsBuy;
   double            totalLotsSell;
   double            avgPriceBuy;
   double            avgPriceSell;
   double            profitBuy;
   double            profitSell;
   
   // Signal data
   ENUM_SIGNAL_TYPE  lastSignal;
   datetime          lastSignalTime;
   double            signalStrength;
   
   // Statistics
   int               totalTrades;
   int               winningTrades;
   int               losingTrades;
   double            totalProfit;
   
   // AI-Enhanced Data
   double            currentVolatility;
   double            avgVolatility;
   double            sentimentScore;
   double            smartMoneyFlow;
   double            mlConfidence;
   bool              isCorrelated;
   
   // Constructor
   SymbolData()
   {
      Init();
   }
   
   void Init()
   {
      name = "";
      digits = 0;
      point = 0;
      pipValue = 0;
      minLot = 0;
      maxLot = 0;
      lotStep = 0;
      tickSize = 0;
      tickValue = 0;
      magicNumber = 0;
      
      handleEmaFast = INVALID_HANDLE;
      handleEmaSlow = INVALID_HANDLE;
      handleRsi = INVALID_HANDLE;
      handleAtr = INVALID_HANDLE;
      handleAdx = INVALID_HANDLE;
      handleVolume = INVALID_HANDLE;
      
      lastGridPriceBuy = 0;
      lastGridPriceSell = 0;
      martingaleLevelBuy = 0;
      martingaleLevelSell = 0;
      gridStatus = GRID_STATUS_NONE;
      
      positionsCount = 0;
      totalLotsBuy = 0;
      totalLotsSell = 0;
      avgPriceBuy = 0;
      avgPriceSell = 0;
      profitBuy = 0;
      profitSell = 0;
      
      lastSignal = SIGNAL_NONE;
      lastSignalTime = 0;
      signalStrength = 0;
      
      totalTrades = 0;
      winningTrades = 0;
      losingTrades = 0;
      totalProfit = 0;
      
      currentVolatility = 0;
      avgVolatility = 0;
      sentimentScore = 0;
      smartMoneyFlow = 0;
      mlConfidence = 0.5;
      isCorrelated = false;
   }
   
   void ResetGridBuy()
   {
      lastGridPriceBuy = 0;
      martingaleLevelBuy = 0;
      UpdateGridStatus();
   }
   
   void ResetGridSell()
   {
      lastGridPriceSell = 0;
      martingaleLevelSell = 0;
      UpdateGridStatus();
   }
   
   void UpdateGridStatus()
   {
      if(martingaleLevelBuy > 0 && martingaleLevelSell > 0)
         gridStatus = GRID_STATUS_BOTH;
      else if(martingaleLevelBuy > 0)
         gridStatus = GRID_STATUS_BUY;
      else if(martingaleLevelSell > 0)
         gridStatus = GRID_STATUS_SELL;
      else
         gridStatus = GRID_STATUS_NONE;
   }
};

SymbolData g_symbolData[];

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
   Print("=== DLRegesign ReCode v1.0 Initializing ===");
   
   // Validate inputs
   if(!ValidateInputs())
   {
      Print("ERROR: Input validation failed");
      return INIT_PARAMETERS_INCORRECT;
   }
   
   // Check timeframe
   if(InpEnforceTimeframe && Period() != InpTimeframe)
   {
      string msg = StringFormat("EA configured for %s. Current: %s", 
                     EnumToString(InpTimeframe), EnumToString(Period()));
      Alert(msg);
      Print("WARNING: ", msg);
   }
   
   // Store initial values
   g_initialBalance = AccountInfoDouble(ACCOUNT_BALANCE);
   g_dailyStartingEquity = AccountInfoDouble(ACCOUNT_EQUITY);
   g_lastDailyReset = TimeCurrent();
   
   // Setup trade object
   g_trade.SetExpertMagicNumber((int)InpMagicNumberBase);
   g_trade.SetDeviationInPoints(InpSlippage);
   g_trade.SetTypeFilling(ORDER_FILLING_FOK);
   g_trade.SetAsyncMode(false);
   
   // Build symbol list
   if(!BuildSymbolList())
   {
      Print("ERROR: Failed to build symbol list");
      return INIT_FAILED;
   }
   
   // Initialize symbol data
   if(!InitializeSymbolData())
   {
      Print("ERROR: Failed to initialize symbol data");
      return INIT_FAILED;
   }
   
   // Log initialization
   Print("Successfully initialized ", g_symbolCount, " symbols");
   Print("Timeframe: ", EnumToString(InpTimeframe), 
         " | Max Drawdown: ", InpMaxDrawdownPct, "%");
   Print("Strategies: Scalping=", InpUseScalping, 
         " Breakout=", InpUseBreakout, 
         " Grid=", InpUseGrid, 
         " Martingale=", InpUseMartingale);
   
   EventSetTimer(60);  // Timer for daily reset
   
   return INIT_SUCCEEDED;
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
   EventKillTimer();
   
   // Release all indicator handles
   for(int i = 0; i < g_symbolCount; i++)
   {
      ReleaseIndicators(i);
   }
   
   // Print final statistics
   PrintFinalStatistics();
   
   Print("DLRegesign ReCode deinitialized. Reason: ", reason);
}

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{
   static datetime lastProcessingTime = 0;
   datetime currentTime = TimeCurrent();
   
   // Only process if new tick received (not just timer event)
   if(currentTime == lastProcessingTime)
      return;
   
   lastProcessingTime = currentTime;
   
   // Check if trading is allowed
   if(!g_tradingEnabled)
      return;
   
   // Check trading conditions
   if(!CheckTradingConditions())
      return;
   
   // Process each symbol
   for(int i = 0; i < g_symbolCount; i++)
   {
      ProcessSymbol(i);
   }
}

//+------------------------------------------------------------------+
//| Timer function                                                   |
//+------------------------------------------------------------------+
void OnTimer()
{
   // Check for new day
   datetime now = TimeCurrent();
   MqlDateTime nowStruct;
   TimeToStruct(now, nowStruct);
   
   MqlDateTime lastStruct;
   TimeToStruct(g_lastDailyReset, lastStruct);
   
   if(nowStruct.day != lastStruct.day)
   {
      // New day - reset daily stats
      g_dailyStartingEquity = AccountInfoDouble(ACCOUNT_EQUITY);
      g_lastDailyReset = now;
      g_dailyLimitReached = false;
      Print("Daily statistics reset. New starting equity: ", g_dailyStartingEquity);
   }
   
   // Check Friday close
   if(InpFridayClosePositions && nowStruct.day_of_week == 5 && nowStruct.hour >= InpFridayCloseHour)
   {
      CloseAllPositions("Friday evening close");
   }
}

//+------------------------------------------------------------------+
//| Validate input parameters                                        |
//+------------------------------------------------------------------+
bool ValidateInputs()
{
   bool valid = true;
   
   // Risk parameters
   if(InpBaseLotSize <= 0)
   {
      Print("ERROR: Base lot size must be greater than 0");
      valid = false;
   }
   
   if(InpMaxLot < InpBaseLotSize)
   {
      Print("ERROR: Max lot must be >= Base lot size");
      valid = false;
   }
   
   if(InpMaxDrawdownPct < 1 || InpMaxDrawdownPct > 100)
   {
      Print("ERROR: Max drawdown must be between 1-100%");
      valid = false;
   }
   
   if(InpDailyLossLimitPct < 0 || InpDailyLossLimitPct > 50)
   {
      Print("ERROR: Daily loss limit must be between 0-50%");
      valid = false;
   }
   
   if(InpMaxSpreadPips <= 0)
   {
      Print("ERROR: Max spread must be greater than 0");
      valid = false;
   }
   
   if(InpMinAccountBalance <= 0)
   {
      Print("ERROR: Minimum account balance must be greater than 0");
      valid = false;
   }
   
   // SL/TP parameters
   if(InpStopLossPips <= 0)
   {
      Print("ERROR: Stop loss must be greater than 0");
      valid = false;
   }
   
   if(InpTakeProfitPips <= 0)
   {
      Print("ERROR: Take profit must be greater than 0");
      valid = false;
   }
   
   // Money management
   if(InpRiskPercent <= 0)
   {
      Print("ERROR: Risk percent must be greater than 0");
      valid = false;
   }
   
   // Scalping parameters
   if(InpEMAFast >= InpEMASlow)
   {
      Print("ERROR: Fast EMA must be less than Slow EMA");
      valid = false;
   }
   
   if(InpRSIOversold >= InpRSIOverbought)
   {
      Print("ERROR: RSI oversold must be less than overbought");
      valid = false;
   }
   
   // Breakout parameters
   if(InpBreakoutLookback < 5)
   {
      Print("ERROR: Breakout lookback must be at least 5");
      valid = false;
   }
   
   if(InpBreakoutThreshold <= 0)
   {
      Print("ERROR: Breakout threshold must be greater than 0");
      valid = false;
   }
   
   // Grid parameters
   if(InpGridStepPips < 5)
   {
      Print("ERROR: Grid step must be at least 5 pips");
      valid = false;
   }
   
   if(InpMaxGridLevels < 1)
   {
      Print("ERROR: Max grid levels must be at least 1");
      valid = false;
   }
   
   // Martingale parameters
   if(InpMartingaleFactor < 1.0)
   {
      Print("ERROR: Martingale factor must be >= 1.0");
      valid = false;
   }
   
   if(InpMaxMartingaleLevel < 0)
   {
      Print("ERROR: Max martingale level must be >= 0");
      valid = false;
   }
   
   // Volatility threshold
   if(InpVolatilityThreshold <= 0)
   {
      Print("ERROR: Volatility threshold must be greater than 0");
      valid = false;
   }
   
   return valid;
}

//+------------------------------------------------------------------+
//| Build symbol list based on settings                              |
//+------------------------------------------------------------------+
bool BuildSymbolList()
{
   ArrayFree(g_symbolList);
   g_symbolCount = 0;
   
   if(InpTradeAllSymbols)
   {
      // Add all available symbols
      int totalSymbols = SymbolsTotal(true);
      for(int i = 0; i < totalSymbols && g_symbolCount < 1000; i++)
      {
         string symbol = SymbolName(i, true);
         
         // Skip symbols that don't meet our criteria
         if(!IsSymbolValid(symbol))
            continue;
            
         ArrayResize(g_symbolList, g_symbolCount + 1);
         g_symbolList[g_symbolCount] = symbol;
         g_symbolCount++;
      }
   }
   else
   {
      // Use single symbol
      string symbol = InpSingleSymbol;
      if(symbol == "")
         symbol = Symbol();
         
      if(IsSymbolValid(symbol))
      {
         ArrayResize(g_symbolList, 1);
         g_symbolList[0] = symbol;
         g_symbolCount = 1;
      }
      else
      {
         Print("ERROR: Invalid single symbol: ", symbol);
         return false;
      }
   }
   
   return g_symbolCount > 0;
}

//+------------------------------------------------------------------+
//| Check if symbol meets our trading criteria                       |
//+------------------------------------------------------------------+
bool IsSymbolValid(string symbol)
{
   // Check if symbol exists and is tradeable
   if(!SymbolSelect(symbol, true))
      return false;
      
   // Check if trading is allowed for this symbol
   if(!SymbolInfoInteger(symbol, SYMBOL_TRADE_MODE))
      return false;
      
   // Check if we have enough historical data
   if(!CheckSymbolHistory(symbol))
      return false;
      
   // Additional checks could be added here
   return true;
}

//+------------------------------------------------------------------+
//| Check if symbol has sufficient history                           |
//+------------------------------------------------------------------+
bool CheckSymbolHistory(string symbol)
{
   // Temporarily select the symbol
   if(!SymbolSelect(symbol, true))
      return false;
      
   // Get timeframe data
   int copied = CopyRates(symbol, InpTimeframe, 0, 100, rates_array);
   return copied >= 100;
}

//+------------------------------------------------------------------+
//| Initialize symbol data structures                                |
//+------------------------------------------------------------------+
bool InitializeSymbolData()
{
   ArrayFree(g_symbolData);
   ArrayResize(g_symbolData, g_symbolCount);
   
   for(int i = 0; i < g_symbolCount; i++)
   {
      g_symbolData[i].Init();
      g_symbolData[i].name = g_symbolList[i];
      
      // Get symbol properties
      if(!GetSymbolProperties(i))
      {
         Print("ERROR: Failed to get properties for symbol: ", g_symbolList[i]);
         return false;
      }
      
      // Create indicator handles for this symbol
      if(!CreateIndicators(i))
      {
         Print("ERROR: Failed to create indicators for symbol: ", g_symbolList[i]);
         return false;
      }
      
      // Set magic number based on index
      g_symbolData[i].magicNumber = InpMagicNumberBase + i;
   }
   
   return true;
}

//+------------------------------------------------------------------+
//| Get symbol properties                                            |
//+------------------------------------------------------------------+
bool GetSymbolProperties(int index)
{
   string symbol = g_symbolData[index].name;
   
   if(!SymbolInfoInteger(symbol, SYMBOL_DIGITS, g_symbolData[index].digits))
      return false;
      
   if(!SymbolInfoDouble(symbol, SYMBOL_POINT, g_symbolData[index].point))
      return false;
      
   if(!SymbolInfoDouble(symbol, SYMBOL_TRADE_TICK_SIZE, g_symbolData[index].tickSize))
      return false;
      
   if(!SymbolInfoDouble(symbol, SYMBOL_TRADE_TICK_VALUE, g_symbolData[index].tickValue))
      return false;
      
   if(!SymbolInfoDouble(symbol, SYMBOL_VOLUME_MIN, g_symbolData[index].minLot))
      return false;
      
   if(!SymbolInfoDouble(symbol, SYMBOL_VOLUME_MAX, g_symbolData[index].maxLot))
      return false;
      
   if(!SymbolInfoDouble(symbol, SYMBOL_VOLUME_STEP, g_symbolData[index].lotStep))
      return false;
      
   // Calculate pip value based on symbol properties
   g_symbolData[index].pipValue = GetPipValue(symbol);
   
   return true;
}

//+------------------------------------------------------------------+
//| Get pip value for symbol                                         |
//+------------------------------------------------------------------+
double GetPipValue(string symbol)
{
   double point_value = SymbolInfoDouble(symbol, SYMBOL_POINT);
   int digits = (int)SymbolInfoInteger(symbol, SYMBOL_DIGITS);
   
   if(digits == 5 || digits == 3)  // 5-digit or 3-digit brokers
      return point_value * 10;
   else
      return point_value;
}

//+------------------------------------------------------------------+
//| Create indicators for a symbol                                   |
//+------------------------------------------------------------------+
bool CreateIndicators(int index)
{
   string symbol = g_symbolData[index].name;
   
   // Create EMA indicators
   g_symbolData[index].handleEmaFast = iMA(symbol, InpTimeframe, InpEMAFast, 0, MODE_EMA, PRICE_CLOSE);
   if(g_symbolData[index].handleEmaFast == INVALID_HANDLE)
      return false;
      
   g_symbolData[index].handleEmaSlow = iMA(symbol, InpTimeframe, InpEMASlow, 0, MODE_EMA, PRICE_CLOSE);
   if(g_symbolData[index].handleEmaSlow == INVALID_HANDLE)
      return false;
      
   // Create RSI
   g_symbolData[index].handleRsi = iRSI(symbol, InpTimeframe, InpRSIPeriod, PRICE_CLOSE);
   if(g_symbolData[index].handleRsi == INVALID_HANDLE)
      return false;
      
   // Create ATR
   g_symbolData[index].handleAtr = iATR(symbol, InpTimeframe, 14);
   if(g_symbolData[index].handleAtr == INVALID_HANDLE)
      return false;
      
   // Create ADX if needed
   if(InpUseADXFilter)
   {
      g_symbolData[index].handleAdx = iADX(symbol, InpTimeframe, InpADXPeriod, PRICE_CLOSE);
      if(g_symbolData[index].handleAdx == INVALID_HANDLE)
         return false;
   }
   
   // Create volume indicator if needed
   if(InpUseVolumeConfirmation)
   {
      g_symbolData[index].handleVolume = iVolume(symbol, InpTimeframe);
      if(g_symbolData[index].handleVolume == INVALID_HANDLE)
         return false;
   }
   
   return true;
}

//+------------------------------------------------------------------+
//| Release indicators for a symbol                                  |
//+------------------------------------------------------------------+
void ReleaseIndicators(int index)
{
   if(g_symbolData[index].handleEmaFast != INVALID_HANDLE)
   {
      IndicatorRelease(g_symbolData[index].handleEmaFast);
      g_symbolData[index].handleEmaFast = INVALID_HANDLE;
   }
   
   if(g_symbolData[index].handleEmaSlow != INVALID_HANDLE)
   {
      IndicatorRelease(g_symbolData[index].handleEmaSlow);
      g_symbolData[index].handleEmaSlow = INVALID_HANDLE;
   }
   
   if(g_symbolData[index].handleRsi != INVALID_HANDLE)
   {
      IndicatorRelease(g_symbolData[index].handleRsi);
      g_symbolData[index].handleRsi = INVALID_HANDLE;
   }
   
   if(g_symbolData[index].handleAtr != INVALID_HANDLE)
   {
      IndicatorRelease(g_symbolData[index].handleAtr);
      g_symbolData[index].handleAtr = INVALID_HANDLE;
   }
   
   if(g_symbolData[index].handleAdx != INVALID_HANDLE)
   {
      IndicatorRelease(g_symbolData[index].handleAdx);
      g_symbolData[index].handleAdx = INVALID_HANDLE;
   }
   
   if(g_symbolData[index].handleVolume != INVALID_HANDLE)
   {
      IndicatorRelease(g_symbolData[index].handleVolume);
      g_symbolData[index].handleVolume = INVALID_HANDLE;
   }
}

//+------------------------------------------------------------------+
//| Check overall trading conditions                                 |
//+------------------------------------------------------------------+
bool CheckTradingConditions()
{
   // Check account balance
   if(AccountInfoDouble(ACCOUNT_BALANCE) < InpMinAccountBalance)
   {
      Print("INFO: Account balance below minimum required: ", InpMinAccountBalance);
      return false;
   }
   
   // Check drawdown limit
   double balance = AccountInfoDouble(ACCOUNT_BALANCE);
   double equity = AccountInfoDouble(ACCOUNT_EQUITY);
   double drawdownPct = (balance - equity) / balance * 100.0;
   
   if(drawdownPct >= InpMaxDrawdownPct)
   {
      if(!g_drawdownLimitReached)
      {
         Print("ALERT: Maximum drawdown limit reached: ", drawdownPct, "%");
         g_drawdownLimitReached = true;
      }
      return false;
   }
   else
   {
      g_drawdownLimitReached = false;
   }
   
   // Check daily loss limit
   double dailyLossPct = (g_dailyStartingEquity - equity) / g_dailyStartingEquity * 100.0;
   
   if(dailyLossPct >= InpDailyLossLimitPct)
   {
      if(!g_dailyLimitReached)
      {
         Print("ALERT: Daily loss limit reached: ", dailyLossPct, "%");
         g_dailyLimitReached = true;
      }
      return false;
   }
   else
   {
      g_dailyLimitReached = false;
   }
   
   // Check total positions limit
   if(GetTotalOpenPositions() >= InpTotalMaxPositions)
   {
      Print("INFO: Total position limit reached: ", InpTotalMaxPositions);
      return false;
   }
   
   // Check trading hours
   if(!IsTradingAllowed())
   {
      return false;
   }
   
   return true;
}

//+------------------------------------------------------------------+
//| Check if trading is allowed based on sessions and filters        |
//+------------------------------------------------------------------+
bool IsTradingAllowed()
{
   MqlDateTime dt;
   TimeToStruct(TimeCurrent(), dt);
   
   // Check weekend
   if(InpAvoidWeekend && (dt.day_of_week == 0 || dt.day_of_week == 6))
   {
      return false;
   }
   
   // Check session filter
   if(InpFilterBySession)
   {
      int hour = dt.hour;
      
      switch(InpTradeSession)
      {
         case SESSION_ASIAN:
            if(!(hour >= 0 && hour < 9))
               return false;
            break;
         case SESSION_LONDON:
            if(!(hour >= 8 && hour < 17))
               return false;
            break;
         case SESSION_NEWYORK:
            if(!(hour >= 13 && hour < 22))
               return false;
            break;
         case SESSION_LONDON_NY:
            if(!((hour >= 8 && hour < 17) || (hour >= 13 && hour < 22)))
               return false;
            break;
         case SESSION_ALL:
            // Always allowed
            break;
      }
   }
   
   // Additional time-based filters can be added here
   return true;
}

//+------------------------------------------------------------------+
//| Get total number of open positions across all symbols            |
//+------------------------------------------------------------------+
int GetTotalOpenPositions()
{
   int count = 0;
   for(int i = 0; i < OrdersTotal(); i++)
   {
      ulong ticket = OrderGetTicket(i);
      if(OrderSelect(ticket) && OrderGetInteger(ORDER_MAGIC) >= InpMagicNumberBase && 
         OrderGetInteger(ORDER_MAGIC) < InpMagicNumberBase + g_symbolCount)
      {
         count++;
      }
   }
   
   return count;
}

//+------------------------------------------------------------------+
//| Process a single symbol                                          |
//+------------------------------------------------------------------+
void ProcessSymbol(int index)
{
   string symbol = g_symbolData[index].name;
   
   // Check spread
   if(!CheckSpread(symbol))
   {
      return;
   }
   
   // Update position information
   UpdatePositionInfo(index);
   
   // Manage existing positions
   ManagePositions(index);
   
   // Check if we can open new positions
   if(g_symbolData[index].positionsCount >= InpMaxPositionsPerSymbol)
   {
      return;
   }
   
   // Check martingale reset conditions
   CheckMartingaleReset(index);
   
   // Generate signals and trade
   GenerateAndProcessSignals(index);
}

//+------------------------------------------------------------------+
//| Check if spread is acceptable for trading                        |
//+------------------------------------------------------------------+
bool CheckSpread(string symbol)
{
   double ask = SymbolInfoDouble(symbol, SYMBOL_ASK);
   double bid = SymbolInfoDouble(symbol, SYMBOL_BID);
   double spread = (ask - bid) / g_symbolData[GetSymbolIndex(symbol)].pipValue;
   
   return spread <= InpMaxSpreadPips;
}

//+------------------------------------------------------------------+
//| Get symbol index from symbol name                                |
//+------------------------------------------------------------------+
int GetSymbolIndex(string symbol)
{
   for(int i = 0; i < g_symbolCount; i++)
   {
      if(g_symbolList[i] == symbol)
         return i;
   }
   return -1;
}

//+------------------------------------------------------------------+
//| Update position information for a symbol                         |
//+------------------------------------------------------------------+
void UpdatePositionInfo(int index)
{
   string symbol = g_symbolData[index].name;
   g_symbolData[index].positionsCount = 0;
   g_symbolData[index].totalLotsBuy = 0;
   g_symbolData[index].totalLotsSell = 0;
   g_symbolData[index].avgPriceBuy = 0;
   g_symbolData[index].avgPriceSell = 0;
   g_symbolData[index].profitBuy = 0;
   g_symbolData[index].profitSell = 0;
   
   // Count positions and calculate averages
   for(int i = 0; i < PositionsTotal(); i++)
   {
      if(PositionGetTicket(i))
      {
         if(PositionGetString(POSITION_SYMBOL) == symbol && 
            PositionGetInteger(POSITION_MAGIC) == g_symbolData[index].magicNumber)
         {
            g_symbolData[index].positionsCount++;
            
            double lots = PositionGetDouble(POSITION_VOLUME);
            double price = PositionGetDouble(POSITION_PRICE_OPEN);
            double profit = PositionGetDouble(POSITION_PROFIT);
            
            if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY)
            {
               g_symbolData[index].totalLotsBuy += lots;
               g_symbolData[index].avgPriceBuy = (g_symbolData[index].avgPriceBuy * (g_symbolData[index].totalLotsBuy - lots) + price * lots) / g_symbolData[index].totalLotsBuy;
               g_symbolData[index].profitBuy += profit;
            }
            else // SELL
            {
               g_symbolData[index].totalLotsSell += lots;
               g_symbolData[index].avgPriceSell = (g_symbolData[index].avgPriceSell * (g_symbolData[index].totalLotsSell - lots) + price * lots) / g_symbolData[index].totalLotsSell;
               g_symbolData[index].profitSell += profit;
            }
         }
      }
   }
}

//+------------------------------------------------------------------+
//| Manage existing positions (trailing stop, breakeven, etc.)       |
//+------------------------------------------------------------------+
void ManagePositions(int index)
{
   if(PositionsTotal() == 0)
      return;
      
   for(int i = PositionsTotal()-1; i >= 0; i--)
   {
      if(PositionGetTicket(i))
      {
         string symbol = PositionGetString(POSITION_SYMBOL);
         if(symbol == g_symbolData[index].name && 
            PositionGetInteger(POSITION_MAGIC) == g_symbolData[index].magicNumber)
         {
            // Apply trailing stop if enabled
            if(InpUseTrailingStop)
            {
               ApplyTrailingStop(i);
            }
            
            // Apply breakeven if enabled
            if(InpUseBreakEven)
            {
               ApplyBreakeven(i);
            }
            
            // Manage grid positions if grid trading is enabled
            if(InpUseGrid)
            {
               ManageGridPositions(index);
            }
         }
      }
   }
}

//+------------------------------------------------------------------+
//| Apply trailing stop to a position                                |
//+------------------------------------------------------------------+
void ApplyTrailingStop(int pos_index)
{
   if(!PositionSelectByTicket(pos_index))
      return;
      
   double profit = PositionGetDouble(POSITION_PROFIT);
   double symbol_point = SymbolInfoDouble(PositionGetString(POSITION_SYMBOL), SYMBOL_POINT);
   int digits = (int)SymbolInfoInteger(PositionGetString(POSITION_SYMBOL), SYMBOL_DIGITS);
   
   if(profit > InpTrailingStartPips * g_symbolData[GetSymbolIndex(PositionGetString(POSITION_SYMBOL))].pipValue)
   {
      double new_sl = 0;
      double current_sl = PositionGetDouble(POSITION_SL);
      double current_price = PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY ? 
                            PositionGetDouble(POSITION_PRICE_CURRENT) : 
                            PositionGetDouble(POSITION_PRICE_CURRENT);
      
      if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY)
      {
         new_sl = current_price - (InpTrailingStartPips * g_symbolData[GetSymbolIndex(PositionGetString(POSITION_SYMBOL))].pipValue);
         if(new_sl > current_sl || current_sl == 0)
         {
            g_trade.PositionModify(PositionGetInteger(POSITION_TICKET), new_sl, PositionGetDouble(POSITION_TP));
         }
      }
      else // SELL
      {
         new_sl = current_price + (InpTrailingStartPips * g_symbolData[GetSymbolIndex(PositionGetString(POSITION_SYMBOL))].pipValue);
         if(new_sl < current_sl || current_sl == 0)
         {
            g_trade.PositionModify(PositionGetInteger(POSITION_TICKET), new_sl, PositionGetDouble(POSITION_TP));
         }
      }
   }
}

//+------------------------------------------------------------------+
//| Apply breakeven to a position                                    |
//+------------------------------------------------------------------+
void ApplyBreakeven(int pos_index)
{
   if(!PositionSelectByTicket(pos_index))
      return;
      
   double profit = PositionGetDouble(POSITION_PROFIT);
   double pip_value = g_symbolData[GetSymbolIndex(PositionGetString(POSITION_SYMBOL))].pipValue;
   
   if(profit > InpBreakEvenPips * pip_value)
   {
      double current_sl = PositionGetDouble(POSITION_SL);
      double current_price = PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY ? 
                            PositionGetDouble(POSITION_PRICE_CURRENT) : 
                            PositionGetDouble(POSITION_PRICE_CURRENT);
      
      if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY)
      {
         double new_sl = PositionGetDouble(POSITION_PRICE_OPEN) + (2 * SymbolInfoDouble(PositionGetString(POSITION_SYMBOL), SYMBOL_POINT));
         if(new_sl > current_sl || current_sl == 0)
         {
            g_trade.PositionModify(PositionGetInteger(POSITION_TICKET), new_sl, PositionGetDouble(POSITION_TP));
         }
      }
      else // SELL
      {
         double new_sl = PositionGetDouble(POSITION_PRICE_OPEN) - (2 * SymbolInfoDouble(PositionGetString(POSITION_SYMBOL), SYMBOL_POINT));
         if(new_sl < current_sl || current_sl == 0)
         {
            g_trade.PositionModify(PositionGetInteger(POSITION_TICKET), new_sl, PositionGetDouble(POSITION_TP));
         }
      }
   }
}

//+------------------------------------------------------------------+
//| Manage grid positions                                            |
//+------------------------------------------------------------------+
void ManageGridPositions(int index)
{
   // Implementation of grid position management
   // This would include adding to grid positions based on price movement
}

//+------------------------------------------------------------------+
//| Check martingale reset conditions                                |
//+------------------------------------------------------------------+
void CheckMartingaleReset(int index)
{
   if(!InpUseMartingale)
      return;
      
   if(InpResetMartingaleOnProfit)
   {
      // Reset martingale levels when profitable
      if(g_symbolData[index].profitBuy > 0)
      {
         g_symbolData[index].martingaleLevelBuy = 0;
      }
      
      if(g_symbolData[index].profitSell > 0)
      {
         g_symbolData[index].martingaleLevelSell = 0;
      }
   }
}

//+------------------------------------------------------------------+
//| Generate and process trading signals                             |
//+------------------------------------------------------------------+
void GenerateAndProcessSignals(int index)
{
   // Calculate technical indicators
   double ema_fast[], ema_slow[], rsi_values[], atr_values[], adx_values[];
   
   ArraySetAsSeries(ema_fast, true);
   ArraySetAsSeries(ema_slow, true);
   ArraySetAsSeries(rsi_values, true);
   ArraySetAsSeries(atr_values, true);
   ArraySetAsSeries(adx_values, true);
   
   int copied;
   
   // Get EMA values
   copied = CopyBuffer(g_symbolData[index].handleEmaFast, 0, 0, 3, ema_fast);
   if(copied <= 0) return;
   
   copied = CopyBuffer(g_symbolData[index].handleEmaSlow, 0, 0, 3, ema_slow);
   if(copied <= 0) return;
   
   // Get RSI values
   copied = CopyBuffer(g_symbolData[index].handleRsi, 0, 0, 3, rsi_values);
   if(copied <= 0) return;
   
   // Get ATR values
   copied = CopyBuffer(g_symbolData[index].handleAtr, 0, 0, 3, atr_values);
   if(copied <= 0) return;
   
   // Get ADX values if needed
   if(InpUseADXFilter)
   {
      copied = CopyBuffer(g_symbolData[index].handleAdx, 0, 0, 3, adx_values);
      if(copied <= 0) return;
   }
   
   // Determine signal based on strategies
   ENUM_SIGNAL_TYPE signal = SIGNAL_NONE;
   double signal_strength = 0;
   
   // Scalping strategy
   if(InpUseScalping)
   {
      ENUM_SIGNAL_TYPE scalping_signal = GetScalpingSignal(index, ema_fast, ema_slow, rsi_values, adx_values);
      if(scalping_signal != SIGNAL_NONE)
      {
         signal = scalping_signal;
         signal_strength = 1.0; // Base strength
      }
   }
   
   // Breakout strategy
   if(InpUseBreakout && signal == SIGNAL_NONE)
   {
      ENUM_SIGNAL_TYPE breakout_signal = GetBreakoutSignal(index);
      if(breakout_signal != SIGNAL_NONE)
      {
         signal = breakout_signal;
         signal_strength = 1.0;
      }
   }
   
   // Apply signal filters
   if(signal != SIGNAL_NONE && signal_strength >= InpMinSignalStrength)
   {
      // Apply trend filter if enabled
      if(InpUseTrendFilter && !IsTrendAligned(index, signal))
      {
         signal = SIGNAL_NONE;
      }
   }
   
   // Execute trade if signal is valid
   if(signal != SIGNAL_NONE)
   {
      ExecuteTrade(index, signal);
   }
}

//+------------------------------------------------------------------+
//| Get scalping signal based on EMA and RSI                         |
//+------------------------------------------------------------------+
ENUM_SIGNAL_TYPE GetScalpingSignal(int index, double &ema_fast[], double &ema_slow[], double &rsi_values[], double &adx_values[])
{
   // Check for EMA crossover
   bool ema_bullish_cross = ema_fast[1] > ema_slow[1] && ema_fast[2] <= ema_slow[2];
   bool ema_bearish_cross = ema_fast[1] < ema_slow[1] && ema_fast[2] >= ema_slow[2];
   
   bool ema_bullish_trend = ema_fast[0] > ema_slow[0];
   bool ema_bearish_trend = ema_fast[0] < ema_slow[0];
   
   // Check RSI conditions
   bool rsi_oversold = rsi_values[0] < InpRSIOversold;
   bool rsi_overbought = rsi_values[0] > InpRSIOverbought;
   bool rsi_bull_momentum = rsi_values[0] > 50 && rsi_values[0] < InpRSIOverbought;
   bool rsi_bear_momentum = rsi_values[0] < 50 && rsi_values[0] > InpRSIOversold;
   
   // ADX filter if enabled
   bool trend_strong = true;
   if(InpUseADXFilter)
   {
      trend_strong = adx_values[0] > InpADXMinimum;
   }
   
   // Generate signals
   if(ema_bullish_cross && rsi_oversold && trend_strong)
   {
      return SIGNAL_BUY_STRONG;
   }
   else if(ema_bearish_cross && rsi_overbought && trend_strong)
   {
      return SIGNAL_SELL_STRONG;
   }
   else if(ema_bullish_trend && (rsi_bull_momentum || InpUseRSIMomentum) && trend_strong)
   {
      return SIGNAL_BUY;
   }
   else if(ema_bearish_trend && (rsi_bear_momentum || InpUseRSIMomentum) && trend_strong)
   {
      return SIGNAL_SELL;
   }
   
   return SIGNAL_NONE;
}

//+------------------------------------------------------------------+
//| Get breakout signal                                              |
//+------------------------------------------------------------------+
ENUM_SIGNAL_TYPE GetBreakoutSignal(int index)
{
   string symbol = g_symbolData[index].name;
   
   // Get recent highs and lows for breakout detection
   double high_buffer[], low_buffer[];
   ArraySetAsSeries(high_buffer, true);
   ArraySetAsSeries(low_buffer, true);
   
   int copied = CopyHigh(symbol, InpTimeframe, 0, InpBreakoutLookback, high_buffer);
   if(copied < InpBreakoutLookback) return SIGNAL_NONE;
   
   copied = CopyLow(symbol, InpTimeframe, 0, InpBreakoutLookback, low_buffer);
   if(copied < InpBreakoutLookback) return SIGNAL_NONE;
   
   // Find highest high and lowest low in lookback period
   double highest_high = high_buffer[0];
   double lowest_low = low_buffer[0];
   
   for(int i = 0; i < InpBreakoutLookback; i++)
   {
      if(high_buffer[i] > highest_high) highest_high = high_buffer[i];
      if(low_buffer[i] < lowest_low) lowest_low = low_buffer[i];
   }
   
   // Current prices
   double ask = SymbolInfoDouble(symbol, SYMBOL_ASK);
   double bid = SymbolInfoDouble(symbol, SYMBOL_BID);
   
   // Check for breakout
   if(ask > highest_high + (InpBreakoutThreshold * g_symbolData[index].pipValue))
   {
      return SIGNAL_BUY;
   }
   else if(bid < lowest_low - (InpBreakoutThreshold * g_symbolData[index].pipValue))
   {
      return SIGNAL_SELL;
   }
   
   return SIGNAL_NONE;
}

//+------------------------------------------------------------------+
//| Check if trend is aligned with signal                            |
//+------------------------------------------------------------------+
bool IsTrendAligned(int index, ENUM_SIGNAL_TYPE signal)
{
   string symbol = g_symbolData[index].name;
   
   // Use higher timeframe for trend determination
   double ht_high[], ht_low[];
   ArraySetAsSeries(ht_high, true);
   ArraySetAsSeries(ht_low, true);
   
   int copied = CopyHigh(symbol, InpTrendTimeframe, 0, 20, ht_high);
   if(copied < 20) return true; // If can't get HT data, assume trend is OK
   
   copied = CopyLow(symbol, InpTrendTimeframe, 0, 20, ht_low);
   if(copied < 20) return true;
   
   // Simple trend detection based on 20-period highs/lows
   double avg_high_prev = 0, avg_low_prev = 0;
   double avg_high_curr = 0, avg_low_curr = 0;
   
   for(int i = 0; i < 10; i++)
   {
      avg_high_prev += ht_high[i+10];
      avg_low_prev += ht_low[i+10];
      avg_high_curr += ht_high[i];
      avg_low_curr += ht_low[i];
   }
   
   avg_high_prev /= 10;
   avg_low_prev /= 10;
   avg_high_curr /= 10;
   avg_low_curr /= 10;
   
   bool uptrend = avg_high_curr > avg_high_prev && avg_low_curr > avg_low_prev;
   bool downtrend = avg_high_curr < avg_high_prev && avg_low_curr < avg_low_prev;
   
   // For BUY signal, we want uptrend; for SELL signal, we want downtrend
   if(signal == SIGNAL_BUY || signal == SIGNAL_BUY_STRONG)
      return uptrend;
   else if(signal == SIGNAL_SELL || signal == SIGNAL_SELL_STRONG)
      return downtrend;
   
   return true; // For other signals, assume trend is OK
}

//+------------------------------------------------------------------+
//| Execute trade based on signal                                    |
//+------------------------------------------------------------------+
void ExecuteTrade(int index, ENUM_SIGNAL_TYPE signal)
{
   string symbol = g_symbolData[index].name;
   double lot_size = CalculateLotSize(index);
   
   if(lot_size <= 0)
      return;
   
   double sl = 0, tp = 0;
   
   if(InpUseFixedSLTP)
   {
      double point = g_symbolData[index].point;
      double sl_pips = InpStopLossPips * g_symbolData[index].pipValue;
      double tp_pips = InpTakeProfitPips * g_symbolData[index].pipValue;
      
      if(signal == SIGNAL_BUY || signal == SIGNAL_BUY_STRONG)
      {
         double price = SymbolInfoDouble(symbol, SYMBOL_ASK);
         sl = price - sl_pips;
         tp = price + tp_pips;
      }
      else // SELL signals
      {
         double price = SymbolInfoDouble(symbol, SYMBOL_BID);
         sl = price + sl_pips;
         tp = price - tp_pips;
      }
   }
   
   // Place order based on signal
   if(signal == SIGNAL_BUY || signal == SIGNAL_BUY_STRONG)
   {
      g_trade.Buy(lot_size, symbol, 0, sl, tp, "DLRegesign BUY");
   }
   else if(signal == SIGNAL_SELL || signal == SIGNAL_SELL_STRONG)
   {
      g_trade.Sell(lot_size, symbol, 0, sl, tp, "DLRegesign SELL");
   }
}

//+------------------------------------------------------------------+
//| Calculate lot size based on money management settings            |
//+------------------------------------------------------------------+
double CalculateLotSize(int index)
{
   double lot = InpBaseLotSize;
   
   if(InpUseRiskPercent)
   {
      double balance = AccountInfoDouble(ACCOUNT_BALANCE);
      double risk_amount = balance * (InpRiskPercent / 100.0);
      double point_value = g_symbolData[index].tickValue; // Using tick value for calculation
      
      // Calculate lot based on risk and stop loss
      double sl_pips = InpStopLossPips;
      if(sl_pips > 0)
      {
         lot = risk_amount / (sl_pips * 10 * point_value);
      }
   }
   
   // Apply Kelly Criterion if enabled
   if(InpUseKellyCriterion)
   {
      // Simplified Kelly calculation
      double kelly_percent = 0.1; // Placeholder - implement proper Kelly calculation
      lot = AccountInfoDouble(ACCOUNT_BALANCE) * kelly_percent;
   }
   
   // Apply martingale if enabled and needed
   if(InpUseMartingale)
   {
      // Increase lot size based on martingale level
      int max_level_buy = g_symbolData[index].martingaleLevelBuy;
      int max_level_sell = g_symbolData[index].martingaleLevelSell;
      
      int current_level = MathMax(max_level_buy, max_level_sell);
      lot *= MathPow(InpMartingaleFactor, current_level);
   }
   
   // Apply limits
   if(lot > InpMaxLot)
      lot = InpMaxLot;
   
   if(lot < g_symbolData[index].minLot)
      lot = g_symbolData[index].minLot;
   
   // Round to lot step
   lot = NormalizeDouble(lot / g_symbolData[index].lotStep, 0) * g_symbolData[index].lotStep;
   
   return lot;
}

//+------------------------------------------------------------------+
//| Close all positions                                              |
//+------------------------------------------------------------------+
void CloseAllPositions(string reason)
{
   for(int i = PositionsTotal()-1; i >= 0; i--)
   {
      if(PositionGetTicket(i))
      {
         string symbol = PositionGetString(POSITION_SYMBOL);
         long magic = PositionGetInteger(POSITION_MAGIC);
         
         // Only close positions belonging to this EA
         if(magic >= InpMagicNumberBase && magic < InpMagicNumberBase + g_symbolCount)
         {
            if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY)
            {
               g_trade.Sell(PositionGetDouble(POSITION_VOLUME), symbol, 0, 0, 0, "Closed: " + reason);
            }
            else
            {
               g_trade.Buy(PositionGetDouble(POSITION_VOLUME), symbol, 0, 0, 0, "Closed: " + reason);
            }
         }
      }
   }
   
   Print("Closed all positions: ", reason);
}

//+------------------------------------------------------------------+
//| Print final statistics                                           |
//+------------------------------------------------------------------+
void PrintFinalStatistics()
{
   double final_balance = AccountInfoDouble(ACCOUNT_BALANCE);
   double final_equity = AccountInfoDouble(ACCOUNT_EQUITY);
   
   Print("=== DLRegesign Final Statistics ===");
   Print("Initial Balance: ", g_initialBalance);
   Print("Final Balance: ", final_balance);
   Print("Final Equity: ", final_equity);
   Print("Net Profit: ", final_equity - g_initialBalance);
   
   // Print per-symbol statistics
   for(int i = 0; i < g_symbolCount; i++)
   {
      Print("Symbol ", g_symbolData[i].name, ": Trades=", g_symbolData[i].totalTrades, 
            " Wins=", g_symbolData[i].winningTrades, " Losses=", g_symbolData[i].losingTrades, 
            " Profit=", g_symbolData[i].totalProfit);
   }
}

//+------------------------------------------------------------------+
//| Global arrays for rates and other data                           |
//+------------------------------------------------------------------+
MqlRates rates_array[];

</script>