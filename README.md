# MQL5 Trading Expert Advisors

This repository contains a collection of Expert Advisors (EAs) and related components developed in MQL5 for MetaTrader 5 trading platform.

## Project Structure

```
Experts/
├── CreateProject.mq5
├── Optimization.mq5
├── SimpleCandles.mq5
├── Stage1.mq5
├── Stage2.mq5
├── Stage3.mq5
└── Strategies/
    └── SimpleCandlesStrategy.mqh

Include/
├── EA/
│   ├── Constants.mqh
│   ├── Filters.mqh
│   ├── Indicators.mqh
│   ├── Inputs.mqh
│   ├── Signals.mqh
│   ├── Strategy.mqh
│   ├── Structs.mqh
│   ├── Trading.mqh
│   └── Utils.mqh
└── EA_120_Logika/
    ├── Constants.mqh
    ├── Filters.mqh
    ├── Indicators.mqh
    ├── Inputs.mqh
    ├── Signals.mqh
    ├── Structs.mqh
    ├── Trading.mqh
    └── Utils.mqh
```

## Components

### Experts
- **CreateProject.mq5**: Project creation utility
- **Optimization.mq5**: Optimization functionality for EAs
- **SimpleCandles.mq5**: Candlestick pattern analysis and recognition tools
- **Stage1.mq5, Stage2.mq5, Stage3.mq5**: Sequential development stages for EA building
- **Strategies/**: Contains trading strategy implementations including SimpleCandlesStrategy.mqh

### Include
- **EA/**: Core Expert Advisor include files with essential modules:
  - Constants.mqh: Defines constants used throughout the EAs
  - Filters.mqh: Price and market condition filtering functions
  - Indicators.mqh: Technical indicator calculations and implementations
  - Inputs.mqh: Input parameters management
  - Signals.mqh: Trading signal generation logic
  - Strategy.mqh: Strategy implementation framework
  - Structs.mqh: Data structures used across the EAs
  - Trading.mqh: Trading operations and order management
  - Utils.mqh: Utility functions and helpers
- **EA_120_Logika/**: Alternative implementation with 120 logic variations of the same modules

## Features

- Modular architecture with reusable components
- Comprehensive technical indicator support
- Flexible signal generation system
- Robust trading management functions
- Multiple strategy implementation approaches
- Extensive configuration options through input parameters
- Error handling and logging capabilities

## Installation

1. Download the repository files
2. Place the Experts folder in your MT5 data folder: `<MT5 Data Folder>/MQL5/Experts/`
3. Place the Include folder in your MT5 data folder: `<MT5 Data Folder>/MQL5/Include/`
4. Restart MetaTrader 5
5. Compile the Expert Advisors in the MetaEditor

## Usage

These Expert Advisors are designed to be used with the MetaTrader 5 trading platform. Each EA can be attached to a chart and configured with various input parameters to customize trading behavior.

## Configuration

The EAs can be configured through input parameters defined in the Inputs.mqh files. These include settings for:
- Lot sizes
- Stop loss and take profit levels
- Indicator periods
- Trading session filters
- Risk management parameters

## License

This project is open source and available under the MIT License.