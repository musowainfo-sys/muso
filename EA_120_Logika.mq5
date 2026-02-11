//+------------------------------------------------------------------+
//|                                              EA_120_Logika.mq5   |
//|                        Enhanced Multi-Symbol Multi-Strategy EA   |
//|                                       AI-Enhanced Version 2.02   |
//+------------------------------------------------------------------+
#define EA_NAME         "EA_120_Logika"
#define EA_VERSION      "2.02"
#define EA_AUTHOR       "AutoTrader"
#define EA_LINK         ""

#property copyright "EA_120_Logika"
#property link      ""
#property version   "2.02"
#property strict

#include <Trade\Trade.mqh>
#include <Arrays\ArrayLong.mqh>

//+------------------------------------------------------------------+
//| Application Constants                                            |
//+------------------------------------------------------------------+
#define EA_NAME         "EA_120_Logika"
#define EA_VERSION      "2.02"
#define EA_AUTHOR       "AutoTrader"
#define EA_LINK         ""

//+------------------------------------------------------------------+
//| Default Values                                                   |
//+------------------------------------------------------------------+
#define DEFAULT_MAX_TREND_LENGTH      100
#define DEFAULT_MAGIC_NUMBER_BASE     120000
#define DEFAULT_SLIPPAGE              10
#define DEFAULT_MAX_SPREAD_PIPS       3.0
#define DEFAULT_MIN_ACCOUNT_BALANCE   100.0

//+------------------------------------------------------------------+
//| Timeframe Constants                                              |
//+------------------------------------------------------------------+
#define MINIMUM_BARS_REQUIRED         100
#define MAX_SYMBOLS_ALLOWED           1000
#define MAX_POSITIONS_TOTAL           1000

//+------------------------------------------------------------------+
//| Risk Management Constants                                        |
//+------------------------------------------------------------------+
#define MAX_DRAWDOWN_MINIMUM          5.0
#define MAX_DRAWDOWN_MAXIMUM          100.0
#define MAX_LOT_MINIMUM               0.01
#define MAX_LOT_ABSOLUTE              1000.0
#define MIN_GRID_STEP_PIPS            5.0
#define MAX_MARTINGALE_LEVEL_ABSOLUTE 20

//+------------------------------------------------------------------+
//| Trading Session Constants                                        |
//+------------------------------------------------------------------+
#define SESSION_ASIAN_START           0     // 00:00 GMT
#define SESSION_ASIAN_END             9     // 09:00 GMT
#define SESSION_LONDON_START          8     // 08:00 GMT
#define SESSION_LONDON_END            17    // 17:00 GMT
#define SESSION_NEWYORK_START         13    // 13:00 GMT
#define SESSION_NEWYORK_END           22    // 22:00 GMT

//+------------------------------------------------------------------+
//| ENUMERATIONS                                                     |
//+------------------------------------------------------------------

// Trend Direction
enum ENUM_TREND_DIRECTION
{
   TREND_UP,           // Uptrend
   TREND_DOWN,         // Downtrend
   TREND_SIDEWAYS,     // Sideways/Range
   TREND_UNKNOWN       // Not determined
};

// Trading Session
enum ENUM_TRADING_SESSION
{
   SESSION_ASIAN,      // Asian session (Tokyo)
   SESSION_LONDON,     // London session
   SESSION_NEWYORK,    // New York session
   SESSION_ALL         // All sessions (24/7)
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

//+------------------------------------------------------------------+
//| Error Code Definitions                                           |
//+------------------------------------------------------------------+
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
//| Default Parameter Structures                                     |
//+------------------------------------------------------------------

// Scalping Parameters
struct ScalpingParams
{
   int    emaFastPeriod;
   int    emaSlowPeriod;
   int    rsiPeriod;
   int    rsiOversold;
   int    rsiOverbought;
   double minAdxForTrend;  // Minimum ADX for trend confirmation

   ScalpingParams()
   {
      emaFastPeriod = 5;
      emaSlowPeriod = 20;
      rsiPeriod = 14;
      rsiOversold = 30;
      rsiOverbought = 70;
      minAdxForTrend = 25.0;
   }
};

// Breakout Parameters
struct BreakoutParams
{
   int    lookbackPeriod;
   double thresholdPips;
   bool   useVolumeConfirmation;
   double minVolumeMultiplier;

   BreakoutParams()
   {
      lookbackPeriod = 20;
      thresholdPips = 5.0;
      useVolumeConfirmation = false;
      minVolumeMultiplier = 1.5;
   }
};

// Grid Parameters
struct GridParams
{
   double stepPips;
   int    maxLevels;
   bool   useTrailingStop;
   double trailingStartPips;
   double trailingStepPips;

   GridParams()
   {
      stepPips = 30.0;
      maxLevels = 10;
      useTrailingStop = false;
      trailingStartPips = 50.0;
      trailingStepPips = 20.0;
   }
};

// Martingale Parameters
struct MartingaleParams
{
   double lotMultiplier;
   int    maxLevel;
   bool   resetOnProfit;
   bool   useEquityRecovery;
   double recoveryTargetPct;

   MartingaleParams()
   {
      lotMultiplier = 1.5;
      maxLevel = 5;
      resetOnProfit = true;
      useEquityRecovery = false;
      recoveryTargetPct = 5.0;
   }
};

//+------------------------------------------------------------------+
//| Helper Functions                                                 |
//+------------------------------------------------------------------

// Get trend direction name
string TrendDirectionToString(ENUM_TREND_DIRECTION dir)
{
   switch(dir)
   {
      case TREND_UP:       return "Uptrend";
      case TREND_DOWN:     return "Downtrend";
      case TREND_SIDEWAYS: return "Sideways";
      case TREND_UNKNOWN:  return "Unknown";
      default:             return "Invalid";
   }
}

// Get signal type name
string SignalTypeToString(ENUM_SIGNAL_TYPE sig)
{
   switch(sig)
   {
      case SIGNAL_NONE:        return "None";
      case SIGNAL_BUY:         return "Buy";
      case SIGNAL_SELL:        return "Sell";
      case SIGNAL_BUY_STRONG:  return "Strong Buy";
      case SIGNAL_SELL_STRONG: return "Strong Sell";
      default:                 return "Invalid";
   }
}

// Get session name
string SessionToString(ENUM_TRADING_SESSION session)
{
   switch(session)
   {
      case SESSION_ASIAN:   return "Asian";
      case SESSION_LONDON:  return "London";
      case SESSION_NEWYORK: return "New York";
      case SESSION_ALL:     return "All Sessions";
      default:              return "Unknown";
   }
}

// Get error description
string ErrorCodeToString(ENUM_EA_ERROR_CODE err)
{
   switch(err)
   {
      case ERR_EA_NONE:                    return "No error";
      case ERR_EA_INIT_FAILED:             return "Initialization failed";
      case ERR_EA_INVALID_SYMBOL:          return "Invalid symbol";
      case ERR_EA_INSUFFICIENT_DATA:       return "Insufficient historical data";
      case ERR_EA_INDICATOR_FAILED:        return "Indicator creation failed";
      case ERR_EA_DRAWDOWN_LIMIT:          return "Drawdown limit reached";
      case ERR_EA_MARGIN_CALL:             return "Margin call level reached";
      case ERR_EA_TRADE_DISABLED:          return "Trading disabled";
      case ERR_EA_SYMBOL_NOT_TRADEABLE:    return "Symbol not tradeable";
      case ERR_EA_INVALID_TIMEFRAME:       return "Invalid timeframe";
      case ERR_EA_POSITION_LIMIT:          return "Position limit reached";
      case ERR_EA_SPREAD_TOO_HIGH:         return "Spread too high";
      case ERR_EA_OFF_HOURS:               return "Outside trading hours";
      case ERR_EA_UNKNOWN:                 return "Unknown error";
      default:                             return "Undefined error";
   }
}

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
input ENUM_TRADING_SESSION InpTradeSession = SESSION_ALL; // Trading session (default to active sessions)
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
   Print("=== ", EA_NAME, " v", EA_VERSION, " Initializing ===");
   
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
   
