/* -------------------------------
Func��������ˮ�ߵ���ͣ�����
	  ����PCֵ�����ɡ�
------------------------------- */

`include "defines.vh"
`timescale 1ns / 1ps

module ctrl(
	input rst,
    input [31:0] exceptionType, // �쳣����
    input [`RegBus] cp0EPCValue, // ����CP0��EPCֵ
    input idStall, exeStall, // ����ID��EXE�׶ε���ͣ����

    output reg[`RegBus] pcNew, // �µ�PCֵ
    output reg flush, // ����ź�
    output reg[5:0] stall // ��ͣ�źţ�ȡַ��ַPC��ȡַ�����룬ִ�У��ô棬��д��
);

	// �����߼�
	always @ (*) begin
		// ��λʱ�����ͣ������źţ���PCֵ��Ϊ0
		if (rst == `RstEnable) begin
			stall <= 6'b000000;
			flush <= 1'b0;
			pcNew <= `ZeroWord;
		end 
		// ���쳣����ʱ
		else if (exceptionType != `ZeroWord) begin
		  	flush <= 1'b1;
		  	stall <= 6'b000000;
			// �����쳣���;����µ�PCֵ
			case (exceptionType)
				32'h00000001, // interrupt
                32'h00000008, // syscall
                32'h0000000a, // inst_invalid
                32'h0000000d, // trap
                32'h0000000c: // ov
                    pcNew <= `ExceptionBegin; // ����PC����Ϊ�쳣������ʼ��ַ
                32'h0000000e: // eret
                    pcNew <= cp0EPCValue; // ���ص��쳣����ǰ�ĵ�ַ
                default: ;
			endcase 						
		end 
		// exe�׶�������ͣ
		else if (exeStall == `Stop) begin
			stall <= 6'b001111;
			flush <= 1'b0;		
		end 
		// id�׶�������ͣ
		else if (idStall == `Stop) begin
			stall <= 6'b000111;	
			flush <= 1'b0;		
		end
		// ��������
		else begin
			stall <= 6'b000000;
			flush <= 1'b0;
			pcNew <= `ZeroWord;		
		end
	end

endmodule