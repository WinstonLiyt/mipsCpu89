/* -------------------------------
Func��ִ���з��Ż��޷��ŵ�32λ������
	  �����̷���
------------------------------- */

`include "defines.vh"
`timescale 1ns / 1ps

module div(
	input clk, // ʱ���ź�
    input rst, // ��λ�ź�
    
    input isSignedDivision, 				// �Ƿ�����з��ų���
    input [31:0] dividend, divisor, 		// �����������
    input startDivision, cancelDivision, 	// ��ʼ/ȡ����ǰ���������ź�
    output reg [63:0] res, 					// ��������������̺�������
    output reg resReady 					// ���׼���õ��ź�
);

	wire [32:0] tmp; 			// ���ڴ洢ÿһ����������ʱ���
    reg [5:0] cnt; 				// ��¼���̷������˼��֣�������32ʱ����ʾ���̷�����
    reg [64:0] dividendtmp; 	// �洢�������Ͳ�������
	reg [31:0] divisortmp; 		// �洢����
    reg [1:0] state; 			// ��������״̬
    reg [31:0] temp_op1, temp_op2; // ��ʱ�洢������ı������ͳ���
	
	// ��ʱ����ļ���
	assign tmp = {1'b0, dividendtmp[63:32]} - {1'b0, divisortmp};

	always @ (posedge clk) begin
		if (rst == `RstEnable) begin
			state <= `DivFree;
			resReady <= `DivResultNotReady;
			res <= 64'b0;
		end 
		else begin
			case (state)
			/* ���� */
		  	`DivFree: begin
		  		if (startDivision == `DivStart && cancelDivision == 1'b0) begin
		  			if (divisor == `ZeroWord)  // �������
		  				state <= `DivByZero;
					else begin
		  				state <= `DivOn;  // ��ʼ��������
		  				cnt <= 6'b000000;
						// ��������з��ų����Ҳ�����Ϊ���������ڿ�ʼʱȡ����һ�������Ʋ��룩��������ɺ��ٴδ�����ŵõ���ȷ�����
		  				temp_op1 = isSignedDivision && dividend[31] ? ~dividend + 1 : dividend;
		  				temp_op2 = isSignedDivision && divisor[31] ? ~divisor + 1 : divisor;
		  				dividendtmp <= {`ZeroWord,`ZeroWord};
              			dividendtmp [32:1] <= temp_op1;
              			divisortmp <= temp_op2;
            		end
          		end
				else begin
					resReady <= `DivResultNotReady;
					res <= 64'b0;
				end          	
		  	end
			/* ������� */
		  	`DivByZero: begin
         			dividendtmp <= 65'b0;
          			state <= `DivEnd;		 		
		  	end
			/* �������� */
		  	`DivOn: begin
		  		if (cancelDivision == 1'b0) begin
		  			if (cnt != 6'b100000) begin
               			dividendtmp <= tmp[32] ? {dividendtmp[63:0], 1'b0} : {tmp[31:0], dividendtmp[31:0], 1'b1};
               			cnt <= cnt + 1;
             		end 
					else begin
               			if ((isSignedDivision == 1'b1) && ((dividend[31] ^ divisor[31]) == 1'b1))
                  			dividendtmp[31:0] <= (~dividendtmp[31:0] + 1);
               			if ((isSignedDivision == 1'b1) && ((dividend[31] ^ dividendtmp[64]) == 1'b1))
                  			dividendtmp[64:33] <= (~dividendtmp[64:33] + 1);
						state <= `DivEnd;
						cnt <= 6'b000000;            	
             		end
		  		end 
				else
		  			state <= `DivFree;
		  	end
			/* ���� */
		  	`DivEnd: begin
        		res <= {dividendtmp[64:33], dividendtmp[31:0]};  
          		resReady <= `DivResultReady;
          		if (startDivision == `DivStop) begin
          			state <= `DivFree;
					resReady <= `DivResultNotReady;
					res <= 64'b0;     	
          		end		  	
		  	end
			endcase
		end
	end

endmodule