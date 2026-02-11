//+------------------------------------------------------------------+
//|                                         EA_Structs.mqh       |
//|                                    EA_120_Logika Includes        |
//|                                                                  |
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//| Default Parameter Structures                                     |
//+------------------------------------------------------------------+

// Scalping Parameters
struct ScalpingParams
{
   int    emaFastPeriod;
   int    emaSlowPeriod;
   int    rsiPeriod;
   int    rsiOversold;
   int    rsiOverbought;
   double minAdxForTrend;  // Minimum ADX for trend confirmation

   ScalpingParams()
   {
      emaFastPeriod = 5;
      emaSlowPeriod = 20;
      rsiPeriod = 14;
      rsiOversold = 30;
      rsiOverbought = 70;
      minAdxForTrend = 25.0;
   }
};

// Breakout Parameters
struct BreakoutParams
{
   int    lookbackPeriod;
   double thresholdPips;
   bool   useVolumeConfirmation;
   double minVolumeMultiplier;

   BreakoutParams()
   {
      lookbackPeriod = 20;
      thresholdPips = 5.0;
      useVolumeConfirmation = false;
      minVolumeMultiplier = 1.5;
   }
};

// Grid Parameters
struct GridParams
{
   double stepPips;
   int    maxLevels;
   bool   useTrailingStop;
   double trailingStartPips;
   double trailingStepPips;

   GridParams()
   {
      stepPips = 30.0;
      maxLevels = 10;
      useTrailingStop = false;
      trailingStartPips = 50.0;
      trailingStepPips = 20.0;
   }
};

// Martingale Parameters
struct MartingaleParams
{
   double lotMultiplier;
   int    maxLevel;
   bool   resetOnProfit;
   bool   useEquityRecovery;
   double recoveryTargetPct;

   MartingaleParams()
   {
      lotMultiplier = 1.5;
      maxLevel = 5;
      resetOnProfit = true;
      useEquityRecovery = false;
      recoveryTargetPct = 5.0;
   }
};

//+------------------------------------------------------------------+
//| Symbol Data Structure                                            |
//+------------------------------------------------------------------+
struct SymbolData
{
   // Symbol info
   string            name;
   int               digits;
   double            point;
   double            pipValue;
   double            minLot;
   double            maxLot;
   double            lotStep;
   double            tickSize;
   double            tickValue;
   long              magicNumber;
   
   // Indicator handles
   int               handleEmaFast;
   int               handleEmaSlow;
   int               handleRsi;
   int               handleAtr;
   int               handleAdx;
   int               handleVolume;
   
   // Grid tracking
   double            lastGridPriceBuy;
   double            lastGridPriceSell;
   int               martingaleLevelBuy;
   int               martingaleLevelSell;
   ENUM_GRID_STATUS  gridStatus;
   
   // Position tracking
   int               positionsCount;
   double            totalLotsBuy;
   double            totalLotsSell;
   double            avgPriceBuy;
   double            avgPriceSell;
   double            profitBuy;
   double            profitSell;
   
   // Signal data
   ENUM_SIGNAL_TYPE  lastSignal;
   datetime          lastSignalTime;
   double            signalStrength;
   
   // Statistics
   int               totalTrades;
   int               winningTrades;
   int               losingTrades;
   double            totalProfit;
   
   // AI-Enhanced Data
   double            currentVolatility;
   double            avgVolatility;
   double            sentimentScore;
   double            smartMoneyFlow;
   double            mlConfidence;
   bool              isCorrelated;
   
   // Constructor
   SymbolData()
   {
      Init();
   }
   
   void Init()
   {
      name = "";
      digits = 0;
      point = 0;
      pipValue = 0;
      minLot = 0;
      maxLot = 0;
      lotStep = 0;
      tickSize = 0;
      tickValue = 0;
      magicNumber = 0;
      
      handleEmaFast = INVALID_HANDLE;
      handleEmaSlow = INVALID_HANDLE;
      handleRsi = INVALID_HANDLE;
      handleAtr = INVALID_HANDLE;
      handleAdx = INVALID_HANDLE;
      handleVolume = INVALID_HANDLE;
      
      lastGridPriceBuy = 0;
      lastGridPriceSell = 0;
      martingaleLevelBuy = 0;
      martingaleLevelSell = 0;
      gridStatus = GRID_STATUS_NONE;
      
      positionsCount = 0;
      totalLotsBuy = 0;
      totalLotsSell = 0;
      avgPriceBuy = 0;
      avgPriceSell = 0;
      profitBuy = 0;
      profitSell = 0;
      
      lastSignal = SIGNAL_NONE;
      lastSignalTime = 0;
      signalStrength = 0;
      
      totalTrades = 0;
      winningTrades = 0;
      losingTrades = 0;
      totalProfit = 0;
      
      currentVolatility = 0;
      avgVolatility = 0;
      sentimentScore = 0;
      smartMoneyFlow = 0;
      mlConfidence = 0.5;
      isCorrelated = false;
   }
   
   void ResetGridBuy()
   {
      lastGridPriceBuy = 0;
      martingaleLevelBuy = 0;
      UpdateGridStatus();
   }
   
   void ResetGridSell()
   {
      lastGridPriceSell = 0;
      martingaleLevelSell = 0;
      UpdateGridStatus();
   }
   
   void UpdateGridStatus()
   {
      if(martingaleLevelBuy > 0 && martingaleLevelSell > 0)
         gridStatus = GRID_STATUS_BOTH;
      else if(martingaleLevelBuy > 0)
         gridStatus = GRID_STATUS_BUY;
      else if(martingaleLevelSell > 0)
         gridStatus = GRID_STATUS_SELL;
      else
         gridStatus = GRID_STATUS_NONE;
   }
};