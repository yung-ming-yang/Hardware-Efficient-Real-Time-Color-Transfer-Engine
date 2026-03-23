# Hardware-Efficient-Real-Time-Color-Transfer-Engine
Real-time 1080p/60FPS Color Transfer Engine. Features YCbCr-based luminance matching and chromaticity mapping with dual-FSM/SRAM parallel architecture. Latency: 7.611ms/frame.

## Key Performance
- Resolution: 1920 x 1080 (1080p)
- Throughput: 7.611 ms/Frame (Exceeds 60 FPS real-time requirement of 16.6ms)
- Power Consumption: 4.417 mW (Post-layout)
- Area: 613,141 µm² (Utilization: 0.75)

## Features
- End-to-End Processing: Processes RAW (RGGB Bayer pattern) input to stylized RGB output.
- Advanced Color Mapping: Implements YCbCr-based luminance matching and chromaticity mapping.
- Hardware Optimizations:
  - Dual-FSM Architecture: Streamlines control logic for high-speed execution.
  - SRAM Partitioning: Utilizes 4-bank parallel access to maximize data throughput.
  - Fixed-Point Precision: Optimized algorithm for integer-only hardware arithmetic to ensure bit-accurate results.

## Verification
The design has been fully verified through a standard IC design flow:
- RTL Simulation: Functional verification using ncverilog.
- Gate-level Simulation: Verified logic after synthesis.
- Post-layout Simulation: Confirmed timing and functionality after APR (Auto Place & Route).
- LEC: Logic Equivalence Check passed.

## Authors
- Ming-Yan Yang (楊明諺)
- Wei-Ju Huang (黃威儒)
- Kuan-Ting Wu (吳冠廷)
- *Department of Electrical Engineering, National Tsing Hua University*
