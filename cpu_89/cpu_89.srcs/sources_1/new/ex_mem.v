`include "defines.vh"
`timescale 1ns / 1ps

module ex_mem(

	input clk,
	input rst,
	input [5:0] stall,
	input flush,
	
	input [`RegAddrBus] exe_waddr,		// ִ�н׶ε�Ŀ��Ĵ�����ַ
	input exe_reg_wena,  				// ִ�н׶εļĴ���дʹ��
	input [`RegBus] exe_wdata,  		// д����
	input exe_HILO_ena,  				// HI/LOдʹ��
	input [`RegBus] exe_HI, exe_LO, 	// HI/LO reg

  	input [`AluOpBus] exe_aluc_op,  	// aluc
	input [`RegBus] exe_addr,  			// �ô��ַ
	input [`RegBus] exe_op2,  			// �ڶ������������ڴ洢������

	input [`DoubleRegBus] HILOLast,  	// ��һ���ڵ�HI/LOֵ
	input [1:0] HILOCnt,  				// HI/LO�Ĵ����Ĳ���������

	input exe_cp0_wena,  				// CP0�Ĵ���дʹ�ܣ�EXE��
	input [4:0] exe_cp0_waddr,  		// CP0�Ĵ���д��ַ��EXE��
	input [`RegBus] exe_cp0_data,  		// CP0�Ĵ���д���ݣ�EXE��

  	input [31:0] exeExceptionType,  	// �쳣����
	input exeInDelaySlot,  				// �Ƿ����ӳٲ���
	input [`RegBus] exeCurInstrAddr,  	// ��ǰָ���ַ
	
	output reg[`RegAddrBus] mem_waddr,  // дĿ��Ĵ�����ַ
	output reg mem_wena,  				// дʹ��
	output reg[`RegBus] mem_data,  		// д����
	output reg[`RegBus] mem_HI, mem_LO, // HI/LO�Ĵ���
	output reg mem_HILO_ena,  			// HI/LOдʹ��

  	output reg[`AluOpBus] mem_aluc_op,  // aluc
	output reg[`RegBus] mem_addr,  		// �ô��ַ
	output reg[`RegBus] mem_op2,  		// �ڶ������������ڴ洢������
	
	output reg mem_cp0_wena,  			// CP0�Ĵ���дʹ�ܣ�MEM��
	output reg[4:0] mem_cp0_waddr, 		// CP0�Ĵ���д��ַ��MEM��
	output reg[`RegBus] mem_cp0_data,  	// CP0�Ĵ���д���ݣ�MEM��
	
	output reg[31:0] memExceptionType,  // �쳣����
  	output reg memInDelaySlot,  		// �Ƿ����ӳٲ���
	output reg[`RegBus] memCurInstrAddr,// ��ǰָ���ַ
		
	output reg[`DoubleRegBus] HILOOut,  // HI/LO�Ĵ���
	output reg[1:0] cntOut  			// HI/LO�Ĵ����Ĳ���������
);

