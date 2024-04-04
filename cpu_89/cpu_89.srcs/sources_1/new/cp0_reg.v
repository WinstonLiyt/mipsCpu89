/* -----------------------------------------
Func��Э������CP0
------------------------------------------- */

`include "defines.vh"
`timescale 1ns / 1ps

module cp0_reg(
	input wire clk,
    input wire rst,

    input wire wena,
    input wire[4:0] waddr, raddr,
    input wire[`RegBus] data,

    input wire[31:0] exceptionType, 			// �쳣����
    input wire[5:0] externalInterrupts, 		// �ⲿ�ж�����
    input wire[`RegBus] currentInstructionAddr, // ��ǰָ���ַ
    input wire isInDelaySlot, 					// �Ƿ����ӳٲ���
	
	output reg[`RegBus] dataOut, 	// CP0�Ĵ�����������
    output reg[`RegBus] cntOut, 	// Count�Ĵ�����ֵ
    output reg[`RegBus] cmpOut, 	// Compare�Ĵ�����ֵ
    output reg[`RegBus] statusOut, 	// Status�Ĵ�����ֵ
    output reg[`RegBus] causeOut, 	// Cause�Ĵ�����ֵ
    output reg[`RegBus] epcOut, 	// EPC�Ĵ�����ֵ
    output reg[`RegBus] configOut, 	// Config�Ĵ�����ֵ
    output reg[`RegBus] processorIDOut, // PRId�Ĵ�����ֵ

    output reg timerInterruptOut 	// �Ƿ��ж�ʱ�жϷ���
	
);

	// ��ʼ��CP0�Ĵ���
	always @ (posedge clk) begin
		if (rst == `RstEnable) begin
			cntOut <= `ZeroWord;
			cmpOut <= `ZeroWord;
			// ����CU�ֶ�Ϊ4'b0001����ʾЭ������CP0����
			statusOut <= 32'b00010000000000000000000000000000;
			causeOut <= `ZeroWord;
			epcOut <= `ZeroWord;
			// ����BE�ֶ�Ϊ1����ʾ�����ڴ��ģʽ(MSB)
			configOut <= 32'b00000000000000001000000000000000;
			// PRId�Ĵ����ĳ�ʼֵ��������������L����Ӧ����0x48�����ж���ģ���������0x1����ʾ�ǻ������ͣ��汾����1.0
			processorIDOut <= 32'b00000000010011000000000100000010;
      		timerInterruptOut <= `InterruptNotAssert;
		end
		// ���¼������ʹ����ж�����
		else begin
			cntOut <= cntOut + 1 ;
			causeOut[15:10] <= externalInterrupts;	// Cause �ĵ�10~15bit �����ⲿ�ж�����
			// ʱ���ж�
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
					// Cause�Ĵ���ֻ��IP[1:0]��IV��WP�ֶ��ǿ�д��
					`CP0_REG_CAUSE: begin
						causeOut[9:8] <= data[9:8];
						causeOut[23] <= data[23];
						causeOut[22] <= data[22];
					end
				endcase			
			end

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