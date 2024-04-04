/* -------------------------------
Func��LLbit�Ĵ�����
------------------------------- */

`include "defines.vh"
`timescale 1ns / 1ps

module LLbit_reg(
	input clk,
	input rst,
	input wire  wena,
	input flush,
	input wire LLbitIn,		// LLbit�����źţ�����ִ�н׶�
	output reg LLbitOut		// LLbit����źţ��洢��ǰ��LLbit״̬
);

	always @ (posedge clk) begin
		if (rst == `RstEnable)
			LLbitOut <= 1'b0;
		else if ((flush == 1'b1))  // �쳣����
			LLbitOut <= 1'b0;
		else if ((wena == `WriteEnable))
			LLbitOut <= LLbitIn;
	end

endmodule