// 	always @ (posedge clk) begin
// 		// ��λ��������Ĵ�������ΪĬ��ֵ
// 		if (rst == `RstEnable) begin
// 			mem_waddr <= `NOPRegAddr;
// 			mem_wena <= `WriteDisable;
// 			mem_data <= `ZeroWord;	
// 			mem_HI <= `ZeroWord;
// 			mem_LO <= `ZeroWord;
// 			mem_HILO_ena <= `WriteDisable;		
// 			HILOOut <= {`ZeroWord, `ZeroWord};
// 			cntOut <= 2'b00;	
//   			mem_aluc_op <= `EXE_NOP_OP;
// 			mem_addr <= `ZeroWord;
// 			mem_op2 <= `ZeroWord;	
// 			mem_cp0_wena <= `WriteDisable;
// 			mem_cp0_waddr <= 5'b00000;
// 			mem_cp0_data <= `ZeroWord;	
// 			memExceptionType <= `ZeroWord;
// 			memInDelaySlot <= `NotInDelaySlot;
// 	    	memCurInstrAddr <= `ZeroWord;
// 		end
// 		// flush�����Ե�ǰ�׶εĲ�����׼��������ָ��
// 		else if (flush == 1'b1 ) begin
// 			mem_waddr <= `NOPRegAddr;
// 			mem_wena <= `WriteDisable;
// 			mem_data <= `ZeroWord;
// 			mem_HI <= `ZeroWord;
// 			mem_LO <= `ZeroWord;
// 			mem_HILO_ena <= `WriteDisable;
//   			mem_aluc_op <= `EXE_NOP_OP;
// 			mem_addr <= `ZeroWord;
// 			mem_op2 <= `ZeroWord;
// 			mem_cp0_wena <= `WriteDisable;
// 			mem_cp0_waddr <= 5'b00000;
// 			mem_cp0_data <= `ZeroWord;
// 			memExceptionType <= `ZeroWord;
// 			memInDelaySlot <= `NotInDelaySlot;
// 	    	memCurInstrAddr <= `ZeroWord;
// 	    	HILOOut <= {`ZeroWord, `ZeroWord};
// 			cntOut <= 2'b00;	    	    				
// 		end
// 		// stall����ͣ��ǰ�׶εĲ�����������һ���ڵ�ֵ
// 		else if (stall[3] == `Stop && stall[4] == `NoStop) begin
// 			mem_waddr <= `NOPRegAddr;
// 			mem_wena <= `WriteDisable;
// 			mem_data <= `ZeroWord;
// 			mem_HI <= `ZeroWord;
// 			mem_LO <= `ZeroWord;
// 			mem_HILO_ena <= `WriteDisable;
// 			HILOOut <= HILOLast;
// 			cntOut <= HILOCnt;	
//   			mem_aluc_op <= `EXE_NOP_OP;
// 			mem_addr <= `ZeroWord;
// 			mem_op2 <= `ZeroWord;		
// 			mem_cp0_wena <= `WriteDisable;
// 			mem_cp0_waddr <= 5'b00000;
// 			mem_cp0_data <= `ZeroWord;	
// 			memExceptionType <= `ZeroWord;
// 			memInDelaySlot <= `NotInDelaySlot;
// 	    	memCurInstrAddr <= `ZeroWord;						  				    
// 		end 
// 		// ����ͣ����������ִ�н׶ε����ݺͿ����źŵ��ô�׶�
// 		else if (stall[3] == `NoStop) begin
// 			mem_waddr <= exe_waddr;
// 			mem_wena <= exe_reg_wena;
// 			mem_data <= exe_wdata;	
// 			mem_HI <= exe_HI;
// 			mem_LO <= exe_LO;
// 			mem_HILO_ena <= exe_HILO_ena;	
// 	    	HILOOut <= {`ZeroWord, `ZeroWord};
// 			cntOut <= 2'b00;	
//   			mem_aluc_op <= exe_aluc_op;
// 			mem_addr <= exe_addr;
// 			mem_op2 <= exe_op2;
// 			mem_cp0_wena <= exe_cp0_wena;
// 			mem_cp0_waddr <= exe_cp0_waddr;
// 			mem_cp0_data <= exe_cp0_data;	
// 			memExceptionType <= exeExceptionType;
// 			memInDelaySlot <= exeInDelaySlot;
// 	    	memCurInstrAddr <= exeCurInstrAddr;						
// 		end
// 		else begin
// 	    	HILOOut <= HILOLast;
// 			cntOut <= HILOCnt;											
// 		end
// 	end

// endmodule
always @ (posedge clk) begin
        if (rst == `RstEnable || flush == 1'b1) begin
            // Reset or flush logic
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
        end else if (stall[3] == `Stop && stall[4] == `NoStop) begin
            // Stall logic for this stage
            // Keep most values unchanged, except for those that might be needed
            HILOOut <= HILOLast;
			cntOut <= HILOCnt;
        end else if (stall[3] == `NoStop) begin
            // Normal operation, propagate signals from EX to MEM
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