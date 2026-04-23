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
Operand 2 (register): only LSR is used (and only for one instruction, so this is a *potential* program-modification case)
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

# Undefined
Expand this case to include any of the unused instructions (so just put it as a default at the end, if possible). Otherwise just include another default case identical to this one, because iirc it might be important to absorb a specific data transfer case that isn't valid

# Block data transfer
Unused

# Branch
Cond: only unconditional, GT, LT, or EQ (ie 1110, 1100, 1011, 0000)
L: unused

# Coprocessor data operations
Already unimplemented