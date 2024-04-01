`include "defines.vh"
`timescale 1ns / 1ps


module pc_reg(

	input wire 					  clk,
	input wire 					  rst,

	input wire[5:0]               stall,	// 流水线停顿控制信号
	input wire                    flush,	// 流水线刷新信号，用于分支预测错误时的恢复
	input wire[`RegBus]           pcNew,	// 新的PC值，用于跳转和分支

	input wire                    branch_flag_i,	// 分支标志，表示是否执行分支
	input wire[`RegBus]           branch_target_address_i,	// 分支目标地址
	
	output reg[`InstAddrBus] 	  pc,	// 当前的程序计数器值
	output reg               	  ce	// 芯片使能信号
	
);

	always @ (posedge clk) begin
		if (ce == `ChipDisable) begin  // 当芯片处于禁用状态时，将PC设置为指令区域的起始地址
		// if (rst == `RstEnable) begin
			pc <= `TextBegin;
		end else if (ce != `ChipDisable) begin
			if (flush == 1'b1) begin	// 如果需要刷新流水线，将PC设置为新的PC值
				pc <= pcNew;
			end 
			else if(stall[0] == `NoStop) begin  // 如果没有停顿，根据分支标志更新PC值
				if (branch_flag_i == `Branch) begin  // 如果有分支，跳转到分支目标地址
					pc <= branch_target_address_i;	
				end 
				else begin  // 如果没有分支，顺序执行下一条指令
		  			pc <= pc + 4'h4;
		  		end
			end
		end
	end

	// 控制芯片使能信号的逻辑，响应时钟的上升沿和复位信号
	always @ (posedge clk) begin
		if (rst == `RstEnable) begin
			ce <= `ChipDisable;
		end else begin
			ce <= `ChipEnable;
		end
	end

endmodule