/* -------------------------------
Func：给出指令地址，控制PC的更新和使能信号
------------------------------- */

`include "defines.vh"
`timescale 1ns / 1ps

module pc_reg(

	input clk,
	input rst,

	input [5:0] stall,		// 流水线停顿控制信号
	input flush,			// 流水线刷新信号，用于分支预测错误时的恢复
	input [`RegBus] pcNew,	// 新的PC值，用于跳转和分支

	input branch_flag_i,	// 分支标志，表示是否执行分支
	input [`RegBus] branch_target_address_i,	// 分支目标地址
	
	output reg[`InstAddrBus] pc,	// 当前的程序计数器值
	output reg ce					// 芯片使能信号
	
);

	// 跳转指令
	always @ (posedge clk) begin
		// 当芯片处于禁用状态时，将PC设置为指令区域的起始地址
		if (ce == `ChipDisable)
			pc <= `TextBegin;
		else if (ce != `ChipDisable) begin
			// 如果需要刷新流水线，将PC设置为新的PC值
			if (flush == 1'b1)
				pc <= pcNew;
			// 如果没有停顿，根据分支标志更新PC值
			else if(stall[0] == `NoStop) begin
				// 如果有分支，跳转到分支目标地址
				if (branch_flag_i == `Branch)
					pc <= branch_target_address_i;
				// 如果没有分支，顺序执行下一条指令
				else
		  			pc <= pc + 4'h4;
			end
		end
	end

	// 控制芯片使能信号的逻辑，响应时钟的上升沿和复位信号
	always @ (posedge clk) begin
		if (rst == `RstEnable)
			ce <= `ChipDisable;
		else
			ce <= `ChipEnable;
	end

endmodule