`include "defines.vh"
`timescale 1ns / 1ps


module pc_reg(

	input wire 					  clk,
	input wire 					  rst,

	input wire[5:0]               stall,	// ��ˮ��ͣ�ٿ����ź�
	input wire                    flush,	// ��ˮ��ˢ���źţ����ڷ�֧Ԥ�����ʱ�Ļָ�
	input wire[`RegBus]           pcNew,	// �µ�PCֵ��������ת�ͷ�֧

	input wire                    branch_flag_i,	// ��֧��־����ʾ�Ƿ�ִ�з�֧
	input wire[`RegBus]           branch_target_address_i,	// ��֧Ŀ���ַ
	
	output reg[`InstAddrBus] 	  pc,	// ��ǰ�ĳ��������ֵ
	output reg               	  ce	// оƬʹ���ź�
	
);

	always @ (posedge clk) begin
		if (ce == `ChipDisable) begin  // ��оƬ���ڽ���״̬ʱ����PC����Ϊָ���������ʼ��ַ
		// if (rst == `RstEnable) begin
			pc <= `TextBegin;
		end else if (ce != `ChipDisable) begin
			if (flush == 1'b1) begin	// �����Ҫˢ����ˮ�ߣ���PC����Ϊ�µ�PCֵ
				pc <= pcNew;
			end 
			else if(stall[0] == `NoStop) begin  // ���û��ͣ�٣����ݷ�֧��־����PCֵ
				if (branch_flag_i == `Branch) begin  // ����з�֧����ת����֧Ŀ���ַ
					pc <= branch_target_address_i;	
				end 
				else begin  // ���û�з�֧��˳��ִ����һ��ָ��
		  			pc <= pc + 4'h4;
		  		end
			end
		end
	end

	// ����оƬʹ���źŵ��߼�����Ӧʱ�ӵ������غ͸�λ�ź�
	always @ (posedge clk) begin
		if (rst == `RstEnable) begin
			ce <= `ChipDisable;
		end else begin
			ce <= `ChipEnable;
		end
	end

endmodule