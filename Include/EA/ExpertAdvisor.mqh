//+------------------------------------------------------------------+
//|                                        ExpertAdvisor.mqh         |
//|                                   Copyright 2023, Antonov A.A.   |
//|                                             https://antekov.com  |
//+------------------------------------------------------------------+
#property copyright "Copyright 2023, Antonov A.A."
#property link      "https://antekov.com"
#property version   "1.00"

#include "Constants.mqh"
#include "Inputs.mqh"
#include "Indicators.mqh"
#include "Signals.mqh"
#include "Strategy.mqh"
#include "Trading.mqh"
#include "Utils.mqh"

//+------------------------------------------------------------------+
//| Expert Advisor Base Class                                        |
//+------------------------------------------------------------------+
class CExpertAdvisor
{
protected:
    //--- Basic properties
    string              m_name;                // Expert advisor name
    string              m_symbol;              // Trading symbol
    ENUM_TIMEFRAMES     m_period;              // Timeframe
    int                 m_digits;              // Number of decimal digits
    double              m_point;               // Point size
    
    //--- Trading information
    int                 m_magicNumber;         // Magic number for orders
    double              m_lotSize;             // Lot size
    int                 m_slippage;            // Maximum slippage
    double              m_stopLoss;            // Stop loss in points
    double              m_takeProfit;          // Take profit in points
    
    //--- Market data
    MqlRates            m_rates[];             // Price rates array
    MqlTick             m_tick;                // Current tick
    
    //--- Strategy pointer
    CVirtualStrategy*   m_strategy;            // Pointer to strategy

public:
                     CExpertAdvisor(void);
    virtual          ~CExpertAdvisor(void);

    //--- Initialization
    virtual bool      OnInit(void);
    virtual void      OnDeinit(const int reason);
    
    //--- Main event handlers
    virtual void      OnTick(void);
    virtual void      OnTimer(void);
    virtual void      OnTrade(void);
    
    //--- Trading functions
    virtual bool      ProcessTrades(void);
    virtual bool      OpenPosition(int signal);
    virtual bool      ClosePosition(void);
    
    //--- Utility functions
    virtual bool      RefreshData(void);
    virtual double    NormalizeLotSize(double lot);
};

//+------------------------------------------------------------------+
//| Constructor                                                      |
//+------------------------------------------------------------------+
CExpertAdvisor::CExpertAdvisor(void)
{
    m_name = __FUNCTION__;
    m_symbol = _Symbol;
    m_period = _Period;
    m_digits = (int)_Digits;
    m_point = _Point;
    
    m_magicNumber = 12345;
    m_lotSize = 0.1;
    m_slippage = 10;
    m_stopLoss = 100;
    m_takeProfit = 200;
    
    m_strategy = NULL;
    
    ArraySetAsSeries(m_rates, true);
}

//+------------------------------------------------------------------+
//| Destructor                                                       |
//+------------------------------------------------------------------+
CExpertAdvisor::~CExpertAdvisor(void)
{
    if(m_strategy != NULL)
    {
        delete m_strategy;
        m_strategy = NULL;
    }
}

//+------------------------------------------------------------------+
//| Initialization function                                          |
//+------------------------------------------------------------------+
bool CExpertAdvisor::OnInit(void)
{
    // Get symbol properties
    m_digits = (int)SymbolInfoInteger(m_symbol, SYMBOL_DIGITS);
    m_point = SymbolInfoDouble(m_symbol, SYMBOL_POINT_SIZE);
    
    // Initialize strategy
    if(m_strategy != NULL)
    {
        if(!m_strategy->InitStrategy(m_symbol, m_period))
        {
            Print("Error initializing strategy");
            return false;
        }
    }
    
    Print("Expert Advisor initialized for ", m_symbol, " on ", EnumToString(m_period));
    return true;
}

//+------------------------------------------------------------------+
//| Deinitialization function                                        |
//+------------------------------------------------------------------+
void CExpertAdvisor::OnDeinit(const int reason)
{
    Print("Expert Advisor deinitialized. Reason: ", reason);
}

//+------------------------------------------------------------------+
//| Tick processing function                                         |
//+------------------------------------------------------------------+
void CExpertAdvisor::OnTick(void)
{
    // Refresh market data
    if(!RefreshData())
        return;
    
    // Process trading logic if strategy is available
    if(m_strategy != NULL)
    {
        // Update strategy with current data
        m_strategy->m_rates = m_rates;
        m_strategy->m_tick = m_tick;
        m_strategy->m_currentPrice = m_tick.ask;
        
        // Process trades based on strategy signals
        ProcessTrades();
    }
}

