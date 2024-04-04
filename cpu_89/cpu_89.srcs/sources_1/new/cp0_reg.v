/* -----------------------------------------
Func：协处理器CP0
------------------------------------------- */

`include "defines.vh"
`timescale 1ns / 1ps

module cp0_reg(
	input wire clk,
    input wire rst,

    input wire wena,
    input wire[4:0] waddr, raddr,
    input wire[`RegBus] data,

    input wire[31:0] exceptionType, 			// 异常类型
    input wire[5:0] externalInterrupts, 		// 外部中断输入
    input wire[`RegBus] currentInstructionAddr, // 当前指令地址
    input wire isInDelaySlot, 					// 是否在延迟槽内
	
	output reg[`RegBus] dataOut, 	// CP0寄存器读出数据
    output reg[`RegBus] cntOut, 	// Count寄存器的值
    output reg[`RegBus] cmpOut, 	// Compare寄存器的值
    output reg[`RegBus] statusOut, 	// Status寄存器的值
    output reg[`RegBus] causeOut, 	// Cause寄存器的值
    output reg[`RegBus] epcOut, 	// EPC寄存器的值
    output reg[`RegBus] configOut, 	// Config寄存器的值
    output reg[`RegBus] processorIDOut, // PRId寄存器的值

    output reg timerInterruptOut 	// 是否有定时中断发生
	
);

	// 初始化CP0寄存器
	always @ (posedge clk) begin
		if (rst == `RstEnable) begin
			cntOut <= `ZeroWord;
			cmpOut <= `ZeroWord;
			// 其中CU字段为4'b0001，表示协处理器CP0存在
			statusOut <= 32'b00010000000000000000000000000000;
			causeOut <= `ZeroWord;
			epcOut <= `ZeroWord;
			// 其中BE字段为1，表示工作在大端模式(MSB)
			configOut <= 32'b00000000000000001000000000000000;
			// PRId寄存器的初始值，其中制作者是L，对应的是0x48（自行定义的），类型是0x1，表示是基本类型，版本号是1.0
			processorIDOut <= 32'b00000000010011000000000100000010;
      		timerInterruptOut <= `InterruptNotAssert;
		end
		// 更新计数器和处理中断请求
		else begin
			cntOut <= cntOut + 1 ;
			causeOut[15:10] <= externalInterrupts;	// Cause 的第10~15bit 保存外部中断声明
			// 时钟中断
			timerInterruptOut <= (cmpOut != `ZeroWord && cntOut == cmpOut) ? `InterruptAssert : `InterruptNotAssert;
		
			if (wena == `WriteEnable) begin
				case (waddr) 
					`CP0_REG_COUNT: begin
						cntOut <= data;
					end
					`CP0_REG_COMPARE: begin
						cmpOut <= data;
            			timerInterruptOut <= `InterruptNotAssert;
					end
					`CP0_REG_STATUS: begin
						statusOut <= data;
					end
					`CP0_REG_EPC: begin
						epcOut <= data;
					end
					// Cause寄存器只有IP[1:0]、IV、WP字段是可写的
					`CP0_REG_CAUSE: begin
						causeOut[9:8] <= data[9:8];
						causeOut[23] <= data[23];
						causeOut[22] <= data[22];
					end
				endcase			
			end

			// 异常处理逻辑优化
			if (exceptionType != `ZeroWord) begin
				epcOut <= isInDelaySlot ? currentInstructionAddr - 4 : currentInstructionAddr;
				causeOut[31] <= isInDelaySlot;
				statusOut[1] <= 1'b1;
				
				case (exceptionType)
					32'h00000001: causeOut[6:2] <= 5'b00000; // interrupt
					32'h00000008: causeOut[6:2] <= 5'b01000; // syscall
					32'h0000000a: causeOut[6:2] <= 5'b01010; // inst_invalid
					32'h0000000d: causeOut[6:2] <= 5'b01101; // trap
					32'h0000000c: causeOut[6:2] <= 5'b01100; // ov
					32'h0000000e: statusOut[1] <= 1'b0;      // eret
					default: ;
				endcase
			end
		end
	end

	// 根据读地址输出CP0寄存器值	
	always @ (*) begin
		if (rst == `RstEnable) dataOut <= `ZeroWord;
		else begin
			case (raddr) 
				`CP0_REG_COUNT:
					dataOut <= cntOut;
				`CP0_REG_COMPARE:
					dataOut <= cmpOut;
				`CP0_REG_STATUS:
					dataOut <= statusOut;
				`CP0_REG_CAUSE:
					dataOut <= causeOut;
				`CP0_REG_EPC:
					dataOut <= epcOut;
				`CP0_REG_PrId:
					dataOut <= processorIDOut;
				`CP0_REG_CONFIG:
					dataOut <= configOut;
				default: begin
				end	
			endcase
		end
	end

endmodule