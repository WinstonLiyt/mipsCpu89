/* -----------------------------------------
Func：32个32位的通用整数寄存器，支持读写操作。
------------------------------------------- */

`include "defines.vh"
`timescale 1ns / 1ps

module regfile(
    input wire clk, // 时钟信号
    input wire rst, // 复位信号

    input wire we, 					// 写使能信号
    input wire[`RegAddrBus] waddr, 	// 写地址
    input wire[`RegBus] wdata, 		// 写数据
    
    input wire re1, 				// 读端口1使能信号
    input wire[`RegAddrBus] raddr1, // 读地址1
    output reg[`RegBus] rdata1, 	// 读数据1
    
    input wire re2, 				// 读端口2使能信号
    input wire[`RegAddrBus] raddr2, // 读地址2
    output reg[`RegBus] rdata2 		// 读数据2
);

	// 寄存器数组声明，存储32个32位宽的寄存器
	reg[`RegBus] array_reg[0:`RegNum - 1];

	initial begin
		array_reg[0] <= 32'b0;
		array_reg[1] <= 32'b0;
		array_reg[2] <= 32'b0;
		array_reg[3] <= 32'b0;
		array_reg[4] <= 32'b0;
		array_reg[5] <= 32'b0;
		array_reg[6] <= 32'b0;
		array_reg[7] <= 32'b0;
		array_reg[8] <= 32'b0;
		array_reg[9] <= 32'b0;
		array_reg[10] <= 32'b0;
		array_reg[11] <= 32'b0;
		array_reg[12] <= 32'b0;
		array_reg[13] <= 32'b0;
		array_reg[14] <= 32'b0;
		array_reg[15] <= 32'b0;
		array_reg[16] <= 32'b0;
		array_reg[17] <= 32'b0;
		array_reg[18] <= 32'b0;
		array_reg[19] <= 32'b0;
		array_reg[20] <= 32'b0;
		array_reg[21] <= 32'b0;
		array_reg[22] <= 32'b0;
		array_reg[23] <= 32'b0;
		array_reg[24] <= 32'b0;
		array_reg[25] <= 32'b0;
		array_reg[26] <= 32'b0;
		array_reg[27] <= 32'b0;
		array_reg[28] <= 32'b0;
		array_reg[29] <= 32'b0;
		array_reg[30] <= 32'b0; 
		array_reg[31] <= 32'b0;
	end

	// 写操作：在时钟上升沿且复位信号为非激活状态下，如果写使能且写地址非0（$0在MIPS 32下只能为0），则更新寄存器值
	always @ (posedge clk) begin
		if (rst == `RstDisable) begin
			if ((we == `WriteEnable) && (waddr != `RegNumLog2'h0))
				array_reg[waddr] <= wdata;
		end
	end
	
	// 读端口1的读取逻辑
	always @ (*) begin
		if (rst == `RstEnable)
			rdata1 <= `ZeroWord;
		else if (raddr1 == `RegNumLog2'h0)  // $0寄存器始终为0
	  		rdata1 <= `ZeroWord;
		/* 如果第一个读寄存器端口要读取的目标寄存器与要写入的目的寄存器是同一个寄存器，
		   那么直接将要写入的值作为第一个读寄存器端口的输出。 */
		else if ((raddr1 == waddr) && (we == `WriteEnable) && (re1 == `ReadEnable))
	  		rdata1 <= wdata;  // 读-写冲突时，直接提供写数据
		else if (re1 == `ReadEnable)
	    	rdata1 <= array_reg[raddr1];
		else
	    	rdata1 <= `ZeroWord;
	end

	// 读端口2的读取逻辑
	always @ (*) begin
		if (rst == `RstEnable)
			rdata2 <= `ZeroWord;
		else if (raddr2 == `RegNumLog2'h0)	// $0寄存器始终为0
	  		rdata2 <= `ZeroWord;
		else if((raddr2 == waddr) && (we == `WriteEnable) && (re2 == `ReadEnable))
	  		rdata2 <= wdata;  // 读-写冲突时，直接提供写数据
		else if(re2 == `ReadEnable)
	    	rdata2 <= array_reg[raddr2];
		else
	    	rdata2 <= `ZeroWord;
	end

endmodule