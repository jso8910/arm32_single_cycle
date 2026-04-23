Binary search assembly: workloads/binsearch/binsearch.s
Binary search imem file: workloads/binsearch/imem.mem
Binary search dmem file: workloads/binsearch/dmem.mem

Instructions, and what features can be removed from them (in the most conservative, no program modification case):

# Data processing
Cond: unused
Opcode: MOV, CMP, ADD, SUB, MVN
S: used
Registers: eliminate registers above R5, R0 never needs to be a destination
Operand 2 (immediate): no need for rotate
Operand 2 (register): only LSR is used (and only for one instruction, so this is a *potential* program-modification case). Also, no need for shift by register (register output c).
- Also, this is always 1. Never more

# Multiply
Unused

# Multiply long
Unused

# Single data swap
Unused

# Branch and exchange
Unused

# Halfword data transfer: register offset
Unused

# Halfword data transfer: immediate offset
Unused

# Single data transfer
Cond: unused
I (immediate): always 0 (immediate)
P: always 1 (pre) but doesn't matter
U: always 1 (up) but doesn't matter
B: always 1 (byte)
W: always 0 (no writeback)
L: always 1 (load)
Offset: always 0

# Block data transfer
Unused

# Branch
Cond: only unconditional, GT, LT, or EQ (ie 1110, 1100, 1011, 0000)
L: unused

# Coprocessor data operations
Already unimplemented

# Misc
Extra ALU output port (only used for branch with link, which I don't need), extra register write port (port B), extra register read ports (C (used for register-shifted registers) and D (D is used for data writing, but I'm never doing that)).

# Results
Using NangateOpenCellLibrary. At default effort level for all synthesis steps.

## Pre-optimization
### Core area
 Instance  Module  Cell Count  Cell Area  Net Area   Total Area
----------------------------------------------------------------
arm32_core               3872   7008.568  6378.705    13387.273
### Core power
                    Leakage    Dynamic     Total
 Instance   Cells  Power(nW)  Power(nW)  Power(nW)
---------------------------------------------------
arm32_core   3872 151261.261 466081.621 617342.882

### Register file area
Instance Module  Cell Count  Cell Area  Net Area   Total Area
--------------------------------------------------------------
regfile                3797   6740.706  6779.092    13519.798

### Register file power
                  Leakage    Dynamic     Total
Instance  Cells  Power(nW)  Power(nW)  Power(nW)
-------------------------------------------------
regfile    3797 122982.806 462685.326 585668.133

## Post-optimization
Core area:
Core power:

Register file area:
Register file power: