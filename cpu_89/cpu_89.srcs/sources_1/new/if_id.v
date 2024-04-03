`include "defines.vh"
`timescale 1ns / 1ps

module if_id(

	input clk,
	input rst,
	input [5:0] stall,	
	input flush,

	input [`InstAddrBus] if_pc,
	input [`InstBus] ifInstr,
	output reg[`InstAddrBus] id_pc,
	output reg[`InstBus] idInstr  
);
	always @ (posedge clk) begin
		// 如果复位，流水线刷新，或特定的暂停条件成立，则清零id_pc和idInstr
		if (rst == `RstEnable || flush == 1'b1 || (stall[1] == `Stop && stall[2] == `NoStop)) begin
			id_pc <= `ZeroWord;
			idInstr <= `ZeroWord;
		end 
		else if (stall[1] == `NoStop) begin
			id_pc <= if_pc;
			idInstr <= ifInstr;
		end
	end


	// always @ (posedge clk) begin
	// 	if (rst == `RstEnable) begin
	// 		id_pc <= `ZeroWord;
	// 		idInstr <= `ZeroWord;
	// 	end
	// 	else if(flush == 1'b1 ) begin
	// 		id_pc <= `ZeroWord;
	// 		idInstr <= `ZeroWord;					
	// 	end
	// 	else if(stall[1] == `Stop && stall[2] == `NoStop) begin
	// 		id_pc <= `ZeroWord;
	// 		idInstr <= `ZeroWord;	
	// 	end
	// 	else if(stall[1] == `NoStop) begin
	// 		id_pc <= if_pc;
	// 		idInstr <= ifInstr;
	// 	end
	// end

endmodule