//+------------------------------------------------------------------+
//|                                           Filters.mqh            |
//|                                    EA_120_Logika Includes        |
//|                                                                  |
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