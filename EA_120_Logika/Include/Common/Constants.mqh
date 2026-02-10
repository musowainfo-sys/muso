//+------------------------------------------------------------------+
//|                                      EA 120 Common Constants     |
//|                                            Enhanced Version 2.01  |
//+------------------------------------------------------------------+
#ifndef __EA_120_CONSTANTS__
#define __EA_120_CONSTANTS__

//+------------------------------------------------------------------+
//| Application Constants                                            |
//+------------------------------------------------------------------+
#define EA_NAME         "EA_120_Logika"
#define EA_VERSION      "2.00"
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
//+------------------------------------------------------------------+

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
//+------------------------------------------------------------------+

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
//+------------------------------------------------------------------+

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
#endif // __EA_120_CONSTANTS__
