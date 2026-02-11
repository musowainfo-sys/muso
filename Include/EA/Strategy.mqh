//+------------------------------------------------------------------+
//|                                         EA_Strategy.mqh         |
//|                                    EA_120_Logika Includes        |
//|                                                                  |
//+------------------------------------------------------------------+

#include "EA_Constants.mqh"
#include "EA_Inputs.mqh"
#include "EA_Structs.mqh"

//+------------------------------------------------------------------+
//| Abstract Strategy Base Class                                     |
//+------------------------------------------------------------------+
class CStrategy
{
protected:
   SymbolData *m_data;
   int         m_index;

public:
                    CStrategy();
   virtual         ~CStrategy();
   
   void            SetSymbolData(SymbolData &data, int index);
   virtual ENUM_SIGNAL_TYPE GenerateSignal(double &emaFast[], double &emaSlow[],
                                         double &rsi[], double &atr[],
                                         double ask, double bid,
                                         double highestHigh, double lowestLow) = 0;
   virtual string  GetName() = 0;
   virtual int     GetPriority() = 0;  // Lower number = higher priority
};

//+------------------------------------------------------------------+
//| Constructor                                                      |
//+------------------------------------------------------------------+
CStrategy::CStrategy()
{
   m_data = NULL;
   m_index = -1;
}

//+------------------------------------------------------------------+
//| Destructor                                                       |
//+------------------------------------------------------------------+
CStrategy::~CStrategy()
{
}

//+------------------------------------------------------------------+
//| Set symbol data                                                  |
//+------------------------------------------------------------------+
void CStrategy::SetSymbolData(SymbolData &data, int index)
{
   m_data = &data;
   m_index = index;
}

//+------------------------------------------------------------------+
//| Scalping Strategy Class                                          |
//+------------------------------------------------------------------+
class CScalping : public CStrategy
{
public:
                    CScalping();
   virtual         ~CScalping();
   
   virtual ENUM_SIGNAL_TYPE GenerateSignal(double &emaFast[], double &emaSlow[],
                                         double &rsi[], double &atr[],
                                         double ask, double bid,
                                         double highestHigh, double lowestLow);
   virtual string  GetName();
   virtual int     GetPriority();
};

//+------------------------------------------------------------------+
//| Constructor                                                      |
//+------------------------------------------------------------------+
CScalping::CScalping()
{
}

//+------------------------------------------------------------------+
//| Destructor                                                       |
//+------------------------------------------------------------------+
CScalping::~CScalping()
{
}

//+------------------------------------------------------------------+
//| Generate signal for scalping                                     |
//+------------------------------------------------------------------+
ENUM_SIGNAL_TYPE CScalping::GenerateSignal(double &emaFast[], double &emaSlow[],
                                         double &rsi[], double &atr[],
                                         double ask, double bid,
                                         double highestHigh, double lowestLow)
{
   if(!InpUseScalping)
      return SIGNAL_NONE;

   bool emaBullish = emaFast[0] > emaSlow[0];
   bool emaBearish = emaFast[0] < emaSlow[0];
   bool emaCrossUp = emaFast[1] <= emaSlow[1] && emaFast[0] > emaSlow[0];
   bool emaCrossDown = emaFast[1] >= emaSlow[1] && emaFast[0] < emaSlow[0];

   double rsiValue = rsi[0];
   int strength = 0;

   // EMA crossover with RSI confirmation (primary scalping signal)
   if(emaCrossUp && rsiValue < InpRSIOversold)
   {
      return SIGNAL_BUY_STRONG;
   }

   if(emaCrossDown && rsiValue > InpRSIOverbought)
   {
      return SIGNAL_SELL_STRONG;
   }

   // Aggressive momentum continuation signals
   if(InpUseRSIMomentum)
   {
      // Bullish momentum: EMA trending up + RSI in bullish zone
      if(emaBullish && rsiValue > 40 && rsiValue < 65)
      {
         return SIGNAL_BUY;
      }

      // Bearish momentum: EMA trending down + RSI in bearish zone
      if(emaBearish && rsiValue < 60 && rsiValue > 35)
      {
         return SIGNAL_SELL;
      }

      // RSI extreme signals (aggressive oversold/overbought)
      if(rsiValue < 20)  // Deep oversold
      {
         return SIGNAL_BUY;
      }
      if(rsiValue > 80)  // Deep overbought
      {
         return SIGNAL_SELL;
      }
   }

   return SIGNAL_NONE;
}

