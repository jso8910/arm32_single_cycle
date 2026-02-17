# ARMv7-A Core Implementation

Simple single cycle implementation of an ARM32 core. I am trying to keep the interface of all modules listed [in this file](https://github.com/TaylorEssien/forecast/blob/main/generating/pythonDesigns/gen_1stage_modDef.py) exactly the same (I took the module definitions from [this file](https://github.com/TaylorEssien/forecast/blob/main/processor/single_cycle/new_riscv_single_cycle.v)). Anywhere I have changed the interfaces of a module in this file, I clearly indicate the change.

Additionally, the register file writes solely on the `we` signal, not waiting for the clock. This is because some ARM32 instructions require multiple register writes per cycle.