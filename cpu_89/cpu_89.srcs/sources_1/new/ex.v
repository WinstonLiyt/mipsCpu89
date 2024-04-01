`include "defines.vh"
`timescale 1ns / 1ps

module ex(

	input rst,
	
	input [`AluOpBus] aluc,  			// aluc��������
	input [`AluSelBus] alucSelect,  	// ָ������
	input [`RegBus] op1, op2,			// ������1��2

	input [`RegAddrBus] EXE_waddr,		// дĿ��Ĵ�����ַ
	input EXE_wena,						// дʹ���ź�
	input [`RegBus] instr,				// ָ����
	input [31:0] exceptionType,			// �쳣����
	input [`RegBus] curInstrAddr,   	// ��ǰָ���ַ

	input [`RegBus] regHI, regLO,		// HI/LO�Ĵ�������
	input [`RegBus] WB_HI, WB_LO,		// HI/LO�Ĵ���д�루WB��
	input WB_HILO_ena,					// HI/LOдʹ�ܣ�WB��
	input [`RegBus] MEM_HI, MEM_LO, 	// HI/LO�Ĵ������루MEM��
	input MEM_HILO_ena,					// HI/LOдʹ�ܣ�MEM��
	input [`DoubleRegBus] HILO_tmp,		// HI/LO��ʱֵ
	input [1:0] HILOCnt,				// HI/LO������

	input [`DoubleRegBus] DIVRes,		// ����res
	input DIVIsReady,					// �����ṹ�Ƿ�ok���ź�
	input [`RegBus] jumpAddr,			// ���ӵ�ַ��������ת�ͷ�ָ֧�
	input isInDelaySlot,				// �Ƿ����ӳٲ���

 	input mem_cp0_wena,					// CP0�Ĵ���дʹ�ܣ�MEM��
	input [4:0] mem_cp0_waddr,			// CP0�Ĵ���д��ַ��MEM��
	input [`RegBus] mem_cp0_data,		// CP0�Ĵ���д���ݣ�MEM��
 	input wb_cp0_wena,					// CP0�Ĵ���дʹ�ܣ�WB��
	input [4:0] wb_cp0_waddr,			// CP0�Ĵ���д��ַ��WB��
	input [`RegBus] wb_cp0_data,		// CP0�Ĵ���д���ݣ�WB��
	input [`RegBus] cp0_reg_data_in,	// ��ȡCP0�Ĵ�������

	output [`AluOpBus] aluc_out,					// aluc������
	output [`RegBus] mem_addr_out,					// �ô��ַ
	output [`RegBus] op2_out,						// �ڶ�������
	output [31:0] exceptionTypeOut,					// �쳣����
	output  isInDelaySlotOut,						// �Ƿ����ӳٲ���
	output [`RegBus] curInstrAddrOut,				// ��ǰָ���ַ
	output reg stallOut,							// ��ͣ�ź�		

	output reg [4:0] cp0_reg_addr_out,  // CP0�Ĵ�����ȡ��ַ
	output reg cp0_reg_wena_out,		// CP0�Ĵ���дʹ��
	output reg [4:0] cp0_reg_waddr_out,	// CP0�Ĵ���д��ַ
	output reg [`RegBus] cp0_reg_data_out,	// CP0�Ĵ�����ȡ����
	
	output reg [`RegAddrBus] wd_out,	// Ŀ��Ĵ�����ַ
	output reg reg_wena,				// �Ĵ���дʹ��
	output reg [`RegBus] wdata_out,		// д����	

	output reg HILO_ena_out,						// HI/LOдʹ��
	output reg [`RegBus] HI_out, LO_out,			// HI/LO�Ĵ������
	output reg [`DoubleRegBus] HILO_tmp_out,		// HI/LO��ʱֵ
	output reg [1:0] cntOut,						// HI/LO������

	output reg [`RegBus] DIV_op1_out, DIV_op2_out,	// ����������
	output reg DIV_start_out,						// ������ʼ�ź�
	output reg DIV_ifSigned_out						// �Ƿ�Ϊ�з��ų���
);

 	assign aluc_out = aluc;
	assign op2_out = op2;
	assign isInDelaySlotOut = isInDelaySlot;
	assign curInstrAddrOut = curInstrAddr;

	// ����Ϊ�߼����㡢��λ���㡢�ƶ����㡢�������㡢�˷�����Ľ��
	reg[`RegBus] logicRes, shiftRes, movRes, arithRes;
	reg[`DoubleRegBus] mulRes;

	// �������������صĸ����ź�
	wire[`RegBus] sumRes;				// �ӷ�������
	wire overflow;						// ����ź�
	reg isOverflow;						// �����־
	reg isTrap;							// �����־
	wire[`RegBus] reg1_not, reg2_mux;	// ������ȡ���Ͳ�����ѡ���ź�
	wire reg1_eq_reg2, reg1_lt_reg2;	// reg1 ���/С�� reg2
	wire[`RegBus] mult_op1, mult_op2;	// �˷�������
	reg[`RegBus] HI, LO;				// HI/LO�Ĵ���
	wire[`DoubleRegBus] HILI_tmp_out;	// ��ʱHI/LO���
	reg[`DoubleRegBus] HILO_tmp1;		// ����MADD��MSUBָ��	
	reg stall_madd_msub;				// MADD��MSUB��ͣ�ź�		
	reg stall_div_divu;					// DIV��DIVU��ͣ�ź�

 	assign mem_addr_out = op1 + {{16{instr[15]}}, instr[15:0]};

	assign exceptionTypeOut = {exceptionType[31:12], isOverflow, isTrap, exceptionType[9:8], 8'h00};

	// ��λ����
	always @ (*) begin
		if (rst == `RstEnable)
			shiftRes <= `ZeroWord;
		else begin
			case (aluc)
				`EXE_SLL_OP: 
					shiftRes <= op2 << op1[4:0];
				`EXE_SRL_OP:
					shiftRes <= op2 >> op1[4:0];
				`EXE_SRA_OP:
					shiftRes <= ({32{op2[31]}} << (6'd32-{1'b0, op1[4:0]})) | op2 >> op1[4:0];
				default:
					shiftRes <= `ZeroWord;
			endcase
		end
	end

	// �߼�����
	always @ (*) begin
		if (rst == `RstEnable)
			logicRes <= `ZeroWord;
		else begin
			case (aluc)
				`EXE_OR_OP:
					logicRes <= op1 | op2;
				`EXE_AND_OP:
					logicRes <= op1 & op2;
				`EXE_NOR_OP:
					logicRes <= ~(op1 |op2);
				`EXE_XOR_OP:
					logicRes <= op1 ^ op2;
				default:
					logicRes <= `ZeroWord;
			endcase
		end
	end

	assign reg2_mux = ((aluc == `EXE_SUB_OP) || (aluc == `EXE_SUBU_OP) || 
                   	   (aluc == `EXE_SLT_OP) || (aluc == `EXE_SLTU_OP)) ? (~op2 + 1) : op2;
	assign sumRes = op1 + reg2_mux;										 
	assign overflow = ((op1[31] == reg2_mux[31]) && (sumRes[31] != op1[31]));
	assign reg1_not = ~op1;					
	assign reg1_lt_reg2 = ((aluc == `EXE_SLT_OP) || (aluc == `EXE_TLT_OP) ||
							(aluc == `EXE_TLTI_OP) || (aluc == `EXE_TGE_OP) || 
							(aluc == `EXE_TGEI_OP)) ? ((op1[31] && !op2[31]) || 
							(!op1[31] && !op2[31] && sumRes[31]) || 
							(op1[31] && op2[31] && sumRes[31])) : (op1 < op2);

	assign mult_op1 = (((aluc == `EXE_MUL_OP) || (aluc == `EXE_MULT_OP) ||
						(aluc == `EXE_MADD_OP) || (aluc == `EXE_MSUB_OP)) & 
						(op1[31] == 1'b1)) ? (~op1 + 1) : op1;

	assign mult_op2 = (((aluc == `EXE_MUL_OP) || (aluc == `EXE_MULT_OP) ||
						(aluc == `EXE_MADD_OP) || (aluc == `EXE_MSUB_OP)) && 
						(op2[31] == 1'b1)) ? (~op2 + 1) : op2;

	assign HILI_tmp_out = mult_op1 * mult_op2;	
							
	always @ (*) begin
		if (rst == `RstEnable)
			arithRes <= `ZeroWord;
		else begin
			case (aluc)
				`EXE_SLT_OP, `EXE_SLTU_OP:
					arithRes <= reg1_lt_reg2 ;
				`EXE_ADD_OP, `EXE_ADDU_OP, `EXE_ADDI_OP, `EXE_ADDIU_OP, `EXE_SUB_OP, `EXE_SUBU_OP:
					arithRes <= sumRes; 
				// `EXE_CLZ_OP:
				// 	arithRes <= op1[31] ? 0 : op1[30] ? 1 : op1[29] ? 2 :
				// 				op1[28] ? 3 : op1[27] ? 4 : op1[26] ? 5 :
				// 				op1[25] ? 6 : op1[24] ? 7 : op1[23] ? 8 : 
				// 				op1[22] ? 9 : op1[21] ? 10 : op1[20] ? 11 :
				// 				op1[19] ? 12 : op1[18] ? 13 : op1[17] ? 14 : 
				// 				op1[16] ? 15 : op1[15] ? 16 : op1[14] ? 17 : 
				// 				op1[13] ? 18 : op1[12] ? 19 : op1[11] ? 20 :
				// 				op1[10] ? 21 : op1[9] ? 22 : op1[8] ? 23 : 
				// 				op1[7] ? 24 : op1[6] ? 25 : op1[5] ? 26 : 
				// 				op1[4] ? 27 : op1[3] ? 28 : op1[2] ? 29 : 
				// 				op1[1] ? 30 : op1[0] ? 31 : 32 ;
				// `EXE_CLO_OP:
				// 	arithRes <= (reg1_not[31] ? 0 : reg1_not[30] ? 1 : reg1_not[29] ? 2 :
				// 				reg1_not[28] ? 3 : reg1_not[27] ? 4 : reg1_not[26] ? 5 :
				// 				reg1_not[25] ? 6 : reg1_not[24] ? 7 : reg1_not[23] ? 8 : 
				// 				reg1_not[22] ? 9 : reg1_not[21] ? 10 : reg1_not[20] ? 11 :
				// 				reg1_not[19] ? 12 : reg1_not[18] ? 13 : reg1_not[17] ? 14 : 
				// 				reg1_not[16] ? 15 : reg1_not[15] ? 16 : reg1_not[14] ? 17 : 
				// 				reg1_not[13] ? 18 : reg1_not[12] ? 19 : reg1_not[11] ? 20 :
				// 				reg1_not[10] ? 21 : reg1_not[9] ? 22 : reg1_not[8] ? 23 : 
				// 				reg1_not[7] ? 24 : reg1_not[6] ? 25 : reg1_not[5] ? 26 : 
				// 				reg1_not[4] ? 27 : reg1_not[3] ? 28 : reg1_not[2] ? 29 : 
				// 				reg1_not[1] ? 30 : reg1_not[0] ? 31 : 32) ;
				`EXE_CLZ_OP:
                	arithRes <= op1 ? 31 - $clog2(op1) : 32; // ʹ��$clog2ϵͳ��������CLZ
            	`EXE_CLO_OP:
                // ����CLO������ȡ��op1��Ȼ��ʹ����CLZ��ͬ�ķ�������
                	arithRes <= reg1_not ? 31 - $clog2(reg1_not) : 32;
				default:
					arithRes <= `ZeroWord;
			endcase
		end
	end

	always @ (*) begin
		if (rst == `RstEnable)
			isTrap <= `TrapNotAssert;
		else begin
			isTrap <= `TrapNotAssert;
			case (aluc)
				`EXE_TEQ_OP, `EXE_TEQI_OP: begin
					if (op1 == op2 )
						isTrap <= `TrapAssert;
				end
				`EXE_TGE_OP, `EXE_TGEI_OP, `EXE_TGEIU_OP, `EXE_TGEU_OP: begin
					if (~reg1_lt_reg2)
						isTrap <= `TrapAssert;
				end
				`EXE_TLT_OP, `EXE_TLTI_OP, `EXE_TLTIU_OP, `EXE_TLTU_OP: begin
					if (reg1_lt_reg2)
						isTrap <= `TrapAssert;
				end
				`EXE_TNE_OP, `EXE_TNEI_OP: begin
					if (op1 != op2)
						isTrap <= `TrapAssert;
				end
				default:
					isTrap <= `TrapNotAssert;
			endcase
		end
	end																

	always @ (*) begin
		if (rst == `RstEnable)
			mulRes <= {`ZeroWord, `ZeroWord};
		else if ((aluc == `EXE_MULT_OP) || (aluc == `EXE_MUL_OP) || (aluc == `EXE_MADD_OP) || (aluc == `EXE_MSUB_OP)) begin
			if (op1[31] ^ op2[31] == 1'b1)
				mulRes <= ~HILI_tmp_out + 1;
			else
				mulRes <= HILI_tmp_out;
		end 
		else
			mulRes <= HILI_tmp_out;
	end

	always @ (*) begin
		if (rst == `RstEnable)
			{HI, LO} <= {`ZeroWord, `ZeroWord};
		else if (MEM_HILO_ena == `WriteEnable)
			{HI, LO} <= {MEM_HI, MEM_LO};
		else if(WB_HILO_ena == `WriteEnable)
			{HI, LO} <= {WB_HI, WB_LO};
		else
			{HI, LO} <= {regHI, regLO};			
	end	

	always @ (*) begin
		stallOut = stall_madd_msub || stall_div_divu;
	end

	always @ (*) begin
		if (rst == `RstEnable) begin
			HILO_tmp_out <= {`ZeroWord, `ZeroWord};
			cntOut <= 2'b00;
			stall_madd_msub <= `NoStop;
		end
		else begin
			HILO_tmp_out <= {`ZeroWord, `ZeroWord};
			cntOut <= 2'b00;
			stall_madd_msub <= `NoStop;

			// ����ALU����ѡ��ͬ�Ĵ����߼�
			case (aluc) 
				`EXE_MADD_OP, `EXE_MADDU_OP, `EXE_MSUB_OP, `EXE_MSUBU_OP: begin
					if (HILOCnt == 2'b00) begin
						// ����MSUB��MSUBU��ȡ����һ��MADD��MADDUֱ�Ӹ�ֵ
						HILO_tmp_out <= (aluc == `EXE_MSUB_OP || aluc == `EXE_MSUBU_OP) ? (~mulRes + 1) : mulRes;
						cntOut <= 2'b01;
						stall_madd_msub <= `Stop;
					end else if (HILOCnt == 2'b01) begin
						cntOut <= 2'b10;
						// ���ڵڶ����ڣ�ͳһ����HILO_tmp1�ĸ���
						HILO_tmp1 <= HILO_tmp + {HI, LO};
					end
				end
			endcase
		end
		// else begin
		// 	case (aluc) 
		// 		`EXE_MADD_OP, `EXE_MADDU_OP: begin
		// 			if (HILOCnt == 2'b00) begin
		// 				HILO_tmp_out <= mulRes;
		// 				cntOut <= 2'b01;
		// 				stall_madd_msub <= `Stop;
		// 				HILO_tmp1 <= {`ZeroWord, `ZeroWord};
		// 			end 
		// 			else if (HILOCnt == 2'b01) begin
		// 				HILO_tmp_out <= {`ZeroWord, `ZeroWord};						
		// 				cntOut <= 2'b10;
		// 				HILO_tmp1 <= HILO_tmp + {HI, LO};
		// 				stall_madd_msub <= `NoStop;
		// 			end
		// 		end
		// 		`EXE_MSUB_OP, `EXE_MSUBU_OP: begin
		// 			if (HILOCnt == 2'b00) begin
		// 				HILO_tmp_out <= ~mulRes + 1 ;
		// 				cntOut <= 2'b01;
		// 				stall_madd_msub <= `Stop;
		// 			end 
		// 			else if (HILOCnt == 2'b01) begin
		// 				HILO_tmp_out <= {`ZeroWord, `ZeroWord};						
		// 				cntOut <= 2'b10;
		// 				HILO_tmp1 <= HILO_tmp + {HI, LO};
		// 				stall_madd_msub <= `NoStop;
		// 			end				
		// 		end
		// 		default: begin
		// 			HILO_tmp_out <= {`ZeroWord, `ZeroWord};
		// 			cntOut <= 2'b00;
		// 			stall_madd_msub <= `NoStop;				
		// 		end
		// 	endcase
		// end
	end	

	always @ (*) begin
		if (rst == `RstEnable) begin
			stall_div_divu <= `NoStop;
			DIV_op1_out <= `ZeroWord;
			DIV_op2_out <= `ZeroWord;
			DIV_start_out <= `DivStop;
			DIV_ifSigned_out <= 1'b0;
		end
		else begin
			// Ĭ��״̬����
			stall_div_divu <= `NoStop;
			DIV_op1_out <= op1;
			DIV_op2_out <= op2;
			DIV_start_out <= `DivStop; // Ĭ��ֹͣ��������
			DIV_ifSigned_out <= 1'b0; // Ĭ��Ϊ�޷��ų���
			
			case (aluc)
				`EXE_DIV_OP, `EXE_DIVU_OP: begin
					if (DIVIsReady == `DivResultNotReady) begin
						// ������������δ׼���ã���������������
						DIV_start_out <= `DivStart;
						DIV_ifSigned_out <= (aluc == `EXE_DIV_OP); // DIVΪ�з��ţ�DIVUΪ�޷���
						stall_div_divu <= `Stop; // ������ͣ�ź�
					end else if (DIVIsReady == `DivResultReady) begin
						// �����������Ѿ�׼���ã�����Ҫ�ٴ�����
						DIV_start_out <= `DivStop;
						DIV_ifSigned_out <= (aluc == `EXE_DIV_OP);
						stall_div_divu <= `NoStop; // �����ͣ�ź�
					end
				end
				default: begin
					// ���ڷǳ�������������Ĭ��״̬
				end
			endcase
		end
		// else begin
		// 	stall_div_divu <= `NoStop;
		// 	DIV_op1_out <= `ZeroWord;
		// 	DIV_op2_out <= `ZeroWord;
		// 	DIV_start_out <= `DivStop;
		// 	DIV_ifSigned_out <= 1'b0;
		// 	case (aluc)
		// 		`EXE_DIV_OP: begin
		// 			if (DIVIsReady == `DivResultNotReady) begin
		// 				DIV_op1_out <= op1;
		// 				DIV_op2_out <= op2;
		// 				DIV_start_out <= `DivStart;
		// 				DIV_ifSigned_out <= 1'b1;
		// 				stall_div_divu <= `Stop;
		// 			end
		// 			else if(DIVIsReady == `DivResultReady) begin
		// 				DIV_op1_out <= op1;
		// 				DIV_op2_out <= op2;
		// 				DIV_start_out <= `DivStop;
		// 				DIV_ifSigned_out <= 1'b1;
		// 				stall_div_divu <= `NoStop;
		// 			end
		// 			else begin
		// 				DIV_op1_out <= `ZeroWord;
		// 				DIV_op2_out <= `ZeroWord;
		// 				DIV_start_out <= `DivStop;
		// 				DIV_ifSigned_out <= 1'b0;
		// 				stall_div_divu <= `NoStop;
		// 			end
		// 		end
		// 		`EXE_DIVU_OP: begin
		// 			if (DIVIsReady == `DivResultNotReady) begin
		// 				DIV_op1_out <= op1;
		// 				DIV_op2_out <= op2;
		// 				DIV_start_out <= `DivStart;
		// 				DIV_ifSigned_out <= 1'b0;
		// 				stall_div_divu <= `Stop;
		// 			end
		// 			else if(DIVIsReady == `DivResultReady) begin
		// 				DIV_op1_out <= op1;
		// 				DIV_op2_out <= op2;
		// 				DIV_start_out <= `DivStop;
		// 				DIV_ifSigned_out <= 1'b0;
		// 				stall_div_divu <= `NoStop;
		// 			end
		// 			else begin
		// 				DIV_op1_out <= `ZeroWord;
		// 				DIV_op2_out <= `ZeroWord;
		// 				DIV_start_out <= `DivStop;
		// 				DIV_ifSigned_out <= 1'b0;
		// 				stall_div_divu <= `NoStop;
		// 			end					
		// 		end
		// 		default: begin
		// 		end
		// 	endcase
		// end
	end

	always @ (*) begin
		if (rst == `RstEnable)
			movRes <= `ZeroWord;
		else begin
			movRes <= `ZeroWord;
			case (aluc)
				`EXE_MFHI_OP: movRes <= HI;
				`EXE_MFLO_OP: movRes <= LO;
				`EXE_MOVZ_OP, `EXE_MOVN_OP: movRes <= op1;
				`EXE_MFC0_OP: begin
					cp0_reg_addr_out <= instr[15:11];
					// movRes <= cp0_reg_data_in;
					// if (mem_cp0_wena == `WriteEnable && mem_cp0_waddr == instr[15:11])
					// 	movRes <= mem_cp0_data;
					// else if (wb_cp0_wena == `WriteEnable && wb_cp0_waddr == instr[15:11])
					// 	movRes <= wb_cp0_data;
					// ����MFC0��ֱ�Ӷ�ȡCP0�Ĵ��������ݣ����ǽ׶μ�ת��
					movRes <= (mem_cp0_wena && mem_cp0_waddr == instr[15:11]) ? mem_cp0_data :
							(wb_cp0_wena && wb_cp0_waddr == instr[15:11]) ? wb_cp0_data :
							cp0_reg_data_in;
				end
				default : begin
				end
			endcase
		end
	end

 	always @ (*) begin
		wd_out <= EXE_waddr;
		reg_wena <= ((aluc == `EXE_ADD_OP || aluc == `EXE_ADDI_OP || aluc == `EXE_SUB_OP) && overflow) ? `WriteDisable : EXE_wena;
    	isOverflow <= (aluc == `EXE_ADD_OP || aluc == `EXE_ADDI_OP || aluc == `EXE_SUB_OP) && overflow;
		// if (((aluc == `EXE_ADD_OP) || (aluc == `EXE_ADDI_OP) || (aluc == `EXE_SUB_OP)) && (overflow == 1'b1)) begin
		// 	reg_wena <= `WriteDisable;
		// 	isOverflow <= 1'b1;
		// end 
		// else begin
		// 	reg_wena <= EXE_wena;
		// 	isOverflow <= 1'b0;
		// end
		
		case (alucSelect) 
			`EXE_RES_LOGIC: wdata_out <= logicRes;
			`EXE_RES_SHIFT: wdata_out <= shiftRes;
			`EXE_RES_MOVE: wdata_out <= movRes;
			`EXE_RES_ARITHMETIC: wdata_out <= arithRes;
			`EXE_RES_MUL: wdata_out <= mulRes[31:0];
			`EXE_RES_JUMP_BRANCH: wdata_out <= jumpAddr;
			default: wdata_out <= `ZeroWord;
	 	endcase
 	end	

	always @ (*) begin
		case (1'b1)
			(rst == `RstEnable): begin
				HILO_ena_out <= `WriteDisable;
				HI_out <= `ZeroWord;
				LO_out <= `ZeroWord;
			end
			default: begin
				case (aluc)
					`EXE_MULT_OP, `EXE_MULTU_OP: begin
						HILO_ena_out <= `WriteEnable;
						HI_out <= mulRes[63:32];
						LO_out <= mulRes[31:0];
					end
					`EXE_MADD_OP, `EXE_MADDU_OP,
					`EXE_MSUB_OP, `EXE_MSUBU_OP: begin
						HILO_ena_out <= `WriteEnable;
						HI_out <= HILO_tmp1[63:32];
						LO_out <= HILO_tmp1[31:0];
					end
					`EXE_DIV_OP, `EXE_DIVU_OP: begin
						HILO_ena_out <= `WriteEnable;
						HI_out <= DIVRes[63:32];
						LO_out <= DIVRes[31:0];
					end
					`EXE_MTHI_OP: begin
						HILO_ena_out <= `WriteEnable;
						HI_out <= op1;
						LO_out <= LO;
					end
					`EXE_MTLO_OP: begin
						HILO_ena_out <= `WriteEnable;
						HI_out <= HI;
						LO_out <= op1;
					end
					default: begin
						HILO_ena_out <= `WriteDisable;
						HI_out <= `ZeroWord;
						LO_out <= `ZeroWord;
					end
				endcase
			end
		endcase
	end

	always @ (*) begin
		cp0_reg_waddr_out <= 5'b00000;
		cp0_reg_wena_out <= `WriteDisable;
		cp0_reg_data_out <= `ZeroWord;

		// ������λ��`MTC0`ָ��
		if (!rst && aluc == `EXE_MTC0_OP) begin
			cp0_reg_waddr_out <= instr[15:11];
			cp0_reg_wena_out <= `WriteEnable;
			cp0_reg_data_out <= op1;
		end
	end
	
endmodule