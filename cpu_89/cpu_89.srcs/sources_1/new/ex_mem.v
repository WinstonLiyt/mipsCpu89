/* -----------------------------------------
Func：将执行阶段取得的运算结果，在下一个时钟传递
	  到流水线访存阶段。
------------------------------------------- */

`include "defines.vh"
`timescale 1ns / 1ps

module ex_mem(
	input clk,
	input rst,
	input [5:0] stall,
	input flush,
	
	input [`RegAddrBus] exe_waddr,		// 执行阶段的目标寄存器地址
	input exe_reg_wena,  				// 执行阶段的寄存器写使能
	input [`RegBus] exe_wdata,  		// 写数据
	input exe_HILO_ena,  				// HI/LO写使能
	input [`RegBus] exe_HI, exe_LO, 	// HI/LO reg

  	input [`AluOpBus] exe_aluc_op,  	// aluc
	input [`RegBus] exe_addr,  			// 访存地址
	input [`RegBus] exe_op2,  			// 第二操作数（用于存储操作）

	input [`DoubleRegBus] HILOLast,  	// 上一周期的HI/LO值
	input [1:0] HILOCnt,  				// HI/LO寄存器的操作计数器

	input exe_cp0_wena,  				// CP0寄存器写使能（EXE）
	input [4:0] exe_cp0_waddr,  		// CP0寄存器写地址（EXE）
	input [`RegBus] exe_cp0_data,  		// CP0寄存器写数据（EXE）

  	input [31:0] exeExceptionType,  	// 异常类型
	input exeInDelaySlot,  				// 是否在延迟槽中
	input [`RegBus] exeCurInstrAddr,  	// 当前指令地址
	
	output reg[`RegAddrBus] mem_waddr,  // 写目标寄存器地址
	output reg mem_wena,  				// 写使能
	output reg[`RegBus] mem_data,  		// 写数据
	output reg[`RegBus] mem_HI, mem_LO, // HI/LO寄存器
	output reg mem_HILO_ena,  			// HI/LO写使能

  	output reg[`AluOpBus] mem_aluc_op,  // aluc
	output reg[`RegBus] mem_addr,  		// 访存地址
	output reg[`RegBus] mem_op2,  		// 第二操作数（用于存储操作）
	
	output reg mem_cp0_wena,  			// CP0寄存器写使能（MEM）
	output reg[4:0] mem_cp0_waddr, 		// CP0寄存器写地址（MEM）
	output reg[`RegBus] mem_cp0_data,  	// CP0寄存器写数据（MEM）
	
	output reg[31:0] memExceptionType,  // 异常类型
  	output reg memInDelaySlot,  		// 是否在延迟槽中
	output reg[`RegBus] memCurInstrAddr,// 当前指令地址
		
	output reg[`DoubleRegBus] HILOOut,  // HI/LO寄存器
	output reg[1:0] cntOut  			// HI/LO寄存器的操作计数器
);

always @ (posedge clk) begin
        if (rst == `RstEnable || flush == 1'b1) begin
            mem_waddr <= `NOPRegAddr;
            mem_wena <= `WriteDisable;
            mem_data <= `ZeroWord;
            mem_HI <= `ZeroWord;
            mem_LO <= `ZeroWord;
            mem_HILO_ena <= `WriteDisable;
  			mem_aluc_op <= `EXE_NOP_OP;
			mem_addr <= `ZeroWord;
			mem_op2 <= `ZeroWord;
			mem_cp0_wena <= `WriteDisable;
			mem_cp0_waddr <= 5'b00000;
			mem_cp0_data <= `ZeroWord;
			memExceptionType <= `ZeroWord;
			memInDelaySlot <= `NotInDelaySlot;
	    	memCurInstrAddr <= `ZeroWord;
            HILOOut <= {`ZeroWord, `ZeroWord};
			cntOut <= 2'b00;	    	
        end 
		else if (stall[3] == `Stop && stall[4] == `NoStop) begin
            HILOOut <= HILOLast;
			cntOut <= HILOCnt;
        end 
		else if (stall[3] == `NoStop) begin
            mem_waddr <= exe_waddr;
            mem_wena <= exe_reg_wena;
            mem_data <= exe_wdata;	
            mem_HI <= exe_HI;
            mem_LO <= exe_LO;
            mem_HILO_ena <= exe_HILO_ena;	
            mem_aluc_op <= exe_aluc_op;
            mem_addr <= exe_addr;
            mem_op2 <= exe_op2;
            mem_cp0_wena <= exe_cp0_wena;
            mem_cp0_waddr <= exe_cp0_waddr;
            mem_cp0_data <= exe_cp0_data;	
            memExceptionType <= exeExceptionType;
            memInDelaySlot <= exeInDelaySlot;
            memCurInstrAddr <= exeCurInstrAddr;						
            HILOOut <= {`ZeroWord, `ZeroWord};
            cntOut <= 2'b00;
        end
    end

endmodule