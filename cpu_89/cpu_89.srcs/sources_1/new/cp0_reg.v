`include "defines.vh"
`timescale 1ns / 1ps

module cp0_reg(
	input wire clk, // ʱ���ź�
    input wire rst, // ��λ�ź�

    input wire wena, // дʹ���ź�
    input wire[4:0] waddr, raddr, // д/����ַ
    input wire[`RegBus] data, // д������

    input wire[31:0] exceptionType, // �쳣����
    input wire[5:0] externalInterrupts, // �ⲿ�ж�����
    input wire[`RegBus] currentInstructionAddr, // ��ǰָ���ַ
    input wire isInDelaySlot, // �Ƿ����ӳٲ���
	
	output reg[`RegBus] dataOut, // CP0�Ĵ�����������
    output reg[`RegBus] cntOut, // ������
    output reg[`RegBus] cmpOut, // �ȽϼĴ���
    output reg[`RegBus] statusOut, // ״̬�Ĵ���
    output reg[`RegBus] causeOut, // ԭ��Ĵ���
    output reg[`RegBus] epcOut, // �쳣���������
    output reg[`RegBus] configOut, // ���üĴ���
    output reg[`RegBus] processorIDOut, // ������ID�Ĵ���

    output reg timerInterruptOut // ��ʱ���ж����   
	
);

	// ��ʼ��CP0�Ĵ���
	always @ (posedge clk) begin
		if (rst == `RstEnable) begin
			cntOut <= `ZeroWord;
			cmpOut <= `ZeroWord;
			statusOut <= 32'b00010000000000000000000000000000;
			causeOut <= `ZeroWord;
			epcOut <= `ZeroWord;
			configOut <= 32'b00000000000000001000000000000000;
			processorIDOut <= 32'b00000000010011000000000100000010;
      		timerInterruptOut <= `InterruptNotAssert;
		end
		// ���¼������ʹ����ж�����
		else begin
			cntOut <= cntOut + 1 ;
			causeOut[15:10] <= externalInterrupts;
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
					`CP0_REG_CAUSE: begin
						causeOut[9:8] <= data[9:8];
						causeOut[23] <= data[23];
						causeOut[22] <= data[22];
					end
				endcase			
			end

			// // �����쳣�������쳣���͸���CP0�Ĵ���
			// case (exceptionType)
			// 	32'h00000001: begin    // interrupt
			// 		if (isInDelaySlot == `InDelaySlot ) begin
			// 			epcOut <= currentInstructionAddr - 4 ;
			// 			causeOut[31] <= 1'b1;
			// 		end
			// 		else begin
			// 			epcOut <= currentInstructionAddr;
			// 			causeOut[31] <= 1'b0;
			// 		end
			// 		statusOut[1] <= 1'b1;
			// 		causeOut[6:2] <= 5'b00000;
			// 	end
			// 	32'h00000008: begin    // syscall
			// 		if (statusOut[1] == 1'b0) begin
			// 			if (isInDelaySlot == `InDelaySlot ) begin
			// 				epcOut <= currentInstructionAddr - 4 ;
			// 				causeOut[31] <= 1'b1;
			// 			end 
			// 			else begin
			// 		  		epcOut <= currentInstructionAddr;
			// 		  		causeOut[31] <= 1'b0;
			// 			end
			// 		end
			// 		statusOut[1] <= 1'b1;
			// 		causeOut[6:2] <= 5'b01000;			
			// 	end
			// 	32'h0000000a: begin    // inst_invalid
			// 		if (statusOut[1] == 1'b0) begin
			// 			if (isInDelaySlot == `InDelaySlot ) begin
			// 				epcOut <= currentInstructionAddr - 4 ;
			// 				causeOut[31] <= 1'b1;
			// 			end 
			// 			else begin
			// 		  		epcOut <= currentInstructionAddr;
			// 		  		causeOut[31] <= 1'b0;
			// 			end
			// 		end
			// 		statusOut[1] <= 1'b1;
			// 		causeOut[6:2] <= 5'b01010;
			// 	end
			// 	32'h0000000d: begin    // trap
			// 		if (statusOut[1] == 1'b0) begin
			// 			if (isInDelaySlot == `InDelaySlot ) begin
			// 				epcOut <= currentInstructionAddr - 4 ;
			// 				causeOut[31] <= 1'b1;
			// 			end 
			// 			else begin
			// 		  		epcOut <= currentInstructionAddr;
			// 		  		causeOut[31] <= 1'b0;
			// 			end
			// 		end
			// 		statusOut[1] <= 1'b1;
			// 		causeOut[6:2] <= 5'b01101;					
			// 	end
			// 	32'h0000000c: begin    // ov
			// 		if (statusOut[1] == 1'b0) begin
			// 			if (isInDelaySlot == `InDelaySlot ) begin
			// 				epcOut <= currentInstructionAddr - 4 ;
			// 				causeOut[31] <= 1'b1;
			// 			end 
			// 			else begin
			// 		  		epcOut <= currentInstructionAddr;
			// 		  		causeOut[31] <= 1'b0;
			// 			end
			// 		end
			// 		statusOut[1] <= 1'b1;
			// 		causeOut[6:2] <= 5'b01100;					
			// 	end				
			// 	32'h0000000e: begin       // eret
			// 		statusOut[1] <= 1'b0;
			// 	end
			// 	default: begin
			// 	end
			// endcase	
			// �쳣�����߼��Ż�
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

	// ���ݶ���ַ���CP0�Ĵ���ֵ	
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