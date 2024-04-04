/* -----------------------------------------
Func����ʱ����ȡָ�׶�ȡ�õ�ָ��Լ� ��Ӧ��ָ��
	  ��ַ��������һ��ʱ�Ӵ��ݵ�����׶�
------------------------------------------- */

`include "defines.vh"
`timescale 1ns / 1ps

module if_id(

	input clk,
	input rst,
	input [5:0] stall,	
	input flush,

	input [`InstAddrBus] if_pc,		// IF�׶ε�PCֵ
	input [`InstBus] ifInstr,		// IF�׶ε�ָ��
	output reg[`InstAddrBus] id_pc,	// ID�׶ε�PCֵ
	output reg[`InstBus] idInstr	// ID�׶ε�ָ��
);
	always @ (posedge clk) begin
		// �����λ����ˮ��ˢ�£��쳣�������ض�����ͣ����������������id_pc��idInstr
		if (rst == `RstEnable || flush == 1'b1 || (stall[1] == `Stop && stall[2] == `NoStop)) begin
			id_pc <= `ZeroWord;
			idInstr <= `ZeroWord;
		end 
		else if (stall[1] == `NoStop) begin
			id_pc <= if_pc;
			idInstr <= ifInstr;
		end
	end

endmodule