//+------------------------------------------------------------------+
//|                                          SimpleCandles.mq5      |
//|                                   Copyright 2023, Antonov A.A. |
//|                                             https://antekov.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2023, Antonov A.A."
#property link      "https://antekov.com"
#property version   "1.00"
#property strict

#define __NAME__ "SimpleCandles" + MQLInfoString(MQL_PROGRAM_NAME)

#include "Strategies/SimpleCandlesStrategy.mqh"
#include <antekov/Advisor/Experts/ExpertAdvisor.mqh>

//--- Input parameters
sinput string     symbol_ = "";
sinput ENUM_TIMEFRAMES period_ = PERIOD_CURRENT;
input int         signalSeqLen_ = 6;
input int         periodATR_ = 0;
input double      stopLevel_ = 25000;
input double      takeLevel_ = 3630;
input int         maxCountOfOrders_ = 9;
input int         maxSpread_ = 10;

//+------------------------------------------------------------------+
//| Get strategy parameters string                                   |
//+------------------------------------------------------------------+
string GetStrategyParams()
{
    return StringFormat(
        "class CSimpleCandlesStrategy(\"%s\",%d,%d,%d,%.3f,%.3f,%d,%d)",
        (symbol_ == "" ? Symbol() : symbol_), period_,
        signalSeqLen_, periodATR_, stopLevel_, takeLevel_,
        maxCountOfOrders_, maxSpread_
    );
}

//+------------------------------------------------------------------+