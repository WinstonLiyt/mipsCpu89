/* -------------------------------
Func：控制流水线的暂停、清除
	  和新PC值的生成。
------------------------------- */

`include "defines.vh"
`timescale 1ns / 1ps

module ctrl(
	input rst,
    input [31:0] exceptionType, // 异常类型
    input [`RegBus] cp0EPCValue, // 来自CP0的EPC值
    input idStall, exeStall, // 来自ID和EXE阶段的暂停请求

    output reg[`RegBus] pcNew, // 新的PC值
    output reg flush, // 清除信号
    output reg[5:0] stall // 暂停信号（取址地址PC，取址，译码，执行，访存，回写）
);

	// 控制逻辑
	always @ (*) begin
		// 复位时清除暂停和清除信号，新PC值设为0
		if (rst == `RstEnable) begin
			stall <= 6'b000000;
			flush <= 1'b0;
			pcNew <= `ZeroWord;
		end 
		// 有异常发生时
		else if (exceptionType != `ZeroWord) begin
		  	flush <= 1'b1;
		  	stall <= 6'b000000;
			// 根据异常类型决定新的PC值
			case (exceptionType)
				32'h00000001, // interrupt
                32'h00000008, // syscall
                32'h0000000a, // inst_invalid
                32'h0000000d, // trap
                32'h0000000c: // ov
                    pcNew <= `ExceptionBegin; // 将新PC设置为异常处理起始地址
                32'h0000000e: // eret
                    pcNew <= cp0EPCValue; // 返回到异常发生前的地址
                default: ;
			endcase 						
		end 
		// exe阶段请求暂停
		else if (exeStall == `Stop) begin
			stall <= 6'b001111;
			flush <= 1'b0;		
		end 
		// id阶段请求暂停
		else if (idStall == `Stop) begin
			stall <= 6'b000111;	
			flush <= 1'b0;		
		end
		// 正常流程
		else begin
			stall <= 6'b000000;
			flush <= 1'b0;
			pcNew <= `ZeroWord;		
		end
	end

endmodule