//+------------------------------------------------------------------+
//|                                         EA120_Trading.mqh       |
//|                                    EA_120_Logika Includes        |
//|                                                                  |
//+------------------------------------------------------------------+

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
   
   if(InpMaxDrawdownPct < MAX_DRAWDOWN_MINIMUM || InpMaxDrawdownPct > MAX_DRADWON_MAXIMUM)
   {
      Print("ERROR: MaxDrawdownPct must be between ", MAX_DRAWDOWN_MINIMUM, " and ", MAX_DRADWON_MAXIMUM);
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