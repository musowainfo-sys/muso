//+------------------------------------------------------------------+
//|                                              EA_120_Logika.mq5   |
//|                        Aggressive Multi-Symbol Multi-Strategy EA |
//|                                                                   |
//+------------------------------------------------------------------+
#property copyright "EA 120"
#property link      ""
#property version   "1.00"
#property strict

#include <Trade\Trade.mqh>

//--- Input parameters
//=== Strategy Configuration ===
input group "=== Multi-Symbol & Timeframe ==="
input bool     TradeAllSymbols = true;          // Trade all available symbols
input string   SingleSymbol = "";               // Single symbol (if TradeAllSymbols=false)
input bool     EnforceM6 = true;                // Enforce M6 timeframe only

input group "=== Risk Management ==="
input double   BaseLotSize = 0.01;              // Base lot size
input double   MaxLot = 10.0;                   // Maximum lot per order
input int      MaxPositionsPerSymbol = 10;      // Max positions per symbol
input double   MaxDrawdownPct = 30.0;           // Max drawdown % (equity vs balance)
input double   StopLossPips = 50;               // Stop Loss in pips
input double   TakeProfitPips = 100;            // Take Profit in pips

input group "=== Scalping Strategy (EMA/RSI) ==="
input bool     UseScalping = true;              // Enable scalping strategy
input int      EMA_Fast = 5;                    // Fast EMA period
input int      EMA_Slow = 20;                   // Slow EMA period
input int      RSI_Period = 14;                 // RSI period
input int      RSI_Oversold = 30;               // RSI oversold level
input int      RSI_Overbought = 70;             // RSI overbought level

input group "=== Breakout Strategy ==="
input bool     UseBreakout = true;              // Enable breakout strategy
input int      BreakoutLookback = 20;           // Breakout lookback bars
input double   BreakoutThreshold = 5.0;         // Breakout threshold in pips

input group "=== Grid & Martingale ==="
input bool     UseGrid = true;                  // Enable grid trading
input double   GridStepPips = 30;               // Grid step in pips
input bool     UseMartingale = true;            // Enable martingale
input double   MartingaleFactor = 1.5;          // Lot multiplier for martingale
input int      MaxMartingaleLevel = 5;          // Max martingale layers

input group "=== Advanced ==="
input int      MagicNumberBase = 120000;        // Magic number base
input int      Slippage = 10;                   // Max slippage in points

//--- Global variables
CTrade trade;
string symbolList[];
int symbolCount = 0;
double initialBalance = 0;
bool drawdownLimitReached = false;

//--- Symbol data structure
struct SymbolData
{
   int      handle_ema_fast;
   int      handle_ema_slow;
   int      handle_rsi;
   int      handle_atr;
   double   lastGridPriceBuy;
   double   lastGridPriceSell;
   int      positionsCount;
   int      martingaleLevel;
};

SymbolData symbolData[];

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
   Print("=== EA_120_Logika Multi-Strategy Initialized ===");
   
   // Check M6 enforcement
   if(EnforceM6 && Period() != PERIOD_M6)
   {
      Alert("EA configured to run on M6 only. Current timeframe: ", EnumToString(Period()));
      Print("WARNING: Current timeframe is ", EnumToString(Period()), " but M6 enforcement is enabled");
   }
   
   // Store initial balance
   initialBalance = AccountInfoDouble(ACCOUNT_BALANCE);
   
   // Setup trade object
   trade.SetExpertMagicNumber(MagicNumberBase);
   trade.SetDeviationInPoints(Slippage);
   trade.SetTypeFilling(ORDER_FILLING_FOK);
   trade.SetAsyncMode(false);
   
   // Build symbol list
   if(!BuildSymbolList())
   {
      Print("ERROR: Failed to build symbol list");
      return(INIT_FAILED);
   }
   
   // Initialize indicators for each symbol
   if(!InitializeSymbolData())
   {
      Print("ERROR: Failed to initialize symbol data");
      return(INIT_FAILED);
   }
   
   Print("Trading ", symbolCount, " symbols with aggressive combined strategies");
   Print("Max Drawdown: ", MaxDrawdownPct, "% | Max Positions/Symbol: ", MaxPositionsPerSymbol);
   Print("Strategies enabled: Scalping=", UseScalping, " Breakout=", UseBreakout, 
         " Grid=", UseGrid, " Martingale=", UseMartingale);
   
   return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
   // Release all indicator handles
   for(int i = 0; i < symbolCount; i++)
   {
      if(symbolData[i].handle_ema_fast != INVALID_HANDLE)
         IndicatorRelease(symbolData[i].handle_ema_fast);
      if(symbolData[i].handle_ema_slow != INVALID_HANDLE)
         IndicatorRelease(symbolData[i].handle_ema_slow);
      if(symbolData[i].handle_rsi != INVALID_HANDLE)
         IndicatorRelease(symbolData[i].handle_rsi);
      if(symbolData[i].handle_atr != INVALID_HANDLE)
         IndicatorRelease(symbolData[i].handle_atr);
   }
   
   Print("EA_120_Logika deinitialized. Reason: ", reason);
}

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{
   // Check drawdown limit
   if(!drawdownLimitReached && !CheckDrawdownLimit())
   {
      Alert("DRAWDOWN LIMIT REACHED! EA stopped trading.");
      drawdownLimitReached = true;
      return;
   }
   
   if(drawdownLimitReached)
      return;
   
   // Process each symbol
   for(int i = 0; i < symbolCount; i++)
   {
      ProcessSymbol(symbolList[i], i);
   }
}

