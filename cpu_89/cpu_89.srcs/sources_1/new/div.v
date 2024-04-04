/* -------------------------------
Func：执行有符号或无符号的32位除法。
	  （试商法）
------------------------------- */

`include "defines.vh"
`timescale 1ns / 1ps

module div(
	input clk, // 时钟信号
    input rst, // 复位信号
    
    input isSignedDivision, 				// 是否进行有符号除法
    input [31:0] dividend, divisor, 		// 被除数与除数
    input startDivision, cancelDivision, 	// 开始/取消当前除法操作信号
    output reg [63:0] res, 					// 除法结果（包括商和余数）
    output reg resReady 					// 结果准备好的信号
);

	wire [32:0] tmp; 			// 用于存储每一步减法的临时结果
    reg [5:0] cnt; 				// 记录试商法进行了几轮，当等于32时，表示试商法结束
    reg [64:0] dividendtmp; 	// 存储被除数和部分余数
	reg [31:0] divisortmp; 		// 存储除数
    reg [1:0] state; 			// 除法器的状态
    reg [31:0] temp_op1, temp_op2; // 临时存储处理过的被除数和除数
	
	// 临时结果的计算
	assign tmp = {1'b0, dividendtmp[63:32]} - {1'b0, divisortmp};

	always @ (posedge clk) begin
		if (rst == `RstEnable) begin
			state <= `DivFree;
			resReady <= `DivResultNotReady;
			res <= 64'b0;
		end 
		else begin
			case (state)
			/* 空闲 */
		  	`DivFree: begin
		  		if (startDivision == `DivStart && cancelDivision == 1'b0) begin
		  			if (divisor == `ZeroWord)  // 除零错误
		  				state <= `DivByZero;
					else begin
		  				state <= `DivOn;  // 开始除法操作
		  				cnt <= 6'b000000;
						// 如果进行有符号除法且操作数为负数，则在开始时取反加一（二进制补码），计算完成后再次处理符号得到正确结果。
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
			/* 除零错误 */
		  	`DivByZero: begin
         			dividendtmp <= 65'b0;
          			state <= `DivEnd;		 		
		  	end
			/* 除法操作 */
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
			/* 结束 */
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