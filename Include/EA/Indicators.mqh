//+------------------------------------------------------------------+
//|                                         EA_Indicators.mqh     |
//|                                    EA_120_Logika Includes        |
//|                                                                  |
//+------------------------------------------------------------------+

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