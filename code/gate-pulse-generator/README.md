# Gate Pulse Generator (MATLAB)

This folder contains MATLAB code used to generate 6 gate pulse text files for a three-phase inverter (upper/lower switches) used as PWL/PULSE inputs in LTspice.

## Output Files
The script generates:
- gate_S1.txt, gate_S2.txt
- gate_S3.txt, gate_S4.txt
- gate_S5.txt, gate_S6.txt

## Steps
Gate signals for the six MOSFET switches were generated using the MATLAB script.

The Flow:
- Implements three-phase switching logic
- Generates six complementary gate pulses
- Exports time–voltage data as .txt files
- These files are used directly as input sources in LTspice

