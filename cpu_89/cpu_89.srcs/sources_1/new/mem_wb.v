//@func   : 
//@time   : 
//@author :

`include "defines.vh"
`timescale 1ns / 1ps

module mem_wb(

	input wire				 	 clk,
	input wire					 rst,

	input wire[5:0]              stall,	
    input wire                   flush,	

	input wire[`RegAddrBus]      mem_waddr,
	input wire                   mem_wena,
	input wire[`RegBus]			 mem_data,
	input wire[`RegBus]          mem_HI,
	input wire[`RegBus]          mem_LO,
	input wire                   mem_HILO_ena,	
	
	input wire                   mem_LLbit_we,
	input wire                   mem_LLbit_value,	

	input wire                   mem_cp0_wena,
	input wire[4:0]              mem_cp0_waddr,
	input wire[`RegBus]          mem_cp0_data,			

	output reg[`RegAddrBus]      wb_wd,
	output reg                   wb_wreg,
	output reg[`RegBus]			 wb_wdata,
	output reg[`RegBus]          wb_hi,
	output reg[`RegBus]          wb_lo,
	output reg                   wb_whilo,

	output reg                   wb_LLbit_we,
	output reg                   wb_LLbit_value,

	output reg                   wb_cp0_wena,
	output reg[4:0]              wb_cp0_waddr,
	output reg[`RegBus]          wb_cp0_data								       
	
);


	always @ (posedge clk) begin
		if(rst == `RstEnable) begin
			wb_wd <= `NOPRegAddr;
			wb_wreg <= `WriteDisable;
		  wb_wdata <= `ZeroWord;	
		  wb_hi <= `ZeroWord;
		  wb_lo <= `ZeroWord;
		  wb_whilo <= `WriteDisable;
		  wb_LLbit_we <= 1'b0;
		  wb_LLbit_value <= 1'b0;		
			wb_cp0_wena <= `WriteDisable;
			wb_cp0_waddr <= 5'b00000;
			wb_cp0_data <= `ZeroWord;			
		end else if(flush == 1'b1 ) begin
			wb_wd <= `NOPRegAddr;
			wb_wreg <= `WriteDisable;
		  wb_wdata <= `ZeroWord;
		  wb_hi <= `ZeroWord;
		  wb_lo <= `ZeroWord;
		  wb_whilo <= `WriteDisable;
		  wb_LLbit_we <= 1'b0;
		  wb_LLbit_value <= 1'b0;	
			wb_cp0_wena <= `WriteDisable;
			wb_cp0_waddr <= 5'b00000;
			wb_cp0_data <= `ZeroWord;				  				  	  	
		end else if(stall[4] == `Stop && stall[5] == `NoStop) begin
			wb_wd <= `NOPRegAddr;
			wb_wreg <= `WriteDisable;
		  wb_wdata <= `ZeroWord;
		  wb_hi <= `ZeroWord;
		  wb_lo <= `ZeroWord;
		  wb_whilo <= `WriteDisable;	
		  wb_LLbit_we <= 1'b0;
		  wb_LLbit_value <= 1'b0;	
			wb_cp0_wena <= `WriteDisable;
			wb_cp0_waddr <= 5'b00000;
			wb_cp0_data <= `ZeroWord;					  		  	  	  
		end else if(stall[4] == `NoStop) begin
			wb_wd <= mem_waddr;
			wb_wreg <= mem_wena;
			wb_wdata <= mem_data;
			wb_hi <= mem_HI;
			wb_lo <= mem_LO;
			wb_whilo <= mem_HILO_ena;		
		  wb_LLbit_we <= mem_LLbit_we;
		  wb_LLbit_value <= mem_LLbit_value;		
			wb_cp0_wena <= mem_cp0_wena;
			wb_cp0_waddr <= mem_cp0_waddr;
			wb_cp0_data <= mem_cp0_data;			  		
		end    //if
	end      //always
			

endmodule