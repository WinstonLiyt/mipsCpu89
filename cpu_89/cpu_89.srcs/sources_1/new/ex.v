/* -----------------------------------------
Func����������׶εĽ������Դ����1��2�������㡣
------------------------------------------- */

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
	// ��д�׶ε�ָ���Ƿ�ҪдHI��IO�����ڼ��HI��LO�Ĵ��������������������
	input [`RegBus] WB_HI, WB_LO,		// HI/LO�Ĵ���д�루WB��
	input WB_HILO_ena,					// HI/LOдʹ�ܣ�WB��
	// �ô�׶ε�ָ���Ƿ�ҪдHI��IO�����ڼ��HI��LO�Ĵ��������������������
	input [`RegBus] MEM_HI, MEM_LO, 	// HI/LO�Ĵ������루MEM��
	input MEM_HILO_ena,					// HI/LOдʹ�ܣ�MEM��
	input [`DoubleRegBus] HILO_tmp,		// HI/LO��ʱֵ�����ۼӡ����ۼ�ָ�
	input [1:0] HILOCnt,				// ��ǰ����ִ�н׶εĵڼ���ʱ������

	input [`DoubleRegBus] DIVRes,		// ����res
	input DIVIsReady,					// �����ṹ�Ƿ�ok���ź�
	input [`RegBus] jumpAddr,			// ���ӵ�ַ��������ת�ͷ�ָ֧�
	input isInDelaySlot,				// �Ƿ����ӳٲ���

	// �ô�/��д�׶ε�ָ���Ƿ�ҪдCP0�еļĴ�������������������
 	input mem_cp0_wena,					// CP0�Ĵ���дʹ�ܣ�MEM��
	input [4:0] mem_cp0_waddr,			// CP0�Ĵ���д��ַ��MEM��
	input [`RegBus] mem_cp0_data,		// CP0�Ĵ���д���ݣ�MEM��
 	input wb_cp0_wena,					// CP0�Ĵ���дʹ�ܣ�WB��
	input [4:0] wb_cp0_waddr,			// CP0�Ĵ���д��ַ��WB��
	input [`RegBus] wb_cp0_data,		// CP0�Ĵ���д���ݣ�WB��
	input [`RegBus] cp0_dataIn,			// ��ȡCP0�Ĵ�������

	output [`AluOpBus] alucOut,			// aluc������
	output [`RegBus] mem_addr_out,		// ���ء��洢ָ���Ӧ�Ĵ洢����ַ
	output [`RegBus] op2_out,			// �洢ָ��Ҫ�洢�����ݣ�����lwl��lwrָ��Ҫ���ص���Ŀ�ļĴ�����ԭʼֵ
	output [31:0] exceptionTypeOut,		// �쳣����
	output  isInDelaySlotOut,			// �Ƿ����ӳٲ���
	output [`RegBus] curInstrAddrOut,	// ��ǰָ���ַ
	output reg stallOut,				// ��ͣ�ź�		

	output reg [4:0] cp0_reg_addr_out,  // CP0�Ĵ�����ȡ��ַ
	output reg cp0_reg_wena_out,		// CP0�Ĵ���дʹ��
	output reg [4:0] cp0_reg_waddr_out,	// CP0�Ĵ���д��ַ
	output reg [`RegBus] cp0_reg_data_out,	// CP0�Ĵ�����ȡ����
	
	output reg [`RegAddrBus] wd_out,	// Ŀ��Ĵ�����ַ
	output reg reg_wena,				// �Ĵ���дʹ��
	output reg [`RegBus] wdata_out,		// д����	

	// ����ִ�н׶ε�ָ���HI��LO�Ĵ�����д��������
	output reg HILO_ena_out,						// HI/LOдʹ��
	output reg [`RegBus] HIOut, LOOut,				// HI/LO�Ĵ������
	output reg [`DoubleRegBus] HILO_tmp_out,		// HI/LO��ʱֵ
	output reg [1:0] cntOut,						// ��ǰ����ִ�н׶εĵڼ���ʱ������

	output reg [`RegBus] DIV_op1_out, DIV_op2_out,	// ����������
	output reg DIV_start_out,						// ������ʼ�ź�
	output reg DIV_ifSigned_out						// �Ƿ�Ϊ�з��ų���
);

 	assign alucOut = aluc;
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
	reg[`RegBus] HI, LO;				// HI/LO�Ĵ���������ֵ
	wire[`DoubleRegBus] HILI_tmp_out;	// ��ʱHI/LO���
	reg[`DoubleRegBus] HILO_tmp1;		// ����MADD��MSUBָ��	
	reg stall_madd_msub;				// MADD��MSUB��ͣ�ź�		
	reg stall_div_divu;					// DIV��DIVU��ͣ�ź�

	// ���ء��洢ָ���Ӧ�Ĵ洢����ַ
 	assign mem_addr_out = op1 + {{16{instr[15]}}, instr[15:0]};

	// �洢ָ��Ҫ�洢�����ݣ�����lwl��lwrָ��Ҫ���ص���Ŀ�ļĴ�����ԭʼֵ��
	assign op2_out = op2;

	// ִ�н׶�������쳣��Ϣ��������׶ε��쳣��Ϣ���������쳣������쳣����Ϣ�����е�10bit��ʾ�Ƿ��������쳣����11bit��ʾ�Ƿ�������쳣
	assign exceptionTypeOut = {exceptionType[31:12], isOverflow, isTrap, exceptionType[9:8], 8'h00};

	/*************************** �߼����� **************************/
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

	/*************************** ��λ���� **************************/
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

	/* ����Ǽ��������з��űȽ����㣬��ôreg2_mux���ڵڶ���������op2�Ĳ��룬����reg2_mux�͵��ڵڶ���������op2 */
	assign reg2_mux = ((aluc == `EXE_SUB_OP) || (aluc == `EXE_SUBU_OP) || 
                   	   (aluc == `EXE_SLT_OP) || (aluc == `EXE_SLTU_OP)) ? (~op2 + 1) : op2;

	/* �ӷ����������з��űȽϡ������÷��Ƚ���� */
	assign sumRes = op1 + reg2_mux;

	/* �ӷ����������п������ */								 
	assign overflow = ((op1[31] == reg2_mux[31]) && (sumRes[31] != op1[31]));

	/* op1ȡ�� */
	assign reg1_not = ~op1;

	/* ��op1�Ƿ�С��op2 */
	assign reg1_lt_reg2 = ((aluc == `EXE_SLT_OP) || (aluc == `EXE_TLT_OP) ||
							(aluc == `EXE_TLTI_OP) || (aluc == `EXE_TGE_OP) || 
							(aluc == `EXE_TGEI_OP)) ? ((op1[31] && !op2[31]) || 
							(!op1[31] && !op2[31] && sumRes[31]) || 
							(op1[31] && op2[31] && sumRes[31])) : (op1 < op2);

	/* ȡ�ó˷�����ı�������������з��ų˷��ұ������Ǹ�������ôȡ���� */
	assign mult_op1 = (((aluc == `EXE_MUL_OP) || (aluc == `EXE_MULT_OP) ||
						(aluc == `EXE_MADD_OP) || (aluc == `EXE_MSUB_OP)) & 
						(op1[31] == 1'b1)) ? (~op1 + 1) : op1;

	/* ȡ�ó˷�����ĳ�����������з��ų˷��ұ������Ǹ�������ôȡ���� */
	assign mult_op2 = (((aluc == `EXE_MUL_OP) || (aluc == `EXE_MULT_OP) ||
						(aluc == `EXE_MADD_OP) || (aluc == `EXE_MSUB_OP)) && 
						(op2[31] == 1'b1)) ? (~op2 + 1) : op2;

	assign HILI_tmp_out = mult_op1 * mult_op2;	

	/************ ���ݲ�ͬ�������������ͣ���arithRes��ֵ ***********/				
	always @ (*) begin
		if (rst == `RstEnable)
			arithRes <= `ZeroWord;
		else begin
			case (aluc)
				`EXE_SLT_OP, `EXE_SLTU_OP:
					arithRes <= reg1_lt_reg2 ;
				`EXE_ADD_OP, `EXE_ADDU_OP, `EXE_ADDI_OP, `EXE_ADDIU_OP, `EXE_SUB_OP, `EXE_SUBU_OP:
					arithRes <= sumRes; 
				`EXE_CLZ_OP:
                	arithRes <= op1[31] ? 0 : op1[30] ? 1 : op1[29] ? 2 : 
								op1[28] ? 3 : op1[27] ? 4 : op1[26] ? 5 :
								op1[25] ? 6 : op1[24] ? 7 : op1[23] ? 8 : 
								op1[22] ? 9 : op1[21] ? 10 : op1[20] ? 11 :
								op1[19] ? 12 : op1[18] ? 13 : op1[17] ? 14 : 
								op1[16] ? 15 : op1[15] ? 16 : op1[14] ? 17 : 
								op1[13] ? 18 : op1[12] ? 19 : op1[11] ? 20 :
								op1[10] ? 21 : op1[9] ? 22 : op1[8] ? 23 : 
								op1[7] ? 24 : op1[6] ? 25 : op1[5] ? 26 : 
								op1[4] ? 27 : op1[3] ? 28 : op1[2] ? 29 : 
								op1[1] ? 30 : op1[0] ? 31 : 32 ;
            	`EXE_CLO_OP:
                // ����CLO������ȡ��op1��Ȼ��ʹ����CLZ��ͬ�ķ�������
					arithRes <= (reg1_not[31] ? 0 : reg1_not[30] ? 1 : reg1_not[29] ? 2 :
								reg1_not[28] ? 3 : reg1_not[27] ? 4 : reg1_not[26] ? 5 :
								reg1_not[25] ? 6 : reg1_not[24] ? 7 : reg1_not[23] ? 8 : 
								reg1_not[22] ? 9 : reg1_not[21] ? 10 : reg1_not[20] ? 11 :
								reg1_not[19] ? 12 : reg1_not[18] ? 13 : reg1_not[17] ? 14 : 
								reg1_not[16] ? 15 : reg1_not[15] ? 16 : reg1_not[14] ? 17 : 
								reg1_not[13] ? 18 : reg1_not[12] ? 19 : reg1_not[11] ? 20 :
								reg1_not[10] ? 21 : reg1_not[9] ? 22 : reg1_not[8] ? 23 : 
								reg1_not[7] ? 24 : reg1_not[6] ? 25 : reg1_not[5] ? 26 : 
								reg1_not[4] ? 27 : reg1_not[3] ? 28 : reg1_not[2] ? 29 : 
								reg1_not[1] ? 30 : reg1_not[0] ? 31 : 32) ;
				default:
					arithRes <= `ZeroWord;
			endcase
		end
	end

	/****************** �ж��Ƿ��������쳣 *****************/
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

	/************ ���ݲ�ͬ�ĳ˷��������ͣ���mulRes��ֵ ***********/
	always @ (*) begin
		if (rst == `RstEnable)
			mulRes <= {`ZeroWord, `ZeroWord};
		else if ((aluc == `EXE_MULT_OP) || (aluc == `EXE_MUL_OP) || (aluc == `EXE_MADD_OP) || (aluc == `EXE_MSUB_OP)) begin
			// �������ͳ����ķ���λ��ͬ
			if (op1[31] ^ op2[31] == 1'b1)
				mulRes <= ~HILI_tmp_out + 1;
			// �������ͳ����ķ���λ��ͬ
			else
				mulRes <= HILI_tmp_out;
		end 
		// multu
		else
			mulRes <= HILI_tmp_out;
	end

	/****** �õ����µ�HI��LO�Ĵ�����ֵ���˴�Ҫ�������������� *******/
	always @ (*) begin
		if (rst == `RstEnable)
			{HI, LO} <= {`ZeroWord, `ZeroWord};
		// �ô�׶ε�ָ��ҪдHI��LO�Ĵ���
		else if (MEM_HILO_ena == `WriteEnable)
			{HI, LO} <= {MEM_HI, MEM_LO};
		// ��д�׶ε�ָ��ҪдHI��LO�Ĵ���
		else if(WB_HILO_ena == `WriteEnable)
			{HI, LO} <= {WB_HI, WB_LO};
		else
			{HI, LO} <= {regHI, regLO};			
	end	

	/**************** ��ͣ��ˮ�� *****************/
	always @ (*) begin
		stallOut = stall_madd_msub || stall_div_divu;
	end

	/**************** MADD��MADDU��MSUB��MSUBUָ�� *****************/
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
					// ִ�н׶ε�һ��ʱ������
					if (HILOCnt == 2'b00) begin
						// ����MSUB��MSUBU��ȡ����һ��MADD��MADDUֱ�Ӹ�ֵ
						HILO_tmp_out <= (aluc == `EXE_MSUB_OP || aluc == `EXE_MSUBU_OP) ? (~mulRes + 1) : mulRes;
						cntOut <= 2'b01;
						stall_madd_msub <= `Stop;
					end
					// ִ�н׶εڶ���ʱ������
					else if (HILOCnt == 2'b01) begin
						cntOut <= 2'b10;
						// ���ڵڶ����ڣ�ͳһ����HILO_tmp1�ĸ���
						HILO_tmp1 <= HILO_tmp + {HI, LO};
					end
				end
			endcase
		end
	end	

	/*********************** DIV��DIVUָ�� *****************************/
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
	end

	/**************** MFHI��MFLO��MOVN��MOVZָ�� *****************/
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
					// ����MFC0��ֱ�Ӷ�ȡCP0�Ĵ��������ݡ���Ҫ�����Ƿ����������
					movRes <= (mem_cp0_wena && mem_cp0_waddr == instr[15:11]) ? mem_cp0_data :
							(wb_cp0_wena && wb_cp0_waddr == instr[15:11]) ? wb_cp0_data :
							cp0_dataIn;
				end
				default : begin
				end
			endcase
		end
	end

	/****** ����alucSelectָʾ���������ͣ�ѡ��һ����������Ϊ���ս�� *******/
 	always @ (*) begin
		wd_out <= EXE_waddr;	// Ҫд��Ŀ�ļĴ�����ַ
		reg_wena <= ((aluc == `EXE_ADD_OP || aluc == `EXE_ADDI_OP || aluc == `EXE_SUB_OP) && overflow) ? `WriteDisable : EXE_wena;
    	isOverflow <= (aluc == `EXE_ADD_OP || aluc == `EXE_ADDI_OP || aluc == `EXE_SUB_OP) && overflow;
		
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

	/********************* HO/LO�Ĵ��� **********************/
	always @ (*) begin
		case (1'b1)
			(rst == `RstEnable): begin
				HILO_ena_out <= `WriteDisable;
				HIOut <= `ZeroWord;
				LOOut <= `ZeroWord;
			end
			default: begin
				case (aluc)
					`EXE_MULT_OP, `EXE_MULTU_OP: begin
						HILO_ena_out <= `WriteEnable;
						HIOut <= mulRes[63:32];
						LOOut <= mulRes[31:0];
					end
					`EXE_MADD_OP, `EXE_MADDU_OP,
					`EXE_MSUB_OP, `EXE_MSUBU_OP: begin
						HILO_ena_out <= `WriteEnable;
						HIOut <= HILO_tmp1[63:32];
						LOOut <= HILO_tmp1[31:0];
					end
					`EXE_DIV_OP, `EXE_DIVU_OP: begin
						HILO_ena_out <= `WriteEnable;
						HIOut <= DIVRes[63:32];
						LOOut <= DIVRes[31:0];
					end
					`EXE_MTHI_OP: begin
						HILO_ena_out <= `WriteEnable;
						HIOut <= op1;
						LOOut <= LO;
					end
					`EXE_MTLO_OP: begin
						HILO_ena_out <= `WriteEnable;
						HIOut <= HI;
						LOOut <= op1;
					end
					default: begin
						HILO_ena_out <= `WriteDisable;
						HIOut <= `ZeroWord;
						LOOut <= `ZeroWord;
					end
				endcase
			end
		endcase
	end

	/****************** ����mtc0ָ���ִ�н�� *******************/
	always @ (*) begin
		cp0_reg_waddr_out <= 5'b00000;
		cp0_reg_wena_out <= `WriteDisable;
		cp0_reg_data_out <= `ZeroWord;

		// ����λ��`MTC0`ָ��
		if (!rst && aluc == `EXE_MTC0_OP) begin
			cp0_reg_waddr_out <= instr[15:11];
			cp0_reg_wena_out <= `WriteEnable;
			cp0_reg_data_out <= op1;
		end
	end
	
endmodule