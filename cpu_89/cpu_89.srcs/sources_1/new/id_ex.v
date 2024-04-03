`include "defines.vh"
`timescale 1ns / 1ps

module id_ex(

	input clk,
	input rst,
	
	input [5:0] stall,
	input flush,
	
	input id_wena,						// дʹ���ź�
	input [`AluOpBus] id_aluc,			// ALU�����ź�
	input [`AluSelBus] id_alucSel,		// ALUѡ���ź�
	input [`RegBus] id_op1, id_op2,		// ������1/2
	input [`RegAddrBus] id_wd,			// Ŀ��Ĵ�����ַ
	input [`RegBus] idJumpAddr,			// ��ת��ַ
	input idInDelaySlots,				// �Ƿ����ӳٲ���
	input nxtInstrInDelaySlots,			// ��һ��ָ���Ƿ����ӳٲ���
	input [`RegBus] idInstr,			// ��ǰָ��
	input [`RegBus] idCurInstrAddr,		// ��ǰָ���ַ
	input [31:0] idExceptionType,		// �쳣����
	
	output reg[`AluOpBus] exe_aluc_op,	// ALU�����źţ�EXE��
	output reg[`AluSelBus] exe_alucSel,	// ALUѡ���źţ�EXE��
	output reg[`RegBus] exe_op1, exe_op2,	// ������1/2��EXE��
	output reg[`RegAddrBus] exe_waddr,	// Ŀ��Ĵ�����ַ��EXE��
	output reg exe_reg_wena,			// �Ĵ���дʹ�ܣ�EXE��
	output reg[`RegBus] exeJumpAddr,	// ��ת��ַ��EXE��
 	output reg exeInDelaySlot,			// �Ƿ����ӳٲ��У�EXE��
	output reg isInDelaySlotOut,		// ��һ��ָ���Ƿ����ӳٲ���
	output reg[`RegBus] exeInstr,		// ��ǰָ�EXE��
	output reg[31:0] exeExceptionType,	// �쳣���ͣ�EXE��
	output reg[`RegBus] exeCurInstrAddr	// ��ǰָ���ַ��EXE��
	
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