//+------------------------------------------------------------------+
//| Build list of symbols to trade                                  |
//+------------------------------------------------------------------+
bool BuildSymbolList()
{
   ArrayResize(symbolList, 0);
   symbolCount = 0;
   
   if(TradeAllSymbols)
   {
      int total = SymbolsTotal(false);
      
      for(int i = 0; i < total; i++)
      {
         string symbol = SymbolName(i, false);
         
         // Check if symbol is tradeable
         if(IsSymbolTradeable(symbol))
         {
            ArrayResize(symbolList, symbolCount + 1);
            symbolList[symbolCount] = symbol;
            symbolCount++;
         }
      }
      
      Print("Found ", symbolCount, " tradeable symbols");
   }
   else
   {
      // Trade single symbol
      string symbol = (SingleSymbol == "") ? _Symbol : SingleSymbol;
      
      if(!IsSymbolTradeable(symbol))
      {
         Print("ERROR: Symbol ", symbol, " is not tradeable");
         return false;
      }
      
      ArrayResize(symbolList, 1);
      symbolList[0] = symbol;
      symbolCount = 1;
      
      Print("Trading single symbol: ", symbol);
   }
   
   return (symbolCount > 0);
}

//+------------------------------------------------------------------+
//| Check if symbol is tradeable                                    |
//+------------------------------------------------------------------+
bool IsSymbolTradeable(string symbol)
{
   // Select symbol in Market Watch
   if(!SymbolSelect(symbol, true))
   {
      Print("Cannot select symbol: ", symbol);
      return false;
   }
   
   // Check trade mode
   ENUM_SYMBOL_TRADE_MODE tradeMode = (ENUM_SYMBOL_TRADE_MODE)SymbolInfoInteger(symbol, SYMBOL_TRADE_MODE);
   if(tradeMode == SYMBOL_TRADE_MODE_DISABLED)
   {
      return false;
   }
   
   // Check if symbol has sufficient data
   MqlRates rates[];
   int copied = CopyRates(symbol, PERIOD_M6, 0, 50, rates);
   if(copied < 50)
   {
      Print("Insufficient M6 data for ", symbol, " (bars: ", copied, ")");
      return false;
   }
   
   return true;
}

//+------------------------------------------------------------------+
//| Initialize indicators for all symbols                            |
//+------------------------------------------------------------------+
bool InitializeSymbolData()
{
   ArrayResize(symbolData, symbolCount);
   
   for(int i = 0; i < symbolCount; i++)
   {
      string symbol = symbolList[i];
      
      // Initialize indicators on M6
      symbolData[i].handle_ema_fast = iMA(symbol, PERIOD_M6, EMA_Fast, 0, MODE_EMA, PRICE_CLOSE);
      symbolData[i].handle_ema_slow = iMA(symbol, PERIOD_M6, EMA_Slow, 0, MODE_EMA, PRICE_CLOSE);
      symbolData[i].handle_rsi = iRSI(symbol, PERIOD_M6, RSI_Period, PRICE_CLOSE);
      symbolData[i].handle_atr = iATR(symbol, PERIOD_M6, 14);
      
      if(symbolData[i].handle_ema_fast == INVALID_HANDLE ||
         symbolData[i].handle_ema_slow == INVALID_HANDLE ||
         symbolData[i].handle_rsi == INVALID_HANDLE ||
         symbolData[i].handle_atr == INVALID_HANDLE)
      {
         Print("ERROR: Failed to create indicators for ", symbol);
         return false;
      }
      
      // Initialize grid tracking
      symbolData[i].lastGridPriceBuy = 0;
      symbolData[i].lastGridPriceSell = 0;
      symbolData[i].positionsCount = 0;
      symbolData[i].martingaleLevel = 0;
   }
   
   return true;
}

