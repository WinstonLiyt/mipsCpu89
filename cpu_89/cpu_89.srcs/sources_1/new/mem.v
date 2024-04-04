/* -----------------------------------------
Func：处理内存访问操作，包括加载和存储指令，以及
	  与协处理器CP0相关的指令。
------------------------------------------- */

`include "defines.vh"
`timescale 1ns / 1ps

module mem(

	input rst,
	
	input [`RegAddrBus] EXE_waddr,	// 写地址（EXE）
	input EXE_wena,					// 写使能
	input [`RegBus] EXE_wdata,		// 写数据

	input [`AluOpBus] aluc,			// ALU控制信号
	input [`RegBus] memAddrIn,		// 内存地址
	input [`RegBus] memDataIn,		// 内存数据
	input [`RegBus] op2,			// 操作数2
	input [`RegBus] regHI, regLO,	// HI/LO寄存器
	input HILO_wena,				// HI/LO写使能

	input LLbitIn,					// LLbit
	input wb_LLbit_wenaIn,			// LLbit写使能
	input wb_LLbit_ValIn,			// LLbit写值	

	input cp0_wenaIn,				// CP0写使能
	input [4:0] cp0_waddrIn,		// CP0写地址
	input [`RegBus] cp0_dataIn,		// CP0写数据
	
	input [31:0] exceptionType,		// 异常类型
	input isInDelaySlot,			// 是否在延迟槽
	input [`RegBus] curInstrAddr,	// 当前指令地址
	
	input [`RegBus] cp0_statusIn,	// CP0状态寄存器
	input [`RegBus] cp0_causeIn,	// CP0原因寄存器
	input [`RegBus] cp0EPCValue,	// CP0 EPC寄存器

  	input wb_cp0_wena,				// CP0写使能
	input [4:0] wb_cp0_waddr,		// CP0写地址
	input [`RegBus] wb_cp0_data,	// CP0写数据
	
	output reg[`RegAddrBus] wd_out,	// 写地址
	output reg reg_wena,			// 写使能
	output reg[`RegBus] wdata_out,	// 写数据
	output reg[`RegBus] HIOut, LOOut,	// HI/LO寄存器
	output reg HILO_ena_out,		// HI/LO写使能

	output reg LLbit_wena_out,		// LLbit写使能
	output reg LLbit_val_out,		// LLbit写值

	output reg cp0_reg_wena_out,			// CP0写使能
	output reg[4:0] cp0_reg_waddr_out,		// CP0写地址
	output reg[`RegBus] cp0_reg_data_out,	// CP0写数据
	
	output reg[`RegBus] mem_addr_out,		// 内存地址
	output mem_wena_out,					// 内存写使能
	output reg[3:0] memSelOut,				// 内存选择（哪部分是有效数据）
	output reg[`RegBus] memDataOut,			// 内存数据
	output reg mem_ce_out,					// 内存使能
	
	output reg[31:0] exceptionTypeOut,		// 异常类型
	output [`RegBus] cp0EPCOut,				// CP0 EPC寄存器
	output isInDelaySlotOut,				// 是否在延迟槽
	output [`RegBus] curInstrAddrOut		// 当前指令地址
);

  	reg LLbit;					// LLbit
	wire[`RegBus] zero32;		// 32位0
	reg[`RegBus] cp0_status;	// CP0状态寄存器
	reg[`RegBus] cp0_cause;		// CP0原因寄存器
	reg[`RegBus] cp0_epc;		// CP0 EPC寄存器
	reg mem_wena;				// 内存写使能

	// 外部数据存储器RAM的读、写信号
	assign mem_wena_out = mem_wena & (~(|exceptionTypeOut));
	assign zero32 = `ZeroWord;

	// 访存阶段的指令是否是延迟槽指令
	assign isInDelaySlotOut = isInDelaySlot;
	// 访存阶段指令的地址
	assign curInstrAddrOut = curInstrAddr;
	assign cp0EPCOut = cp0_epc;

	/* 获取 bit 寄存器的最新值，如果回写阶段的指令要写LLbit，
	   那么回写阶段要写入的值就是LLbit寄存器的最新值;
	   反之，LLbit模块给出的值LLbitIn是最新值 */
	always @ (*) begin
		if (rst == `RstEnable) 
			LLbit <= 1'b0;
		else begin
			if (wb_LLbit_wenaIn == 1'b1)
				LLbit <= wb_LLbit_ValIn;
			else
				LLbit <= LLbitIn;
		end
	end
	
	always @ (*) begin
		if (rst == `RstEnable) begin
			wd_out <= `NOPRegAddr;
			reg_wena <= `WriteDisable;
			wdata_out <= `ZeroWord;
			HIOut <= `ZeroWord;
			LOOut <= `ZeroWord;
			HILO_ena_out <= `WriteDisable;
			mem_addr_out <= `ZeroWord;
			mem_wena <= `WriteDisable;
			memSelOut <= 4'b0000;
			memDataOut <= `ZeroWord;
			mem_ce_out <= `ChipDisable;
			LLbit_wena_out <= 1'b0;
			LLbit_val_out <= 1'b0;
			cp0_reg_wena_out <= `WriteDisable;
			cp0_reg_waddr_out <= 5'b00000;
			cp0_reg_data_out <= `ZeroWord;
		end 
		else begin
			wd_out <= EXE_waddr;
			reg_wena <= EXE_wena;
			wdata_out <= EXE_wdata;
			HIOut <= regHI;
			LOOut <= regLO;
			HILO_ena_out <= HILO_wena;
			mem_wena <= `WriteDisable;
			mem_addr_out <= `ZeroWord;
			memSelOut <= 4'b1111;
			mem_ce_out <= `ChipDisable;
			LLbit_wena_out <= 1'b0;
			LLbit_val_out <= 1'b0;
			cp0_reg_wena_out <= cp0_wenaIn;
			cp0_reg_waddr_out <= cp0_waddrIn;
			cp0_reg_data_out <= cp0_dataIn;
			case (aluc)
				`EXE_LB_OP: begin
					mem_addr_out <= memAddrIn;	// 要访问的数据存储器地址
					mem_wena <= `WriteDisable;	// 加载数据，不写
					mem_ce_out <= `ChipEnable;	// 要访问数据存储器
					// 依据 memAddrIn 的最后两位，确定 memSelOut 的值
					// 【说明】 参考了 Wishbone 总线的相关规范
					case (memAddrIn[1:0])
						2'b00: begin
							wdata_out <= {{24{memDataIn[31]}}, memDataIn[31:24]};
							memSelOut <= 4'b1000;
						end
						2'b01: begin
							wdata_out <= {{24{memDataIn[23]}}, memDataIn[23:16]};
							memSelOut <= 4'b0100;
						end
						2'b10: begin
							wdata_out <= {{24{memDataIn[15]}}, memDataIn[15:8]};
							memSelOut <= 4'b0010;
						end
						2'b11: begin
							wdata_out <= {{24{memDataIn[7]}}, memDataIn[7:0]};
							memSelOut <= 4'b0001;
						end
						default: begin
							wdata_out <= `ZeroWord;
						end
					endcase
				end
				`EXE_LBU_OP: begin
					mem_addr_out <= memAddrIn;
					mem_wena <= `WriteDisable;
					mem_ce_out <= `ChipEnable;
					case (memAddrIn[1:0])
						2'b00: begin
							wdata_out <= {{24{1'b0}}, memDataIn[31:24]};
							memSelOut <= 4'b1000;
						end
						2'b01: begin
							wdata_out <= {{24{1'b0}}, memDataIn[23:16]};
							memSelOut <= 4'b0100;
						end
						2'b10: begin
							wdata_out <= {{24{1'b0}}, memDataIn[15:8]};
							memSelOut <= 4'b0010;
						end
						2'b11: begin
							wdata_out <= {{24{1'b0}}, memDataIn[7:0]};
							memSelOut <= 4'b0001;
						end
						default: begin
							wdata_out <= `ZeroWord;
						end
					endcase
				end
				`EXE_LH_OP: begin
					mem_addr_out <= memAddrIn;
					mem_wena <= `WriteDisable;
					mem_ce_out <= `ChipEnable;
					case (memAddrIn[1:0])
						2'b00: begin
							wdata_out <= {{16{memDataIn[31]}}, memDataIn[31:16]};
							memSelOut <= 4'b1100;
						end
						2'b10: begin
							wdata_out <= {{16{memDataIn[15]}}, memDataIn[15:0]};
							memSelOut <= 4'b0011;
						end
						default: begin
							wdata_out <= `ZeroWord;
						end
					endcase					
				end
				`EXE_LHU_OP: begin
					mem_addr_out <= memAddrIn;
					mem_wena <= `WriteDisable;
					mem_ce_out <= `ChipEnable;
					case (memAddrIn[1:0])
						2'b00: begin
							wdata_out <= {{16{1'b0}}, memDataIn[31:16]};
							memSelOut <= 4'b1100;
						end
						2'b10: begin
							wdata_out <= {{16{1'b0}}, memDataIn[15:0]};
							memSelOut <= 4'b0011;
						end
						default: begin
							wdata_out <= `ZeroWord;
						end
					endcase
				end
				`EXE_LW_OP: begin
					mem_addr_out <= memAddrIn;
					mem_wena <= `WriteDisable;
					wdata_out <= memDataIn;
					memSelOut <= 4'b1111;
					mem_ce_out <= `ChipEnable;
				end
				`EXE_LWL_OP: begin
					mem_addr_out <= {memAddrIn[31:2], 2'b00};
					mem_wena <= `WriteDisable;
					memSelOut <= 4'b1111;
					mem_ce_out <= `ChipEnable;
					case (memAddrIn[1:0])
						2'b00:
							wdata_out <= memDataIn[31:0];
						2'b01:
							wdata_out <= {memDataIn[23:0], op2[7:0]};
						2'b10:
							wdata_out <= {memDataIn[15:0], op2[15:0]};
						2'b11:
							wdata_out <= {memDataIn[7:0], op2[23:0]};	
						default: begin
							wdata_out <= `ZeroWord;
						end
					endcase
				end
				`EXE_LWR_OP: begin
					mem_addr_out <= {memAddrIn[31:2], 2'b00};
					mem_wena <= `WriteDisable;
					memSelOut <= 4'b1111;
					mem_ce_out <= `ChipEnable;
					case (memAddrIn[1:0])
						2'b00:
							wdata_out <= {op2[31:8],memDataIn[31:24]};
						2'b01:
							wdata_out <= {op2[31:16],memDataIn[31:16]};
						2'b10:
							wdata_out <= {op2[31:24],memDataIn[31:8]};
						2'b11:
							wdata_out <= memDataIn;	
						default: begin
							wdata_out <= `ZeroWord;
						end
					endcase
				end
				`EXE_LL_OP:	begin  // 【特殊】
					mem_addr_out <= memAddrIn;
					mem_wena <= `WriteDisable;
					wdata_out <= memDataIn;
					LLbit_wena_out <= 1'b1;
					LLbit_val_out <= 1'b1;
					memSelOut <= 4'b1111;
					mem_ce_out <= `ChipEnable;
				end				
				`EXE_SB_OP:	begin
					mem_addr_out <= memAddrIn;
					mem_wena <= `WriteEnable;
					memDataOut <= {op2[7:0],op2[7:0],op2[7:0],op2[7:0]};
					mem_ce_out <= `ChipEnable;
					case (memAddrIn[1:0])
						2'b00:	begin
							memSelOut <= 4'b1000;
						end
						2'b01:	begin
							memSelOut <= 4'b0100;
						end
						2'b10:	begin
							memSelOut <= 4'b0010;
						end
						2'b11:	begin
							memSelOut <= 4'b0001;	
						end
						default:	begin
							memSelOut <= 4'b0000;
						end
					endcase				
				end
				`EXE_SH_OP: begin
					mem_addr_out <= memAddrIn;
					mem_wena <= `WriteEnable;
					memDataOut <= {op2[15:0],op2[15:0]};
					mem_ce_out <= `ChipEnable;
					case (memAddrIn[1:0])
						2'b00:	begin
							memSelOut <= 4'b1100;
						end
						2'b10:	begin
							memSelOut <= 4'b0011;
						end
						default:	begin
							memSelOut <= 4'b0000;
						end
					endcase						
				end
				`EXE_SW_OP: begin
					mem_addr_out <= memAddrIn;
					mem_wena <= `WriteEnable;
					memDataOut <= op2;
					memSelOut <= 4'b1111;			
					mem_ce_out <= `ChipEnable;
				end
				`EXE_SWL_OP: begin
					mem_addr_out <= {memAddrIn[31:2], 2'b00};
					mem_wena <= `WriteEnable;
					mem_ce_out <= `ChipEnable;
					case (memAddrIn[1:0])
						2'b00:	begin						  
							memSelOut <= 4'b1111;
							memDataOut <= op2;
						end
						2'b01:	begin
							memSelOut <= 4'b0111;
							memDataOut <= {zero32[7:0],op2[31:8]};
						end
						2'b10:	begin
							memSelOut <= 4'b0011;
							memDataOut <= {zero32[15:0],op2[31:16]};
						end
						2'b11:	begin
							memSelOut <= 4'b0001;	
							memDataOut <= {zero32[23:0],op2[31:24]};
						end
						default:	begin
							memSelOut <= 4'b0000;
						end
					endcase							
				end
				`EXE_SWR_OP: begin
					mem_addr_out <= {memAddrIn[31:2], 2'b00};
					mem_wena <= `WriteEnable;
					mem_ce_out <= `ChipEnable;
					case (memAddrIn[1:0])
						2'b00:	begin						  
							memSelOut <= 4'b1000;
							memDataOut <= {op2[7:0],zero32[23:0]};
						end
						2'b01:	begin
							memSelOut <= 4'b1100;
							memDataOut <= {op2[15:0],zero32[15:0]};
						end
						2'b10:	begin
							memSelOut <= 4'b1110;
							memDataOut <= {op2[23:0],zero32[7:0]};
						end
						2'b11:	begin
							memSelOut <= 4'b1111;	
							memDataOut <= op2[31:0];
						end
						default:	begin
							memSelOut <= 4'b0000;
						end
					endcase											
				end 
				`EXE_SC_OP: begin  // 【特殊】
					if (LLbit == 1'b1) begin
						LLbit_wena_out <= 1'b1;
						LLbit_val_out <= 1'b0;
						mem_addr_out <= memAddrIn;
						mem_wena <= `WriteEnable;
						memDataOut <= op2;
						wdata_out <= 32'b1;
						memSelOut <= 4'b1111;  // 存储1个字	
						mem_ce_out <= `ChipEnable;				
					end
					else
						wdata_out <= 32'b0;
				end				
				default: begin
				end
			endcase							
		end
	end

	always @ (*) begin
		if (rst == `RstEnable)
			cp0_status <= `ZeroWord;
		else if ((wb_cp0_wena == `WriteEnable) && (wb_cp0_waddr == `CP0_REG_STATUS ))
			cp0_status <= wb_cp0_data;
		else
			cp0_status <= cp0_statusIn;
	end
	
	always @ (*) begin
		if (rst == `RstEnable)
			cp0_epc <= `ZeroWord;
		else if ((wb_cp0_wena == `WriteEnable) && (wb_cp0_waddr == `CP0_REG_EPC ))
			cp0_epc <= wb_cp0_data;
		else
		  cp0_epc <= cp0EPCValue;
	end

  	always @ (*) begin
		if (rst == `RstEnable)
			cp0_cause <= `ZeroWord;
		else if ((wb_cp0_wena == `WriteEnable) && (wb_cp0_waddr == `CP0_REG_CAUSE )) begin
			cp0_cause[9:8] <= wb_cp0_data[9:8];
			cp0_cause[22] <= wb_cp0_data[22];
			cp0_cause[23] <= wb_cp0_data[23];
		end 
		else
		  cp0_cause <= cp0_causeIn;
	end

	// 给出最终的异常类型
	always @ (*) begin
		if (rst == `RstEnable)
			exceptionTypeOut <= `ZeroWord;
		else begin
			exceptionTypeOut <= `ZeroWord;
			
			if (curInstrAddr != `ZeroWord) begin
				// interrupt
				if (((cp0_cause[15:8] & (cp0_status[15:8])) != 8'h00) 
					&& (cp0_status[1] == 1'b0) && (cp0_status[0] == 1'b1))
					exceptionTypeOut <= 32'h00000001;
				// syscall
				else if (exceptionType[8] == 1'b1)
			  		exceptionTypeOut <= 32'h00000008;
				// inst_invalid
				else if (exceptionType[9] == 1'b1)
					exceptionTypeOut <= 32'h0000000a;
				// trap
				else if (exceptionType[10] ==1'b1)
					exceptionTypeOut <= 32'h0000000d;
				// ov
				else if (exceptionType[11] == 1'b1)
					exceptionTypeOut <= 32'h0000000c;
				else if (exceptionType[12] == 1'b1)
					exceptionTypeOut <= 32'h0000000e;
			end
				
		end
	end			

endmodule