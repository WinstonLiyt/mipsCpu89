`include "defines.vh"
`timescale 1ns / 1ps

module id_ex(

	input clk,
	input rst,
	
	input [5:0] stall,
	input flush,
	
	input id_wena,						// 写使能信号
	input [`AluOpBus] id_aluc,			// ALU控制信号
	input [`AluSelBus] id_alucSel,		// ALU选择信号
	input [`RegBus] id_op1, id_op2,		// 操作数1/2
	input [`RegAddrBus] id_wd,			// 目标寄存器地址
	input [`RegBus] idJumpAddr,			// 跳转地址
	input idInDelaySlots,				// 是否在延迟槽中
	input nxtInstrInDelaySlots,			// 下一条指令是否在延迟槽中
	input [`RegBus] idInstr,			// 当前指令
	input [`RegBus] idCurInstrAddr,		// 当前指令地址
	input [31:0] idExceptionType,		// 异常类型
	
	output reg[`AluOpBus] exe_aluc_op,	// ALU控制信号（EXE）
	output reg[`AluSelBus] exe_alucSel,	// ALU选择信号（EXE）
	output reg[`RegBus] exe_op1, exe_op2,	// 操作数1/2（EXE）
	output reg[`RegAddrBus] exe_waddr,	// 目标寄存器地址（EXE）
	output reg exe_reg_wena,			// 寄存器写使能（EXE）
	output reg[`RegBus] exeJumpAddr,	// 跳转地址（EXE）
 	output reg exeInDelaySlot,			// 是否在延迟槽中（EXE）
	output reg isInDelaySlotOut,		// 下一条指令是否在延迟槽中
	output reg[`RegBus] exeInstr,		// 当前指令（EXE）
	output reg[31:0] exeExceptionType,	// 异常类型（EXE）
	output reg[`RegBus] exeCurInstrAddr	// 当前指令地址（EXE）
	
);

// 	always @ (posedge clk) begin
// 		if (rst == `RstEnable) begin
// 			exe_aluc_op <= `EXE_NOP_OP;
// 			exe_alucSel <= `EXE_RES_NOP;
// 			exe_op1 <= `ZeroWord;
// 			exe_op2 <= `ZeroWord;
// 			exe_waddr <= `NOPRegAddr;
// 			exe_reg_wena <= `WriteDisable;
// 			exeJumpAddr <= `ZeroWord;
// 			exeInDelaySlot <= `NotInDelaySlot;
// 	    	isInDelaySlotOut <= `NotInDelaySlot;		
// 	    	exeInstr <= `ZeroWord;	
// 	    	exeExceptionType <= `ZeroWord;
// 	    	exeCurInstrAddr <= `ZeroWord;
// 		end
// 		else if(flush == 1'b1 ) begin
// 			exe_aluc_op <= `EXE_NOP_OP;
// 			exe_alucSel <= `EXE_RES_NOP;
// 			exe_op1 <= `ZeroWord;
// 			exe_op2 <= `ZeroWord;
// 			exe_waddr <= `NOPRegAddr;
// 			exe_reg_wena <= `WriteDisable;
// 			exeExceptionType <= `ZeroWord;
// 			exeJumpAddr <= `ZeroWord;
// 			exeInstr <= `ZeroWord;
// 			exeInDelaySlot <= `NotInDelaySlot;
// 	    	exeCurInstrAddr <= `ZeroWord;	
// 	    	isInDelaySlotOut <= `NotInDelaySlot;		    
// 		end
// 		else if(stall[2] == `Stop && stall[3] == `NoStop) begin
// 			exe_aluc_op <= `EXE_NOP_OP;
// 			exe_alucSel <= `EXE_RES_NOP;
// 			exe_op1 <= `ZeroWord;
// 			exe_op2 <= `ZeroWord;
// 			exe_waddr <= `NOPRegAddr;
// 			exe_reg_wena <= `WriteDisable;	
// 			exeJumpAddr <= `ZeroWord;
// 			exeInDelaySlot <= `NotInDelaySlot;
// 	    	exeInstr <= `ZeroWord;			
// 	    	exeExceptionType <= `ZeroWord;
// 	    	exeCurInstrAddr <= `ZeroWord;	
// 		end
// 		else if(stall[2] == `NoStop) begin		
// 			exe_aluc_op <= id_aluc;
// 			exe_alucSel <= id_alucSel;
// 			exe_op1 <= id_op1;
// 			exe_op2 <= id_op2;
// 			exe_waddr <= id_wd;
// 			exe_reg_wena <= id_wena;		
// 			exeJumpAddr <= idJumpAddr;
// 			exeInDelaySlot <= idInDelaySlots;
// 	    	isInDelaySlotOut <= nxtInstrInDelaySlots;
// 	    	exeInstr <= idInstr;			
// 	    	exeExceptionType <= idExceptionType;
// 	    	exeCurInstrAddr <= idCurInstrAddr;		
// 		end
// 	end
	
// endmodule

always @(posedge clk) begin
    if (rst == `RstEnable || flush == 1'b1 || (stall[2] == `Stop && stall[3] == `NoStop)) begin
        // Reset or flush pipeline stage, setting default values
        exe_aluc_op <= `EXE_NOP_OP;
        exe_alucSel <= `EXE_RES_NOP;
        exe_op1 <= `ZeroWord;
        exe_op2 <= `ZeroWord;
        exe_waddr <= `NOPRegAddr;
        exe_reg_wena <= `WriteDisable;
        exeJumpAddr <= `ZeroWord;
        exeInDelaySlot <= `NotInDelaySlot;
        isInDelaySlotOut <= `NotInDelaySlot;      
        exeInstr <= `ZeroWord;  
        exeExceptionType <= `ZeroWord;
        exeCurInstrAddr <= `ZeroWord;
    end 
	else if (stall[2] == `NoStop) begin
        // Pass ID stage values to EX stage
        exe_aluc_op <= id_aluc;
        exe_alucSel <= id_alucSel;
        exe_op1 <= id_op1;
        exe_op2 <= id_op2;
        exe_waddr <= id_wd;
        exe_reg_wena <= id_wena;       
        exeJumpAddr <= idJumpAddr;
        exeInDelaySlot <= idInDelaySlots;
        isInDelaySlotOut <= nxtInstrInDelaySlots;
        exeInstr <= idInstr;           
        exeExceptionType <= idExceptionType;
        exeCurInstrAddr <= idCurInstrAddr;
    end
end

endmodule