//+------------------------------------------------------------------+
//| Get strategy name                                                |
//+------------------------------------------------------------------+
string CScalping::GetName()
{
   return "Scalping";
}

//+------------------------------------------------------------------+
//| Get strategy priority                                            |
//+------------------------------------------------------------------+
int CScalping::GetPriority()
{
   return 10;  // High priority for scalping
}

//+------------------------------------------------------------------+
//| Breakout Strategy Class                                          |
//+------------------------------------------------------------------+
class CBreakout : public CStrategy
{
public:
                    CBreakout();
   virtual         ~CBreakout();
   
   virtual ENUM_SIGNAL_TYPE GenerateSignal(double &emaFast[], double &emaSlow[],
                                         double &rsi[], double &atr[],
                                         double ask, double bid,
                                         double highestHigh, double lowestLow);
   virtual string  GetName();
   virtual int     GetPriority();
};

//+------------------------------------------------------------------+
//| Constructor                                                      |
//+------------------------------------------------------------------+
CBreakout::CBreakout()
{
}

//+------------------------------------------------------------------+
//| Destructor                                                       |
//+------------------------------------------------------------------+
CBreakout::~CBreakout()
{
}

//+------------------------------------------------------------------+
//| Generate signal for breakout                                     |
//+------------------------------------------------------------------+
ENUM_SIGNAL_TYPE CBreakout::GenerateSignal(double &emaFast[], double &emaSlow[],
                                         double &rsi[], double &atr[],
                                         double ask, double bid,
                                         double highestHigh, double lowestLow)
{
   if(!InpUseBreakout || highestHigh <= 0 || lowestLow <= 0)
      return SIGNAL_NONE;

   SymbolData &data = *m_data;
   double threshold = InpBreakoutThreshold * data.pipValue;
   int strength = 0;

   // Aggressive breakout detection
   if(ask > highestHigh + threshold)
   {
      strength += 3;
      return SIGNAL_BUY_STRONG;
   }

   if(bid < lowestLow - threshold)
   {
      strength += 3;
      return SIGNAL_SELL_STRONG;
   }

   // Additional breakout confirmation: strong close above/below
   MqlRates rates[];
   if(CopyRates(data.name, InpTimeframe, 0, 2, rates) >= 2)
   {
      // Bullish continuation after breakout
      if(ask > highestHigh && rates[0].close > rates[0].open)
      {
         strength += 1;
      }
      // Bearish continuation after breakout
      if(bid < lowestLow && rates[0].close < rates[0].open)
      {
         strength += 1;
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
            strength += 1;
         }
      }
   }

   if(strength >= 3)
      return SIGNAL_BUY_STRONG;
   else if(strength >= 1)
      return SIGNAL_BUY;

   return SIGNAL_NONE;
}

//+------------------------------------------------------------------+
//| Get strategy name                                                |
//+------------------------------------------------------------------+
string CBreakout::GetName()
{
   return "Breakout";
}

//+------------------------------------------------------------------+
//| Get strategy priority                                            |
//+------------------------------------------------------------------+
int CBreakout::GetPriority()
{
   return 20;  // Medium priority
}

//+------------------------------------------------------------------+
//| Composite Strategy Class (Combines multiple strategies)          |
//+------------------------------------------------------------------+
class CCompositeStrategy : public CStrategy
{
private:
   CScalping      *m_scalping;
   CBreakout      *m_breakout;

public:
                    CCompositeStrategy();
   virtual         ~CCompositeStrategy();
   
   virtual ENUM_SIGNAL_TYPE GenerateSignal(double &emaFast[], double &emaSlow[],
                                         double &rsi[], double &atr[],
                                         double ask, double bid,
                                         double highestHigh, double lowestLow);
   virtual string  GetName();
   virtual int     GetPriority();
};

