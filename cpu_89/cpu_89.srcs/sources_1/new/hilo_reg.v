//@func   : 
//@time   : 
//@author :

`include "defines.vh"
`timescale 1ns / 1ps

module hilo_reg(

	input	wire					clk,
	input wire						rst,
	
	input wire						we,
	input wire[`RegBus]				regHI,
	input wire[`RegBus]				regLO,
	
	output reg[`RegBus]           	HI_out,
	output reg[`RegBus]           	LO_out
	
);

	always @ (posedge clk) begin
		if (rst == `RstEnable) begin
					HI_out <= `ZeroWord;
					LO_out <= `ZeroWord;
		end else if((we == `WriteEnable)) begin
					HI_out <= regHI;
					LO_out <= regLO;
		end
	end

endmodule