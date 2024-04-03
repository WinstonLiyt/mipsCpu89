`include "defines.vh"
`timescale 1ns / 1ps

module mem_wb(

	input clk,
	input rst,
	input [5:0] stall,	
    input flush,	

	input [`RegAddrBus] mem_waddr,		// Ŀ��Ĵ�����ַ��MEM��
	input mem_wena,						// дʹ��
	input [`RegBus] mem_data,			// д����
	input [`RegBus] mem_HI, mem_LO,		// HI,LO�Ĵ�������
	input mem_HILO_ena,					// HI,LO�Ĵ���дʹ��
	input mem_LLbit_wena,				// LLbitдʹ��
	input mem_LLbit,					// LLbitд����
	input mem_cp0_wena,					// CP0дʹ��
	input [4:0] mem_cp0_waddr,			// CP0д��ַ
	input [`RegBus] mem_cp0_data,		// CP0д����

	output reg[`RegAddrBus] wb_waddr,	// Ŀ��Ĵ�����ַ��WB��
	output reg wb_wena,					// дʹ��
	output reg[`RegBus] wb_data,		// д����
	output reg[`RegBus] wb_HI, wb_LO,	// HI,LO�Ĵ�������
	output reg wb_HILO_ena,				// HI,LO�Ĵ���дʹ��
	output reg wb_LLbit_wena,			// LLbitдʹ��			
	output reg wb_LLbit,				// LLbitд����
	output reg wb_cp0_wena,				// CP0дʹ��
	output reg[4:0] wb_cp0_waddr,		// CP0д��ַ
	output reg[`RegBus] wb_cp0_data		// CP0д����							       
	
);


	always @ (posedge clk) begin
		// �ڸ�λ��ˢ�»��ض�����ͣ�����£������������
		if (rst == `RstEnable || flush == 1'b1 || (stall[4] == `Stop && stall[5] == `NoStop)) begin
        wb_waddr <= `NOPRegAddr;
        wb_wena <= `WriteDisable;
        wb_data <= `ZeroWord;
        wb_HI <= `ZeroWord;
        wb_LO <= `ZeroWord;
        wb_HILO_ena <= `WriteDisable;
        wb_LLbit_wena <= 1'b0;
        wb_LLbit <= 1'b0;
        wb_cp0_wena <= `WriteDisable;
        wb_cp0_waddr <= 5'b00000;
        wb_cp0_data <= `ZeroWord;
		end
		// ��û����ͣ�������£���MEM�׶δ������ݵ�WB�׶�
		else if (stall[4] == `NoStop) begin
			wb_waddr <= mem_waddr;
			wb_wena <= mem_wena;
			wb_data <= mem_data;
			wb_HI <= mem_HI;
			wb_LO <= mem_LO;
			wb_HILO_ena <= mem_HILO_ena;
			wb_LLbit_wena <= mem_LLbit_wena;
			wb_LLbit <= mem_LLbit;
			wb_cp0_wena <= mem_cp0_wena;
			wb_cp0_waddr <= mem_cp0_waddr;
			wb_cp0_data <= mem_cp0_data;
		end
	end

endmodule