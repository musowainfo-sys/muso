//+------------------------------------------------------------------+
//|                                        CreateProject.mq5        |
//|                                   Copyright 2023, Antonov A.A. |
//|                                             https://antekov.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2023, Antonov A.A."
#property link      "https://antekov.com"
#property version   "1.00"
#property strict

#include "..\Include\EA\ExpertAdvisor.mqh"

//--- Input parameters for the project
input string         symbol_ = "GBPUSD";
input ENUM_TIMEFRAMES period_ = PERIOD_H1;
input int            digits_ = 5;
input uint           maxBarsBack_ = 10000;
input bool           useAutoUpdate_ = true;
input int            groupId_ = 1;

//+------------------------------------------------------------------+
//| Parameters template for SimpleCandles strategy                  |
//+------------------------------------------------------------------+
string paramsTemplate1()
{
    string result = "";
    result += "input int    signalSeqLen_ = 3,4,5,6,7,8,9,10; ";
    result += "input int    periodATR_ = 0,1,2,3,4,5,6,7,8,9,10; ";
    result += "input double stopLevel_ = 10000,15000,20000,25000,30000,35000,40000; ";
    result += "input double takeLevel_ = 1815,2420,3025,3630,4235,4840,5445; ";
    result += "input int    maxCountOfOrders_ = 1,2,3,4,5,6,7,8,9,10; ";
    result += "input int    maxSpread_ = 5,10,15,20,25,30; ";
    return result;
}

//+------------------------------------------------------------------+
//| Get strategy parameters string                                   |
//+------------------------------------------------------------------+
string GetStrategyParams()
{
    return "class CSimpleCandlesStrategy(\"" + symbol_ + "\"," + 
           IntegerToString(period_) + ",6,0,25000,3630,9,10)";
}

//+------------------------------------------------------------------+