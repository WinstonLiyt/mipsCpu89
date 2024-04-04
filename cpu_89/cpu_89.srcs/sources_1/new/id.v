/* -----------------------------------------
Func����ָ��������룬�õ�������������͡������͡�
	  Դ������1��Դ������ 2��Ҫд���Ŀ�ļĴ���
	  ��ַ����Ϣ��������������ָ�����߼����㡢
	  ��λ���㡢��������ȣ�������ָ���Ǹ�����ϸ
	  ���������ͣ�����:�������������߼�����ʱ��
	  ���������Ϳ������߼��������㡢�߼����롱���㡢
	  �߼����������ȡ�
------------------------------------------- */

`include "defines.vh"
`timescale 1ns / 1ps

module id(
	input rst,
	input [`InstAddrBus] pcIn,
	input [`InstBus] instr,

  	input [`AluOpBus] exe_aluc,		// ALU�����ź�

	// ��������ǰ�Ƶķ����������ˮ�������������
	input exe_waddr_in,				// �Ƿ�ҪдĿ�ļĴ�����EXE��
	input [`RegBus] exe_data_in,	// Ŀ��Ĵ�������
	input [`RegAddrBus] exe_wd_in,	// Ŀ��Ĵ�����ַ
	input mem_waddr_in,				// �Ƿ�ҪдĿ�ļĴ�����MEM��
	input [`RegBus] mem_data_in,	// Ŀ��Ĵ�������
	input [`RegAddrBus] mem_wd_in,	// Ŀ��Ĵ�����ַ
	input [`RegBus] op1_in, op2_in,	// Դ������1/2
	input isInDelaySlot,			// �Ƿ����ӳٲ�

	output reg op1_rena, op2_rena,						// ��ʹ�� 
	output reg[`RegAddrBus] op1AddrOut, op2AddrOut, 	// Դ������1/2��ַ	      
	output reg[`AluOpBus] alucOut,						// ALU�����ź�
	output reg[`AluSelBus] alucSelOut,					// ALUѡ���ź�
	output reg[`RegBus] op1_out, op2_out,				// Դ������1/2����
	output reg[`RegAddrBus] wd_out,						// Ŀ��Ĵ�����ַ
	output reg reg_wena,								// дʹ��
	output wire[`RegBus] inst_out,						// ָ����������ڴ洢ָ�

	output reg nxtInstrInDelaySlotsOut,					// ��һ��ָ���Ƿ����ӳٲ�
	output reg isBranch,								// �Ƿ��֧
	output reg[`RegBus] branchAddr,						// ��֧Ŀ���ַ
	output reg[`RegBus] linkAddr,						// ���ӵ�ַ
	output reg isInDelaySlotOut,						// �Ƿ����ӳٲ�
  	output [`RegBus] exceptionTypeOut,					// �쳣����
  	output [`RegBus] curInstrAddrOut,					// ��ǰָ���ַ
	output stallOut										// ��ͣ�ź�
);

	assign inst_out = instr;

	wire[5:0] op = instr[31:26];	// op
	wire[5:0] func = instr[5:0];	// func
	wire[4:0] rt = instr[20:16];	// rt
	wire[4:0] rs = instr[25:21];	// rs
	wire[4:0] rd = instr[15:11];	// rd
	wire[4:0] shamt = instr[10:6];	// shamt
	reg[`RegBus] imm;				// ������
	wire[`RegBus] offset;			// offset
	assign offset = {{14{instr[15]}}, instr[15:0], 2'b00};

	wire[`RegBus] pc4;
	assign pc4 = pcIn + 4;
	assign curInstrAddrOut = pcIn;
	wire[`RegBus] pc8;
	assign pc8 = pcIn + 8;
	wire preInstrIsLoad;			// ǰһ��ָ���Ƿ���Loadָ��
	reg instvalid;					// ָ����Ч
	reg isSyscall, isEret;			// �Ƿ���ϵͳ����/�쳣����
	reg stallLoad1, stallLoad2;
	assign stallOut = stallLoad1 | stallLoad2;
	assign preInstrIsLoad = ((exe_aluc == `EXE_LB_OP) || (exe_aluc == `EXE_LBU_OP) 
						 || (exe_aluc == `EXE_LH_OP) || (exe_aluc == `EXE_LHU_OP)
						 || (exe_aluc == `EXE_LW_OP) || (exe_aluc == `EXE_LWR_OP)
						 || (exe_aluc == `EXE_LWL_OP)|| (exe_aluc == `EXE_LL_OP)
						 || (exe_aluc == `EXE_SC_OP)) ? 1'b1 : 1'b0;
	/* exceptionTypeOut�ĵ�8bit�����ⲿ�жϣ���8bit��ʾ�Ƿ���syscallָ�������ϵͳ�����쳣��
	   ��9bit��ʾ�Ƿ�����Чָ��������쳣����12bit��ʾ�Ƿ���eretָ�
	   eretָ�������Ϊ��һ��������쳣--�����쳣 */
	assign exceptionTypeOut = {19'b0, isEret, 2'b0, instvalid, isSyscall, 8'b0};
    
	/*************************��ָ���������*************************/
	// nop��ssnopָ�������ʵ�֣���ȫ���Ե���������߼�����ָ��sll��
	always @ (*) begin	
		if (rst == `RstEnable) begin
			alucOut <= `EXE_NOP_OP;
			alucSelOut <= `EXE_RES_NOP;
			wd_out <= `NOPRegAddr;
			reg_wena <= `WriteDisable;
			instvalid <= `InstValid;
			op1_rena <= 1'b0;
			op2_rena <= 1'b0;
			op1AddrOut <= `NOPRegAddr;
			op2AddrOut <= `NOPRegAddr;
			imm <= 32'h0;	
			linkAddr <= `ZeroWord;
			branchAddr <= `ZeroWord;
			isBranch <= `NotBranch;
			nxtInstrInDelaySlotsOut <= `NotInDelaySlot;
			isSyscall <= `False_v;
			isEret <= `False_v;
	  	end
		else begin
			alucOut <= `EXE_NOP_OP;
			alucSelOut <= `EXE_RES_NOP;
			wd_out <= rd;
			reg_wena <= `WriteDisable;
			instvalid <= `InstInvalid;	   
			op1_rena <= 1'b0;
			op2_rena <= 1'b0;
			op1AddrOut <= rs;	// Դ������1��ַ
			op2AddrOut <= rt;	// Դ������2��ַ
			imm <= `ZeroWord;
			linkAddr <= `ZeroWord;
			branchAddr <= `ZeroWord;
			isBranch <= `NotBranch;	
			nxtInstrInDelaySlotsOut <= `NotInDelaySlot;
			isSyscall <= `False_v;	
			isEret <= `False_v;					 			
			case (op)
		    	`EXE_SPECIAL_INST: begin
				// shamt
					case (shamt)
		    			5'b00000: begin
							// func
		    				case (func)
								// R�����߼�ָ�4��
		    					`EXE_OR: begin
									reg_wena <= `WriteEnable;
									alucOut <= `EXE_OR_OP;
									alucSelOut <= `EXE_RES_LOGIC;
									op1_rena <= 1'b1;
									op2_rena <= 1'b1;
									instvalid <= `InstValid;	
								end  
		    					`EXE_AND: begin
									reg_wena <= `WriteEnable;
									alucOut <= `EXE_AND_OP;
									alucSelOut <= `EXE_RES_LOGIC;
									op1_rena <= 1'b1;
									op2_rena <= 1'b1;	
									instvalid <= `InstValid;	
								end  	
		    					`EXE_XOR: begin
									reg_wena <= `WriteEnable;
									alucOut <= `EXE_XOR_OP;
		  							alucSelOut <= `EXE_RES_LOGIC;
									op1_rena <= 1'b1;
									op2_rena <= 1'b1;	
		  							instvalid <= `InstValid;	
								end  				
		    					`EXE_NOR: begin
		    						reg_wena <= `WriteEnable;
									alucOut <= `EXE_NOR_OP;
		  							alucSelOut <= `EXE_RES_LOGIC;
									op1_rena <= 1'b1;
									op2_rena <= 1'b1;	
		  							instvalid <= `InstValid;	
								end 
								`EXE_SLLV: begin
									reg_wena <= `WriteEnable;
									alucOut <= `EXE_SLL_OP;
		  							alucSelOut <= `EXE_RES_SHIFT;
									op1_rena <= 1'b1;
									op2_rena <= 1'b1;
		  							instvalid <= `InstValid;	
								end 
								`EXE_SRLV: begin
									reg_wena <= `WriteEnable;
									alucOut <= `EXE_SRL_OP;
		  							alucSelOut <= `EXE_RES_SHIFT;
									op1_rena <= 1'b1;
									op2_rena <= 1'b1;
		  							instvalid <= `InstValid;	
								end 					
								`EXE_SRAV: begin
									reg_wena <= `WriteEnable;
									alucOut <= `EXE_SRA_OP;
		  							alucSelOut <= `EXE_RES_SHIFT;
									op1_rena <= 1'b1;
									op2_rena <= 1'b1;
		  							instvalid <= `InstValid;			
		  						end
								// �ƶ�����ָ�6��
								`EXE_MFHI: begin
									reg_wena <= `WriteEnable;
									alucOut <= `EXE_MFHI_OP;
		  							alucSelOut <= `EXE_RES_MOVE;
									op1_rena <= 1'b0;
									op2_rena <= 1'b0;
		  							instvalid <= `InstValid;	
								end
								`EXE_MFLO: begin
									reg_wena <= `WriteEnable;
									alucOut <= `EXE_MFLO_OP;
		  							alucSelOut <= `EXE_RES_MOVE;
									op1_rena <= 1'b0;
									op2_rena <= 1'b0;
		  							instvalid <= `InstValid;	
								end
								`EXE_MTHI: begin
									reg_wena <= `WriteDisable;  // ��дͨ�üĴ���
									alucOut <= `EXE_MTHI_OP;
		  							op1_rena <= 1'b1;
									op2_rena <= 1'b0; 
									instvalid <= `InstValid;	
								end
								`EXE_MTLO: begin
									reg_wena <= `WriteDisable;
									alucOut <= `EXE_MTLO_OP;
		  							op1_rena <= 1'b1;
									op2_rena <= 1'b0;
									instvalid <= `InstValid;	
								end
								`EXE_MOVN: begin
									alucOut <= `EXE_MOVN_OP;
		  							alucSelOut <= `EXE_RES_MOVE;
									op1_rena <= 1'b1;
									op2_rena <= 1'b1;
		  							instvalid <= `InstValid;
								 	if (op2_out != `ZeroWord)
	 									reg_wena <= `WriteEnable;
	 								else
	 									reg_wena <= `WriteDisable;
								end
								`EXE_MOVZ: begin
									alucOut <= `EXE_MOVZ_OP;
		  							alucSelOut <= `EXE_RES_MOVE;
									op1_rena <= 1'b1;
									op2_rena <= 1'b1;
		  							instvalid <= `InstValid;
								 	if (op2_out == `ZeroWord)
	 									reg_wena <= `WriteEnable;
	 								else
	 									reg_wena <= `WriteDisable;	  							
								end
								// ����������ָ�2��
								`EXE_SLT: begin
									reg_wena <= `WriteEnable;
									alucOut <= `EXE_SLT_OP;
		  							alucSelOut <= `EXE_RES_ARITHMETIC;
									op1_rena <= 1'b1;
									op2_rena <= 1'b1;
		  							instvalid <= `InstValid;	
								end
								`EXE_SLTU: begin
									reg_wena <= `WriteEnable;
									alucOut <= `EXE_SLTU_OP;
		  							alucSelOut <= `EXE_RES_ARITHMETIC;
									op1_rena <= 1'b1;
									op2_rena <= 1'b1;
		  							instvalid <= `InstValid;	
								end
								`EXE_SYNC: begin
									reg_wena <= `WriteDisable;
									alucOut <= `EXE_NOP_OP;
		  							alucSelOut <= `EXE_RES_NOP;
									op1_rena <= 1'b0;
									op2_rena <= 1'b1;
		  							instvalid <= `InstValid;	
								end
								// ����������ָ�4��
								`EXE_ADD: begin
									reg_wena <= `WriteEnable;
									alucOut <= `EXE_ADD_OP;
		  							alucSelOut <= `EXE_RES_ARITHMETIC;
									op1_rena <= 1'b1;
									op2_rena <= 1'b1;
		  							instvalid <= `InstValid;	
								end
								`EXE_ADDU: begin
									reg_wena <= `WriteEnable;
									alucOut <= `EXE_ADDU_OP;
		  							alucSelOut <= `EXE_RES_ARITHMETIC;
									op1_rena <= 1'b1;
									op2_rena <= 1'b1;
		  							instvalid <= `InstValid;	
								end
								`EXE_SUB: begin
									reg_wena <= `WriteEnable;
									alucOut <= `EXE_SUB_OP;
		  							alucSelOut <= `EXE_RES_ARITHMETIC;
									op1_rena <= 1'b1;
									op2_rena <= 1'b1;
		  							instvalid <= `InstValid;	
								end
								`EXE_SUBU: begin
									reg_wena <= `WriteEnable;
									alucOut <= `EXE_SUBU_OP;
		  							alucSelOut <= `EXE_RES_ARITHMETIC;
									op1_rena <= 1'b1;
									op2_rena <= 1'b1;
		  							instvalid <= `InstValid;	
								end
								// ����������ָ��-R��2��
								`EXE_MULT: begin
									reg_wena <= `WriteDisable;
									alucOut <= `EXE_MULT_OP;
		  							op1_rena <= 1'b1;
									op2_rena <= 1'b1;
									instvalid <= `InstValid;	
								end
								`EXE_MULTU: begin
									reg_wena <= `WriteDisable;
									alucOut <= `EXE_MULTU_OP;
		  							op1_rena <= 1'b1;
									op2_rena <= 1'b1;
									instvalid <= `InstValid;	
								end
								// ������2��
								`EXE_DIV: begin
									reg_wena <= `WriteDisable;
									alucOut <= `EXE_DIV_OP;
		  							op1_rena <= 1'b1;
									op2_rena <= 1'b1;
									instvalid <= `InstValid;	
								end
								`EXE_DIVU: begin
									reg_wena <= `WriteDisable;
									alucOut <= `EXE_DIVU_OP;
		  							op1_rena <= 1'b1;
									op2_rena <= 1'b1;
									instvalid <= `InstValid;	
								end
								// ��תָ�2��
								`EXE_JR: begin  // ����Ҫ���淵�ص�ַ����Ϊ����ת��
									reg_wena <= `WriteDisable;
									alucOut <= `EXE_JR_OP;
		  							alucSelOut <= `EXE_RES_JUMP_BRANCH;
									op1_rena <= 1'b1;
									op2_rena <= 1'b0;
		  							linkAddr <= `ZeroWord;
									branchAddr <= op1_out;
									isBranch <= `Branch;
									nxtInstrInDelaySlotsOut <= `InDelaySlot;
									instvalid <= `InstValid;	
								end
								`EXE_JALR: begin  // ��Ҫ���淵�ص�ַ�����ص�ַΪ��ǰת��ָ������2��ָ��ĵ�ַ
									reg_wena <= `WriteEnable;
									alucOut <= `EXE_JALR_OP;
		  							alucSelOut <= `EXE_RES_JUMP_BRANCH;
									op1_rena <= 1'b1;
									op2_rena <= 1'b0;
		  							wd_out <= rd;
		  							linkAddr <= pc8;
									branchAddr <= op1_out;
			            			isBranch <= `Branch;
									nxtInstrInDelaySlotsOut <= `InDelaySlot;
			            			instvalid <= `InstValid;	
								end													 											  											
								default: begin
								end
							endcase
						end
						default: begin
						end
					endcase	
					case (func)
						// �쳣ָ�6��
						`EXE_TEQ: begin
							reg_wena <= `WriteDisable;
							alucOut <= `EXE_TEQ_OP;
		  					alucSelOut <= `EXE_RES_NOP;
							op1_rena <= 1'b0;
							op2_rena <= 1'b0;
		  					instvalid <= `InstValid;
		  				end
		  				`EXE_TGE: begin
							reg_wena <= `WriteDisable;
							alucOut <= `EXE_TGE_OP;
		  					alucSelOut <= `EXE_RES_NOP;
							op1_rena <= 1'b1;
							op2_rena <= 1'b1;
		  					instvalid <= `InstValid;
		  				end		
		  				`EXE_TGEU: begin
							reg_wena <= `WriteDisable;
							alucOut <= `EXE_TGEU_OP;
		  					alucSelOut <= `EXE_RES_NOP;
							op1_rena <= 1'b1;
							op2_rena <= 1'b1;
		  					instvalid <= `InstValid;
		  				end	
		  				`EXE_TLT: begin
							reg_wena <= `WriteDisable;
							alucOut <= `EXE_TLT_OP;
		  					alucSelOut <= `EXE_RES_NOP;
							op1_rena <= 1'b1;
							op2_rena <= 1'b1;
		  					instvalid <= `InstValid;
		  				end
						`EXE_TLTU: begin
							reg_wena <= `WriteDisable;
							alucOut <= `EXE_TLTU_OP;
							alucSelOut <= `EXE_RES_NOP;
							op1_rena <= 1'b1;
							op2_rena <= 1'b1;
							instvalid <= `InstValid;
						end	
						`EXE_TNE: begin
							reg_wena <= `WriteDisable;
							alucOut <= `EXE_TNE_OP;
							alucSelOut <= `EXE_RES_NOP;
							op1_rena <= 1'b1;
							op2_rena <= 1'b1;
							instvalid <= `InstValid;
		  				end
						`EXE_SYSCALL: begin
							reg_wena <= `WriteDisable;
							alucOut <= `EXE_SYSCALL_OP;
							alucSelOut <= `EXE_RES_NOP;
							op1_rena <= 1'b0;
							op2_rena <= 1'b0;
							instvalid <= `InstValid;
							isSyscall<= `True_v;  // �����⡿
						end							 																					
						default: begin
						end	
					endcase									
				end
				// I����ָ�4��
		  		`EXE_ORI: begin
		  			reg_wena <= `WriteEnable;		// oriָ����Ҫ�����д��Ŀ�ļĴ���
					alucOut <= `EXE_OR_OP;			// ����������Ϊ�߼���������
		  			alucSelOut <= `EXE_RES_LOGIC;	// ��������Ϊ�߼�����
					op1_rena <= 1'b1;				// ��Ҫͨ�� Regfile�Ķ��˿�1��ȡ�Ĵ���
					op2_rena <= 1'b0;	  			// ����Ҫͨ�� Regfile�Ķ��˿�2��ȡ�Ĵ���
					imm <= {16'h0, instr[15:0]};	// ������Ϊָ��ĵ�16λ
					wd_out <= rt;					// Ŀ�ļĴ�����ַΪָ���rt�ֶ�
					instvalid <= `InstValid;		// ָ����Ч
		  		end
		  		`EXE_ANDI: begin
		  			reg_wena <= `WriteEnable; 
					alucOut <= `EXE_AND_OP;
		  			alucSelOut <= `EXE_RES_LOGIC;
					op1_rena <= 1'b1;
					op2_rena <= 1'b0;	  	
					imm <= {16'h0, instr[15:0]};
					wd_out <= rt;		  	
					instvalid <= `InstValid;	
				end	 	
		  		`EXE_XORI: begin
		  			reg_wena <= `WriteEnable;
					alucOut <= `EXE_XOR_OP;
		  			alucSelOut <= `EXE_RES_LOGIC;
					op1_rena <= 1'b1;
					op2_rena <= 1'b0;	  	
					imm <= {16'h0, instr[15:0]};
					wd_out <= rt;		  	
					instvalid <= `InstValid;	
				end	 		
		  		`EXE_LUI: begin  // ת��oriָ��
		  			reg_wena <= `WriteEnable;
					alucOut <= `EXE_OR_OP;
		  			alucSelOut <= `EXE_RES_LOGIC;
					op1_rena <= 1'b1;
					op2_rena <= 1'b0;	  	
					imm <= {instr[15:0], 16'h0};
					wd_out <= rt;		  	
					instvalid <= `InstValid;	
				end
				// ����������ָ�2��	
				`EXE_SLTI: begin
		  			reg_wena <= `WriteEnable;
					alucOut <= `EXE_SLT_OP;
		  			alucSelOut <= `EXE_RES_ARITHMETIC;
					op1_rena <= 1'b1;
					op2_rena <= 1'b0;	  	
					imm <= {{16{instr[15]}}, instr[15:0]};
					wd_out <= rt;		  	
					instvalid <= `InstValid;	
				end
				`EXE_SLTIU: begin
		  			reg_wena <= `WriteEnable;
					alucOut <= `EXE_SLTU_OP;
		  			alucSelOut <= `EXE_RES_ARITHMETIC;
					op1_rena <= 1'b1;
					op2_rena <= 1'b0;	  	
					imm <= {{16{instr[15]}}, instr[15:0]};
					wd_out <= rt;		  	
					instvalid <= `InstValid;	
				end
				`EXE_PREF: begin
		  			reg_wena <= `WriteDisable;
					alucOut <= `EXE_NOP_OP;
		  			alucSelOut <= `EXE_RES_NOP;
					op1_rena <= 1'b0;
					op2_rena <= 1'b0;	  	  	
					instvalid <= `InstValid;	
				end
				// ����������ָ�2��				
				`EXE_ADDI: begin
		  			reg_wena <= `WriteEnable;
					alucOut <= `EXE_ADDI_OP;
		  			alucSelOut <= `EXE_RES_ARITHMETIC;
					op1_rena <= 1'b1;
					op2_rena <= 1'b0;	  	
					imm <= {{16{instr[15]}}, instr[15:0]};
					wd_out <= rt;		  	
					instvalid <= `InstValid;	
				end
				`EXE_ADDIU: begin
		  			reg_wena <= `WriteEnable;
					alucOut <= `EXE_ADDIU_OP;
		  			alucSelOut <= `EXE_RES_ARITHMETIC;
					op1_rena <= 1'b1;
					op2_rena <= 1'b0;
					imm <= {{16{instr[15]}}, instr[15:0]};
					wd_out <= rt;
					instvalid <= `InstValid;
				end
				// ��תָ�6��
				`EXE_J: begin
		  			reg_wena <= `WriteDisable;
					alucOut <= `EXE_J_OP;
		  			alucSelOut <= `EXE_RES_JUMP_BRANCH;
					op1_rena <= 1'b0;
					op2_rena <= 1'b0;
		  			linkAddr <= `ZeroWord;
			    	branchAddr <= {pc4[31:28], instr[25:0], 2'b00};
			    	isBranch <= `Branch;
			    	nxtInstrInDelaySlotsOut <= `InDelaySlot;
			    	instvalid <= `InstValid;
				end
				`EXE_JAL: begin
		  			reg_wena <= `WriteEnable;
					alucOut <= `EXE_JAL_OP;
		  			alucSelOut <= `EXE_RES_JUMP_BRANCH;
					op1_rena <= 1'b0;
					op2_rena <= 1'b0;
					wd_out <= 5'b11111;
					linkAddr <= pc8 ;
					branchAddr <= {pc4[31:28], instr[25:0], 2'b00};
					isBranch <= `Branch;
					nxtInstrInDelaySlotsOut <= `InDelaySlot;
					instvalid <= `InstValid;
				end
				`EXE_BEQ: begin
		  			reg_wena <= `WriteDisable;
					alucOut <= `EXE_BEQ_OP;
					alucSelOut <= `EXE_RES_JUMP_BRANCH;
					op1_rena <= 1'b1;
					op2_rena <= 1'b1;
		  			instvalid <= `InstValid;	
					if (op1_out == op2_out) begin
						branchAddr <= pc4 + offset;
						isBranch <= `Branch;
						nxtInstrInDelaySlotsOut <= `InDelaySlot;		  	
					end
				end
				`EXE_BGTZ: begin
					reg_wena <= `WriteDisable;
					alucOut <= `EXE_BGTZ_OP;
					alucSelOut <= `EXE_RES_JUMP_BRANCH;
					op1_rena <= 1'b1;
					op2_rena <= 1'b0;
					instvalid <= `InstValid;	
					if ((op1_out[31] == 1'b0) && (op1_out != `ZeroWord)) begin
						branchAddr <= pc4 + offset;
						isBranch <= `Branch;
						nxtInstrInDelaySlotsOut <= `InDelaySlot;		  	
			    	end
				end
				`EXE_BLEZ: begin
					reg_wena <= `WriteDisable;
					alucOut <= `EXE_BLEZ_OP;
					alucSelOut <= `EXE_RES_JUMP_BRANCH;
					op1_rena <= 1'b1;
					op2_rena <= 1'b0;
					instvalid <= `InstValid;	
					if ((op1_out[31] == 1'b1) || (op1_out == `ZeroWord)) begin
						branchAddr <= pc4 + offset;
						isBranch <= `Branch;
						nxtInstrInDelaySlotsOut <= `InDelaySlot;		  	
					end
				end
				`EXE_BNE: begin
					reg_wena <= `WriteDisable;
					alucOut <= `EXE_BLEZ_OP;
					alucSelOut <= `EXE_RES_JUMP_BRANCH;
					op1_rena <= 1'b1;
					op2_rena <= 1'b1;
					instvalid <= `InstValid;	
					if (op1_out != op2_out) begin
						branchAddr <= pc4 + offset;
						isBranch <= `Branch;
						nxtInstrInDelaySlotsOut <= `InDelaySlot;		  	
					end
				end
				// ���ش洢ָ�13��LL�����⴦��
				`EXE_LB: begin
					reg_wena <= `WriteEnable;
					alucOut <= `EXE_LB_OP;
					alucSelOut <= `EXE_RES_LOAD_STORE;
					op1_rena <= 1'b1;
					op2_rena <= 1'b0;	  	
					wd_out <= rt;
					instvalid <= `InstValid;	
				end
				`EXE_LBU: begin
		  			reg_wena <= `WriteEnable;
					alucOut <= `EXE_LBU_OP;
		  			alucSelOut <= `EXE_RES_LOAD_STORE;
					op1_rena <= 1'b1;
					op2_rena <= 1'b0;	  	
					wd_out <= rt;
					instvalid <= `InstValid;	
				end
				`EXE_LH: begin
					reg_wena <= `WriteEnable;
					alucOut <= `EXE_LH_OP;
					alucSelOut <= `EXE_RES_LOAD_STORE;
					op1_rena <= 1'b1;
					op2_rena <= 1'b0;	  	
					wd_out <= rt;
					instvalid <= `InstValid;	
				end
				`EXE_LHU: begin
		  			reg_wena <= `WriteEnable;
					alucOut <= `EXE_LHU_OP;
		  			alucSelOut <= `EXE_RES_LOAD_STORE;
					op1_rena <= 1'b1;
					op2_rena <= 1'b0;	  	
					wd_out <= rt;
					instvalid <= `InstValid;	
				end
				`EXE_LW: begin
		  			reg_wena <= `WriteEnable;
					alucOut <= `EXE_LW_OP;
		  			alucSelOut <= `EXE_RES_LOAD_STORE;
					op1_rena <= 1'b1;
					op2_rena <= 1'b0;	  	
					wd_out <= rt;
					instvalid <= `InstValid;	
				end
				`EXE_LL: begin
		  			reg_wena <= `WriteEnable;
					alucOut <= `EXE_LL_OP;
					alucSelOut <= `EXE_RES_LOAD_STORE;
					op1_rena <= 1'b1;
					op2_rena <= 1'b0;	  	
					wd_out <= rt;
					instvalid <= `InstValid;	
				end
				`EXE_LWL: begin
					reg_wena <= `WriteEnable;
					alucOut <= `EXE_LWL_OP;
					alucSelOut <= `EXE_RES_LOAD_STORE;
					op1_rena <= 1'b1;
					op2_rena <= 1'b1;  // ֻ�ǲ����޸�Ŀ�ļĴ��������Ի������Ŀ�ļĴ���
					wd_out <= rt;
					instvalid <= `InstValid;	
				end
				`EXE_LWR: begin
		  			reg_wena <= `WriteEnable;
					alucOut <= `EXE_LWR_OP;
		  			alucSelOut <= `EXE_RES_LOAD_STORE;
					op1_rena <= 1'b1;
					op2_rena <= 1'b1;	  	
					wd_out <= rt;
					instvalid <= `InstValid;	
				end	
				`EXE_SB: begin
					reg_wena <= `WriteDisable;
					alucOut <= `EXE_SB_OP;
					op1_rena <= 1'b1;
					op2_rena <= 1'b1;
					instvalid <= `InstValid;	
					alucSelOut <= `EXE_RES_LOAD_STORE; 
				end
				`EXE_SH: begin
					reg_wena <= `WriteDisable;
					alucOut <= `EXE_SH_OP;
					op1_rena <= 1'b1;
					op2_rena <= 1'b1;
					instvalid <= `InstValid;	
					alucSelOut <= `EXE_RES_LOAD_STORE; 
				end
				`EXE_SW: begin
					reg_wena <= `WriteDisable;
					alucOut <= `EXE_SW_OP;
					op1_rena <= 1'b1;
					op2_rena <= 1'b1;
					instvalid <= `InstValid;	
					alucSelOut <= `EXE_RES_LOAD_STORE; 
				end
				`EXE_SWL: begin  // �Ƕ���洢ָ�����洢
					reg_wena <= `WriteDisable;
					alucOut <= `EXE_SWL_OP;
					op1_rena <= 1'b1;
					op2_rena <= 1'b1;
					instvalid <= `InstValid;	
					alucSelOut <= `EXE_RES_LOAD_STORE; 
				end
				`EXE_SWR: begin
					reg_wena <= `WriteDisable;
					alucOut <= `EXE_SWR_OP;
					op1_rena <= 1'b1;
					op2_rena <= 1'b1;
					instvalid <= `InstValid;	
					alucSelOut <= `EXE_RES_LOAD_STORE; 
				end
				`EXE_SC: begin
					reg_wena <= `WriteEnable;
					alucOut <= `EXE_SC_OP;
					alucSelOut <= `EXE_RES_LOAD_STORE;
					op1_rena <= 1'b1;
					op2_rena <= 1'b1;	  	
					wd_out <= rt;
					instvalid <= `InstValid;	
					alucSelOut <= `EXE_RES_LOAD_STORE; 
				end								
				`EXE_REGIMM_INST: begin
					case (rt)
						// ��תָ�4��
						`EXE_BGEZ: begin
							reg_wena <= `WriteDisable;
							alucOut <= `EXE_BGEZ_OP;
		  					alucSelOut <= `EXE_RES_JUMP_BRANCH;
							op1_rena <= 1'b1;
							op2_rena <= 1'b0;
		  					instvalid <= `InstValid;	
							if (op1_out[31] == 1'b0) begin
								branchAddr <= pc4 + offset;
								isBranch <= `Branch;
								nxtInstrInDelaySlotsOut <= `InDelaySlot;		  	
							end
						end
						`EXE_BGEZAL: begin  // ���ص�ַ���浽�Ĵ��� $31
							reg_wena <= `WriteEnable;
							alucOut <= `EXE_BGEZAL_OP;
		  					alucSelOut <= `EXE_RES_JUMP_BRANCH;
							op1_rena <= 1'b1;
							op2_rena <= 1'b0;
		  					linkAddr <= pc8; 
		  					wd_out <= 5'b11111;
							instvalid <= `InstValid;
		  					if (op1_out[31] == 1'b0) begin
								branchAddr <= pc4 + offset;
								isBranch <= `Branch;
								nxtInstrInDelaySlotsOut <= `InDelaySlot;
			   				end
						end
						`EXE_BLTZ: begin
							reg_wena <= `WriteDisable;
							alucOut <= `EXE_BGEZAL_OP;
							alucSelOut <= `EXE_RES_JUMP_BRANCH;
							op1_rena <= 1'b1;
							op2_rena <= 1'b0;
							instvalid <= `InstValid;	
							if (op1_out[31] == 1'b1) begin
								branchAddr <= pc4 + offset;
								isBranch <= `Branch;
								nxtInstrInDelaySlotsOut <= `InDelaySlot;		  	
							end
						end
						`EXE_BLTZAL: begin
							reg_wena <= `WriteEnable;
							alucOut <= `EXE_BGEZAL_OP;
		  					alucSelOut <= `EXE_RES_JUMP_BRANCH;
							op1_rena <= 1'b1;
							op2_rena <= 1'b0;
		  					linkAddr <= pc8;	
		  					wd_out <= 5'b11111;
							instvalid <= `InstValid;
							if (op1_out[31] == 1'b1) begin
								branchAddr <= pc4 + offset;
								isBranch <= `Branch;
								nxtInstrInDelaySlotsOut <= `InDelaySlot;
							end
						end
						// �쳣ָ�6��
						`EXE_TEQI: begin
							reg_wena <= `WriteDisable;
							alucOut <= `EXE_TEQI_OP;
							alucSelOut <= `EXE_RES_NOP;
							op1_rena <= 1'b1;
							op2_rena <= 1'b0;	  	
							imm <= {{16{instr[15]}}, instr[15:0]};		  	
							instvalid <= `InstValid;	
						end
						`EXE_TGEI: begin
							reg_wena <= `WriteDisable;
							alucOut <= `EXE_TGEI_OP;
							alucSelOut <= `EXE_RES_NOP;
							op1_rena <= 1'b1;
							op2_rena <= 1'b0;	  	
							imm <= {{16{instr[15]}}, instr[15:0]};		  	
							instvalid <= `InstValid;	
						end
						`EXE_TGEIU: begin
							reg_wena <= `WriteDisable;
							alucOut <= `EXE_TGEIU_OP;
							alucSelOut <= `EXE_RES_NOP;
							op1_rena <= 1'b1;
							op2_rena <= 1'b0;	  	
							imm <= {{16{instr[15]}}, instr[15:0]};		  	
							instvalid <= `InstValid;	
						end
						`EXE_TLTI: begin
							reg_wena <= `WriteDisable;
							alucOut <= `EXE_TLTI_OP;
							alucSelOut <= `EXE_RES_NOP;
							op1_rena <= 1'b1;
							op2_rena <= 1'b0;	  	
							imm <= {{16{instr[15]}}, instr[15:0]};		  	
							instvalid <= `InstValid;	
						end
						`EXE_TLTIU: begin
							reg_wena <= `WriteDisable;
							alucOut <= `EXE_TLTIU_OP;
							alucSelOut <= `EXE_RES_NOP;
							op1_rena <= 1'b1;
							op2_rena <= 1'b0;	  	
							imm <= {{16{instr[15]}}, instr[15:0]};		  	
							instvalid <= `InstValid;	
						end
						`EXE_TNEI: begin
							reg_wena <= `WriteDisable;
							alucOut <= `EXE_TNEI_OP;
							alucSelOut <= `EXE_RES_NOP;
							op1_rena <= 1'b1;
							op2_rena <= 1'b0;	  	
							imm <= {{16{instr[15]}}, instr[15:0]};		  	
							instvalid <= `InstValid;	
						end						
						default: begin
						end
					endcase
				end								
				`EXE_SPECIAL2_INST: begin
					case (func)
						// ����������ָ��-R��3��
						`EXE_CLZ: begin
							reg_wena <= `WriteEnable;
							alucOut <= `EXE_CLZ_OP;
		  					alucSelOut <= `EXE_RES_ARITHMETIC;
							op1_rena <= 1'b1;
							op2_rena <= 1'b0;	  	
							instvalid <= `InstValid;	
						end
						`EXE_CLO: begin
							reg_wena <= `WriteEnable;
							alucOut <= `EXE_CLO_OP;
		  					alucSelOut <= `EXE_RES_ARITHMETIC;
							op1_rena <= 1'b1;
							op2_rena <= 1'b0;	  	
							instvalid <= `InstValid;	
						end
						`EXE_MUL: begin
							reg_wena <= `WriteEnable;
							alucOut <= `EXE_MUL_OP;
		  					alucSelOut <= `EXE_RES_MUL;
							op1_rena <= 1'b1;
							op2_rena <= 1'b1;	
		  					instvalid <= `InstValid;	  			
						end
						// ���ۼӡ����ۼ�ָ�4��
						`EXE_MADD: begin
							reg_wena <= `WriteDisable;
							alucOut <= `EXE_MADD_OP;
		  					alucSelOut <= `EXE_RES_MUL;
							op1_rena <= 1'b1;
							op2_rena <= 1'b1;	  			
		  					instvalid <= `InstValid;	
						end
						`EXE_MADDU:	begin
							reg_wena <= `WriteDisable;
							alucOut <= `EXE_MADDU_OP;
		  					alucSelOut <= `EXE_RES_MUL;
							op1_rena <= 1'b1;
							op2_rena <= 1'b1;	  			
		  					instvalid <= `InstValid;	
						end
						`EXE_MSUB: begin
							reg_wena <= `WriteDisable;
							alucOut <= `EXE_MSUB_OP;
							alucSelOut <= `EXE_RES_MUL;
							op1_rena <= 1'b1;
							op2_rena <= 1'b1;	  			
							instvalid <= `InstValid;	
						end
						`EXE_MSUBU: begin
							reg_wena <= `WriteDisable;
							alucOut <= `EXE_MSUBU_OP;
		  					alucSelOut <= `EXE_RES_MUL;
							op1_rena <= 1'b1;
							op2_rena <= 1'b1;	  			
		  					instvalid <= `InstValid;	
						end						
						default: begin
						end
					endcase
				end																		  	
				default: begin
				end
		  	endcase
		// R����ָ�3��
		// �������Ƚ����⣬Ҫ�� 21~25bit Ϊ0��-->�ж�ָ�� 21~31bit �Ƿ�ȫΪ0�������� 6~10bit Ϊ��λλ����
		if (instr[31:21] == 11'b00000000000) begin
		  	if (func == `EXE_SLL) begin
		  		reg_wena <= `WriteEnable;
				alucOut <= `EXE_SLL_OP;
		  		alucSelOut <= `EXE_RES_SHIFT;
				op1_rena <= 1'b0;
				op2_rena <= 1'b1;	  	
				imm[4:0] <= shamt;
				wd_out <= rd;
				instvalid <= `InstValid;	
			end
			else if (func == `EXE_SRL) begin
				reg_wena <= `WriteEnable;
				alucOut <= `EXE_SRL_OP;
				alucSelOut <= `EXE_RES_SHIFT;
				op1_rena <= 1'b0;
				op2_rena <= 1'b1;	  	
				imm[4:0] <= shamt;
				wd_out <= rd;
				instvalid <= `InstValid;	
			end
			else if (func == `EXE_SRA) begin
				reg_wena <= `WriteEnable;
				alucOut <= `EXE_SRA_OP;
				alucSelOut <= `EXE_RES_SHIFT;
				op1_rena <= 1'b0;
				op2_rena <= 1'b1;	  	
				imm[4:0] <= shamt;
				wd_out <= rd;
				instvalid <= `InstValid;	
			end
		end		  

     	if (instr == `EXE_ERET) begin
			reg_wena <= `WriteDisable;
			alucOut <= `EXE_ERET_OP;
			alucSelOut <= `EXE_RES_NOP;
			op1_rena <= 1'b0;
			op2_rena <= 1'b0;
			instvalid <= `InstValid; isEret<= `True_v;				
		end
		// mfc0
		else if (instr[31:21] == 11'b01000000000 && instr[10:0] == 11'b00000000000) begin
			alucOut <= `EXE_MFC0_OP;
			alucSelOut <= `EXE_RES_MOVE;
			wd_out <= rt;
			reg_wena <= `WriteEnable;
			instvalid <= `InstValid;	   
			op1_rena <= 1'b0;
			op2_rena <= 1'b0;		
		end
		// mtc0
		else if (instr[31:21] == 11'b01000000100 && instr[10:0] == 11'b00000000000) begin
			alucOut <= `EXE_MTC0_OP;
			alucSelOut <= `EXE_RES_NOP;
			reg_wena <= `WriteDisable;
			instvalid <= `InstValid;	   
			op1_rena <= 1'b1;
			op1AddrOut <= rt;
			op2_rena <= 1'b0;					
			end
		end
	end
	
	/************* ȷ�����������Դ������1 *************/
	always @ (*) begin
		stallLoad1 <= `NoStop;	
		if (rst == `RstEnable)
			op1_out <= `ZeroWord;
		// load���
		else if (preInstrIsLoad == 1'b1 && exe_wd_in == op1AddrOut && op1_rena == 1'b1)
			stallLoad1 <= `Stop;
		// ���Regfileģ����˿�1Ҫ��ȡ�ļĴ�������ִ�н׶�Ҫд��Ŀ�ļĴ�������ôֱ�Ӱ�ִ�н׶εĽ��exe_data_in��Ϊop1_out��ֵ��
		else if((op1_rena == 1'b1) && (exe_waddr_in == 1'b1) && (exe_wd_in == op1AddrOut))
			op1_out <= exe_data_in;
		// ���Regfileģ����˿�1Ҫ��ȡ�ļĴ������Ƿô�׶�Ҫд��Ŀ�ļĴ�������ôֱ�Ӱ�ִ�н׶εĽ��exe_data_in��Ϊop1_out��ֵ��
		else if((op1_rena == 1'b1) && (mem_waddr_in == 1'b1) && (mem_wd_in == op1AddrOut))
			op1_out <= mem_data_in; 			
		else if(op1_rena == 1'b1)	// �Ĵ���
			op1_out <= op1_in;
		else if(op1_rena == 1'b0)	// ������
	  		op1_out <= imm;
		else
	    	op1_out <= `ZeroWord;
	end
	
	/************* ȷ�����������Դ������1 *************/
	always @ (*) begin
		stallLoad2 <= `NoStop;
		if (rst == `RstEnable)
			op2_out <= `ZeroWord;
		else if (preInstrIsLoad == 1'b1 && exe_wd_in == op2AddrOut && op2_rena == 1'b1)
			stallLoad2 <= `Stop;			
		else if((op2_rena == 1'b1) && (exe_waddr_in == 1'b1) && (exe_wd_in == op2AddrOut))
			op2_out <= exe_data_in;
		else if((op2_rena == 1'b1) && (mem_waddr_in == 1'b1) && (mem_wd_in == op2AddrOut))
			op2_out <= mem_data_in;
		else if (op2_rena == 1'b1)
	  		op2_out <= op2_in;
		else if(op2_rena == 1'b0)
	  		op2_out <= imm;
	  	else
	    	op2_out <= `ZeroWord;
	end

	always @ (*) begin
		if (rst == `RstEnable)
			isInDelaySlotOut <= `NotInDelaySlot;
		else
			isInDelaySlotOut <= isInDelaySlot;
	end

endmodule