   Print(EA_NAME, " deinitialized. Reason: ", reason);
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
      Print("ERROR: BaseLotSize must be > 0");
      valid = false;
   }
   
   if(InpMaxLot < InpBaseLotSize)
   {
      Print("ERROR: MaxLot must be >= BaseLotSize");
      valid = false;
   }
   
   if(InpMaxDrawdownPct < MAX_DRAWDOWN_MINIMUM || InpMaxDrawdownPct > MAX_DRAWDOWN_MAXIMUM)
   {
      Print("ERROR: MaxDrawdownPct must be between ", MAX_DRAWDOWN_MINIMUM, " and ", MAX_DRAWDOWN_MAXIMUM);
      valid = false;
   }
   
   if(InpMaxPositionsPerSymbol <= 0)
   {
      Print("ERROR: MaxPositionsPerSymbol must be > 0");
      valid = false;
   }
   
   if(InpTotalMaxPositions < InpMaxPositionsPerSymbol)
   {
      Print("ERROR: TotalMaxPositions must be >= MaxPositionsPerSymbol");
      valid = false;
   }
   
   // Strategy parameters
   if(InpEMAFast >= InpEMASlow)
   {
      Print("ERROR: EMA Fast must be < EMA Slow");
      valid = false;
   }
   
   if(InpRSIPeriod < 2)
   {
      Print("ERROR: RSI Period must be >= 2");
      valid = false;
   }
   
   if(InpRSIOversold >= InpRSIOverbought)
   {
      Print("ERROR: RSI Oversold must be < RSI Overbought");
      valid = false;
   }
   
   if(InpBreakoutLookback < 5)
   {
      Print("ERROR: BreakoutLookback must be >= 5");
      valid = false;
   }
   
   if(InpGridStepPips < MIN_GRID_STEP_PIPS)
   {
      Print("ERROR: GridStepPips must be >= ", MIN_GRID_STEP_PIPS);
      valid = false;
   }
   
   if(InpMartingaleFactor < 1.0)
   {
      Print("ERROR: MartingaleFactor must be >= 1.0");
      valid = false;
   }
   
   if(InpMaxMartingaleLevel > MAX_MARTINGALE_LEVEL_ABSOLUTE)
   {
      Print("ERROR: MaxMartingaleLevel must be <= ", MAX_MARTINGALE_LEVEL_ABSOLUTE);
      valid = false;
   }
   
   // At least one strategy must be enabled
   if(!InpUseScalping && !InpUseBreakout)
   {
      Print("ERROR: At least one entry strategy must be enabled (Scalping or Breakout)");
      valid = false;
   }
   
   return valid;
}

//+------------------------------------------------------------------+
//| Check trading conditions                                         |
//+------------------------------------------------------------------+
bool CheckTradingConditions()
{
   static datetime lastCheckTime = 0;
   datetime currentTime = TimeCurrent();
   
   // Only perform expensive checks periodically (every 30 seconds)
   if(currentTime - lastCheckTime < 30)
      return g_tradingEnabled && !g_drawdownLimitReached && !g_dailyLimitReached;
   
   lastCheckTime = currentTime;
   
   // Check drawdown limit
   if(!g_drawdownLimitReached && !CheckDrawdownLimit())
   {
      Alert("DRAWDOWN LIMIT REACHED! Trading stopped.");
      g_drawdownLimitReached = true;
      g_tradingEnabled = false;
      return false;
   }
   
   if(g_drawdownLimitReached)
      return false;
   
   // Check daily loss limit
   if(!g_dailyLimitReached && !CheckDailyLossLimit())
   {
      Alert("DAILY LOSS LIMIT REACHED! Trading stopped for today.");
      g_dailyLimitReached = true;
      return false;
   }
   
   if(g_dailyLimitReached)
      return false;
   
   // Check account balance
   double balance = AccountInfoDouble(ACCOUNT_BALANCE);
   if(balance < InpMinAccountBalance)
   {
      Print("Account balance ", balance, " below minimum ", InpMinAccountBalance);
      return false;
   }
   
   // Check total positions
   int totalPos = PositionsTotal();
   if(totalPos >= InpTotalMaxPositions)
   {
      return false;
   }
   
   // Check trading session
   if(InpFilterBySession && !IsTradeSessionAllowed())
   {
      return false;
   }
   
   // Check weekend
   if(InpAvoidWeekend && IsWeekend())
   {
      return false;
   }
   
   return true;
}

//+------------------------------------------------------------------+
//| AI-Enhanced Market Analysis Functions                            |
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//| Enhanced News Filter with AI Analysis                           |
//+------------------------------------------------------------------+
bool IsNewsTime()
{
   if(!InpUseNewsFilter) return false;
   
   datetime now = TimeCurrent();
   MqlDateTime dt;
   TimeToStruct(now, dt);
   
   // Major news times (GMT) - You can expand this list
   static int newsHours[] = {1, 2, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15}; // Major sessions
   static int newsDays[] = {1, 2, 3, 4, 5}; // Monday to Friday
   
   // Check if current day is a trading day
   bool isTradingDay = false;
   for(int i = 0; i < ArraySize(newsDays); i++)
   {
      if(dt.day_of_week == newsDays[i])
      {
         isTradingDay = true;
         break;
      }
   }
   
   if(!isTradingDay) return false;
   
   // Check if current hour is around news time
   for(int i = 0; i < ArraySize(newsHours); i++)
   {
      if(MathAbs(dt.hour - newsHours[i]) <= InpNewsWindowMinutes / 60)
      {
         return true;
      }
   }
   
   return false;
}

//+------------------------------------------------------------------+
//| Calculate Market Volatility                                     |
//+------------------------------------------------------------------+
double CalculateVolatility(string symbol)
{
   double atr[], macdMain[];
   
   SymbolData* data = GetSymbolData(symbol);
   if(data == NULL || data.handleAtr == INVALID_HANDLE)
      return 0;
   
   // Get ATR value
   if(CopyBuffer(data.handleAtr, 0, 0, 20, atr) < 20)
      return 0;
   
   // Calculate volatility as ATR percentage of price
   double price = SymbolInfoDouble(symbol, SYMBOL_BID);
   double avgATR = 0;
   for(int i = 0; i < 20; i++)
   {
      avgATR += atr[i];
   }
   avgATR /= 20;
   
   return (avgATR / price) * 100;
}

//+------------------------------------------------------------------+
//| Analyze Market Sentiment                                         |
//+------------------------------------------------------------------+
double AnalyzeMarketSentiment(int index)
{
   if(!InpUseMarketSentiment) return 0;
   
   SymbolData &data = g_symbolData[index];
   
   // Sentiment based on multiple indicators
   double rsi[], emaFast[], atr[];
   double sentiment = 0;
   int signalCount = 0;
   
   // RSI sentiment
   if(CopyBuffer(data.handleRsi, 0, 0, 3, rsi) >= 3)
   {
      double rsiValue = rsi[0];
      if(rsiValue < 30)
         sentiment += 0.3; // Oversold = Bullish
      else if(rsiValue > 70)
         sentiment -= 0.3; // Overbought = Bearish
      else if(rsiValue > 50)
         sentiment += 0.1; // Bullish zone
      else
         sentiment -= 0.1; // Bearish zone
      signalCount++;
   }
   
   // EMA trend sentiment
   if(CopyBuffer(data.handleEmaFast, 0, 0, 2, emaFast) >= 2 &&
      CopyBuffer(data.handleEmaSlow, 0, 0, 2, emaSlow) >= 2)
   {
      if(emaFast[0] > emaSlow[0])
         sentiment += 0.2; // EMA bullish
      else
         sentiment -= 0.2; // EMA bearish
      signalCount++;
   }
   
   // ADX sentiment (if available)
   if(data.handleAdx != INVALID_HANDLE)
   {
      double adxMain[], adxPlus[], adxMinus[];
      if(CopyBuffer(data.handleAdx, 0, 0, 2, adxMain) >= 2 &&
         CopyBuffer(data.handleAdx, 1, 0, 2, adxPlus) >= 2 &&
         CopyBuffer(data.handleAdx, 2, 0, 2, adxMinus) >= 2)
      {
         if(adxMain[0] > 25) // Strong trend
         {
            if(adxPlus[0] > adxMinus[0])
               sentiment += 0.15; // Bullish trend
            else
               sentiment -= 0.15; // Bearish trend
            signalCount++;
         }
      }
   }
   
   // Normalize sentiment to -1 to +1 range
   if(signalCount > 0)
   {
      sentiment = sentiment / signalCount;
   }
   
   return sentiment;
}

