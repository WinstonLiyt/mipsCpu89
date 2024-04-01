`include "defines.vh"
`timescale 1ns / 1ps

module regfile(
    input wire clk, // ʱ���ź�
    input wire rst, // ��λ�ź�

    input wire we, 					// дʹ���ź�
    input wire[`RegAddrBus] waddr, 	// д��ַ
    input wire[`RegBus] wdata, 		// д����
    
    input wire re1, 				// ���˿�1ʹ���ź�
    input wire[`RegAddrBus] raddr1, // ����ַ1
    output reg[`RegBus] rdata1, 	// ������1
    
    input wire re2, 				// ���˿�2ʹ���ź�
    input wire[`RegAddrBus] raddr2, // ����ַ2
    output reg[`RegBus] rdata2 		// ������2
);

	// �Ĵ��������������洢32��32λ��ļĴ���
	reg[`RegBus] array_reg[0:`RegNum - 1];

	initial begin
		array_reg[0] <= 32'b0;
		array_reg[1] <= 32'b0;
		array_reg[2] <= 32'b0;
		array_reg[3] <= 32'b0;
		array_reg[4] <= 32'b0;
		array_reg[5] <= 32'b0;
		array_reg[6] <= 32'b0;
		array_reg[7] <= 32'b0;
		array_reg[8] <= 32'b0;
		array_reg[9] <= 32'b0;
		array_reg[10] <= 32'b0;
		array_reg[11] <= 32'b0;
		array_reg[12] <= 32'b0;
		array_reg[13] <= 32'b0;
		array_reg[14] <= 32'b0;
		array_reg[15] <= 32'b0;
		array_reg[16] <= 32'b0;
		array_reg[17] <= 32'b0;
		array_reg[18] <= 32'b0;
		array_reg[19] <= 32'b0;
		array_reg[20] <= 32'b0;
		array_reg[21] <= 32'b0;
		array_reg[22] <= 32'b0;
		array_reg[23] <= 32'b0;
		array_reg[24] <= 32'b0;
		array_reg[25] <= 32'b0;
		array_reg[26] <= 32'b0;
		array_reg[27] <= 32'b0;
		array_reg[28] <= 32'b0;
		array_reg[29] <= 32'b0;
		array_reg[30] <= 32'b0; 
		array_reg[31] <= 32'b0;
	end

    // initial begin
    //     array_reg[0] <= 0; array_reg[1] <= 0; array_reg[2] <= 0; array_reg[3] <= 0; array_reg[4] <= 0;
    //     array_reg[5] <= 0; array_reg[6] <= 0; array_reg[7] <= 0; array_reg[8] <= 0; array_reg[9] <= 0;
    //     array_reg[10] <= 0; array_reg[11] <= 0; array_reg[12] <= 0; array_reg[13] <= 0; array_reg[14] <= 0;
    //     array_reg[15] <= 0; array_reg[16] <= 0; array_reg[17] <= 0; array_reg[18] <= 0; array_reg[19] <= 0;
    //     array_reg[20] <= 0; array_reg[21] <= 0; array_reg[22] <= 0; array_reg[23] <= 0; array_reg[24] <= 0;
    //     array_reg[25] <= 0; array_reg[26] <= 0; array_reg[27] <= 0; array_reg[28] <= 0; array_reg[29] <= 0;
    //     array_reg[30] <= 0; array_reg[31] <= 0;
    // end
	// ��ʼ�����мĴ���Ϊ0
    // initial begin
    //     integer i;
    //     for (i = 0; i < `RegNum; i = i + 1) begin
    //         array_reg[i] <= 0;
    //     end
    // end

	// д��������ʱ���������Ҹ�λ�ź�Ϊ�Ǽ���״̬�£����дʹ����д��ַ��0������¼Ĵ���ֵ
	always @ (posedge clk) begin
		if (rst == `RstDisable) begin
			if ((we == `WriteEnable) && (waddr != `RegNumLog2'h0)) begin
				array_reg[waddr] <= wdata;
			end
		end
	end
	
	// ���˿�1�Ķ�ȡ�߼�
	always @ (*) begin
		if (rst == `RstEnable) begin
			rdata1 <= `ZeroWord;
	  	end 
		else if (raddr1 == `RegNumLog2'h0) begin
	  		rdata1 <= `ZeroWord;
	  	end
		else if((raddr1 == waddr) && (we == `WriteEnable) && (re1 == `ReadEnable)) begin
	  		rdata1 <= wdata;  // ��-д��ͻʱ��ֱ���ṩд����
	  	end
		else if(re1 == `ReadEnable) begin
	    	rdata1 <= array_reg[raddr1];
	  	end
		else begin
	    	rdata1 <= `ZeroWord;
	  	end
	end

	// ���˿�2�Ķ�ȡ�߼�
	always @ (*) begin
		if (rst == `RstEnable) begin
			rdata2 <= `ZeroWord;
	  	end
		else if (raddr2 == `RegNumLog2'h0) begin
	  		rdata2 <= `ZeroWord;
	  	end
		else if((raddr2 == waddr) && (we == `WriteEnable) && (re2 == `ReadEnable)) begin
	  		rdata2 <= wdata;  // ��-д��ͻʱ��ֱ���ṩд����
	  	end
		else if(re2 == `ReadEnable) begin
	    	rdata2 <= array_reg[raddr2];
	  	end
		else begin
	    	rdata2 <= `ZeroWord;
	  	end
	end

endmodule