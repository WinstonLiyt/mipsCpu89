/* -----------------------------------------
Func�������ڴ���ʲ������������غʹ洢ָ��Լ�
	  ��Э������CP0��ص�ָ�
------------------------------------------- */

`include "defines.vh"
`timescale 1ns / 1ps

module mem(

	input rst,
	
	input [`RegAddrBus] EXE_waddr,	// д��ַ��EXE��
	input EXE_wena,					// дʹ��
	input [`RegBus] EXE_wdata,		// д����

	input [`AluOpBus] aluc,			// ALU�����ź�
	input [`RegBus] memAddrIn,		// �ڴ��ַ
	input [`RegBus] memDataIn,		// �ڴ�����
	input [`RegBus] op2,			// ������2
	input [`RegBus] regHI, regLO,	// HI/LO�Ĵ���
	input HILO_wena,				// HI/LOдʹ��

	input LLbitIn,					// LLbit
	input wb_LLbit_wenaIn,			// LLbitдʹ��
	input wb_LLbit_ValIn,			// LLbitдֵ	

	input cp0_wenaIn,				// CP0дʹ��
	input [4:0] cp0_waddrIn,		// CP0д��ַ
	input [`RegBus] cp0_dataIn,		// CP0д����
	
	input [31:0] exceptionType,		// �쳣����
	input isInDelaySlot,			// �Ƿ����ӳٲ�
	input [`RegBus] curInstrAddr,	// ��ǰָ���ַ
	
	input [`RegBus] cp0_statusIn,	// CP0״̬�Ĵ���
	input [`RegBus] cp0_causeIn,	// CP0ԭ��Ĵ���
	input [`RegBus] cp0EPCValue,	// CP0 EPC�Ĵ���

  	input wb_cp0_wena,				// CP0дʹ��
	input [4:0] wb_cp0_waddr,		// CP0д��ַ
	input [`RegBus] wb_cp0_data,	// CP0д����
	
	output reg[`RegAddrBus] wd_out,	// д��ַ
	output reg reg_wena,			// дʹ��
	output reg[`RegBus] wdata_out,	// д����
	output reg[`RegBus] HIOut, LOOut,	// HI/LO�Ĵ���
	output reg HILO_ena_out,		// HI/LOдʹ��

	output reg LLbit_wena_out,		// LLbitдʹ��
	output reg LLbit_val_out,		// LLbitдֵ

	output reg cp0_reg_wena_out,			// CP0дʹ��
	output reg[4:0] cp0_reg_waddr_out,		// CP0д��ַ
	output reg[`RegBus] cp0_reg_data_out,	// CP0д����
	
	output reg[`RegBus] mem_addr_out,		// �ڴ��ַ
	output mem_wena_out,					// �ڴ�дʹ��
	output reg[3:0] memSelOut,				// �ڴ�ѡ���Ĳ�������Ч���ݣ�
	output reg[`RegBus] memDataOut,			// �ڴ�����
	output reg mem_ce_out,					// �ڴ�ʹ��
	
	output reg[31:0] exceptionTypeOut,		// �쳣����
	output [`RegBus] cp0EPCOut,				// CP0 EPC�Ĵ���
	output isInDelaySlotOut,				// �Ƿ����ӳٲ�
	output [`RegBus] curInstrAddrOut		// ��ǰָ���ַ
);

  	reg LLbit;					// LLbit
	wire[`RegBus] zero32;		// 32λ0
	reg[`RegBus] cp0_status;	// CP0״̬�Ĵ���
	reg[`RegBus] cp0_cause;		// CP0ԭ��Ĵ���
	reg[`RegBus] cp0_epc;		// CP0 EPC�Ĵ���
	reg mem_wena;				// �ڴ�дʹ��

	// �ⲿ���ݴ洢��RAM�Ķ���д�ź�
	assign mem_wena_out = mem_wena & (~(|exceptionTypeOut));
	assign zero32 = `ZeroWord;

	// �ô�׶ε�ָ���Ƿ����ӳٲ�ָ��
	assign isInDelaySlotOut = isInDelaySlot;
	// �ô�׶�ָ��ĵ�ַ
	assign curInstrAddrOut = curInstrAddr;
	assign cp0EPCOut = cp0_epc;

	/* ��ȡ bit �Ĵ���������ֵ�������д�׶ε�ָ��ҪдLLbit��
	   ��ô��д�׶�Ҫд���ֵ����LLbit�Ĵ���������ֵ;
	   ��֮��LLbitģ�������ֵLLbitIn������ֵ */
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
					mem_addr_out <= memAddrIn;	// Ҫ���ʵ����ݴ洢����ַ
					mem_wena <= `WriteDisable;	// �������ݣ���д
					mem_ce_out <= `ChipEnable;	// Ҫ�������ݴ洢��
					// ���� memAddrIn �������λ��ȷ�� memSelOut ��ֵ
					// ��˵���� �ο��� Wishbone ���ߵ���ع淶
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
				`EXE_LL_OP:	begin  // �����⡿
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
				`EXE_SC_OP: begin  // �����⡿
					if (LLbit == 1'b1) begin
						LLbit_wena_out <= 1'b1;
						LLbit_val_out <= 1'b0;
						mem_addr_out <= memAddrIn;
						mem_wena <= `WriteEnable;
						memDataOut <= op2;
						wdata_out <= 32'b1;
						memSelOut <= 4'b1111;  // �洢1����	
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

	// �������յ��쳣����
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