//+------------------------------------------------------------------+
//| Smart Money Flow Analysis                                        |
//+------------------------------------------------------------------+
double CalculateSmartMoneyFlow(int index)
{
   if(!InpUseSmartMoneyFlow) return 0;
   
   SymbolData &data = g_symbolData[index];
   
   // Smart Money Flow = (Volume * Price Change) / ATR
   double volume[], prices[];
   double macdMain[], macdSignal[];
   
   double flow = 0;
   
   // Volume analysis
   if(data.handleVolume != INVALID_HANDLE && CopyBuffer(data.handleVolume, 0, 0, 10, volume) >= 10)
   {
      double avgVolume = 0;
      for(int i = 1; i < 10; i++)
         avgVolume += volume[i];
      avgVolume /= 9;
      
      double currentVolume = volume[0];
      double volumeRatio = currentVolume / avgVolume;
      
      // Price movement analysis
      MqlRates rates[];
      if(CopyRates(data.name, InpTimeframe, 0, 3, rates) >= 3)
      {
         double priceChange = (rates[0].close - rates[1].close) / rates[1].close;
         double priceRange = (rates[0].high - rates[0].low) / rates[0].low;
         
         // Smart money typically moves against retail sentiment
         flow = (volumeRatio * priceChange) / priceRange;
      }
   }
   
   return flow;
}

//+------------------------------------------------------------------+
//| Machine Learning Signal Confidence                               |
//+------------------------------------------------------------------+
double CalculateMLConfidence(int index, ENUM_SIGNAL_TYPE signal)
{
   if(!InpUseMachineLearningFilter) return 0.5; // Default 50% confidence
   
   SymbolData &data = g_symbolData[index];
   double confidence = 0.5;
   
   // ML features based on historical performance
   double winRate = (data.totalTrades > 0) ? (double)data.winningTrades / data.totalTrades : 0.5;
   double avgProfit = (data.totalTrades > 0) ? data.totalProfit / data.totalTrades : 0;
   
   // Signal strength confidence
   double signalConfidence = (data.signalStrength > 2) ? 0.8 : (data.signalStrength > 1) ? 0.6 : 0.4;
   
   // Market conditions confidence
   double marketConfidence = 0.5;
   if(data.currentVolatility > 0 && data.avgVolatility > 0)
   {
      double volRatio = data.currentVolatility / data.avgVolatility;
      marketConfidence = (volRatio > 1.5) ? 0.3 : (volRatio < 0.5) ? 0.7 : 0.6;
   }
   
   // Combine features
   confidence = (winRate * 0.3 + signalConfidence * 0.4 + marketConfidence * 0.3);
   
   // Adjust based on signal type
   if(signal == SIGNAL_BUY_STRONG || signal == SIGNAL_SELL_STRONG)
      confidence *= InpSmartMoneyMultiplier;
   
   return MathMax(0.1, MathMin(0.9, confidence));
}

//+------------------------------------------------------------------+
//| Check if symbol is correlated with existing positions           |
//+------------------------------------------------------------------+
bool IsCorrelatedSymbol(int index)
{
   if(!InpUseCorrelationFilter) return false;
   
   SymbolData &data = g_symbolData[index];
   
   // Simple correlation check based on symbol names and volatility patterns
   for(int i = 0; i < g_symbolCount; i++)
   {
      if(i == index) continue;
      
      SymbolData &otherData = g_symbolData[i];
      
      // Check if both symbols are in same currency family
      if(StringFind(data.name, "USD") >= 0 && StringFind(otherData.name, "USD") >= 0)
      {
         // Check volatility correlation
         double volRatio = data.currentVolatility / otherData.currentVolatility;
         if(volRatio > 1.2 || volRatio < 0.8)
         {
            // High correlation if volatility patterns are similar
            return true;
         }
      }
   }
   
   return false;
}

//+------------------------------------------------------------------+
//| Check optimal volatility conditions                              |
//+------------------------------------------------------------------+
bool IsOptimalVolatility(int index)
{
   if(!InpUseVolatilityFilter) return true;
   
   SymbolData &data = g_symbolData[index];
   
   // Trade only when volatility is within optimal range
   if(data.currentVolatility == 0 || data.avgVolatility == 0)
      return false;
   
   double volRatio = data.currentVolatility / data.avgVolatility;
   
   // Optimal volatility range
   return (volRatio >= 0.8 && volRatio <= 1.5);
}

//+------------------------------------------------------------------+
//| Get symbol data by name                                          |
//+------------------------------------------------------------------+
SymbolData* GetSymbolData(string symbol)
{
   for(int i = 0; i < g_symbolCount; i++)
   {
      if(g_symbolData[i].name == symbol)
         return &g_symbolData[i];
   }
   return NULL;
}

//+------------------------------------------------------------------+
//| Check if weekend                                                 |
//+------------------------------------------------------------------+
bool IsWeekend()
{
   datetime now = TimeCurrent();
   MqlDateTime dt;
   TimeToStruct(now, dt);
   
   // Friday after 22:00 or Saturday or Sunday
   if(dt.day_of_week == 5 && dt.hour >= 22)
      return true;
   if(dt.day_of_week == 6 || dt.day_of_week == 0)
      return true;
   
   return false;
}

//+------------------------------------------------------------------+
//| Check trading session                                            |
//+------------------------------------------------------------------+
bool IsTradeSessionAllowed()
{
   datetime now = TimeCurrent();
   MqlDateTime dt;
   TimeToStruct(now, dt);
   int hour = dt.hour;
   
   switch(InpTradeSession)
   {
      case SESSION_ASIAN:
         return (hour >= SESSION_ASIAN_START && hour < SESSION_ASIAN_END);
      
      case SESSION_LONDON:
         return (hour >= SESSION_LONDON_START && hour < SESSION_LONDON_END);
      
      case SESSION_NEWYORK:
         return (hour >= SESSION_NEWYORK_START && hour < SESSION_NEWYORK_END);
      
      case SESSION_ALL:
      default:
      {
         bool asian = InpTradeAsian && (hour >= SESSION_ASIAN_START && hour < SESSION_ASIAN_END);
         bool london = InpTradeLondon && (hour >= SESSION_LONDON_START && hour < SESSION_LONDON_END);
         bool ny = InpTradeNewYork && (hour >= SESSION_NEWYORK_START && hour < SESSION_NEWYORK_END);
         return (asian || london || ny);
      }
   }
   
   return true;
}

//+------------------------------------------------------------------+
//| Check drawdown limit                                             |
//+------------------------------------------------------------------+
bool CheckDrawdownLimit()
{
   double balance = AccountInfoDouble(ACCOUNT_BALANCE);
   double equity = AccountInfoDouble(ACCOUNT_EQUITY);
   
   if(balance <= 0)
      return true;
   
   double drawdownPct = ((balance - equity) / balance) * 100.0;
   
   if(drawdownPct >= InpMaxDrawdownPct)
   {
      Print("DRAWDOWN LIMIT! Current: ", DoubleToString(drawdownPct, 2), 
            "% | Limit: ", InpMaxDrawdownPct, "%");
      return false;
   }
   
   return true;
}

//+------------------------------------------------------------------+
//| Check daily loss limit                                           |
//+------------------------------------------------------------------+
bool CheckDailyLossLimit()
{
   double currentEquity = AccountInfoDouble(ACCOUNT_EQUITY);
   
   if(g_dailyStartingEquity <= 0)
      return true;
   
   double lossPct = ((g_dailyStartingEquity - currentEquity) / g_dailyStartingEquity) * 100.0;
   
   if(lossPct >= InpDailyLossLimitPct)
   {
      Print("DAILY LOSS LIMIT! Loss: ", DoubleToString(lossPct, 2), 
            "% | Limit: ", InpDailyLossLimitPct, "%");
      return false;
   }
   
   return true;
}

//+------------------------------------------------------------------+
//| Build list of symbols to trade                                   |
//+------------------------------------------------------------------+
bool BuildSymbolList()
{
   ArrayResize(g_symbolList, 0);
   g_symbolCount = 0;
   
   if(InpTradeAllSymbols)
   {
      int total = SymbolsTotal(false);
      int added = 0;
      
      for(int i = 0; i < total && added < MAX_SYMBOLS_ALLOWED; i++)
      {
         string symbol = SymbolName(i, false);
         
         if(IsSymbolTradeable(symbol))
         {
            ArrayResize(g_symbolList, added + 1);
            g_symbolList[added] = symbol;
            added++;
         }
      }
      
      g_symbolCount = added;
      Print("Added ", g_symbolCount, " tradeable symbols out of ", total);
   }
   else
   {
      string symbol = (InpSingleSymbol == "") ? _Symbol : InpSingleSymbol;
      
      if(!IsSymbolTradeable(symbol))
      {
         Print("ERROR: Symbol ", symbol, " is not tradeable");
         return false;
      }
      
      ArrayResize(g_symbolList, 1);
      g_symbolList[0] = symbol;
      g_symbolCount = 1;
      
      Print("Trading single symbol: ", symbol);
   }
   
   ArrayResize(g_symbolData, g_symbolCount);
   
   return (g_symbolCount > 0);
}

