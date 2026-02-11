//+------------------------------------------------------------------+
//|                                              SimpleCandles.mqh |
//|                                   Copyright 2023, Antonov A.A. |
//|                                             https://antekov.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2023, Antonov A.A."
#property link      "https://antekov.com"
#property version   "1.00"

#include "..\Include\EA\VirtualStrategy.mqh"

//+------------------------------------------------------------------+
//|                                      Simple Candles Strategy   |
//+------------------------------------------------------------------+
class CSimpleCandlesStrategy : public CVirtualStrategy
{
protected:
    //--- Parameters
    int               m_signalSeqLen;      // Jumlah candle searah
    int               m_periodATR;         // Periode ATR (0 = TP/SL dalam points)
    double            m_stopLevel;         // Level Stop Loss
    double            m_takeLevel;         // Level Take Profit
    int               m_maxCountOfOrders;  // Max posisi terbuka
    int               m_maxSpread;         // Spread maksimum yang diizinkan

public:
                     CSimpleCandlesStrategy(void);
                     CSimpleCandlesStrategy(string symbol, 
                                           ENUM_TIMEFRAMES tf,
                                           int signal_seq_len,
                                           int period_atr,
                                           double stop_level,
                                           double take_level,
                                           int max_orders,
                                           int max_spread);
    virtual          ~CSimpleCandlesStrategy(void);

    //--- Virtual methods
    virtual int       SignalForOpen(void);
    virtual double    CalculateStopLoss(void);
    virtual double    CalculateTakeProfit(void);
    virtual bool      SignalForClose(void);
    virtual void      OnTick(void);
    
protected:
    virtual bool      CheckOpenConditions(void);
    virtual bool      CheckCloseConditions(void);
};

//+------------------------------------------------------------------+
//| Constructor                                                      |
//+------------------------------------------------------------------+
CSimpleCandlesStrategy::CSimpleCandlesStrategy(void)
{
    m_signalSeqLen = 6;
    m_periodATR = 0;
    m_stopLevel = 25000;
    m_takeLevel = 3630;
    m_maxCountOfOrders = 9;
    m_maxSpread = 10;
}

//+------------------------------------------------------------------+
//| Constructor with parameters                                      |
//+------------------------------------------------------------------+
CSimpleCandlesStrategy::CSimpleCandlesStrategy(string symbol, 
                                              ENUM_TIMEFRAMES tf,
                                              int signal_seq_len,
                                              int period_atr,
                                              double stop_level,
                                              double take_level,
                                              int max_orders,
                                              int max_spread)
{
    m_symbol = symbol;
    m_period = tf;
    m_signalSeqLen = signal_seq_len;
    m_periodATR = period_atr;
    m_stopLevel = stop_level;
    m_takeLevel = take_level;
    m_maxCountOfOrders = max_orders;
    m_maxSpread = max_spread;
}

//+------------------------------------------------------------------+
//| Destructor                                                       |
//+------------------------------------------------------------------+
CSimpleCandlesStrategy::~CSimpleCandlesStrategy(void)
{
}

//+------------------------------------------------------------------+
//| Check open conditions                                            |
//+------------------------------------------------------------------+
bool CSimpleCandlesStrategy::CheckOpenConditions(void)
{
    if(m_countPositions >= m_maxCountOfOrders)
    {
        return false;
    }
    return true;
}

//+------------------------------------------------------------------+
//| Check close conditions                                           |
//+------------------------------------------------------------------+
bool CSimpleCandlesStrategy::CheckCloseConditions(void)
{
    return false; // For now, no automatic closing conditions
}

//+------------------------------------------------------------------+
//| Signal for opening position                                      |
//+------------------------------------------------------------------+
int CSimpleCandlesStrategy::SignalForOpen(void)
{
    if(!CheckOpenConditions())
        return 0;

    if(ArraySize(m_rates) < m_signalSeqLen + 1)
        return 0;

    int signal = 0;
    
    // Check for buy signal: consecutive bullish candles
    bool isBuySignal = true;
    for(int i = 1; i <= m_signalSeqLen; i++)
    {
        if(m_rates[i].close <= m_rates[i].open) // Not a bullish candle
        {
            isBuySignal = false;
            break;
        }
    }
    
    if(isBuySignal)
        signal = 1;
    
    // Check for sell signal: consecutive bearish candles
    bool isSellSignal = true;
    for(int i = 1; i <= m_signalSeqLen; i++)
    {
        if(m_rates[i].close >= m_rates[i].open) // Not a bearish candle
        {
            isSellSignal = false;
            break;
        }
    }
    
    if(isSellSignal)
        signal = -1;
        
    // Check spread condition
    if(signal != 0) 
    {
        if(m_rates[0].spread > m_maxSpread) 
        {
            PrintFormat(__FUNCTION__ " | IGNORE %s Signal, spread too big (%d > %d)",
                       (signal > 0 ? "BUY" : "SELL"),
                       m_rates[0].spread, m_maxSpread);
            signal = 0;
        }
    }

    return signal;
}

//+------------------------------------------------------------------+
//| Calculate Stop Loss                                              |
//+------------------------------------------------------------------+
double CSimpleCandlesStrategy::CalculateStopLoss(void)
{
    if(m_periodATR > 0)
    {
        // Using ATR-based calculation
        double atr = iATR(m_symbol, m_period, m_periodATR, 0);
        if(m_openType == POSITION_TYPE_BUY)
            return m_openPrice - (atr * m_stopLevel);
        else
            return m_openPrice + (atr * m_stopLevel);
    }
    else
    {
        // Using points-based calculation
        if(m_openType == POSITION_TYPE_BUY)
            return NormalizeDouble(m_openPrice - m_stopLevel * m_point, m_digits);
        else
            return NormalizeDouble(m_openPrice + m_stopLevel * m_point, m_digits);
    }
}

//+------------------------------------------------------------------+
//| Calculate Take Profit                                            |
//+------------------------------------------------------------------+
double CSimpleCandlesStrategy::CalculateTakeProfit(void)
{
    if(m_periodATR > 0)
    {
        // Using ATR-based calculation
        double atr = iATR(m_symbol, m_period, m_periodATR, 0);
        if(m_openType == POSITION_TYPE_BUY)
            return m_openPrice + (atr * m_takeLevel);
        else
            return m_openPrice - (atr * m_takeLevel);
    }
    else
    {
        // Using points-based calculation
        if(m_openType == POSITION_TYPE_BUY)
            return NormalizeDouble(m_openPrice + m_takeLevel * m_point, m_digits);
        else
            return NormalizeDouble(m_openPrice - m_takeLevel * m_point, m_digits);
    }
}

//+------------------------------------------------------------------+
//| Signal for closing position                                      |
//+------------------------------------------------------------------+
bool CSimpleCandlesStrategy::SignalForClose(void)
{
    return CheckCloseConditions();
}

//+------------------------------------------------------------------+
//| Tick processing                                                  |
//+------------------------------------------------------------------+
void CSimpleCandlesStrategy::OnTick(void)
{
    // Process ticks if needed
}
//+------------------------------------------------------------------+