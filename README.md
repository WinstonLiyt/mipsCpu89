## MIPS32-based Cpu89
### Introduction
- By referencing the book "Build Your Own CPU," the CPU with 54 instructions was modified to support 89 instructions, and implemented the co-processor CP0 and exception handling.

### Illustration
- The CPU implemented in this experimental project, based on the MIPS 32 architecture, adopts the Harvard architecture, featuring separate instruction and data memories. Additionally, this CPU is a five-stage pipeline CPU, with stages including Instruction Fetch (IF), Decode (ID), Execute (EXE), Memory Access (MEM), and Write Back (WB). According to the requirements of the test program, the CPU in this project uses **big-endian mode**.

### Environment
- **Operating System:** Windows 10
- **Software Environment:** Vivado v2016.2, MARS 4.5, ModelSim PE 10.4c
- **Compiler:** Visual Studio Code
- **Plugins:** Github Copilot v1.177.0, Verilog-HDL v1.13.5
- **Hardware Device:** Nexys 4 DDR Artix-7 FPGA Trainer Board
- **IP Core Calls:** Distributed Memory Generator memory (ROM)

### Overall Structure and Data Path Design Diagram of CPU 89
![CPU89](https://github.com/WinstonLiyt/mipsCpu89/assets/104308117/96c8566d-53db-472c-9aac-be3c92406c92)