//+------------------------------------------------------------------+
//| Check if symbol is tradeable                                     |
//+------------------------------------------------------------------+
bool IsSymbolTradeable(string symbol)
{
   // Select symbol
   if(!SymbolSelect(symbol, true))
   {
      return false;
   }
   
   // Check trade mode
   ENUM_SYMBOL_TRADE_MODE tradeMode = (ENUM_SYMBOL_TRADE_MODE)SymbolInfoInteger(symbol, SYMBOL_TRADE_MODE);
   if(tradeMode == SYMBOL_TRADE_MODE_DISABLED)
   {
      return false;
   }
   
   // Check if symbol is a standard forex pair or CFD
   string symbolUpper = symbol;
   StringToUpper(symbolUpper);
   
   // Skip non-forex symbols (custom indices, etc)
   if(StringFind(symbolUpper, "#") >= 0)
      return false;
   
   // Check minimum data
   MqlRates rates[];
   int copied = CopyRates(symbol, InpTimeframe, 0, MINIMUM_BARS_REQUIRED, rates);
   if(copied < MINIMUM_BARS_REQUIRED)
   {
      return false;
   }
   
   // Check spread
   double spread = SymbolInfoInteger(symbol, SYMBOL_SPREAD);
   double point = SymbolInfoDouble(symbol, SYMBOL_POINT);
   int digits = (int)SymbolInfoInteger(symbol, SYMBOL_DIGITS);
   double spreadPips = spread * ((digits == 5 || digits == 3) ? 0.1 : 1.0);
   
   if(spreadPips > InpMaxSpreadPips * 2)  // Be lenient during initialization
   {
      return false;
   }
   
   return true;
}

//+------------------------------------------------------------------+
//| Initialize symbol data                                           |
//+------------------------------------------------------------------+
bool InitializeSymbolData()
{
   for(int i = 0; i < g_symbolCount; i++)
   {
      string symbol = g_symbolList[i];
      
      // Store symbol info
      g_symbolData[i].name = symbol;
      g_symbolData[i].digits = (int)SymbolInfoInteger(symbol, SYMBOL_DIGITS);
      g_symbolData[i].point = SymbolInfoDouble(symbol, SYMBOL_POINT);
      g_symbolData[i].pipValue = (g_symbolData[i].digits == 5 || g_symbolData[i].digits == 3) ? 
                                   g_symbolData[i].point * 10 : g_symbolData[i].point;
      g_symbolData[i].minLot = SymbolInfoDouble(symbol, SYMBOL_VOLUME_MIN);
      g_symbolData[i].maxLot = SymbolInfoDouble(symbol, SYMBOL_VOLUME_MAX);
      g_symbolData[i].lotStep = SymbolInfoDouble(symbol, SYMBOL_VOLUME_STEP);
      g_symbolData[i].tickSize = SymbolInfoDouble(symbol, SYMBOL_TRADE_TICK_SIZE);
      g_symbolData[i].tickValue = SymbolInfoDouble(symbol, SYMBOL_TRADE_TICK_VALUE);
      g_symbolData[i].magicNumber = InpMagicNumberBase + i;
      
      // Create indicators
      if(!CreateIndicators(i))
      {
         Print("ERROR: Failed to create indicators for ", symbol);
         return false;
      }
      
      g_symbolData[i].Init();
      g_symbolData[i].name = symbol;
      g_symbolData[i].digits = (int)SymbolInfoInteger(symbol, SYMBOL_DIGITS);
      g_symbolData[i].magicNumber = InpMagicNumberBase + i;
   }
   
   return true;
}

//+------------------------------------------------------------------+
//| Create indicators for symbol                                     |
//+------------------------------------------------------------------+
bool CreateIndicators(int index)
{
   string symbol = g_symbolList[index];
   ENUM_TIMEFRAMES tf = InpTimeframe;
   
   // EMA indicators
   g_symbolData[index].handleEmaFast = iMA(symbol, tf, InpEMAFast, 0, MODE_EMA, PRICE_CLOSE);
   g_symbolData[index].handleEmaSlow = iMA(symbol, tf, InpEMASlow, 0, MODE_EMA, PRICE_CLOSE);
   g_symbolData[index].handleRsi = iRSI(symbol, tf, InpRSIPeriod, PRICE_CLOSE);
   g_symbolData[index].handleAtr = iATR(symbol, tf, 14);
   
   // ADX filter
   if(InpUseADXFilter)
   {
      g_symbolData[index].handleAdx = iADX(symbol, tf, InpADXPeriod);
   }
   
   // Volume indicator (if volume confirmation is enabled)
   if(InpUseVolumeConfirmation)
   {
      g_symbolData[index].handleVolume = iVolumes(symbol, tf, VOLUME_TICK);
   }
   
   // Validate critical handles
   if(g_symbolData[index].handleEmaFast == INVALID_HANDLE ||
      g_symbolData[index].handleEmaSlow == INVALID_HANDLE ||
      g_symbolData[index].handleRsi == INVALID_HANDLE ||
      g_symbolData[index].handleAtr == INVALID_HANDLE)
   {
      Print("ERROR: Failed to create essential indicators for ", symbol);
      return false;
   }
   
   return true;
}

//+------------------------------------------------------------------+
//| Release indicators                                               |
//+------------------------------------------------------------------+
void ReleaseIndicators(int index)
{
   if(g_symbolData[index].handleEmaFast != INVALID_HANDLE)
      IndicatorRelease(g_symbolData[index].handleEmaFast);
   if(g_symbolData[index].handleEmaSlow != INVALID_HANDLE)
      IndicatorRelease(g_symbolData[index].handleEmaSlow);
   if(g_symbolData[index].handleRsi != INVALID_HANDLE)
      IndicatorRelease(g_symbolData[index].handleRsi);
   if(g_symbolData[index].handleAtr != INVALID_HANDLE)
      IndicatorRelease(g_symbolData[index].handleAtr);
   if(g_symbolData[index].handleAdx != INVALID_HANDLE)
      IndicatorRelease(g_symbolData[index].handleAdx);
   if(g_symbolData[index].handleVolume != INVALID_HANDLE)
      IndicatorRelease(g_symbolData[index].handleVolume);
}

//+------------------------------------------------------------------+
//| Process individual symbol                                        |
//+------------------------------------------------------------------+
void ProcessSymbol(int index)
{
   string symbol = g_symbolList[index];
   SymbolData &data = g_symbolData[index];
   
   // Check position limits early to avoid unnecessary calculations
   if(GetPositionsCountForSymbol(symbol) >= InpMaxPositionsPerSymbol)
      return;
   
   // Check spread
   if(!CheckSpread(symbol))
      return;
   
   // AI-Enhanced Market Analysis
   if(InpUseMarketSentiment || InpUseVolatilityFilter || 
      InpUseSmartMoneyFlow || InpUseCorrelationFilter)
   {
      // Calculate volatility
      if(InpUseVolatilityFilter)
      {
         data.currentVolatility = CalculateVolatility(symbol);
         if(data.avgVolatility == 0)
            data.avgVolatility = data.currentVolatility;
         else
            data.avgVolatility = (data.avgVolatility * 0.9 + data.currentVolatility * 0.1);
         
         // Check optimal volatility
         if(!IsOptimalVolatility(index))
         {
            // Skip this symbol - volatility not optimal
         }
      }
      
      // Analyze market sentiment
      if(InpUseMarketSentiment)
      {
         data.sentimentScore = AnalyzeMarketSentiment(index);
      }
      
      // Calculate Smart Money Flow
      if(InpUseSmartMoneyFlow)
      {
         data.smartMoneyFlow = CalculateSmartMoneyFlow(index);
      }
      
      // Check correlation
      if(InpUseCorrelationFilter)
      {
         data.isCorrelated = IsCorrelatedSymbol(index);
      }
   }
   
   // Update position info
   UpdatePositionInfo(index);
   
   // Manage open positions (trailing, breakeven)
   ManageOpenPositions(index);
   
   // Check martingale reset conditions
   CheckMartingaleReset(index);
   
   // Get indicator data
   double emaFast[], emaSlow[], rsi[], atr[];
   if(CopyBuffer(data.handleEmaFast, 0, 0, 3, emaFast) < 3 ||
      CopyBuffer(data.handleEmaSlow, 0, 0, 3, emaSlow) < 3 ||
      CopyBuffer(data.handleRsi, 0, 0, 3, rsi) < 3 ||
      CopyBuffer(data.handleAtr, 0, 0, 3, atr) < 3)
   {
      return;
   }
   
   // Get current prices
   double ask = SymbolInfoDouble(symbol, SYMBOL_ASK);
   double bid = SymbolInfoDouble(symbol, SYMBOL_BID);
   
   if(ask <= 0 || bid <= 0)
      return;
   
   // Get breakout levels
   double highestHigh = 0, lowestLow = 0;
   if(InpUseBreakout)
   {
      GetBreakoutLevels(symbol, highestHigh, lowestLow);
   }
   
   // Generate signals
   ENUM_SIGNAL_TYPE signal = GenerateSignals(index, emaFast, emaSlow, rsi, atr, 
                                              ask, bid, highestHigh, lowestLow);
   
   // AI-Enhanced Signal Validation
   if(InpUseMachineLearningFilter && signal != SIGNAL_NONE)
   {
      data.mlConfidence = CalculateMLConfidence(index, signal);
      
      // Filter out low confidence signals
      if(data.mlConfidence < 0.4)
      {
         signal = SIGNAL_NONE;
      }
   }
   
   // Execute trades based on signals and current positions
   if(data.positionsCount == 0)
   {
      // No positions - open new if signal exists
      if(signal == SIGNAL_BUY || signal == SIGNAL_BUY_STRONG)
      {
         double lot = CalculateLotSize(index, ORDER_TYPE_BUY, 0);
         if(lot > 0)
            OpenPosition(index, ORDER_TYPE_BUY, lot);
      }
      else if(signal == SIGNAL_SELL || signal == SIGNAL_SELL_STRONG)
      {
         double lot = CalculateLotSize(index, ORDER_TYPE_SELL, 0);
         if(lot > 0)
            OpenPosition(index, ORDER_TYPE_SELL, lot);
      }
   }
   else if(data.positionsCount < InpMaxPositionsPerSymbol)
   {
      // Have positions - check grid/martingale
      if(InpUseGrid || InpUseMartingale)
      {
         ManageGridMartingale(index, ask, bid);
      }
   }
}

