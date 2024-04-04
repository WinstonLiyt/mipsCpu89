/* -------------------------------
Func：LLbit寄存器。
------------------------------- */

`include "defines.vh"
`timescale 1ns / 1ps

module LLbit_reg(
	input clk,
	input rst,
	input wire  wena,
	input flush,
	input wire LLbitIn,		// LLbit输入信号，来自执行阶段
	output reg LLbitOut		// LLbit输出信号，存储当前的LLbit状态
);

	always @ (posedge clk) begin
		if (rst == `RstEnable)
			LLbitOut <= 1'b0;
		else if ((flush == 1'b1))  // 异常发生
			LLbitOut <= 1'b0;
		else if ((wena == `WriteEnable))
			LLbitOut <= LLbitIn;
	end

endmodule