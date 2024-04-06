/* -----------------------------------------
Func��HI/LO�Ĵ��������ڴ洢�˷��ͳ����Ľ��
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
		// ����ͨ��we�ж��Ƿ�д��
		else if ((wena == `WriteEnable)) begin
			HIOut <= regHI;
			LOOut <= regLO;
		end
	end

endmodule