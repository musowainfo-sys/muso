//+------------------------------------------------------------------+
//|                                              EA_120_Logika.mq5   |
//|                        Enhanced Multi-Symbol Multi-Strategy EA   |
//|                                            Version 2.0           |
//+------------------------------------------------------------------+
#property copyright EA_NAME
#property link      EA_LINK
#property version   EA_VERSION
#property strict

#include <Trade\Trade.mqh>
#include <Arrays\ArrayLong.mqh>
#include "EA_120_Logika\Include\Common\Constants.mqh"

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
input double   InpBaseLotSize = 0.01;            // Base lot size
input double   InpMaxLot = 10.0;                 // Maximum lot per order
input int      InpMaxPositionsPerSymbol = 10;    // Max positions per symbol
input int      InpTotalMaxPositions = 100;       // Max total positions (all symbols)
input double   InpMaxDrawdownPct = 30.0;         // Max drawdown % (equity vs balance)
input double   InpDailyLossLimitPct = 10.0;      // Daily loss limit %
input double   InpMaxSpreadPips = 5.0;           // Max spread allowed (pips)
input double   InpMinAccountBalance = 100.0;     // Minimum account balance to trade

input group "=== Stop Loss & Take Profit ==="
input bool     InpUseFixedSLTP = true;           // Use fixed SL/TP (pips)
input double   InpStopLossPips = 50;             // Stop Loss in pips
input double   InpTakeProfitPips = 100;          // Take Profit in pips
input bool     InpUseTrailingStop = false;       // Enable trailing stop
input double   InpTrailingStartPips = 50;        // Trailing start (pips)
input double   InpTrailingStepPips = 20;         // Trailing step (pips)
input bool     InpUseBreakEven = false;          // Enable breakeven
input double   InpBreakEvenPips = 30;            // Breakeven trigger (pips)

input group "=== Money Management ==="
input bool     InpUseRiskPercent = false;        // Use risk % per trade
input double   InpRiskPercent = 1.0;             // Risk % per trade
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
input bool     InpUseGrid = true;                // Enable grid trading
input double   InpGridStepPips = 30;             // Grid step in pips
input int      InpMaxGridLevels = 10;            // Max grid levels
input bool     InpGridTrailingStop = false;      // Use trailing stop on grid

input group "=== Martingale System ==="
input bool     InpUseMartingale = true;          // Enable martingale
input double   InpMartingaleFactor = 1.5;        // Lot multiplier
input int      InpMaxMartingaleLevel = 5;        // Max martingale levels
input bool     InpResetMartingaleOnProfit = true; // Reset after profitable close
input bool     InpMartingaleUseEquityRecovery = false; // Use equity-based recovery

//=== Trading Hours & Filters ===
input group "=== Trading Sessions ==="
input bool     InpFilterBySession = false;       // Filter by trading session
input ENUM_TRADING_SESSION InpTradeSession = SESSION_ALL; // Trading session
input bool     InpTradeAsian = true;             // Trade Asian session
input bool     InpTradeLondon = true;            // Trade London session
input bool     InpTradeNewYork = true;           // Trade New York session

input group "=== Time Filters ==="
input bool     InpAvoidNewsHours = false;        // Avoid high-impact news hours
input int      InpNewsWindowMinutes = 30;        // News window (minutes before/after)
input bool     InpAvoidWeekend = true;           // Avoid trading on weekends
input bool     InpFridayClosePositions = false;  // Close positions Friday evening
input int      InpFridayCloseHour = 20;          // Friday close hour (server time)