//+------------------------------------------------------------------+
//| Check spread                                                     |
//+------------------------------------------------------------------+
bool CheckSpread(string symbol)
{
   long spread = SymbolInfoInteger(symbol, SYMBOL_SPREAD);
   int digits = (int)SymbolInfoInteger(symbol, SYMBOL_DIGITS);
   double spreadPips = spread * ((digits == 5 || digits == 3) ? 0.1 : 1.0);
   
   return (spreadPips <= InpMaxSpreadPips);
}

//+------------------------------------------------------------------+
//| Update position information                                      |
//+------------------------------------------------------------------+
void UpdatePositionInfo(int index)
{
   SymbolData &data = g_symbolData[index];
   
   data.positionsCount = 0;
   data.totalLotsBuy = 0;
   data.totalLotsSell = 0;
   data.profitBuy = 0;
   data.profitSell = 0;
   
   double buyPriceSum = 0;
   double sellPriceSum = 0;
   int buyCount = 0;
   int sellCount = 0;
   
   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      ulong ticket = PositionGetTicket(i);
      if(ticket <= 0)
         continue;
      
      if(PositionGetString(POSITION_SYMBOL) != data.name)
         continue;
      
      long magic = PositionGetInteger(POSITION_MAGIC);
      if(magic < InpMagicNumberBase || magic >= InpMagicNumberBase + MAX_SYMBOLS_ALLOWED)
         continue;
      
      ENUM_POSITION_TYPE posType = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
      double lots = PositionGetDouble(POSITION_VOLUME);
      double profit = PositionGetDouble(POSITION_PROFIT) + PositionGetDouble(POSITION_SWAP);
      double openPrice = PositionGetDouble(POSITION_PRICE_OPEN);
      
      data.positionsCount++;
      
      if(posType == POSITION_TYPE_BUY)
      {
         data.totalLotsBuy += lots;
         data.profitBuy += profit;
         buyPriceSum += openPrice * lots;
         buyCount++;
      }
      else
      {
         data.totalLotsSell += lots;
         data.profitSell += profit;
         sellPriceSum += openPrice * lots;
         sellCount++;
      }
   }
   
   data.avgPriceBuy = (data.totalLotsBuy > 0) ? buyPriceSum / data.totalLotsBuy : 0;
   data.avgPriceSell = (data.totalLotsSell > 0) ? sellPriceSum / data.totalLotsSell : 0;
   
   // Update grid tracking
   if(buyCount == 0)
      data.ResetGridBuy();
   if(sellCount == 0)
      data.ResetGridSell();
}

//+------------------------------------------------------------------+
//| Manage open positions (trailing, breakeven)                      |
//+------------------------------------------------------------------+
void ManageOpenPositions(int index)
{
   if(!InpUseTrailingStop && !InpUseBreakEven)
      return;
   
   SymbolData &data = g_symbolData[index];
   
   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      ulong ticket = PositionGetTicket(i);
      if(ticket <= 0)
         continue;
      
      if(PositionGetString(POSITION_SYMBOL) != data.name)
         continue;
      
      long magic = PositionGetInteger(POSITION_MAGIC);
      if(magic != data.magicNumber)
         continue;
      
      double openPrice = PositionGetDouble(POSITION_PRICE_OPEN);
      double currentSL = PositionGetDouble(POSITION_SL);
      double currentTP = PositionGetDouble(POSITION_TP);
      double bid = SymbolInfoDouble(data.name, SYMBOL_BID);
      double ask = SymbolInfoDouble(data.name, SYMBOL_ASK);
      ENUM_POSITION_TYPE posType = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
      
      double point = data.point;
      double pipValue = data.pipValue;
      double newSL = currentSL;
      bool modify = false;
      
      // Breakeven
      if(InpUseBreakEven && currentSL == 0)
      {
         double beDistance = InpBreakEvenPips * pipValue;
         
         if(posType == POSITION_TYPE_BUY && bid >= openPrice + beDistance)
         {
            newSL = NormalizeDouble(openPrice + (2 * pipValue), data.digits);
            modify = true;
         }
         else if(posType == POSITION_TYPE_SELL && ask <= openPrice - beDistance)
         {
            newSL = NormalizeDouble(openPrice - (2 * pipValue), data.digits);
            modify = true;
         }
      }
      
      // Trailing stop
      if(InpUseTrailingStop)
      {
         double trailStart = InpTrailingStartPips * pipValue;
         double trailStep = InpTrailingStepPips * pipValue;
         
         if(posType == POSITION_TYPE_BUY)
         {
            double profitPips = (bid - openPrice) / pipValue;
            if(profitPips >= InpTrailingStartPips)
            {
               double desiredSL = NormalizeDouble(bid - trailStep, data.digits);
               if(desiredSL > currentSL || currentSL == 0)
               {
                  newSL = desiredSL;
                  modify = true;
               }
            }
         }
         else // SELL
         {
            double profitPips = (openPrice - ask) / pipValue;
            if(profitPips >= InpTrailingStartPips)
            {
               double desiredSL = NormalizeDouble(ask + trailStep, data.digits);
               if(desiredSL < currentSL || currentSL == 0)
               {
                  newSL = desiredSL;
                  modify = true;
               }
            }
         }
      }
      
      // Modify position
      if(modify && newSL != currentSL)
      {
         g_trade.PositionModify(ticket, newSL, currentTP);
      }
   }
}

//+------------------------------------------------------------------+
//| Check and reset martingale conditions                            |
//+------------------------------------------------------------------+
void CheckMartingaleReset(int index)
{
   if(!InpResetMartingaleOnProfit)
      return;
   
   SymbolData &data = g_symbolData[index];
   
   // Reset buy grid if buy positions are profitable
   if(data.totalLotsBuy > 0 && data.profitBuy > 0)
   {
      data.ResetGridBuy();
   }
   
   // Reset sell grid if sell positions are profitable
   if(data.totalLotsSell > 0 && data.profitSell > 0)
   {
      data.ResetGridSell();
   }
}

