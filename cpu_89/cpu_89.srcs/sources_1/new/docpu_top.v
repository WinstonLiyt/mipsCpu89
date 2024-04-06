`include "defines.vh"
`timescale 1ns / 1ps

module docpu_top(
	input           clk,
	input           rst,
    output [31:0]   pc,
    output [31:0]   inst,
    output [31:0]   result
);

    wire rom_ce;
    wire mem_we_i;
    wire[`RegBus] memAddrIn;
    wire[`RegBus] memDataIn;
    wire[`RegBus] memDataOut;
    wire[3:0] mem_sel_i; 
    wire mem_ce_i;   
    wire[5:0] int;
    wire timer_int;
    
    assign int = {5'b00000, timer_int};
    
    docpu docpu(
        .clk(clk),
        .rst(rst),
    
        .rom_addr_o(pc),
        .rom_data_i(inst),
        .rom_ce_o(rom_ce),

        .externalInterrupts(int),

        .ram_we_o(mem_we_i),
        .ram_addr_o(memAddrIn),
        .ram_sel_o(mem_sel_i),
        .ram_data_o(memDataIn),
        .ram_data_i(memDataOut),
        .ram_ce_o(mem_ce_i),
        
        .timerInterruptOut(timer_int)
    );

    wire [31:0] a;
    assign a = pc - `TextBegin;
    imem imem(a[12:2],inst);

    dmem dmem(
        .clk(clk),
        .ce(mem_ce_i),
        .we(mem_we_i),
        .addr_in(memAddrIn),
        .sel(mem_sel_i),
        .data(memDataIn),
        .dataOut(memDataOut),
        .result(result)
    );

endmodule