input group "=== Signal Filters ==="
input bool     InpUseTrendFilter = false;        // Filter by higher timeframe trend
input ENUM_TIMEFRAMES InpTrendTimeframe = PERIOD_H1; // Trend filter timeframe
input int      InpMinSignalStrength = 1;         // Minimum signal strength (1-3)

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
   
   if(InpUseADXFilter)
   {
      g_symbolData[index].handleAdx = iADX(symbol, tf, InpADXPeriod);
   }
   
   // Validate handles
   if(g_symbolData[index].handleEmaFast == INVALID_HANDLE ||
      g_symbolData[index].handleEmaSlow == INVALID_HANDLE ||
      g_symbolData[index].handleRsi == INVALID_HANDLE ||
      g_symbolData[index].handleAtr == INVALID_HANDLE)
   {
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
   
   // Check spread
   if(!CheckSpread(symbol))
      return;
   
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
//| Generate trading signals                                         |
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
   
   // Scalping signals
   if(InpUseScalping)
   {
      // EMA crossover with RSI confirmation
      bool emaBullish = emaFast[0] > emaSlow[0];
      bool emaBearish = emaFast[0] < emaSlow[0];
      bool emaCrossUp = emaFast[1] <= emaSlow[1] && emaFast[0] > emaSlow[0];
      bool emaCrossDown = emaFast[1] >= emaSlow[1] && emaFast[0] < emaSlow[0];
      
      double rsiValue = rsi[0];
      
      // Strong signals
      if(emaCrossUp && rsiValue < InpRSIOversold)
      {
         buyScalp = true;
         buyStrength += 2;
      }
      
      if(emaCrossDown && rsiValue > InpRSIOverbought)
      {
         sellScalp = true;
         sellStrength += 2;
      }
      
      // Momentum continuation
      if(InpUseRSIMomentum)
      {
         if(emaBullish && rsiValue > 50 && rsiValue < InpRSIOverbought)
         {
            buyScalp = true;
            buyStrength += 1;
         }
         
         if(emaBearish && rsiValue < 50 && rsiValue > InpRSIOversold)
         {
            sellScalp = true;
            sellStrength += 1;
         }
      }
      
      // ADX filter
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
         }
      }
   }
   
   // Breakout signals
   if(InpUseBreakout && highestHigh > 0 && lowestLow > 0)
   {
      double threshold = InpBreakoutThreshold * data.pipValue;
      
      if(ask > highestHigh + threshold)
      {
         buyBreak = true;
         buyStrength += 2;
      }
      
      if(bid < lowestLow - threshold)
      {
         sellBreak = true;
         sellStrength += 2;
      }
   }
   
   // Combine signals
   bool buySignal = buyScalp || buyBreak;
   bool sellSignal = sellScalp || sellBreak;
   
   // Check minimum signal strength
   if(buySignal && buyStrength < InpMinSignalStrength)
      buySignal = false;
   if(sellSignal && sellStrength < InpMinSignalStrength)
      sellSignal = false;
   
   // Trend filter
   if(InpUseTrendFilter)
   {
      ENUM_TREND_DIRECTION trend = GetHigherTimeframeTrend(data.name);
      if(trend == TREND_DOWN && buySignal)
         buySignal = false;
      if(trend == TREND_UP && sellSignal)
         sellSignal = false;
   }
   
   // Store signal
   if(buySignal && !sellSignal)
   {
      data.lastSignal = (buyStrength >= 3) ? SIGNAL_BUY_STRONG : SIGNAL_BUY;
      data.lastSignalTime = TimeCurrent();
      data.signalStrength = buyStrength;
      return data.lastSignal;
   }
   else if(sellSignal && !buySignal)
   {
      data.lastSignal = (sellStrength >= 3) ? SIGNAL_SELL_STRONG : SIGNAL_SELL;
      data.lastSignalTime = TimeCurrent();
      data.signalStrength = sellStrength;
      return data.lastSignal;
   }
   
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
//| Open position                                                    |
//+------------------------------------------------------------------+
bool OpenPosition(int index, ENUM_ORDER_TYPE orderType, double lotSize)
{
   SymbolData &data = g_symbolData[index];
   
   if(lotSize <= 0)
      return false;
   
   double sl = 0, tp = 0;
   double ask = SymbolInfoDouble(data.name, SYMBOL_ASK);
   double bid = SymbolInfoDouble(data.name, SYMBOL_BID);
   
   // Calculate SL/TP
   if(InpUseFixedSLTP)
   {
      double slDistance = InpStopLossPips * data.pipValue;
      double tpDistance = InpTakeProfitPips * data.pipValue;
      
      if(orderType == ORDER_TYPE_BUY)
      {
         sl = NormalizeDouble(ask - slDistance, data.digits);
         tp = NormalizeDouble(ask + tpDistance, data.digits);
      }
      else
      {
         sl = NormalizeDouble(bid + slDistance, data.digits);
         tp = NormalizeDouble(bid - tpDistance, data.digits);
      }
   }
   
   // Set magic number
   g_trade.SetExpertMagicNumber((int)data.magicNumber);
   
   // Open position
   string comment = StringFormat("EA120_%s_S%d", 
                     EnumToString(orderType), 
                     (int)data.signalStrength);
   
   double price = (orderType == ORDER_TYPE_BUY) ? ask : bid;
   
   if(!g_trade.PositionOpen(data.name, orderType, lotSize, price, sl, tp, comment))
   {
      Print("ERROR opening position on ", data.name, ": ", g_trade.ResultRetcodeDescription());
      return false;
   }
   
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
         " Lot: ", lotSize, " SL: ", sl, " TP: ", tp);
   
   data.totalTrades++;
   return true;
}

//+------------------------------------------------------------------+
//| Manage grid and martingale                                       |
//+------------------------------------------------------------------+
void ManageGridMartingale(int index, double ask, double bid)
{
   SymbolData &data = g_symbolData[index];
   
   if(!InpUseGrid && !InpUseMartingale)
      return;
   
   double gridStep = InpGridStepPips * data.pipValue;
   
   // Check buy grid
   if(data.totalLotsBuy > 0 && data.martingaleLevelBuy < InpMaxMartingaleLevel)
   {
      if(data.lastGridPriceBuy > 0 && bid <= data.lastGridPriceBuy - gridStep)
      {
         double newLot = CalculateLotSize(index, ORDER_TYPE_BUY, data.totalLotsBuy);
         
         if(OpenPosition(index, ORDER_TYPE_BUY, newLot))
         {
            data.martingaleLevelBuy++;
         }
      }
   }
   
   // Check sell grid
   if(data.totalLotsSell > 0 && data.martingaleLevelSell < InpMaxMartingaleLevel)
   {
      if(data.lastGridPriceSell > 0 && ask >= data.lastGridPriceSell + gridStep)
      {
         double newLot = CalculateLotSize(index, ORDER_TYPE_SELL, data.totalLotsSell);
         
         if(OpenPosition(index, ORDER_TYPE_SELL, newLot))
         {
            data.martingaleLevelSell++;
         }
      }
   }
   
   data.UpdateGridStatus();
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
