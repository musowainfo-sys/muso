//+------------------------------------------------------------------+
//|                                        Optimization.mq5        |
//|                                   Copyright 2023, Antonov A.A. |
//|                                             https://antekov.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2023, Antonov A.A."
#property link      "https://antekov.com"
#property version   "1.00"
#property strict

#include "..\Include\EA\ExpertAdvisor.mqh"

//--- Input parameters
input string         symbol_ = "GBPUSD";
input ENUM_TIMEFRAMES period_ = PERIOD_H1;
input int            digits_ = 5;
input uint           maxBarsBack_ = 10000;
input bool           useAutoUpdate_ = true;
input int            groupId_ = 1;

//+------------------------------------------------------------------+
//| Get strategy parameters string                                   |
//+------------------------------------------------------------------+
string GetStrategyParams()
{
    return "class CSimpleCandlesStrategy(\"" + symbol_ + "\"," + 
           IntegerToString(period_) + ",6,0,25000,3630,9,10)";
}

//+------------------------------------------------------------------+