//+------------------------------------------------------------------+
//| Generate trading signals - Combined aggressive multi-strategy      |
//+------------------------------------------------------------------+
ENUM_SIGNAL_TYPE GenerateSignals(int index, double &emaFast[], double &emaSlow[], 
                                  double &rsi[], double &atr[], 
                                  double ask, double bid,
                                  double highestHigh, double lowestLow)
{
   SymbolData &data = g_symbolData[index];
   
   bool buyScalp = false;
   bool sellScalp = false;
   bool buyBreak = false;
   bool sellBreak = false;
   int buyStrength = 0;
   int sellStrength = 0;
   
   // === SCALPING STRATEGY (EMA/RSI) ===
   if(InpUseScalping)
   {
      bool emaBullish = emaFast[0] > emaSlow[0];
      bool emaBearish = emaFast[0] < emaSlow[0];
      bool emaCrossUp = emaFast[1] <= emaSlow[1] && emaFast[0] > emaSlow[0];
      bool emaCrossDown = emaFast[1] >= emaSlow[1] && emaFast[0] < emaSlow[0];
      
      double rsiValue = rsi[0];
      
      // EMA crossover with RSI confirmation (primary scalping signal)
      if(emaCrossUp && rsiValue < InpRSIOversold)
      {
         buyScalp = true;
         buyStrength += 3;  // Strong signal
      }
      
      if(emaCrossDown && rsiValue > InpRSIOverbought)
      {
         sellScalp = true;
         sellStrength += 3;  // Strong signal
      }
      
      // Aggressive momentum continuation signals
      if(InpUseRSIMomentum)
      {
         // Bullish momentum: EMA trending up + RSI in bullish zone
         if(emaBullish && rsiValue > 40 && rsiValue < 65)
         {
            buyScalp = true;
            buyStrength += 2;
         }
         
         // Bearish momentum: EMA trending down + RSI in bearish zone
         if(emaBearish && rsiValue < 60 && rsiValue > 35)
         {
            sellScalp = true;
            sellStrength += 2;
         }
         
         // RSI extreme signals (aggressive oversold/overbought)
         if(rsiValue < 20)  // Deep oversold
         {
            buyScalp = true;
            buyStrength += 2;
         }
         if(rsiValue > 80)  // Deep overbought
         {
            sellScalp = true;
            sellStrength += 2;
         }
      }
      
      // ADX trend filter (optional)
      if(InpUseADXFilter && data.handleAdx != INVALID_HANDLE)
      {
         double adxMain[], adxPlus[], adxMinus[];
         if(CopyBuffer(data.handleAdx, 0, 0, 2, adxMain) >= 2 &&
            CopyBuffer(data.handleAdx, 1, 0, 2, adxPlus) >= 2 &&
            CopyBuffer(data.handleAdx, 2, 0, 2, adxMinus) >= 2)
         {
            if(adxMain[0] >= InpADXMinimum)
            {
               if(adxPlus[0] > adxMinus[0])
                  buyStrength += 1;
               else if(adxMinus[0] > adxPlus[0])
                  sellStrength += 1;
            }
            else
            {
               // Low ADX = ranging market, reduce confidence
               buyStrength -= 1;
               sellStrength -= 1;
            }
         }
      }
   }
   
   // === BREAKOUT STRATEGY ===
   if(InpUseBreakout && highestHigh > 0 && lowestLow > 0)
   {
      double threshold = InpBreakoutThreshold * data.pipValue;
      
      // Aggressive breakout detection
      if(ask > highestHigh + threshold)
      {
         buyBreak = true;
         buyStrength += 3;
      }
      
      if(bid < lowestLow - threshold)
      {
         sellBreak = true;
         sellStrength += 3;
      }
      
      // Additional breakout confirmation: strong close above/below
      MqlRates rates[];
      if(CopyRates(data.name, InpTimeframe, 0, 2, rates) >= 2)
      {
         // Bullish continuation after breakout
         if(ask > highestHigh && rates[0].close > rates[0].open)
         {
            buyStrength += 1;
         }
         // Bearish continuation after breakout
         if(bid < lowestLow && rates[0].close < rates[0].open)
         {
            sellStrength += 1;
         }
      }
      
      // Volume confirmation (if enabled)
      if(InpUseVolumeConfirmation && data.handleVolume != INVALID_HANDLE)
      {
         double volume[];
         if(CopyBuffer(data.handleVolume, 0, 0, 3, volume) >= 3)
         {
            double avgVolume = (volume[1] + volume[2]) / 2.0;
            if(volume[0] > avgVolume * InpVolumeMultiplier)
            {
               buyStrength += 1;
               sellStrength += 1;
            }
         }
      }
   }
   
   // === AGGRESSIVE SIGNAL COMBINATION ===
   // Combined strategy: both scalping and breakout agree = stronger signal
   bool buySignalCombined = buyScalp && buyBreak;
   bool sellSignalCombined = sellScalp && sellBreak;
   
   // Boost strength for combined signals (aggressive confirmation)
   if(buySignalCombined)
      buyStrength += 2;
   if(sellSignalCombined)
      sellStrength += 2;
   
   // Final signal determination
   bool buySignal = buyScalp || buyBreak;
   bool sellSignal = sellScalp || sellBreak;
   
   // Minimum signal strength check (lower threshold for aggressive trading)
   if(buySignal && buyStrength < MathMax(1, InpMinSignalStrength - 1))
      buySignal = false;
   if(sellSignal && sellStrength < MathMax(1, InpMinSignalStrength - 1))
      sellSignal = false;
   
   // Trend filter (optional)
   if(InpUseTrendFilter)
   {
      ENUM_TREND_DIRECTION trend = GetHigherTimeframeTrend(data.name);
      if(trend == TREND_DOWN && buySignal)
      {
         buySignal = false;
         buyStrength = 0;
      }
      if(trend == TREND_UP && sellSignal)
      {
         sellSignal = false;
         sellStrength = 0;
      }
   }
   
   // Store signal
   if(buySignal && !sellSignal)
   {
      data.lastSignal = (buyStrength >= 4) ? SIGNAL_BUY_STRONG : SIGNAL_BUY;
      data.lastSignalTime = TimeCurrent();
      data.signalStrength = buyStrength;
      return data.lastSignal;
   }
   else if(sellSignal && !buySignal)
   {
      data.lastSignal = (sellStrength >= 4) ? SIGNAL_SELL_STRONG : SIGNAL_SELL;
      data.lastSignalTime = TimeCurrent();
      data.signalStrength = sellStrength;
      return data.lastSignal;
   }
   
   // No clear signal
   data.lastSignal = SIGNAL_NONE;
   data.signalStrength = 0;
   return SIGNAL_NONE;
}

//+------------------------------------------------------------------+
//| Get higher timeframe trend                                       |
//+------------------------------------------------------------------+
ENUM_TREND_DIRECTION GetHigherTimeframeTrend(string symbol)
{
   int handleFast = iMA(symbol, InpTrendTimeframe, 50, 0, MODE_EMA, PRICE_CLOSE);
   int handleSlow = iMA(symbol, InpTrendTimeframe, 200, 0, MODE_EMA, PRICE_CLOSE);
   
   if(handleFast == INVALID_HANDLE || handleSlow == INVALID_HANDLE)
      return TREND_UNKNOWN;
   
   double fast[], slow[];
   ENUM_TREND_DIRECTION trend = TREND_UNKNOWN;
   
   if(CopyBuffer(handleFast, 0, 0, 2, fast) >= 2 &&
      CopyBuffer(handleSlow, 0, 0, 2, slow) >= 2)
   {
      if(fast[0] > slow[0] && fast[1] <= slow[1])
         trend = TREND_UP;
      else if(fast[0] < slow[0] && fast[1] >= slow[1])
         trend = TREND_DOWN;
      else if(fast[0] > slow[0])
         trend = TREND_UP;
      else if(fast[0] < slow[0])
         trend = TREND_DOWN;
      else
         trend = TREND_SIDEWAYS;
   }
   
   IndicatorRelease(handleFast);
   IndicatorRelease(handleSlow);
   
   return trend;
}

//+------------------------------------------------------------------+
//| Get breakout levels                                              |
//+------------------------------------------------------------------+
void GetBreakoutLevels(string symbol, double &highestHigh, double &lowestLow)
{
   MqlRates rates[];
   int copied = CopyRates(symbol, InpTimeframe, 1, InpBreakoutLookback, rates);
   
   if(copied < InpBreakoutLookback)
   {
      highestHigh = 0;
      lowestLow = 0;
      return;
   }
   
   highestHigh = rates[0].high;
   lowestLow = rates[0].low;
   
   for(int i = 1; i < copied; i++)
   {
      if(rates[i].high > highestHigh)
         highestHigh = rates[i].high;
      if(rates[i].low < lowestLow)
         lowestLow = rates[i].low;
   }
}