//+------------------------------------------------------------------+
//| Constructor                                                      |
//+------------------------------------------------------------------+
CCompositeStrategy::CCompositeStrategy()
{
   m_scalping = new CScalping();
   m_breakout = new CBreakout();
}

//+------------------------------------------------------------------+
//| Destructor                                                       |
//+------------------------------------------------------------------+
CCompositeStrategy::~CCompositeStrategy()
{
   if(m_scalping) delete m_scalping;
   if(m_breakout) delete m_breakout;
}

//+------------------------------------------------------------------+
//| Generate signal combining multiple strategies                    |
//+------------------------------------------------------------------+
ENUM_SIGNAL_TYPE CCompositeStrategy::GenerateSignal(double &emaFast[], double &emaSlow[],
                                         double &rsi[], double &atr[],
                                         double ask, double bid,
                                         double highestHigh, double lowestLow)
{
   SymbolData &data = *m_data;
   int buyStrength = 0;
   int sellStrength = 0;
   bool buySignal = false;
   bool sellSignal = false;

   // Get signals from individual strategies
   ENUM_SIGNAL_TYPE scalpingSignal = SIGNAL_NONE;
   if(InpUseScalping)
   {
      scalpingSignal = m_scalping->GenerateSignal(emaFast, emaSlow, rsi, atr, ask, bid, highestHigh, lowestLow);
      
      if(scalpingSignal == SIGNAL_BUY || scalpingSignal == SIGNAL_BUY_STRONG)
      {
         buySignal = true;
         buyStrength += (scalpingSignal == SIGNAL_BUY_STRONG) ? 3 : 2;
      }
      else if(scalpingSignal == SIGNAL_SELL || scalpingSignal == SIGNAL_SELL_STRONG)
      {
         sellSignal = true;
         sellStrength += (scalpingSignal == SIGNAL_SELL_STRONG) ? 3 : 2;
      }
   }

   ENUM_SIGNAL_TYPE breakoutSignal = SIGNAL_NONE;
   if(InpUseBreakout && highestHigh > 0 && lowestLow > 0)
   {
      // We need to temporarily set the symbol data for the sub-strategies
      m_breakout->SetSymbolData(data, m_index);
      breakoutSignal = m_breakout->GenerateSignal(emaFast, emaSlow, rsi, atr, ask, bid, highestHigh, lowestLow);
      
      if(breakoutSignal == SIGNAL_BUY || breakoutSignal == SIGNAL_BUY_STRONG)
      {
         buySignal = true;
         buyStrength += (breakoutSignal == SIGNAL_BUY_STRONG) ? 3 : 2;
      }
      else if(breakoutSignal == SIGNAL_SELL || breakoutSignal == SIGNAL_SELL_STRONG)
      {
         sellSignal = true;
         sellStrength += (breakoutSignal == SIGNAL_SELL_STRONG) ? 3 : 2;
      }
   }

   // Combined strategy: both scalping and breakout agree = stronger signal
   bool buySignalCombined = (scalpingSignal == SIGNAL_BUY || scalpingSignal == SIGNAL_BUY_STRONG) && 
                           (breakoutSignal == SIGNAL_BUY || breakoutSignal == SIGNAL_BUY_STRONG);
   bool sellSignalCombined = (scalpingSignal == SIGNAL_SELL || scalpingSignal == SIGNAL_SELL_STRONG) && 
                            (breakoutSignal == SIGNAL_SELL || breakoutSignal == SIGNAL_SELL_STRONG);

   // Boost strength for combined signals (aggressive confirmation)
   if(buySignalCombined)
      buyStrength += 2;
   if(sellSignalCombined)
      sellStrength += 2;

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
//| Get strategy name                                                |
//+------------------------------------------------------------------+
string CCompositeStrategy::GetName()
{
   return "Composite";
}

//+------------------------------------------------------------------+
//| Get strategy priority                                            |
//+------------------------------------------------------------------+
int CCompositeStrategy::GetPriority()
{
   return 5;  // Highest priority for composite strategy
}