`include "defines.vh"
`timescale 1ns / 1ps


module mem(

	input wire					 rst,
	
	input wire[`RegAddrBus]      EXE_waddr,
	input wire                   EXE_wena,
	input wire[`RegBus]			 wdata_i,
	input wire[`RegBus]          regHI,
	input wire[`RegBus]          regLO,
	input wire                   whilo_i,	

 	input wire[`AluOpBus]        aluc,
	input wire[`RegBus]          mem_addr_i,
	input wire[`RegBus]          op2,
	
	input wire[`RegBus]          mem_data_i,

	input wire                   LLbit_i,
	input wire                 	 wb_LLbit_we_i,
	input wire                 	 wb_LLbit_value_i,

	input wire                   cp0_reg_we_i,
	input wire[4:0]              cp0_reg_write_addr_i,
	input wire[`RegBus]          cp0_reg_data_in,
	
	input wire[31:0]             exceptionType,
	input wire                   isInDelaySlot,
	input wire[`RegBus]          curInstrAddr,	
	
	input wire[`RegBus]          cp0_status_i,
	input wire[`RegBus]          cp0_cause_i,
	input wire[`RegBus]          cp0EPCValue,

  	input wire                   wb_cp0_wena,
	input wire[4:0]              wb_cp0_waddr,
	input wire[`RegBus]          wb_cp0_data,
	
	output reg[`RegAddrBus]      wd_out,
	output reg                   reg_wena,
	output reg[`RegBus]			 wdata_out,
	output reg[`RegBus]          HI_out,
	output reg[`RegBus]          LO_out,
	output reg                   HILO_ena_out,

	output reg                   LLbit_we_o,
	output reg                   LLbit_value_o,

	output reg                   cp0_reg_wena_out,
	output reg[4:0]              cp0_reg_waddr_out,
	output reg[`RegBus]          cp0_reg_data_out,
	
	output reg[`RegBus]          mem_addr_out,
	output wire					 mem_we_o,
	output reg[3:0]              mem_sel_o,
	output reg[`RegBus]          mem_data_o,
	output reg                   mem_ce_o,
	
	output reg[31:0]             exceptionTypeOut,
	output wire[`RegBus]          cp0_epc_o,
	output wire                  isInDelaySlotOut,
	
	output wire[`RegBus]         curInstrAddrOut		
	
);

  	reg 			      LLbit;
	wire[`RegBus] 	      zero32;
	reg[`RegBus]          cp0_status;
	reg[`RegBus]          cp0_cause;
	reg[`RegBus]          cp0_epc;	
	reg                   mem_we;

	assign mem_we_o = mem_we & (~(|exceptionTypeOut));
	assign zero32 = `ZeroWord;

	assign isInDelaySlotOut = isInDelaySlot;
	assign curInstrAddrOut = curInstrAddr;
	assign cp0_epc_o = cp0_epc;

  //????????LLbit???
	always @ (*) begin
		if(rst == `RstEnable) begin
			LLbit <= 1'b0;
		end else begin
			if(wb_LLbit_we_i == 1'b1) begin
				LLbit <= wb_LLbit_value_i;
			end else begin
				LLbit <= LLbit_i;
			end
		end
	end
	
	always @ (*) begin
		if(rst == `RstEnable) begin
			wd_out <= `NOPRegAddr;
			reg_wena <= `WriteDisable;
		  wdata_out <= `ZeroWord;
		  HI_out <= `ZeroWord;
		  LO_out <= `ZeroWord;
		  HILO_ena_out <= `WriteDisable;		
		  mem_addr_out <= `ZeroWord;
		  mem_we <= `WriteDisable;
		  mem_sel_o <= 4'b0000;
		  mem_data_o <= `ZeroWord;		
		  mem_ce_o <= `ChipDisable;
		  LLbit_we_o <= 1'b0;
		  LLbit_value_o <= 1'b0;		
		  cp0_reg_wena_out <= `WriteDisable;
		  cp0_reg_waddr_out <= 5'b00000;
		  cp0_reg_data_out <= `ZeroWord;		        
		end else begin
		  wd_out <= EXE_waddr;
			reg_wena <= EXE_wena;
			wdata_out <= wdata_i;
			HI_out <= regHI;
			LO_out <= regLO;
			HILO_ena_out <= whilo_i;		
			mem_we <= `WriteDisable;
			mem_addr_out <= `ZeroWord;
			mem_sel_o <= 4'b1111;
			mem_ce_o <= `ChipDisable;
		  LLbit_we_o <= 1'b0;
		  LLbit_value_o <= 1'b0;		
		  cp0_reg_wena_out <= cp0_reg_we_i;
		  cp0_reg_waddr_out <= cp0_reg_write_addr_i;
		  cp0_reg_data_out <= cp0_reg_data_in;		 		  	
			case (aluc)
				`EXE_LB_OP:		begin
					mem_addr_out <= mem_addr_i;
					mem_we <= `WriteDisable;
					mem_ce_o <= `ChipEnable;
					case (mem_addr_i[1:0])
						2'b00:	begin
							wdata_out <= {{24{mem_data_i[31]}},mem_data_i[31:24]};
							mem_sel_o <= 4'b1000;
						end
						2'b01:	begin
							wdata_out <= {{24{mem_data_i[23]}},mem_data_i[23:16]};
							mem_sel_o <= 4'b0100;
						end
						2'b10:	begin
							wdata_out <= {{24{mem_data_i[15]}},mem_data_i[15:8]};
							mem_sel_o <= 4'b0010;
						end
						2'b11:	begin
							wdata_out <= {{24{mem_data_i[7]}},mem_data_i[7:0]};
							mem_sel_o <= 4'b0001;
						end
						default:	begin
							wdata_out <= `ZeroWord;
						end
					endcase
				end
				`EXE_LBU_OP:		begin
					mem_addr_out <= mem_addr_i;
					mem_we <= `WriteDisable;
					mem_ce_o <= `ChipEnable;
					case (mem_addr_i[1:0])
						2'b00:	begin
							wdata_out <= {{24{1'b0}},mem_data_i[31:24]};
							mem_sel_o <= 4'b1000;
						end
						2'b01:	begin
							wdata_out <= {{24{1'b0}},mem_data_i[23:16]};
							mem_sel_o <= 4'b0100;
						end
						2'b10:	begin
							wdata_out <= {{24{1'b0}},mem_data_i[15:8]};
							mem_sel_o <= 4'b0010;
						end
						2'b11:	begin
							wdata_out <= {{24{1'b0}},mem_data_i[7:0]};
							mem_sel_o <= 4'b0001;
						end
						default:	begin
							wdata_out <= `ZeroWord;
						end
					endcase				
				end
				`EXE_LH_OP:		begin
					mem_addr_out <= mem_addr_i;
					mem_we <= `WriteDisable;
					mem_ce_o <= `ChipEnable;
					case (mem_addr_i[1:0])
						2'b00:	begin
							wdata_out <= {{16{mem_data_i[31]}},mem_data_i[31:16]};
							mem_sel_o <= 4'b1100;
						end
						2'b10:	begin
							wdata_out <= {{16{mem_data_i[15]}},mem_data_i[15:0]};
							mem_sel_o <= 4'b0011;
						end
						default:	begin
							wdata_out <= `ZeroWord;
						end
					endcase					
				end
				`EXE_LHU_OP:		begin
					mem_addr_out <= mem_addr_i;
					mem_we <= `WriteDisable;
					mem_ce_o <= `ChipEnable;
					case (mem_addr_i[1:0])
						2'b00:	begin
							wdata_out <= {{16{1'b0}},mem_data_i[31:16]};
							mem_sel_o <= 4'b1100;
						end
						2'b10:	begin
							wdata_out <= {{16{1'b0}},mem_data_i[15:0]};
							mem_sel_o <= 4'b0011;
						end
						default:	begin
							wdata_out <= `ZeroWord;
						end
					endcase				
				end
				`EXE_LW_OP:		begin
					mem_addr_out <= mem_addr_i;
					mem_we <= `WriteDisable;
					wdata_out <= mem_data_i;
					mem_sel_o <= 4'b1111;		
					mem_ce_o <= `ChipEnable;
				end
				`EXE_LWL_OP:		begin
					mem_addr_out <= {mem_addr_i[31:2], 2'b00};
					mem_we <= `WriteDisable;
					mem_sel_o <= 4'b1111;
					mem_ce_o <= `ChipEnable;
					case (mem_addr_i[1:0])
						2'b00:	begin
							wdata_out <= mem_data_i[31:0];
						end
						2'b01:	begin
							wdata_out <= {mem_data_i[23:0],op2[7:0]};
						end
						2'b10:	begin
							wdata_out <= {mem_data_i[15:0],op2[15:0]};
						end
						2'b11:	begin
							wdata_out <= {mem_data_i[7:0],op2[23:0]};	
						end
						default:	begin
							wdata_out <= `ZeroWord;
						end
					endcase				
				end
				`EXE_LWR_OP:		begin
					mem_addr_out <= {mem_addr_i[31:2], 2'b00};
					mem_we <= `WriteDisable;
					mem_sel_o <= 4'b1111;
					mem_ce_o <= `ChipEnable;
					case (mem_addr_i[1:0])
						2'b00:	begin
							wdata_out <= {op2[31:8],mem_data_i[31:24]};
						end
						2'b01:	begin
							wdata_out <= {op2[31:16],mem_data_i[31:16]};
						end
						2'b10:	begin
							wdata_out <= {op2[31:24],mem_data_i[31:8]};
						end
						2'b11:	begin
							wdata_out <= mem_data_i;	
						end
						default:	begin
							wdata_out <= `ZeroWord;
						end
					endcase					
				end
				`EXE_LL_OP:		begin
					mem_addr_out <= mem_addr_i;
					mem_we <= `WriteDisable;
					wdata_out <= mem_data_i;	
		  		LLbit_we_o <= 1'b1;
		  		LLbit_value_o <= 1'b1;
		  		mem_sel_o <= 4'b1111;					
		  		mem_ce_o <= `ChipEnable;				
				end				
				`EXE_SB_OP:		begin
					mem_addr_out <= mem_addr_i;
					mem_we <= `WriteEnable;
					mem_data_o <= {op2[7:0],op2[7:0],op2[7:0],op2[7:0]};
					mem_ce_o <= `ChipEnable;
					case (mem_addr_i[1:0])
						2'b00:	begin
							mem_sel_o <= 4'b1000;
						end
						2'b01:	begin
							mem_sel_o <= 4'b0100;
						end
						2'b10:	begin
							mem_sel_o <= 4'b0010;
						end
						2'b11:	begin
							mem_sel_o <= 4'b0001;	
						end
						default:	begin
							mem_sel_o <= 4'b0000;
						end
					endcase				
				end
				`EXE_SH_OP:		begin
					mem_addr_out <= mem_addr_i;
					mem_we <= `WriteEnable;
					mem_data_o <= {op2[15:0],op2[15:0]};
					mem_ce_o <= `ChipEnable;
					case (mem_addr_i[1:0])
						2'b00:	begin
							mem_sel_o <= 4'b1100;
						end
						2'b10:	begin
							mem_sel_o <= 4'b0011;
						end
						default:	begin
							mem_sel_o <= 4'b0000;
						end
					endcase						
				end
				`EXE_SW_OP:		begin
					mem_addr_out <= mem_addr_i;
					mem_we <= `WriteEnable;
					mem_data_o <= op2;
					mem_sel_o <= 4'b1111;			
					mem_ce_o <= `ChipEnable;
				end
				`EXE_SWL_OP:		begin
					mem_addr_out <= {mem_addr_i[31:2], 2'b00};
					mem_we <= `WriteEnable;
					mem_ce_o <= `ChipEnable;
					case (mem_addr_i[1:0])
						2'b00:	begin						  
							mem_sel_o <= 4'b1111;
							mem_data_o <= op2;
						end
						2'b01:	begin
							mem_sel_o <= 4'b0111;
							mem_data_o <= {zero32[7:0],op2[31:8]};
						end
						2'b10:	begin
							mem_sel_o <= 4'b0011;
							mem_data_o <= {zero32[15:0],op2[31:16]};
						end
						2'b11:	begin
							mem_sel_o <= 4'b0001;	
							mem_data_o <= {zero32[23:0],op2[31:24]};
						end
						default:	begin
							mem_sel_o <= 4'b0000;
						end
					endcase							
				end
				`EXE_SWR_OP:		begin
					mem_addr_out <= {mem_addr_i[31:2], 2'b00};
					mem_we <= `WriteEnable;
					mem_ce_o <= `ChipEnable;
					case (mem_addr_i[1:0])
						2'b00:	begin						  
							mem_sel_o <= 4'b1000;
							mem_data_o <= {op2[7:0],zero32[23:0]};
						end
						2'b01:	begin
							mem_sel_o <= 4'b1100;
							mem_data_o <= {op2[15:0],zero32[15:0]};
						end
						2'b10:	begin
							mem_sel_o <= 4'b1110;
							mem_data_o <= {op2[23:0],zero32[7:0]};
						end
						2'b11:	begin
							mem_sel_o <= 4'b1111;	
							mem_data_o <= op2[31:0];
						end
						default:	begin
							mem_sel_o <= 4'b0000;
						end
					endcase											
				end 
				`EXE_SC_OP:		begin
					if(LLbit == 1'b1) begin
						LLbit_we_o <= 1'b1;
						LLbit_value_o <= 1'b0;
						mem_addr_out <= mem_addr_i;
						mem_we <= `WriteEnable;
						mem_data_o <= op2;
						wdata_out <= 32'b1;
						mem_sel_o <= 4'b1111;		
						mem_ce_o <= `ChipEnable;				
					end else begin
						wdata_out <= 32'b0;
					end
				end				
				default:		begin
          //???????
				end
			endcase							
		end    //if
	end      //always

	always @ (*) begin
		if(rst == `RstEnable) begin
			cp0_status <= `ZeroWord;
		end else if((wb_cp0_wena == `WriteEnable) && 
								(wb_cp0_waddr == `CP0_REG_STATUS ))begin
			cp0_status <= wb_cp0_data;
		end else begin
		  cp0_status <= cp0_status_i;
		end
	end
	
	always @ (*) begin
		if(rst == `RstEnable) begin
			cp0_epc <= `ZeroWord;
		end else if((wb_cp0_wena == `WriteEnable) && 
								(wb_cp0_waddr == `CP0_REG_EPC ))begin
			cp0_epc <= wb_cp0_data;
		end else begin
		  cp0_epc <= cp0EPCValue;
		end
	end

  always @ (*) begin
		if(rst == `RstEnable) begin
			cp0_cause <= `ZeroWord;
		end else if((wb_cp0_wena == `WriteEnable) && 
								(wb_cp0_waddr == `CP0_REG_CAUSE ))begin
			cp0_cause[9:8] <= wb_cp0_data[9:8];
			cp0_cause[22] <= wb_cp0_data[22];
			cp0_cause[23] <= wb_cp0_data[23];
		end else begin
		  cp0_cause <= cp0_cause_i;
		end
	end

	always @ (*) begin
		if(rst == `RstEnable) begin
			exceptionTypeOut <= `ZeroWord;
		end else begin
			exceptionTypeOut <= `ZeroWord;
			
			if(curInstrAddr != `ZeroWord) begin
				if(((cp0_cause[15:8] & (cp0_status[15:8])) != 8'h00) && (cp0_status[1] == 1'b0) && 
							(cp0_status[0] == 1'b1)) begin
					exceptionTypeOut <= 32'h00000001;        //interrupt
				end else if(exceptionType[8] == 1'b1) begin
			  	exceptionTypeOut <= 32'h00000008;        //syscall
				end else if(exceptionType[9] == 1'b1) begin
					exceptionTypeOut <= 32'h0000000a;        //inst_invalid
				end else if(exceptionType[10] ==1'b1) begin
					exceptionTypeOut <= 32'h0000000d;        //trap
				end else if(exceptionType[11] == 1'b1) begin  //ov
					exceptionTypeOut <= 32'h0000000c;
				end else if(exceptionType[12] == 1'b1) begin  //???????
					exceptionTypeOut <= 32'h0000000e;
				end
			end
				
		end
	end			

endmodule