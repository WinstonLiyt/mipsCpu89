`include "defines.vh"
`timescale 1ns / 1ps

module dmem(
	input clk,
	input ce,						// ʹ���ź�
	input we,						// дʹ���ź�
	input [`DataAddrBus] addr_in,	// ���ݵ�ַ����
	input [3:0] sel,				// �ֽ�ѡ���ź�
	input [`DataBus] data,  		// д������
	output reg[`DataBus] dataOut,  		// ��������
	output [`DataBus] result  		// ���Ի����Ŀ�ĵĽ�����
);

	// ���ݴ洢�����飬��Ϊ4�����֣��ֱ�洢32λ���ݵ�ÿ���ֽ�
	reg[`ByteWidth]  data_mem0[0:`DataMemNum - 1];
	reg[`ByteWidth]  data_mem1[0:`DataMemNum - 1];
	reg[`ByteWidth]  data_mem2[0:`DataMemNum - 1];
	reg[`ByteWidth]  data_mem3[0:`DataMemNum - 1];

	// ������ַ����Ӧ���ݴ洢������ʼλ��
    wire [`DataAddrBus] addr = addr_in - `DataBegin;

	// ���Ի������;������ĸ��ֽڵ��������γ�32λ����
    assign result = {data_mem3[0], data_mem2[0], data_mem1[0], data_mem0[0]};

	// д���ݴ洢��
	always @ (posedge clk) begin
		// ��оƬδʹ��ʱ��ִ���κβ���
		if (ce == `ChipDisable) begin
		end
		// ��дʹ���ź�Ϊ��ʱ�������ֽ�ѡ���ź�д������
		else if(we == `WriteEnable) begin
			if (sel[3]) data_mem3[addr[`DataMemNumLog2 + 1:2]] <= data[31:24];
            if (sel[2]) data_mem2[addr[`DataMemNumLog2 + 1:2]] <= data[23:16];
            if (sel[1]) data_mem1[addr[`DataMemNumLog2 + 1:2]] <= data[15:8];
            if (sel[0]) data_mem0[addr[`DataMemNumLog2 + 1:2]] <= data[7:0];
		end
	end
	
	// ��ȡ���ݴ洢��
	always @ (*) begin
		// ��оƬδʹ��ʱ�����
		if (ce == `ChipDisable)
			dataOut <= `ZeroWord;
		else if (we == `WriteDisable)
		    dataOut <= {data_mem3[addr[`DataMemNumLog2 + 1:2]],
		                data_mem2[addr[`DataMemNumLog2 + 1:2]],
		                data_mem1[addr[`DataMemNumLog2 + 1:2]],
		                data_mem0[addr[`DataMemNumLog2 + 1:2]]};
		// ��ע�⡿���ͬʱʹ��д������������㣨��ֹ��д�������ڶ�ȡ���ݣ�
		else
			dataOut <= `ZeroWord;
	end		

endmodule