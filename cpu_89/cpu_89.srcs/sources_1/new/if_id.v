/* -----------------------------------------
Func：暂时保存取指阶段取得的指令，以及 对应的指令
	  地址，并在下一个时钟传递到译码阶段
------------------------------------------- */

`include "defines.vh"
`timescale 1ns / 1ps

module if_id(

	input clk,
	input rst,
	input [5:0] stall,	
	input flush,

	input [`InstAddrBus] if_pc,		// IF阶段的PC值
	input [`InstBus] ifInstr,		// IF阶段的指令
	output reg[`InstAddrBus] id_pc,	// ID阶段的PC值
	output reg[`InstBus] idInstr	// ID阶段的指令
);
	always @ (posedge clk) begin
		// 如果复位，流水线刷新（异常），或特定的暂停条件成立，则清零id_pc和idInstr
		if (rst == `RstEnable || flush == 1'b1 || (stall[1] == `Stop && stall[2] == `NoStop)) begin
			id_pc <= `ZeroWord;
			idInstr <= `ZeroWord;
		end 
		else if (stall[1] == `NoStop) begin
			id_pc <= if_pc;
			idInstr <= ifInstr;
		end
	end

endmodule