//+------------------------------------------------------------------+
//| Check drawdown limit                                            |
//+------------------------------------------------------------------+
bool CheckDrawdownLimit()
{
   double balance = AccountInfoDouble(ACCOUNT_BALANCE);
   double equity = AccountInfoDouble(ACCOUNT_EQUITY);
   
   if(balance <= 0)
      return true;
   
   double drawdownPct = ((balance - equity) / balance) * 100.0;
   
   if(drawdownPct >= MaxDrawdownPct)
   {
      Print("DRAWDOWN LIMIT REACHED! Drawdown: ", DoubleToString(drawdownPct, 2), 
            "% | Limit: ", MaxDrawdownPct, "%");
      return false;
   }
   
   return true;
}

//+------------------------------------------------------------------+
//| Process individual symbol                                        |
//+------------------------------------------------------------------+
void ProcessSymbol(string symbol, int index)
{
   // Count current positions for this symbol
   int posCount = CountPositions(symbol);
   symbolData[index].positionsCount = posCount;
   
   // Get current prices
   double ask = SymbolInfoDouble(symbol, SYMBOL_ASK);
   double bid = SymbolInfoDouble(symbol, SYMBOL_BID);
   
   if(ask <= 0 || bid <= 0)
      return;
   
   // Calculate indicators
   double emaFast[], emaSlow[], rsi[], atr[];
   
   if(CopyBuffer(symbolData[index].handle_ema_fast, 0, 0, 3, emaFast) < 3 ||
      CopyBuffer(symbolData[index].handle_ema_slow, 0, 0, 3, emaSlow) < 3 ||
      CopyBuffer(symbolData[index].handle_rsi, 0, 0, 3, rsi) < 3 ||
      CopyBuffer(symbolData[index].handle_atr, 0, 0, 3, atr) < 3)
   {
      return; // Insufficient data
   }
   
   // Get breakout levels
   double highestHigh = 0, lowestLow = 0;
   if(UseBreakout)
   {
      GetBreakoutLevels(symbol, highestHigh, lowestLow);
   }
   
   // Generate signals
   bool buySignal = false;
   bool sellSignal = false;
   
   GenerateSignals(symbol, emaFast, emaSlow, rsi, atr, ask, bid, 
                   highestHigh, lowestLow, buySignal, sellSignal);
   
   // Open new positions if no positions exist
   if(posCount == 0)
   {
      if(buySignal)
      {
         OpenPosition(symbol, ORDER_TYPE_BUY, BaseLotSize, index);
      }
      else if(sellSignal)
      {
         OpenPosition(symbol, ORDER_TYPE_SELL, BaseLotSize, index);
      }
   }
   // Grid/Martingale logic for existing positions
   else if(posCount < MaxPositionsPerSymbol && (UseGrid || UseMartingale))
   {
      ManageGridMartingale(symbol, index, ask, bid);
   }
}

//+------------------------------------------------------------------+
//| Generate trading signals                                         |
//+------------------------------------------------------------------+
void GenerateSignals(string symbol, double &emaFast[], double &emaSlow[], 
                    double &rsi[], double &atr[], double ask, double bid,
                    double highestHigh, double lowestLow,
                    bool &buySignal, bool &sellSignal)
{
   buySignal = false;
   sellSignal = false;
   
   // Scalping strategy: EMA crossover + RSI
   bool scalpBuy = false;
   bool scalpSell = false;
   
   if(UseScalping)
   {
      // Buy: Fast EMA crosses above Slow EMA and RSI < oversold
      if(emaFast[0] > emaSlow[0] && emaFast[1] <= emaSlow[1] && rsi[0] < RSI_Oversold)
      {
         scalpBuy = true;
      }
      
      // Sell: Fast EMA crosses below Slow EMA and RSI > overbought
      if(emaFast[0] < emaSlow[0] && emaFast[1] >= emaSlow[1] && rsi[0] > RSI_Overbought)
      {
         scalpSell = true;
      }
      
      // Additional aggressive scalping: momentum continuation
      if(emaFast[0] > emaSlow[0] && rsi[0] > 50 && rsi[0] < RSI_Overbought)
      {
         scalpBuy = true;
      }
      
      if(emaFast[0] < emaSlow[0] && rsi[0] < 50 && rsi[0] > RSI_Oversold)
      {
         scalpSell = true;
      }
   }
   
   // Breakout strategy
   bool breakoutBuy = false;
   bool breakoutSell = false;
   
   if(UseBreakout && highestHigh > 0 && lowestLow > 0)
   {
      double point = SymbolInfoDouble(symbol, SYMBOL_POINT);
      double digits = (int)SymbolInfoInteger(symbol, SYMBOL_DIGITS);
      double pipValue = (digits == 5 || digits == 3) ? point * 10 : point;
      double threshold = BreakoutThreshold * pipValue;
      
      // Buy breakout: price breaks above highest high
      if(ask > highestHigh + threshold)
      {
         breakoutBuy = true;
      }
      
      // Sell breakout: price breaks below lowest low
      if(bid < lowestLow - threshold)
      {
         breakoutSell = true;
      }
   }
   
   // Combine signals (OR logic for aggressive entry)
   buySignal = scalpBuy || breakoutBuy;
   sellSignal = scalpSell || breakoutSell;
}

