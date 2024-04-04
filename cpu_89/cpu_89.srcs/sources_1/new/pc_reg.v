/* -------------------------------
Func������ָ���ַ������PC�ĸ��º�ʹ���ź�
------------------------------- */

`include "defines.vh"
`timescale 1ns / 1ps

module pc_reg(

	input clk,
	input rst,

	input [5:0] stall,		// ��ˮ��ͣ�ٿ����ź�
	input flush,			// ��ˮ��ˢ���źţ����ڷ�֧Ԥ�����ʱ�Ļָ�
	input [`RegBus] pcNew,	// �µ�PCֵ��������ת�ͷ�֧

	input branch_flag_i,	// ��֧��־����ʾ�Ƿ�ִ�з�֧
	input [`RegBus] branch_target_address_i,	// ��֧Ŀ���ַ
	
	output reg[`InstAddrBus] pc,	// ��ǰ�ĳ��������ֵ
	output reg ce					// оƬʹ���ź�
	
);

	// ��תָ��
	always @ (posedge clk) begin
		// ��оƬ���ڽ���״̬ʱ����PC����Ϊָ���������ʼ��ַ
		if (ce == `ChipDisable)
			pc <= `TextBegin;
		else if (ce != `ChipDisable) begin
			// �����Ҫˢ����ˮ�ߣ���PC����Ϊ�µ�PCֵ
			if (flush == 1'b1)
				pc <= pcNew;
			// ���û��ͣ�٣����ݷ�֧��־����PCֵ
			else if(stall[0] == `NoStop) begin
				// ����з�֧����ת����֧Ŀ���ַ
				if (branch_flag_i == `Branch)
					pc <= branch_target_address_i;
				// ���û�з�֧��˳��ִ����һ��ָ��
				else
		  			pc <= pc + 4'h4;
			end
		end
	end

	// ����оƬʹ���źŵ��߼�����Ӧʱ�ӵ������غ͸�λ�ź�
	always @ (posedge clk) begin
		if (rst == `RstEnable)
			ce <= `ChipDisable;
		else
			ce <= `ChipEnable;
	end

endmodule