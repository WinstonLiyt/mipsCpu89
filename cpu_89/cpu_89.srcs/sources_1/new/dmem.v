`include "defines.vh"
`timescale 1ns / 1ps

module dmem(
	input clk,
	input ce,						// 使能信号
	input we,						// 写使能信号
	input [`DataAddrBus] addr_in,	// 数据地址输入
	input [3:0] sel,				// 字节选择信号
	input [`DataBus] data,  		// 写入数据
	output reg[`DataBus] dataOut,  		// 读出数据
	output [`DataBus] result  		// 调试或监视目的的结果输出
);

	// 数据存储器数组，分为4个部分，分别存储32位数据的每个字节
	reg[`ByteWidth]  data_mem0[0:`DataMemNum - 1];
	reg[`ByteWidth]  data_mem1[0:`DataMemNum - 1];
	reg[`ByteWidth]  data_mem2[0:`DataMemNum - 1];
	reg[`ByteWidth]  data_mem3[0:`DataMemNum - 1];

	// 修正地址以适应数据存储器的起始位置
    wire [`DataAddrBus] addr = addr_in - `DataBegin;

	// 测试或监视用途，组合四个字节的数据以形成32位数据
    assign result = {data_mem3[0], data_mem2[0], data_mem1[0], data_mem0[0]};

	// 写数据存储器
	always @ (posedge clk) begin
		// 当芯片未使能时不执行任何操作
		if (ce == `ChipDisable) begin
		end
		// 当写使能信号为高时，根据字节选择信号写入数据
		else if(we == `WriteEnable) begin
			if (sel[3]) data_mem3[addr[`DataMemNumLog2 + 1:2]] <= data[31:24];
            if (sel[2]) data_mem2[addr[`DataMemNumLog2 + 1:2]] <= data[23:16];
            if (sel[1]) data_mem1[addr[`DataMemNumLog2 + 1:2]] <= data[15:8];
            if (sel[0]) data_mem0[addr[`DataMemNumLog2 + 1:2]] <= data[7:0];
		end
	end
	
	// 读取数据存储器
	always @ (*) begin
		// 当芯片未使能时输出零
		if (ce == `ChipDisable)
			dataOut <= `ZeroWord;
		else if (we == `WriteDisable)
		    dataOut <= {data_mem3[addr[`DataMemNumLog2 + 1:2]],
		                data_mem2[addr[`DataMemNumLog2 + 1:2]],
		                data_mem1[addr[`DataMemNumLog2 + 1:2]],
		                data_mem0[addr[`DataMemNumLog2 + 1:2]]};
		// 【注意】如果同时使能写操作，则输出零（防止在写操作周期读取数据）
		else
			dataOut <= `ZeroWord;
	end		

endmodule