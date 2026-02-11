//+------------------------------------------------------------------+
//|                                         EA120_Utils.mqh         |
//|                                    EA_120_Logika Includes        |
//|                                                                  |
//+------------------------------------------------------------------+

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

// Check if weekend
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

// Check trading session
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

// Get symbol data by name
SymbolData* GetSymbolData(string symbol)
{
   for(int i = 0; i < g_symbolCount; i++)
   {
      if(g_symbolData[i].name == symbol)
         return &g_symbolData[i];
   }
   return NULL;
}