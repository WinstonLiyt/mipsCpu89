//@func   : 
//@time   : 
//@author :

`include "defines.vh"
`timescale 1ns / 1ps

module id_ex(

	input wire					  clk,
	input wire					  rst,
	
	input wire[5:0]				  stall,
	input wire                    flush,
	
	input wire[`AluOpBus]         id_aluop,
	input wire[`AluSelBus]        id_alusel,
	input wire[`RegBus]           id_reg1,
	input wire[`RegBus]           id_reg2,
	input wire[`RegAddrBus]       id_wd,
	input wire                    id_wreg,
	input wire[`RegBus]           id_link_address,
	input wire                    id_is_in_delayslot,
	input wire                    next_inst_in_delayslot_i,		
	input wire[`RegBus]           id_inst,		
	input wire[`RegBus]           id_current_inst_address,
	input wire[31:0]              id_excepttype,
	
	output reg[`AluOpBus]         exe_aluc_op,
	output reg[`AluSelBus]        ex_alusel,
	output reg[`RegBus]           ex_reg1,
	output reg[`RegBus]           exe_op2,
	output reg[`RegAddrBus]       exe_waddr,
	output reg                    exe_reg_wena,
	output reg[`RegBus]           ex_link_address,
 	 output reg                   exeInDelaySlot,
	output reg                    isInDelaySlotOut,
	output reg[`RegBus]           ex_inst,
	output reg[31:0]              exeExceptionType,
	output reg[`RegBus]           exeCurInstrAddr	
	
);

	always @ (posedge clk) begin
		if (rst == `RstEnable) begin
			exe_aluc_op <= `EXE_NOP_OP;
			ex_alusel <= `EXE_RES_NOP;
			ex_reg1 <= `ZeroWord;
			exe_op2 <= `ZeroWord;
			exe_waddr <= `NOPRegAddr;
			exe_reg_wena <= `WriteDisable;
			ex_link_address <= `ZeroWord;
			exeInDelaySlot <= `NotInDelaySlot;
	    	isInDelaySlotOut <= `NotInDelaySlot;		
	    	ex_inst <= `ZeroWord;	
	    	exeExceptionType <= `ZeroWord;
	    	exeCurInstrAddr <= `ZeroWord;
		end else if(flush == 1'b1 ) begin
			exe_aluc_op <= `EXE_NOP_OP;
			ex_alusel <= `EXE_RES_NOP;
			ex_reg1 <= `ZeroWord;
			exe_op2 <= `ZeroWord;
			exe_waddr <= `NOPRegAddr;
			exe_reg_wena <= `WriteDisable;
			exeExceptionType <= `ZeroWord;
			ex_link_address <= `ZeroWord;
			ex_inst <= `ZeroWord;
			exeInDelaySlot <= `NotInDelaySlot;
	    	exeCurInstrAddr <= `ZeroWord;	
	    	isInDelaySlotOut <= `NotInDelaySlot;		    
		end else if(stall[2] == `Stop && stall[3] == `NoStop) begin
			exe_aluc_op <= `EXE_NOP_OP;
			ex_alusel <= `EXE_RES_NOP;
			ex_reg1 <= `ZeroWord;
			exe_op2 <= `ZeroWord;
			exe_waddr <= `NOPRegAddr;
			exe_reg_wena <= `WriteDisable;	
			ex_link_address <= `ZeroWord;
			exeInDelaySlot <= `NotInDelaySlot;
	    	ex_inst <= `ZeroWord;			
	    	exeExceptionType <= `ZeroWord;
	    	exeCurInstrAddr <= `ZeroWord;	
		end else if(stall[2] == `NoStop) begin		
			exe_aluc_op <= id_aluop;
			ex_alusel <= id_alusel;
			ex_reg1 <= id_reg1;
			exe_op2 <= id_reg2;
			exe_waddr <= id_wd;
			exe_reg_wena <= id_wreg;		
			ex_link_address <= id_link_address;
			exeInDelaySlot <= id_is_in_delayslot;
	    	isInDelaySlotOut <= next_inst_in_delayslot_i;
	    	ex_inst <= id_inst;			
	    	exeExceptionType <= id_excepttype;
	    	exeCurInstrAddr <= id_current_inst_address;		
		end
	end
	
endmodule