`include "defines.vh"
`timescale 1ns / 1ps

module mem_wb(

	input clk,
	input rst,
	input [5:0] stall,	
    input flush,	

	input [`RegAddrBus] mem_waddr,		// 目标寄存器地址（MEM）
	input mem_wena,						// 写使能
	input [`RegBus] mem_data,			// 写数据
	input [`RegBus] mem_HI, mem_LO,		// HI,LO寄存器数据
	input mem_HILO_ena,					// HI,LO寄存器写使能
	input mem_LLbit_wena,				// LLbit写使能
	input mem_LLbit,					// LLbit写数据
	input mem_cp0_wena,					// CP0写使能
	input [4:0] mem_cp0_waddr,			// CP0写地址
	input [`RegBus] mem_cp0_data,		// CP0写数据

	output reg[`RegAddrBus] wb_waddr,	// 目标寄存器地址（WB）
	output reg wb_wena,					// 写使能
	output reg[`RegBus] wb_data,		// 写数据
	output reg[`RegBus] wb_HI, wb_LO,	// HI,LO寄存器数据
	output reg wb_HILO_ena,				// HI,LO寄存器写使能
	output reg wb_LLbit_wena,			// LLbit写使能			
	output reg wb_LLbit,				// LLbit写数据
	output reg wb_cp0_wena,				// CP0写使能
	output reg[4:0] wb_cp0_waddr,		// CP0写地址
	output reg[`RegBus] wb_cp0_data		// CP0写数据							       
	
);


	always @ (posedge clk) begin
		// 在复位、刷新或特定的暂停条件下，清零所有输出
		if (rst == `RstEnable || flush == 1'b1 || (stall[4] == `Stop && stall[5] == `NoStop)) begin
        wb_waddr <= `NOPRegAddr;
        wb_wena <= `WriteDisable;
        wb_data <= `ZeroWord;
        wb_HI <= `ZeroWord;
        wb_LO <= `ZeroWord;
        wb_HILO_ena <= `WriteDisable;
        wb_LLbit_wena <= 1'b0;
        wb_LLbit <= 1'b0;
        wb_cp0_wena <= `WriteDisable;
        wb_cp0_waddr <= 5'b00000;
        wb_cp0_data <= `ZeroWord;
		end
		// 在没有暂停的条件下，从MEM阶段传递数据到WB阶段
		else if (stall[4] == `NoStop) begin
			wb_waddr <= mem_waddr;
			wb_wena <= mem_wena;
			wb_data <= mem_data;
			wb_HI <= mem_HI;
			wb_LO <= mem_LO;
			wb_HILO_ena <= mem_HILO_ena;
			wb_LLbit_wena <= mem_LLbit_wena;
			wb_LLbit <= mem_LLbit;
			wb_cp0_wena <= mem_cp0_wena;
			wb_cp0_waddr <= mem_cp0_waddr;
			wb_cp0_data <= mem_cp0_data;
		end
	end

endmodule