//+------------------------------------------------------------------+
//| Calculate lot size                                               |
//+------------------------------------------------------------------+
double CalculateLotSize(int index, ENUM_ORDER_TYPE orderType, double existingLots)
{
   SymbolData &data = g_symbolData[index];
   double lot = InpBaseLotSize;
   
   // Risk-based sizing
   if(InpUseRiskPercent)
   {
      double tickValue = data.tickValue;
      double tickSize = data.tickSize;
      
      if(tickValue > 0 && tickSize > 0 && InpStopLossPips > 0)
      {
         double riskAmount = AccountInfoDouble(ACCOUNT_BALANCE) * InpRiskPercent / 100.0;
         double slTicks = InpStopLossPips * (data.pipValue / tickSize);
         double valuePerLot = slTicks * tickValue;
         
         if(valuePerLot > 0)
            lot = riskAmount / valuePerLot;
      }
   }
   
   // Kelly criterion (simplified)
   if(InpUseKellyCriterion && data.totalTrades > 20)
   {
      double winRate = (double)data.winningTrades / data.totalTrades;
      double avgWin = (data.winningTrades > 0) ? data.totalProfit / data.winningTrades : 0;
      double avgLoss = (data.losingTrades > 0) ? 
         -data.totalProfit / data.losingTrades : avgWin;
      
      if(avgLoss > 0)
      {
         double kelly = (winRate - ((1 - winRate) / (avgWin / avgLoss))) / 2;  // Half Kelly
         if(kelly > 0)
            lot *= kelly;
      }
   }
   
   // Martingale adjustment
   if(existingLots > 0 && InpUseMartingale)
   {
      lot = existingLots * InpMartingaleFactor;
   }
   
   return NormalizeLot(index, lot);
}

//+------------------------------------------------------------------+
//| Normalize lot size                                               |
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//| Calculate Adaptive SL/TP based on volatility                      |
//+------------------------------------------------------------------+
void CalculateAdaptiveSLTP(int index, ENUM_ORDER_TYPE orderType, 
                           double &slDistance, double &tpDistance)
{
   if(!InpUseAdaptiveSLTP) return;
   
   SymbolData &data = g_symbolData[index];
   
   // Get current volatility
   double atrBuffer[];
   if(CopyBuffer(data.handleAtr, 0, 0, 1, atrBuffer) <= 0)
      return;
   
   double atrValue = atrBuffer[0];
   double price = SymbolInfoDouble(data.name, SYMBOL_BID);
   
   // Calculate volatility ratio
   double volRatio = (data.avgVolatility > 0) ? data.currentVolatility / data.avgVolatility : 1.0;
   
   // Adjust SL based on volatility
   // Higher volatility = wider SL to avoid noise
   double volatilityMultiplier = 1.0;
   if(volRatio > 1.5)
      volatilityMultiplier = 1.5; // Wider SL in high volatility
   else if(volRatio < 0.8)
      volatilityMultiplier = 0.8; // Tighter SL in low volatility
   
   // Apply adaptive multiplier
   slDistance *= volatilityMultiplier;
   
   // Adjust TP based on sentiment and confidence
   if(InpUseMarketSentiment && data.mlConfidence > 0)
   {
      // Higher confidence = wider TP for more profit potential
      double tpMultiplier = 0.8 + (data.mlConfidence * 0.4); // Range: 0.8 to 1.2
      tpDistance *= tpMultiplier;
   }
   
   // Minimum SL/TP based on ATR
   double minSL = atrValue * 1.5;
   double minTP = atrValue * 1.0;
   
   slDistance = MathMax(slDistance, minSL);
   tpDistance = MathMax(tpDistance, minTP);
}

//+------------------------------------------------------------------+
//| Normalize lot size                                               |
//+------------------------------------------------------------------+
double NormalizeLot(int index, double lot)
{
   SymbolData &data = g_symbolData[index];
   
   if(lot < data.minLot)
      lot = data.minLot;
   if(lot > data.maxLot)
      lot = data.maxLot;
   if(lot > InpMaxLot)
      lot = InpMaxLot;
   
   lot = MathFloor(lot / data.lotStep) * data.lotStep;
   lot = NormalizeDouble(lot, 2);
   
   return lot;
}

//+------------------------------------------------------------------+
//| Open position with enhanced SL/TP normalization and validation    |
//+------------------------------------------------------------------+
bool OpenPosition(int index, ENUM_ORDER_TYPE orderType, double lotSize)
{
   SymbolData &data = g_symbolData[index];
   
   if(lotSize <= 0)
      return false;
   
   // Validate lot size
   lotSize = NormalizeLot(index, lotSize);
   if(lotSize <= 0)
      return false;
   
   double sl = 0, tp = 0;
   double ask = SymbolInfoDouble(data.name, SYMBOL_ASK);
   double bid = SymbolInfoDouble(data.name, SYMBOL_BID);
   
   // Calculate SL/TP with enhanced normalization
   if(InpUseFixedSLTP)
   {
      double slDistance = InpStopLossPips * data.pipValue;
      double tpDistance = InpTakeProfitPips * data.pipValue;
      
      // Apply AI-Enhanced Adaptive SL/TP
      CalculateAdaptiveSLTP(index, orderType, slDistance, tpDistance);
      
      // Get ATR for dynamic adjustment (optional enhancement)
      double atrBuffer[];
      if(CopyBuffer(data.handleAtr, 0, 0, 1, atrBuffer) > 0)
      {
         double atrValue = atrBuffer[0];
         // Use maximum of fixed SL/TP or ATR-based levels
         slDistance = MathMax(slDistance, atrValue * 2);
         tpDistance = MathMax(tpDistance, atrValue * 1.5);
      }
      
      if(orderType == ORDER_TYPE_BUY)
      {
         sl = NormalizeDouble(ask - slDistance, data.digits);
         tp = NormalizeDouble(ask + tpDistance, data.digits);
         
         // Ensure SL is below current price
         if(sl >= ask) sl = NormalizeDouble(ask - slDistance, data.digits);
         if(tp <= ask) tp = NormalizeDouble(ask + tpDistance, data.digits);
      }
      else
      {
         sl = NormalizeDouble(bid + slDistance, data.digits);
         tp = NormalizeDouble(bid - tpDistance, data.digits);
         
         // Ensure SL is above current price
         if(sl <= bid) sl = NormalizeDouble(bid + slDistance, data.digits);
         if(tp >= bid) tp = NormalizeDouble(bid - tpDistance, data.digits);
      }
   }
   
   // Set magic number for this symbol
   g_trade.SetExpertMagicNumber((int)data.magicNumber);
   
   // Enhanced order comment
   string strategyInfo = "";
   if(InpUseScalping && InpUseBreakout)
      strategyInfo = "SCALP_BRK";
   else if(InpUseScalping)
      strategyInfo = "SCALP";
   else if(InpUseBreakout)
      strategyInfo = "BREAK";
   
   if(InpUseGrid) strategyInfo += "_GRID";
   if(InpUseMartingale) strategyInfo += "_MG";
   
   string comment = StringFormat("EA120_%s_%s_%d", 
                     EnumToString(orderType), 
                     strategyInfo,
                     (int)data.signalStrength);
   
   double price = (orderType == ORDER_TYPE_BUY) ? ask : bid;
   
   // Open position with retry logic
   int maxRetries = 2;
   for(int attempt = 0; attempt < maxRetries; attempt++)
   {
      if(g_trade.PositionOpen(data.name, orderType, lotSize, price, sl, tp, comment))
      {
         // Update grid tracking
         if(orderType == ORDER_TYPE_BUY)
         {
            data.lastGridPriceBuy = ask;
         }
         else
         {
            data.lastGridPriceSell = bid;
         }
         
         Print("Position opened: ", data.name, " ", EnumToString(orderType), 
               " Lot: ", lotSize, " SL: ", sl, " TP: ", tp, " Strategy: ", strategyInfo);
         
         data.totalTrades++;
         return true;
      }
      else
      {
         Print("Position open attempt ", (attempt + 1), " failed: ", g_trade.ResultRetcodeDescription());
         if(attempt < maxRetries - 1)
         {
            Sleep(100); // Brief pause before retry
            ask = SymbolInfoDouble(data.name, SYMBOL_ASK);
            bid = SymbolInfoDouble(data.name, SYMBOL_BID);
            price = (orderType == ORDER_TYPE_BUY) ? ask : bid;
         }
      }
   }
   
   Print("ERROR: Failed to open position on ", data.name, " after ", maxRetries, " attempts");
   return false;
}