//+------------------------------------------------------------------+
//| Get breakout levels                                             |
//+------------------------------------------------------------------+
void GetBreakoutLevels(string symbol, double &highestHigh, double &lowestLow)
{
   MqlRates rates[];
   int copied = CopyRates(symbol, PERIOD_M6, 1, BreakoutLookback, rates);
   
   if(copied < BreakoutLookback)
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
//| Open position                                                    |
//+------------------------------------------------------------------+
void OpenPosition(string symbol, ENUM_ORDER_TYPE orderType, double lotSize, int symbolIndex)
{
   // Normalize lot size
   double lot = NormalizeLot(symbol, lotSize);
   
   if(lot <= 0 || lot > MaxLot)
      return;
   
   // Calculate SL/TP
   double point = SymbolInfoDouble(symbol, SYMBOL_POINT);
   int digits = (int)SymbolInfoInteger(symbol, SYMBOL_DIGITS);
   double pipValue = (digits == 5 || digits == 3) ? point * 10 : point;
   
   double sl = 0, tp = 0;
   double ask = SymbolInfoDouble(symbol, SYMBOL_ASK);
   double bid = SymbolInfoDouble(symbol, SYMBOL_BID);
   
   if(orderType == ORDER_TYPE_BUY)
   {
      sl = NormalizeDouble(ask - StopLossPips * pipValue, digits);
      tp = NormalizeDouble(ask + TakeProfitPips * pipValue, digits);
      
      // Track grid price
      symbolData[symbolIndex].lastGridPriceBuy = ask;
   }
   else // SELL
   {
      sl = NormalizeDouble(bid + StopLossPips * pipValue, digits);
      tp = NormalizeDouble(bid - TakeProfitPips * pipValue, digits);
      
      // Track grid price
      symbolData[symbolIndex].lastGridPriceSell = bid;
   }
   
   // Open position
   string comment = "EA120_" + EnumToString(orderType);
   
   if(trade.PositionOpen(symbol, orderType, lot, 
                         orderType == ORDER_TYPE_BUY ? ask : bid,
                         sl, tp, comment))
   {
      Print("Position opened: ", symbol, " ", EnumToString(orderType), 
            " Lot: ", lot, " SL: ", sl, " TP: ", tp);
      
      // Reset martingale level on new position
      symbolData[symbolIndex].martingaleLevel = 0;
   }
   else
   {
      Print("ERROR opening position on ", symbol, ": ", trade.ResultRetcodeDescription());
   }
}

//+------------------------------------------------------------------+
//| Manage grid and martingale                                      |
//+------------------------------------------------------------------+
void ManageGridMartingale(string symbol, int symbolIndex, double ask, double bid)
{
   double point = SymbolInfoDouble(symbol, SYMBOL_POINT);
   int digits = (int)SymbolInfoInteger(symbol, SYMBOL_DIGITS);
   double pipValue = (digits == 5 || digits == 3) ? point * 10 : point;
   double gridStep = GridStepPips * pipValue;
   
   // Get existing positions
   double totalBuyLots = 0, totalSellLots = 0;
   double avgBuyPrice = 0, avgSellPrice = 0;
   int buyCount = 0, sellCount = 0;
   
   GetPositionInfo(symbol, totalBuyLots, totalSellLots, avgBuyPrice, avgSellPrice, buyCount, sellCount);
   
   // Check if we need to add grid/martingale positions
   bool addBuyGrid = false;
   bool addSellGrid = false;
   
   if(buyCount > 0 && UseGrid)
   {
      // Price moved down (against buy position) by grid step
      if(symbolData[symbolIndex].lastGridPriceBuy > 0 && 
         bid <= symbolData[symbolIndex].lastGridPriceBuy - gridStep)
      {
         addBuyGrid = true;
      }
   }
   
   if(sellCount > 0 && UseGrid)
   {
      // Price moved up (against sell position) by grid step
      if(symbolData[symbolIndex].lastGridPriceSell > 0 && 
         ask >= symbolData[symbolIndex].lastGridPriceSell + gridStep)
      {
         addSellGrid = true;
      }
   }
   
   // Add martingale position
   if(addBuyGrid && symbolData[symbolIndex].martingaleLevel < MaxMartingaleLevel)
   {
      double newLot = BaseLotSize;
      
      if(UseMartingale)
      {
         newLot = totalBuyLots * MartingaleFactor;
      }
      
      OpenPosition(symbol, ORDER_TYPE_BUY, newLot, symbolIndex);
      symbolData[symbolIndex].martingaleLevel++;
   }
   
   if(addSellGrid && symbolData[symbolIndex].martingaleLevel < MaxMartingaleLevel)
   {
      double newLot = BaseLotSize;
      
      if(UseMartingale)
      {
         newLot = totalSellLots * MartingaleFactor;
      }
      
      OpenPosition(symbol, ORDER_TYPE_SELL, newLot, symbolIndex);
      symbolData[symbolIndex].martingaleLevel++;
   }
}

//+------------------------------------------------------------------+
//| Get position information for symbol                             |
//+------------------------------------------------------------------+
void GetPositionInfo(string symbol, double &totalBuyLots, double &totalSellLots,
                    double &avgBuyPrice, double &avgSellPrice, 
                    int &buyCount, int &sellCount)
{
   totalBuyLots = 0;
   totalSellLots = 0;
   double buyPriceSum = 0;
   double sellPriceSum = 0;
   buyCount = 0;
   sellCount = 0;
   
   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      ulong ticket = PositionGetTicket(i);
      if(ticket <= 0)
         continue;
      
      if(PositionGetString(POSITION_SYMBOL) != symbol)
         continue;
      
      long magic = PositionGetInteger(POSITION_MAGIC);
      if(magic != MagicNumberBase)
         continue;
      
      ENUM_POSITION_TYPE posType = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
      double lots = PositionGetDouble(POSITION_VOLUME);
      double openPrice = PositionGetDouble(POSITION_PRICE_OPEN);
      
      if(posType == POSITION_TYPE_BUY)
      {
         totalBuyLots += lots;
         buyPriceSum += openPrice * lots;
         buyCount++;
      }
      else if(posType == POSITION_TYPE_SELL)
      {
         totalSellLots += lots;
         sellPriceSum += openPrice * lots;
         sellCount++;
      }
   }
   
   avgBuyPrice = (totalBuyLots > 0) ? buyPriceSum / totalBuyLots : 0;
   avgSellPrice = (totalSellLots > 0) ? sellPriceSum / totalSellLots : 0;
}

//+------------------------------------------------------------------+
//| Count positions for symbol                                      |
//+------------------------------------------------------------------+
int CountPositions(string symbol)
{
   int count = 0;
   
   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      ulong ticket = PositionGetTicket(i);
      if(ticket <= 0)
         continue;
      
      if(PositionGetString(POSITION_SYMBOL) == symbol &&
         PositionGetInteger(POSITION_MAGIC) == MagicNumberBase)
      {
         count++;
      }
   }
   
   return count;
}

//+------------------------------------------------------------------+
//| Normalize lot size to symbol requirements                       |
//+------------------------------------------------------------------+
double NormalizeLot(string symbol, double lot)
{
   double minLot = SymbolInfoDouble(symbol, SYMBOL_VOLUME_MIN);
   double maxLot = SymbolInfoDouble(symbol, SYMBOL_VOLUME_MAX);
   double stepLot = SymbolInfoDouble(symbol, SYMBOL_VOLUME_STEP);
   
   if(lot < minLot)
      lot = minLot;
   if(lot > maxLot)
      lot = maxLot;
   
   lot = MathFloor(lot / stepLot) * stepLot;
   
   return NormalizeDouble(lot, 2);
}
//+------------------------------------------------------------------+
