//+------------------------------------------------------------------+
//|                                          Signals.mqh             |
//|                                    EA_120_Logika Includes        |
//|                                                                  |
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//| Analyze Market Sentiment                                         |
//+------------------------------------------------------------------+
double AnalyzeMarketSentiment(int index)
{
   if(!InpUseMarketSentiment) return 0;
   
   SymbolData &data = g_symbolData[index];
   
   // Sentiment based on multiple indicators
   double rsi[], emaFast[], emaSlow[], atr[];  // Fixed: Added missing emaSlow array declaration
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