//+------------------------------------------------------------------+
//| Manage grid and martingale - Enhanced aggressive implementation  |
//+------------------------------------------------------------------+
void ManageGridMartingale(int index, double ask, double bid)
{
   SymbolData &data = g_symbolData[index];
   
   if(!InpUseGrid && !InpUseMartingale)
      return;
   
   double gridStep = InpGridStepPips * data.pipValue;
   
   // === AGGRESSIVE BUY GRID MANAGEMENT ===
   if(data.totalLotsBuy > 0 && data.martingaleLevelBuy < InpMaxMartingaleLevel)
   {
      // Standard grid step check
      if(data.lastGridPriceBuy > 0 && bid <= data.lastGridPriceBuy - gridStep)
      {
         double newLot = CalculateLotSize(index, ORDER_TYPE_BUY, data.totalLotsBuy);
         
         // Enhanced grid with equity recovery logic
         if(InpMartingaleUseEquityRecovery)
         {
            double currentEquity = AccountInfoDouble(ACCOUNT_EQUITY);
            double buyLossPct = (data.profitBuy < 0) ? 
               MathAbs(data.profitBuy) / (currentEquity) * 100.0 : 0;
            
            if(buyLossPct > 2.0) // 2% equity drawdown on buy positions
            {
               newLot *= 1.3; // Aggressive recovery
            }
         }
         
         if(OpenPosition(index, ORDER_TYPE_BUY, newLot))
         {
            data.martingaleLevelBuy++;
            Print("BUY Grid Level ", data.martingaleLevelBuy, 
                  " | Lot: ", newLot, " | Loss: ", data.profitBuy);
         }
      }
      
      // Additional aggressive grid entries based on ATR and loss
      if(data.profitBuy < 0 && MathAbs(data.profitBuy) > (AccountInfoDouble(ACCOUNT_EQUITY) * 0.01))
      {
         // Add grid level if 1% equity loss on buy side
         if(data.martingaleLevelBuy < InpMaxMartingaleLevel)
         {
            double recoveryLot = CalculateLotSize(index, ORDER_TYPE_BUY, data.totalLotsBuy) * 1.5;
            if(OpenPosition(index, ORDER_TYPE_BUY, recoveryLot))
            {
               data.martingaleLevelBuy++;
               Print("RECOVERY BUY Grid Level ", data.martingaleLevelBuy, 
                     " | Lot: ", recoveryLot, " | Loss: ", data.profitBuy);
            }
         }
      }
   }
   
   // === AGGRESSIVE SELL GRID MANAGEMENT ===
   if(data.totalLotsSell > 0 && data.martingaleLevelSell < InpMaxMartingaleLevel)
   {
      // Standard grid step check
      if(data.lastGridPriceSell > 0 && ask >= data.lastGridPriceSell + gridStep)
      {
         double newLot = CalculateLotSize(index, ORDER_TYPE_SELL, data.totalLotsSell);
         
         // Enhanced grid with equity recovery logic
         if(InpMartingaleUseEquityRecovery)
         {
            double currentEquity = AccountInfoDouble(ACCOUNT_EQUITY);
            double sellLossPct = (data.profitSell < 0) ? 
               MathAbs(data.profitSell) / (currentEquity) * 100.0 : 0;
            
            if(sellLossPct > 2.0) // 2% equity drawdown on sell positions
            {
               newLot *= 1.3; // Aggressive recovery
            }
         }
         
         if(OpenPosition(index, ORDER_TYPE_SELL, newLot))
         {
            data.martingaleLevelSell++;
            Print("SELL Grid Level ", data.martingaleLevelSell, 
                  " | Lot: ", newLot, " | Loss: ", data.profitSell);
         }
      }
      
      // Additional aggressive grid entries based on ATR and loss
      if(data.profitSell < 0 && MathAbs(data.profitSell) > (AccountInfoDouble(ACCOUNT_EQUITY) * 0.01))
      {
         // Add grid level if 1% equity loss on sell side
         if(data.martingaleLevelSell < InpMaxMartingaleLevel)
         {
            double recoveryLot = CalculateLotSize(index, ORDER_TYPE_SELL, data.totalLotsSell) * 1.5;
            if(OpenPosition(index, ORDER_TYPE_SELL, recoveryLot))
            {
               data.martingaleLevelSell++;
               Print("RECOVERY SELL Grid Level ", data.martingaleLevelSell, 
                     " | Lot: ", recoveryLot, " | Loss: ", data.profitSell);
            }
         }
      }
   }
   
   // === AGGRESSIVE GRID TRAILING STOP ===
   if(InpGridTrailingStop && (data.martingaleLevelBuy > 0 || data.martingaleLevelSell > 0))
   {
      ManageGridTrailingStop(index);
   }
   
   data.UpdateGridStatus();
}

//+------------------------------------------------------------------+
//| Manage grid trailing stop                                        |
//+------------------------------------------------------------------+
void ManageGridTrailingStop(int index)
{
   SymbolData &data = g_symbolData[index];
   double currentBid = SymbolInfoDouble(data.name, SYMBOL_BID);
   double currentAsk = SymbolInfoDouble(data.name, SYMBOL_ASK);
   
   // Calculate average prices for grid
   if(data.totalLotsBuy > 0)
   {
      double gridProfit = data.profitBuy;
      if(gridProfit > 0)
      {
         double trailDistance = InpTrailingStepPips * data.pipValue;
         double currentLevel = currentBid - trailDistance;
         
         // Move all buy positions to breakeven + trailing
         for(int i = PositionsTotal() - 1; i >= 0; i--)
         {
            ulong ticket = PositionGetTicket(i);
            if(ticket <= 0) continue;
            
            if(PositionGetString(POSITION_SYMBOL) != data.name) continue;
            if(PositionGetInteger(POSITION_MAGIC) != data.magicNumber) continue;
            if(PositionGetInteger(POSITION_TYPE) != POSITION_TYPE_BUY) continue;
            
            double openPrice = PositionGetDouble(POSITION_PRICE_OPEN);
            double currentSL = PositionGetDouble(POSITION_SL);
            
            if(currentBid > openPrice + trailDistance)
            {
               double newSL = NormalizeDouble(currentBid - trailDistance, data.digits);
               if(newSL > currentSL)
               {
                  g_trade.PositionModify(ticket, newSL, PositionGetDouble(POSITION_TP));
               }
            }
         }
      }
   }
   
   if(data.totalLotsSell > 0)
   {
      double gridProfit = data.profitSell;
      if(gridProfit > 0)
      {
         double trailDistance = InpTrailingStepPips * data.pipValue;
         double currentLevel = currentAsk + trailDistance;
         
         // Move all sell positions to breakeven + trailing
         for(int i = PositionsTotal() - 1; i >= 0; i--)
         {
            ulong ticket = PositionGetTicket(i);
            if(ticket <= 0) continue;
            
            if(PositionGetString(POSITION_SYMBOL) != data.name) continue;
            if(PositionGetInteger(POSITION_MAGIC) != data.magicNumber) continue;
            if(PositionGetInteger(POSITION_TYPE) != POSITION_TYPE_SELL) continue;
            
            double openPrice = PositionGetDouble(POSITION_PRICE_OPEN);
            double currentSL = PositionGetDouble(POSITION_SL);
            
            if(currentAsk < openPrice - trailDistance)
            {
               double newSL = NormalizeDouble(currentAsk + trailDistance, data.digits);
               if(newSL < currentSL || currentSL == 0)
               {
                  g_trade.PositionModify(ticket, newSL, PositionGetDouble(POSITION_TP));
               }
            }
         }
      }
   }
}

//+------------------------------------------------------------------+
//| Close all positions                                              |
//+------------------------------------------------------------------+
void CloseAllPositions(string reason)
{
   Print("Closing all positions. Reason: ", reason);
   
   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      ulong ticket = PositionGetTicket(i);
      if(ticket <= 0)
         continue;
      
      long magic = PositionGetInteger(POSITION_MAGIC);
      if(magic < InpMagicNumberBase || magic >= InpMagicNumberBase + MAX_SYMBOLS_ALLOWED)
         continue;
      
      g_trade.PositionClose(ticket);
   }
}

//+------------------------------------------------------------------+
//| Print final statistics                                           |
//+------------------------------------------------------------------+
void PrintFinalStatistics()
{
   Print("=== ", EA_NAME, " Final Statistics ===");
   
   double finalBalance = AccountInfoDouble(ACCOUNT_BALANCE);
   double profit = finalBalance - g_initialBalance;
   double profitPct = (g_initialBalance > 0) ? (profit / g_initialBalance) * 100.0 : 0;
   
   Print("Initial Balance: ", DoubleToString(g_initialBalance, 2));
   Print("Final Balance: ", DoubleToString(finalBalance, 2));
   Print("Total Profit: ", DoubleToString(profit, 2), " (", DoubleToString(profitPct, 2), "%)");
   
   // Per-symbol stats
   for(int i = 0; i < g_symbolCount; i++)
   {
      SymbolData &data = g_symbolData[i];
      if(data.totalTrades > 0)
      {
         Print(data.name, ": Trades=", data.totalTrades, 
               " Win=", data.winningTrades, 
               " Loss=", data.losingTrades);
      }
   }
}

//+------------------------------------------------------------------+