//+------------------------------------------------------------------+
//| Timer event handler                                              |
//+------------------------------------------------------------------+
void CExpertAdvisor::OnTimer(void)
{
    // Empty implementation - to be overridden if needed
}

//+------------------------------------------------------------------+
//| Trade event handler                                              |
//+------------------------------------------------------------------+
void CExpertAdvisor::OnTrade(void)
{
    // Empty implementation - to be overridden if needed
}

//+------------------------------------------------------------------+
//| Process trading decisions                                        |
//+------------------------------------------------------------------+
bool CExpertAdvisor::ProcessTrades(void)
{
    if(m_strategy == NULL)
        return false;
    
    // Get signal from strategy
    int signal = m_strategy->SignalForOpen();
    
    // Process the signal
    if(signal != 0)
    {
        return OpenPosition(signal);
    }
    
    // Check for close signal
    if(m_strategy->SignalForClose())
    {
        return ClosePosition();
    }
    
    return true;
}

//+------------------------------------------------------------------+
//| Open position based on signal                                    |
//+------------------------------------------------------------------+
bool CExpertAdvisor::OpenPosition(int signal)
{
    // Implementation would depend on specific trading logic
    // This is a simplified version
    
    // Determine order type
    ENUM_ORDER_TYPE orderType = (signal > 0) ? ORDER_TYPE_BUY : ORDER_TYPE_SELL;
    
    // Get prices
    double price = (orderType == ORDER_TYPE_BUY) ? m_tick.ask : m_tick.bid;
    double sl = 0, tp = 0;
    
    // Calculate stops if needed
    if(m_strategy != NULL)
    {
        sl = m_strategy->CalculateStopLoss();
        tp = m_strategy->CalculateTakeProfit();
    }
    
    // Prepare request
    MqlTradeRequest request = {};
    MqlTradeResult result = {};
    
    request.action = TRADE_ACTION_DEAL;
    request.symbol = m_symbol;
    request.volume = m_lotSize;
    request.type = orderType;
    request.price = price;
    request.sl = sl;
    request.tp = tp;
    request.deviation = m_slippage;
    request.magic = m_magicNumber;
    request.comment = "EA Trade";
    
    // Send order
    if(OrderSend(request, result))
    {
        if(result.retcode == TRADE_RETCODE_DONE)
        {
            Print("Position opened: ", EnumToString(orderType), " at ", price);
            return true;
        }
        else
        {
            Print("Order failed: ", result.retcode, " - ", result.comment);
            return false;
        }
    }
    else
    {
        Print("OrderSend failed: ", GetLastError());
        return false;
    }
}

//+------------------------------------------------------------------+
//| Close current position                                           |
//+------------------------------------------------------------------+
bool CExpertAdvisor::ClosePosition(void)
{
    // Implementation would close existing positions
    // This is a simplified version
    
    // For now, just return true
    return true;
}

//+------------------------------------------------------------------+
//| Refresh market data                                              |
//+------------------------------------------------------------------+
bool CExpertAdvisor::RefreshData(void)
{
    // Copy current rates
    if(CopyRates(m_symbol, m_period, 0, 100, m_rates) <= 0)
    {
        Print("Error copying rates for ", m_symbol);
        return false;
    }
    
    // Get current tick
    if(!SymbolInfoTick(m_symbol, m_tick))
    {
        Print("Error getting tick for ", m_symbol);
        return false;
    }
    
    return true;
}

//+------------------------------------------------------------------+
//| Normalize lot size                                               |
//+------------------------------------------------------------------+
double CExpertAdvisor::NormalizeLotSize(double lot)
{
    double minLot = SymbolInfoDouble(m_symbol, SYMBOL_VOLUME_MIN);
    double maxLot = SymbolInfoDouble(m_symbol, SYMBOL_VOLUME_MAX);
    double lotStep = SymbolInfoDouble(m_symbol, SYMBOL_VOLUME_STEP);
    
    // Normalize to allowed lot size
    lot = MathMax(minLot, lot);
    lot = MathMin(maxLot, lot);
    
    // Adjust to lot step
    lot = MathFloor(lot / lotStep) * lotStep;
    
    return lot;
}

#endif