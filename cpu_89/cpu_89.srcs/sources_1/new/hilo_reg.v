/* -----------------------------------------
Func：HI/LO寄存器，用于存储乘法和除法的结果
------------------------------------------- */

`include "defines.vh"
`timescale 1ns / 1ps

module hilo_reg(

	input clk,
	input rst,

	input wena,
	input [`RegBus] regHI, regLO,
	
	output reg[`RegBus] HIOut, LOOut
);

	always @ (posedge clk) begin
		if (rst == `RstEnable) begin
			HIOut <= `ZeroWord;
			LOOut <= `ZeroWord;
		end
		// 就是通过we判断是否写入
		else if ((wena == `WriteEnable)) begin
			HIOut <= regHI;
			LOOut <= regLO;
		end
	end

endmodule