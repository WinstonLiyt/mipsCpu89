//@func   : 
//@time   : 
//@author :

`include "defines.vh"
`timescale 1ns / 1ps

module id(

	input wire					  rst,
	input wire[`InstAddrBus]	  pc_i,
	input wire[`InstBus]          instr,

  	input wire[`AluOpBus]		  ex_aluop_i,

	input wire					  ex_wreg_i,
	input wire[`RegBus]			  ex_wdata_i,
	input wire[`RegAddrBus]       ex_wd_i,
	
	input wire					  mem_wreg_i,
	input wire[`RegBus]			  mem_wdata_i,
	input wire[`RegAddrBus]       mem_wd_i,
	
	input wire[`RegBus]           reg1_data_i,
	input wire[`RegBus]           reg2_data_i,

	input wire                    isInDelaySlot,

	output reg                    reg1_read_o,
	output reg                    reg2_read_o,     
	output reg[`RegAddrBus]       reg1_addr_o,
	output reg[`RegAddrBus]       reg2_addr_o, 	      
	
	output reg[`AluOpBus]         aluc_out,
	output reg[`AluSelBus]        alusel_o,
	output reg[`RegBus]           reg1_o,
	output reg[`RegBus]           op2_out,
	output reg[`RegAddrBus]       wd_out,
	output reg                    reg_wena,
	output wire[`RegBus]          inst_o,

	output reg                    next_inst_in_delayslot_o,
	
	output reg                    branch_flag_o,
	output reg[`RegBus]           branch_target_address_o,       
	output reg[`RegBus]           link_addr_o,
	output reg                    isInDelaySlotOut,

  	output wire[31:0]             exceptionTypeOut,
  	output wire[`RegBus]          curInstrAddrOut,
	
	output wire                   stallOut	
);

  wire[5:0] op = instr[31:26];
  wire[4:0] op2 = instr[10:6];
  wire[5:0] op3 = instr[5:0];
  wire[4:0] op4 = instr[20:16];
  reg[`RegBus]	imm;
  reg instvalid;
  wire[`RegBus] pc_plus_8;
  wire[`RegBus] pc_plus_4;
  wire[`RegBus] imm_sll2_signedext;  

  reg stallreq_for_reg1_loadrelate;
  reg stallreq_for_reg2_loadrelate;
  wire pre_inst_is_load;
  reg excepttype_is_syscall;
  reg excepttype_is_eret;
  
  assign pc_plus_8 = pc_i + 8;
  assign pc_plus_4 = pc_i +4;
  assign imm_sll2_signedext = {{14{instr[15]}}, instr[15:0], 2'b00 };  
  assign stallOut = stallreq_for_reg1_loadrelate | stallreq_for_reg2_loadrelate;
  assign pre_inst_is_load = ((ex_aluop_i == `EXE_LB_OP) || 
  													(ex_aluop_i == `EXE_LBU_OP)||
  													(ex_aluop_i == `EXE_LH_OP) ||
  													(ex_aluop_i == `EXE_LHU_OP)||
  													(ex_aluop_i == `EXE_LW_OP) ||
  													(ex_aluop_i == `EXE_LWR_OP)||
  													(ex_aluop_i == `EXE_LWL_OP)||
  													(ex_aluop_i == `EXE_LL_OP) ||
  													(ex_aluop_i == `EXE_SC_OP)) ? 1'b1 : 1'b0;

  assign inst_o = instr;

  //exceptiontype�ĵ�8bit�����ⲿ�жϣ���9bit��ʾ�Ƿ���syscallָ��
  //��10bit��ʾ�Ƿ�����Чָ���11bit��ʾ�Ƿ���trapָ��
  assign exceptionTypeOut = {19'b0,excepttype_is_eret,2'b0,
  												instvalid, excepttype_is_syscall,8'b0};
  //assign excepttye_is_trapinst = 1'b0;
  
	assign curInstrAddrOut = pc_i;
    
	always @ (*) begin	
		if (rst == `RstEnable) begin
			aluc_out <= `EXE_NOP_OP;
			alusel_o <= `EXE_RES_NOP;
			wd_out <= `NOPRegAddr;
			reg_wena <= `WriteDisable;
			instvalid <= `InstValid;
			reg1_read_o <= 1'b0;
			reg2_read_o <= 1'b0;
			reg1_addr_o <= `NOPRegAddr;
			reg2_addr_o <= `NOPRegAddr;
			imm <= 32'h0;	
			link_addr_o <= `ZeroWord;
			branch_target_address_o <= `ZeroWord;
			branch_flag_o <= `NotBranch;
			next_inst_in_delayslot_o <= `NotInDelaySlot;
			excepttype_is_syscall <= `False_v;
			excepttype_is_eret <= `False_v;								
	  end else begin
			aluc_out <= `EXE_NOP_OP;
			alusel_o <= `EXE_RES_NOP;
			wd_out <= instr[15:11];
			reg_wena <= `WriteDisable;
			instvalid <= `InstInvalid;	   
			reg1_read_o <= 1'b0;
			reg2_read_o <= 1'b0;
			reg1_addr_o <= instr[25:21];
			reg2_addr_o <= instr[20:16];		
			imm <= `ZeroWord;
			link_addr_o <= `ZeroWord;
			branch_target_address_o <= `ZeroWord;
			branch_flag_o <= `NotBranch;	
			next_inst_in_delayslot_o <= `NotInDelaySlot;
			excepttype_is_syscall <= `False_v;	
			excepttype_is_eret <= `False_v;					 			
		  case (op)
		    `EXE_SPECIAL_INST:		begin
		    	case (op2)
		    		5'b00000:			begin
		    			case (op3)
		    				`EXE_OR:	begin
		    					reg_wena <= `WriteEnable;		aluc_out <= `EXE_OR_OP;
		  						alusel_o <= `EXE_RES_LOGIC; 	reg1_read_o <= 1'b1;	reg2_read_o <= 1'b1;
		  						instvalid <= `InstValid;	
								end  
		    				`EXE_AND:	begin
		    					reg_wena <= `WriteEnable;		aluc_out <= `EXE_AND_OP;
		  						alusel_o <= `EXE_RES_LOGIC;	  reg1_read_o <= 1'b1;	reg2_read_o <= 1'b1;	
		  						instvalid <= `InstValid;	
								end  	
		    				`EXE_XOR:	begin
		    					reg_wena <= `WriteEnable;		aluc_out <= `EXE_XOR_OP;
		  						alusel_o <= `EXE_RES_LOGIC;		reg1_read_o <= 1'b1;	reg2_read_o <= 1'b1;	
		  						instvalid <= `InstValid;	
								end  				
		    				`EXE_NOR:	begin
		    					reg_wena <= `WriteEnable;		aluc_out <= `EXE_NOR_OP;
		  						alusel_o <= `EXE_RES_LOGIC;		reg1_read_o <= 1'b1;	reg2_read_o <= 1'b1;	
		  						instvalid <= `InstValid;	
								end 
								`EXE_SLLV: begin
									reg_wena <= `WriteEnable;		aluc_out <= `EXE_SLL_OP;
		  						alusel_o <= `EXE_RES_SHIFT;		reg1_read_o <= 1'b1;	reg2_read_o <= 1'b1;
		  						instvalid <= `InstValid;	
								end 
								`EXE_SRLV: begin
									reg_wena <= `WriteEnable;		aluc_out <= `EXE_SRL_OP;
		  						alusel_o <= `EXE_RES_SHIFT;		reg1_read_o <= 1'b1;	reg2_read_o <= 1'b1;
		  						instvalid <= `InstValid;	
								end 					
								`EXE_SRAV: begin
									reg_wena <= `WriteEnable;		aluc_out <= `EXE_SRA_OP;
		  						alusel_o <= `EXE_RES_SHIFT;		reg1_read_o <= 1'b1;	reg2_read_o <= 1'b1;
		  						instvalid <= `InstValid;			
		  					end
								`EXE_MFHI: begin
									reg_wena <= `WriteEnable;		aluc_out <= `EXE_MFHI_OP;
		  						alusel_o <= `EXE_RES_MOVE;   reg1_read_o <= 1'b0;	reg2_read_o <= 1'b0;
		  						instvalid <= `InstValid;	
								end
								`EXE_MFLO: begin
									reg_wena <= `WriteEnable;		aluc_out <= `EXE_MFLO_OP;
		  						alusel_o <= `EXE_RES_MOVE;   reg1_read_o <= 1'b0;	reg2_read_o <= 1'b0;
		  						instvalid <= `InstValid;	
								end
								`EXE_MTHI: begin
									reg_wena <= `WriteDisable;		aluc_out <= `EXE_MTHI_OP;
		  						reg1_read_o <= 1'b1;	reg2_read_o <= 1'b0; instvalid <= `InstValid;	
								end
								`EXE_MTLO: begin
									reg_wena <= `WriteDisable;		aluc_out <= `EXE_MTLO_OP;
		  						reg1_read_o <= 1'b1;	reg2_read_o <= 1'b0; instvalid <= `InstValid;	
								end
								`EXE_MOVN: begin
									aluc_out <= `EXE_MOVN_OP;
		  						alusel_o <= `EXE_RES_MOVE;   reg1_read_o <= 1'b1;	reg2_read_o <= 1'b1;
		  						instvalid <= `InstValid;
								 	if(op2_out != `ZeroWord) begin
	 									reg_wena <= `WriteEnable;
	 								end else begin
	 									reg_wena <= `WriteDisable;
	 								end
								end
								`EXE_MOVZ: begin
									aluc_out <= `EXE_MOVZ_OP;
		  						alusel_o <= `EXE_RES_MOVE;   reg1_read_o <= 1'b1;	reg2_read_o <= 1'b1;
		  						instvalid <= `InstValid;
								 	if(op2_out == `ZeroWord) begin
	 									reg_wena <= `WriteEnable;
	 								end else begin
	 									reg_wena <= `WriteDisable;
	 								end		  							
								end
								`EXE_SLT: begin
									reg_wena <= `WriteEnable;		aluc_out <= `EXE_SLT_OP;
		  						alusel_o <= `EXE_RES_ARITHMETIC;		reg1_read_o <= 1'b1;	reg2_read_o <= 1'b1;
		  						instvalid <= `InstValid;	
								end
								`EXE_SLTU: begin
									reg_wena <= `WriteEnable;		aluc_out <= `EXE_SLTU_OP;
		  						alusel_o <= `EXE_RES_ARITHMETIC;		reg1_read_o <= 1'b1;	reg2_read_o <= 1'b1;
		  						instvalid <= `InstValid;	
								end
								`EXE_SYNC: begin
									reg_wena <= `WriteDisable;		aluc_out <= `EXE_NOP_OP;
		  						alusel_o <= `EXE_RES_NOP;		reg1_read_o <= 1'b0;	reg2_read_o <= 1'b1;
		  						instvalid <= `InstValid;	
								end								
								`EXE_ADD: begin
									reg_wena <= `WriteEnable;		aluc_out <= `EXE_ADD_OP;
		  						alusel_o <= `EXE_RES_ARITHMETIC;		reg1_read_o <= 1'b1;	reg2_read_o <= 1'b1;
		  						instvalid <= `InstValid;	
								end
								`EXE_ADDU: begin
									reg_wena <= `WriteEnable;		aluc_out <= `EXE_ADDU_OP;
		  						alusel_o <= `EXE_RES_ARITHMETIC;		reg1_read_o <= 1'b1;	reg2_read_o <= 1'b1;
		  						instvalid <= `InstValid;	
								end
								`EXE_SUB: begin
									reg_wena <= `WriteEnable;		aluc_out <= `EXE_SUB_OP;
		  						alusel_o <= `EXE_RES_ARITHMETIC;		reg1_read_o <= 1'b1;	reg2_read_o <= 1'b1;
		  						instvalid <= `InstValid;	
								end
								`EXE_SUBU: begin
									reg_wena <= `WriteEnable;		aluc_out <= `EXE_SUBU_OP;
		  						alusel_o <= `EXE_RES_ARITHMETIC;		reg1_read_o <= 1'b1;	reg2_read_o <= 1'b1;
		  						instvalid <= `InstValid;	
								end
								`EXE_MULT: begin
									reg_wena <= `WriteDisable;		aluc_out <= `EXE_MULT_OP;
		  						reg1_read_o <= 1'b1;	reg2_read_o <= 1'b1; instvalid <= `InstValid;	
								end
								`EXE_MULTU: begin
									reg_wena <= `WriteDisable;		aluc_out <= `EXE_MULTU_OP;
		  						reg1_read_o <= 1'b1;	reg2_read_o <= 1'b1; instvalid <= `InstValid;	
								end
								`EXE_DIV: begin
									reg_wena <= `WriteDisable;		aluc_out <= `EXE_DIV_OP;
		  						reg1_read_o <= 1'b1;	reg2_read_o <= 1'b1; instvalid <= `InstValid;	
								end
								`EXE_DIVU: begin
									reg_wena <= `WriteDisable;		aluc_out <= `EXE_DIVU_OP;
		  						reg1_read_o <= 1'b1;	reg2_read_o <= 1'b1; instvalid <= `InstValid;	
								end			
								`EXE_JR: begin
									reg_wena <= `WriteDisable;		aluc_out <= `EXE_JR_OP;
		  						alusel_o <= `EXE_RES_JUMP_BRANCH;   reg1_read_o <= 1'b1;	reg2_read_o <= 1'b0;
		  						link_addr_o <= `ZeroWord;
		  						
			            	branch_target_address_o <= reg1_o;
			            	branch_flag_o <= `Branch;
			           
			            next_inst_in_delayslot_o <= `InDelaySlot;
			            instvalid <= `InstValid;	
								end
								`EXE_JALR: begin
									reg_wena <= `WriteEnable;		aluc_out <= `EXE_JALR_OP;
		  						alusel_o <= `EXE_RES_JUMP_BRANCH;   reg1_read_o <= 1'b1;	reg2_read_o <= 1'b0;
		  						wd_out <= instr[15:11];
		  						link_addr_o <= pc_plus_8;
		  						
			            	branch_target_address_o <= reg1_o;
			            	branch_flag_o <= `Branch;
			           
			            next_inst_in_delayslot_o <= `InDelaySlot;
			            instvalid <= `InstValid;	
								end													 											  											
						    default:	begin
						    end
						  endcase
						 end
						default: begin
						end
					endcase	
          case (op3)
								`EXE_TEQ: begin
									reg_wena <= `WriteDisable;		aluc_out <= `EXE_TEQ_OP;
		  						alusel_o <= `EXE_RES_NOP;   reg1_read_o <= 1'b0;	reg2_read_o <= 1'b0;
		  						instvalid <= `InstValid;
		  					end
		  					`EXE_TGE: begin
									reg_wena <= `WriteDisable;		aluc_out <= `EXE_TGE_OP;
		  						alusel_o <= `EXE_RES_NOP;   reg1_read_o <= 1'b1;	reg2_read_o <= 1'b1;
		  						instvalid <= `InstValid;
		  					end		
		  					`EXE_TGEU: begin
									reg_wena <= `WriteDisable;		aluc_out <= `EXE_TGEU_OP;
		  						alusel_o <= `EXE_RES_NOP;   reg1_read_o <= 1'b1;	reg2_read_o <= 1'b1;
		  						instvalid <= `InstValid;
		  					end	
		  					`EXE_TLT: begin
									reg_wena <= `WriteDisable;		aluc_out <= `EXE_TLT_OP;
		  						alusel_o <= `EXE_RES_NOP;   reg1_read_o <= 1'b1;	reg2_read_o <= 1'b1;
		  						instvalid <= `InstValid;
		  					end
		  					`EXE_TLTU: begin
									reg_wena <= `WriteDisable;		aluc_out <= `EXE_TLTU_OP;
		  						alusel_o <= `EXE_RES_NOP;   reg1_read_o <= 1'b1;	reg2_read_o <= 1'b1;
		  						instvalid <= `InstValid;
		  					end	
		  					`EXE_TNE: begin
									reg_wena <= `WriteDisable;		aluc_out <= `EXE_TNE_OP;
		  						alusel_o <= `EXE_RES_NOP;   reg1_read_o <= 1'b1;	reg2_read_o <= 1'b1;
		  						instvalid <= `InstValid;
		  					end
		  					`EXE_SYSCALL: begin
									reg_wena <= `WriteDisable;		aluc_out <= `EXE_SYSCALL_OP;
		  						alusel_o <= `EXE_RES_NOP;   reg1_read_o <= 1'b0;	reg2_read_o <= 1'b0;
		  						instvalid <= `InstValid; excepttype_is_syscall<= `True_v;
		  					end							 																					
								default:	begin
								end	
					 endcase									
					end									  
		  	`EXE_ORI:			begin                        //ORIָ��
		  		reg_wena <= `WriteEnable;		aluc_out <= `EXE_OR_OP;
		  		alusel_o <= `EXE_RES_LOGIC; reg1_read_o <= 1'b1;	reg2_read_o <= 1'b0;	  	
					imm <= {16'h0, instr[15:0]};		wd_out <= instr[20:16];
					instvalid <= `InstValid;	
		  	end
		  	`EXE_ANDI:			begin
		  		reg_wena <= `WriteEnable;		aluc_out <= `EXE_AND_OP;
		  		alusel_o <= `EXE_RES_LOGIC;	reg1_read_o <= 1'b1;	reg2_read_o <= 1'b0;	  	
					imm <= {16'h0, instr[15:0]};		wd_out <= instr[20:16];		  	
					instvalid <= `InstValid;	
				end	 	
		  	`EXE_XORI:			begin
		  		reg_wena <= `WriteEnable;		aluc_out <= `EXE_XOR_OP;
		  		alusel_o <= `EXE_RES_LOGIC;	reg1_read_o <= 1'b1;	reg2_read_o <= 1'b0;	  	
					imm <= {16'h0, instr[15:0]};		wd_out <= instr[20:16];		  	
					instvalid <= `InstValid;	
				end	 		
		  	`EXE_LUI:			begin
		  		reg_wena <= `WriteEnable;		aluc_out <= `EXE_OR_OP;
		  		alusel_o <= `EXE_RES_LOGIC; reg1_read_o <= 1'b1;	reg2_read_o <= 1'b0;	  	
					imm <= {instr[15:0], 16'h0};		wd_out <= instr[20:16];		  	
					instvalid <= `InstValid;	
				end			
				`EXE_SLTI:			begin
		  		reg_wena <= `WriteEnable;		aluc_out <= `EXE_SLT_OP;
		  		alusel_o <= `EXE_RES_ARITHMETIC; reg1_read_o <= 1'b1;	reg2_read_o <= 1'b0;	  	
					imm <= {{16{instr[15]}}, instr[15:0]};		wd_out <= instr[20:16];		  	
					instvalid <= `InstValid;	
				end
				`EXE_SLTIU:			begin
		  		reg_wena <= `WriteEnable;		aluc_out <= `EXE_SLTU_OP;
		  		alusel_o <= `EXE_RES_ARITHMETIC; reg1_read_o <= 1'b1;	reg2_read_o <= 1'b0;	  	
					imm <= {{16{instr[15]}}, instr[15:0]};		wd_out <= instr[20:16];		  	
					instvalid <= `InstValid;	
				end
				`EXE_PREF:			begin
		  		reg_wena <= `WriteDisable;		aluc_out <= `EXE_NOP_OP;
		  		alusel_o <= `EXE_RES_NOP; reg1_read_o <= 1'b0;	reg2_read_o <= 1'b0;	  	  	
					instvalid <= `InstValid;	
				end						
				`EXE_ADDI:			begin
		  		reg_wena <= `WriteEnable;		aluc_out <= `EXE_ADDI_OP;
		  		alusel_o <= `EXE_RES_ARITHMETIC; reg1_read_o <= 1'b1;	reg2_read_o <= 1'b0;	  	
					imm <= {{16{instr[15]}}, instr[15:0]};		wd_out <= instr[20:16];		  	
					instvalid <= `InstValid;	
				end
				`EXE_ADDIU:			begin
		  		reg_wena <= `WriteEnable;		aluc_out <= `EXE_ADDIU_OP;
		  		alusel_o <= `EXE_RES_ARITHMETIC; reg1_read_o <= 1'b1;	reg2_read_o <= 1'b0;	  	
					imm <= {{16{instr[15]}}, instr[15:0]};		wd_out <= instr[20:16];		  	
					instvalid <= `InstValid;	
				end
				`EXE_J:			begin
		  		reg_wena <= `WriteDisable;		aluc_out <= `EXE_J_OP;
		  		alusel_o <= `EXE_RES_JUMP_BRANCH; reg1_read_o <= 1'b0;	reg2_read_o <= 1'b0;
		  		link_addr_o <= `ZeroWord;
			    branch_target_address_o <= {pc_plus_4[31:28], instr[25:0], 2'b00};
			    branch_flag_o <= `Branch;
			    next_inst_in_delayslot_o <= `InDelaySlot;		  	
			    instvalid <= `InstValid;	
				end
				`EXE_JAL:			begin
		  		reg_wena <= `WriteEnable;		aluc_out <= `EXE_JAL_OP;
		  		alusel_o <= `EXE_RES_JUMP_BRANCH; reg1_read_o <= 1'b0;	reg2_read_o <= 1'b0;
		  		wd_out <= 5'b11111;	
		  		link_addr_o <= pc_plus_8 ;
			    branch_target_address_o <= {pc_plus_4[31:28], instr[25:0], 2'b00};
			    branch_flag_o <= `Branch;
			    next_inst_in_delayslot_o <= `InDelaySlot;		  	
			    instvalid <= `InstValid;	
				end
				`EXE_BEQ:			begin
		  		reg_wena <= `WriteDisable;		aluc_out <= `EXE_BEQ_OP;
		  		alusel_o <= `EXE_RES_JUMP_BRANCH; reg1_read_o <= 1'b1;	reg2_read_o <= 1'b1;
		  		instvalid <= `InstValid;	
		  		if(reg1_o == op2_out) begin
			    	branch_target_address_o <= pc_plus_4 + imm_sll2_signedext;
			    	branch_flag_o <= `Branch;
			    	next_inst_in_delayslot_o <= `InDelaySlot;		  	
			    end
				end
				`EXE_BGTZ:			begin
		  		reg_wena <= `WriteDisable;		aluc_out <= `EXE_BGTZ_OP;
		  		alusel_o <= `EXE_RES_JUMP_BRANCH; reg1_read_o <= 1'b1;	reg2_read_o <= 1'b0;
		  		instvalid <= `InstValid;	
		  		if((reg1_o[31] == 1'b0) && (reg1_o != `ZeroWord)) begin
			    	branch_target_address_o <= pc_plus_4 + imm_sll2_signedext;
			    	branch_flag_o <= `Branch;
			    	next_inst_in_delayslot_o <= `InDelaySlot;		  	
			    end
				end
				`EXE_BLEZ:			begin
		  		reg_wena <= `WriteDisable;		aluc_out <= `EXE_BLEZ_OP;
		  		alusel_o <= `EXE_RES_JUMP_BRANCH; reg1_read_o <= 1'b1;	reg2_read_o <= 1'b0;
		  		instvalid <= `InstValid;	
		  		if((reg1_o[31] == 1'b1) || (reg1_o == `ZeroWord)) begin
			    	branch_target_address_o <= pc_plus_4 + imm_sll2_signedext;
			    	branch_flag_o <= `Branch;
			    	next_inst_in_delayslot_o <= `InDelaySlot;		  	
			    end
				end
				`EXE_BNE:			begin
		  		reg_wena <= `WriteDisable;		aluc_out <= `EXE_BLEZ_OP;
		  		alusel_o <= `EXE_RES_JUMP_BRANCH; reg1_read_o <= 1'b1;	reg2_read_o <= 1'b1;
		  		instvalid <= `InstValid;	
		  		if(reg1_o != op2_out) begin
			    	branch_target_address_o <= pc_plus_4 + imm_sll2_signedext;
			    	branch_flag_o <= `Branch;
			    	next_inst_in_delayslot_o <= `InDelaySlot;		  	
			    end
				end
				`EXE_LB:			begin
		  		reg_wena <= `WriteEnable;		aluc_out <= `EXE_LB_OP;
		  		alusel_o <= `EXE_RES_LOAD_STORE; reg1_read_o <= 1'b1;	reg2_read_o <= 1'b0;	  	
					wd_out <= instr[20:16]; instvalid <= `InstValid;	
				end
				`EXE_LBU:			begin
		  		reg_wena <= `WriteEnable;		aluc_out <= `EXE_LBU_OP;
		  		alusel_o <= `EXE_RES_LOAD_STORE; reg1_read_o <= 1'b1;	reg2_read_o <= 1'b0;	  	
					wd_out <= instr[20:16]; instvalid <= `InstValid;	
				end
				`EXE_LH:			begin
		  		reg_wena <= `WriteEnable;		aluc_out <= `EXE_LH_OP;
		  		alusel_o <= `EXE_RES_LOAD_STORE; reg1_read_o <= 1'b1;	reg2_read_o <= 1'b0;	  	
					wd_out <= instr[20:16]; instvalid <= `InstValid;	
				end
				`EXE_LHU:			begin
		  		reg_wena <= `WriteEnable;		aluc_out <= `EXE_LHU_OP;
		  		alusel_o <= `EXE_RES_LOAD_STORE; reg1_read_o <= 1'b1;	reg2_read_o <= 1'b0;	  	
					wd_out <= instr[20:16]; instvalid <= `InstValid;	
				end
				`EXE_LW:			begin
		  		reg_wena <= `WriteEnable;		aluc_out <= `EXE_LW_OP;
		  		alusel_o <= `EXE_RES_LOAD_STORE; reg1_read_o <= 1'b1;	reg2_read_o <= 1'b0;	  	
					wd_out <= instr[20:16]; instvalid <= `InstValid;	
				end
				`EXE_LL:			begin
		  		reg_wena <= `WriteEnable;		aluc_out <= `EXE_LL_OP;
		  		alusel_o <= `EXE_RES_LOAD_STORE; reg1_read_o <= 1'b1;	reg2_read_o <= 1'b0;	  	
					wd_out <= instr[20:16]; instvalid <= `InstValid;	
				end
				`EXE_LWL:			begin
		  		reg_wena <= `WriteEnable;		aluc_out <= `EXE_LWL_OP;
		  		alusel_o <= `EXE_RES_LOAD_STORE; reg1_read_o <= 1'b1;	reg2_read_o <= 1'b1;	  	
					wd_out <= instr[20:16]; instvalid <= `InstValid;	
				end
				`EXE_LWR:			begin
		  		reg_wena <= `WriteEnable;		aluc_out <= `EXE_LWR_OP;
		  		alusel_o <= `EXE_RES_LOAD_STORE; reg1_read_o <= 1'b1;	reg2_read_o <= 1'b1;	  	
					wd_out <= instr[20:16]; instvalid <= `InstValid;	
				end			
				`EXE_SB:			begin
		  		reg_wena <= `WriteDisable;		aluc_out <= `EXE_SB_OP;
		  		reg1_read_o <= 1'b1;	reg2_read_o <= 1'b1; instvalid <= `InstValid;	
		  		alusel_o <= `EXE_RES_LOAD_STORE; 
				end
				`EXE_SH:			begin
		  		reg_wena <= `WriteDisable;		aluc_out <= `EXE_SH_OP;
		  		reg1_read_o <= 1'b1;	reg2_read_o <= 1'b1; instvalid <= `InstValid;	
		  		alusel_o <= `EXE_RES_LOAD_STORE; 
				end
				`EXE_SW:			begin
		  		reg_wena <= `WriteDisable;		aluc_out <= `EXE_SW_OP;
		  		reg1_read_o <= 1'b1;	reg2_read_o <= 1'b1; instvalid <= `InstValid;	
		  		alusel_o <= `EXE_RES_LOAD_STORE; 
				end
				`EXE_SWL:			begin
		  		reg_wena <= `WriteDisable;		aluc_out <= `EXE_SWL_OP;
		  		reg1_read_o <= 1'b1;	reg2_read_o <= 1'b1; instvalid <= `InstValid;	
		  		alusel_o <= `EXE_RES_LOAD_STORE; 
				end
				`EXE_SWR:			begin
		  		reg_wena <= `WriteDisable;		aluc_out <= `EXE_SWR_OP;
		  		reg1_read_o <= 1'b1;	reg2_read_o <= 1'b1; instvalid <= `InstValid;	
		  		alusel_o <= `EXE_RES_LOAD_STORE; 
				end
				`EXE_SC:			begin
		  		reg_wena <= `WriteEnable;		aluc_out <= `EXE_SC_OP;
		  		alusel_o <= `EXE_RES_LOAD_STORE; reg1_read_o <= 1'b1;	reg2_read_o <= 1'b1;	  	
					wd_out <= instr[20:16]; instvalid <= `InstValid;	
					alusel_o <= `EXE_RES_LOAD_STORE; 
				end								
				`EXE_REGIMM_INST:		begin
					case (op4)
						`EXE_BGEZ:	begin
							reg_wena <= `WriteDisable;		aluc_out <= `EXE_BGEZ_OP;
		  				alusel_o <= `EXE_RES_JUMP_BRANCH; reg1_read_o <= 1'b1;	reg2_read_o <= 1'b0;
		  				instvalid <= `InstValid;	
		  				if(reg1_o[31] == 1'b0) begin
			    			branch_target_address_o <= pc_plus_4 + imm_sll2_signedext;
			    			branch_flag_o <= `Branch;
			    			next_inst_in_delayslot_o <= `InDelaySlot;		  	
			   			end
						end
						`EXE_BGEZAL:		begin
							reg_wena <= `WriteEnable;		aluc_out <= `EXE_BGEZAL_OP;
		  				alusel_o <= `EXE_RES_JUMP_BRANCH; reg1_read_o <= 1'b1;	reg2_read_o <= 1'b0;
		  				link_addr_o <= pc_plus_8; 
		  				wd_out <= 5'b11111;  	instvalid <= `InstValid;
		  				if(reg1_o[31] == 1'b0) begin
			    			branch_target_address_o <= pc_plus_4 + imm_sll2_signedext;
			    			branch_flag_o <= `Branch;
			    			next_inst_in_delayslot_o <= `InDelaySlot;
			   			end
						end
						`EXE_BLTZ:		begin
						  reg_wena <= `WriteDisable;		aluc_out <= `EXE_BGEZAL_OP;
		  				alusel_o <= `EXE_RES_JUMP_BRANCH; reg1_read_o <= 1'b1;	reg2_read_o <= 1'b0;
		  				instvalid <= `InstValid;	
		  				if(reg1_o[31] == 1'b1) begin
			    			branch_target_address_o <= pc_plus_4 + imm_sll2_signedext;
			    			branch_flag_o <= `Branch;
			    			next_inst_in_delayslot_o <= `InDelaySlot;		  	
			   			end
						end
						`EXE_BLTZAL:		begin
							reg_wena <= `WriteEnable;		aluc_out <= `EXE_BGEZAL_OP;
		  				alusel_o <= `EXE_RES_JUMP_BRANCH; reg1_read_o <= 1'b1;	reg2_read_o <= 1'b0;
		  				link_addr_o <= pc_plus_8;	
		  				wd_out <= 5'b11111; instvalid <= `InstValid;
		  				if(reg1_o[31] == 1'b1) begin
			    			branch_target_address_o <= pc_plus_4 + imm_sll2_signedext;
			    			branch_flag_o <= `Branch;
			    			next_inst_in_delayslot_o <= `InDelaySlot;
			   			end
						end
						`EXE_TEQI:			begin
		  				reg_wena <= `WriteDisable;		aluc_out <= `EXE_TEQI_OP;
		  				alusel_o <= `EXE_RES_NOP; reg1_read_o <= 1'b1;	reg2_read_o <= 1'b0;	  	
							imm <= {{16{instr[15]}}, instr[15:0]};		  	
							instvalid <= `InstValid;	
						end
						`EXE_TGEI:			begin
		  				reg_wena <= `WriteDisable;		aluc_out <= `EXE_TGEI_OP;
		  				alusel_o <= `EXE_RES_NOP; reg1_read_o <= 1'b1;	reg2_read_o <= 1'b0;	  	
							imm <= {{16{instr[15]}}, instr[15:0]};		  	
							instvalid <= `InstValid;	
						end
						`EXE_TGEIU:			begin
		  				reg_wena <= `WriteDisable;		aluc_out <= `EXE_TGEIU_OP;
		  				alusel_o <= `EXE_RES_NOP; reg1_read_o <= 1'b1;	reg2_read_o <= 1'b0;	  	
							imm <= {{16{instr[15]}}, instr[15:0]};		  	
							instvalid <= `InstValid;	
						end
						`EXE_TLTI:			begin
		  				reg_wena <= `WriteDisable;		aluc_out <= `EXE_TLTI_OP;
		  				alusel_o <= `EXE_RES_NOP; reg1_read_o <= 1'b1;	reg2_read_o <= 1'b0;	  	
							imm <= {{16{instr[15]}}, instr[15:0]};		  	
							instvalid <= `InstValid;	
						end
						`EXE_TLTIU:			begin
		  				reg_wena <= `WriteDisable;		aluc_out <= `EXE_TLTIU_OP;
		  				alusel_o <= `EXE_RES_NOP; reg1_read_o <= 1'b1;	reg2_read_o <= 1'b0;	  	
							imm <= {{16{instr[15]}}, instr[15:0]};		  	
							instvalid <= `InstValid;	
						end
						`EXE_TNEI:			begin
		  				reg_wena <= `WriteDisable;		aluc_out <= `EXE_TNEI_OP;
		  				alusel_o <= `EXE_RES_NOP; reg1_read_o <= 1'b1;	reg2_read_o <= 1'b0;	  	
							imm <= {{16{instr[15]}}, instr[15:0]};		  	
							instvalid <= `InstValid;	
						end						
						default:	begin
						end
					endcase
				end								
				`EXE_SPECIAL2_INST:		begin
					case ( op3 )
						`EXE_CLZ:		begin
							reg_wena <= `WriteEnable;		aluc_out <= `EXE_CLZ_OP;
		  				alusel_o <= `EXE_RES_ARITHMETIC; reg1_read_o <= 1'b1;	reg2_read_o <= 1'b0;	  	
							instvalid <= `InstValid;	
						end
						`EXE_CLO:		begin
							reg_wena <= `WriteEnable;		aluc_out <= `EXE_CLO_OP;
		  				alusel_o <= `EXE_RES_ARITHMETIC; reg1_read_o <= 1'b1;	reg2_read_o <= 1'b0;	  	
							instvalid <= `InstValid;	
						end
						`EXE_MUL:		begin
							reg_wena <= `WriteEnable;		aluc_out <= `EXE_MUL_OP;
		  				alusel_o <= `EXE_RES_MUL; reg1_read_o <= 1'b1;	reg2_read_o <= 1'b1;	
		  				instvalid <= `InstValid;	  			
						end
						`EXE_MADD:		begin
							reg_wena <= `WriteDisable;		aluc_out <= `EXE_MADD_OP;
		  				alusel_o <= `EXE_RES_MUL; reg1_read_o <= 1'b1;	reg2_read_o <= 1'b1;	  			
		  				instvalid <= `InstValid;	
						end
						`EXE_MADDU:		begin
							reg_wena <= `WriteDisable;		aluc_out <= `EXE_MADDU_OP;
		  				alusel_o <= `EXE_RES_MUL; reg1_read_o <= 1'b1;	reg2_read_o <= 1'b1;	  			
		  				instvalid <= `InstValid;	
						end
						`EXE_MSUB:		begin
							reg_wena <= `WriteDisable;		aluc_out <= `EXE_MSUB_OP;
		  				alusel_o <= `EXE_RES_MUL; reg1_read_o <= 1'b1;	reg2_read_o <= 1'b1;	  			
		  				instvalid <= `InstValid;	
						end
						`EXE_MSUBU:		begin
							reg_wena <= `WriteDisable;		aluc_out <= `EXE_MSUBU_OP;
		  				alusel_o <= `EXE_RES_MUL; reg1_read_o <= 1'b1;	reg2_read_o <= 1'b1;	  			
		  				instvalid <= `InstValid;	
						end						
						default:	begin
						end
					endcase      //EXE_SPECIAL_INST2 case
				end																		  	
		    default:			begin
		    end
		  endcase		  //case op
		  
		  if (instr[31:21] == 11'b00000000000) begin
		  	if (op3 == `EXE_SLL) begin
		  		reg_wena <= `WriteEnable;		aluc_out <= `EXE_SLL_OP;
		  		alusel_o <= `EXE_RES_SHIFT; reg1_read_o <= 1'b0;	reg2_read_o <= 1'b1;	  	
					imm[4:0] <= instr[10:6];		wd_out <= instr[15:11];
					instvalid <= `InstValid;	
				end else if ( op3 == `EXE_SRL ) begin
		  		reg_wena <= `WriteEnable;		aluc_out <= `EXE_SRL_OP;
		  		alusel_o <= `EXE_RES_SHIFT; reg1_read_o <= 1'b0;	reg2_read_o <= 1'b1;	  	
					imm[4:0] <= instr[10:6];		wd_out <= instr[15:11];
					instvalid <= `InstValid;	
				end else if ( op3 == `EXE_SRA ) begin
		  		reg_wena <= `WriteEnable;		aluc_out <= `EXE_SRA_OP;
		  		alusel_o <= `EXE_RES_SHIFT; reg1_read_o <= 1'b0;	reg2_read_o <= 1'b1;	  	
					imm[4:0] <= instr[10:6];		wd_out <= instr[15:11];
					instvalid <= `InstValid;	
				end
			end		  

     	if(instr == `EXE_ERET) begin
				reg_wena <= `WriteDisable;		aluc_out <= `EXE_ERET_OP;
		  	alusel_o <= `EXE_RES_NOP;   reg1_read_o <= 1'b0;	reg2_read_o <= 1'b0;
		  	instvalid <= `InstValid; excepttype_is_eret<= `True_v;				
			end else if(instr[31:21] == 11'b01000000000 && 
										instr[10:0] == 11'b00000000000) begin
				aluc_out <= `EXE_MFC0_OP;
				alusel_o <= `EXE_RES_MOVE;
				wd_out <= instr[20:16];
				reg_wena <= `WriteEnable;
				instvalid <= `InstValid;	   
				reg1_read_o <= 1'b0;
				reg2_read_o <= 1'b0;		
			end else if(instr[31:21] == 11'b01000000100 && 
										instr[10:0] == 11'b00000000000) begin
				aluc_out <= `EXE_MTC0_OP;
				alusel_o <= `EXE_RES_NOP;
				reg_wena <= `WriteDisable;
				instvalid <= `InstValid;	   
				reg1_read_o <= 1'b1;
				reg1_addr_o <= instr[20:16];
				reg2_read_o <= 1'b0;					
			end
		  
		end       //if
	end         //always
	

	always @ (*) begin
			stallreq_for_reg1_loadrelate <= `NoStop;	
		if(rst == `RstEnable) begin
			reg1_o <= `ZeroWord;	
		end else if(pre_inst_is_load == 1'b1 && ex_wd_i == reg1_addr_o 
								&& reg1_read_o == 1'b1 ) begin
		  stallreq_for_reg1_loadrelate <= `Stop;							
		end else if((reg1_read_o == 1'b1) && (ex_wreg_i == 1'b1) 
								&& (ex_wd_i == reg1_addr_o)) begin
			reg1_o <= ex_wdata_i; 
		end else if((reg1_read_o == 1'b1) && (mem_wreg_i == 1'b1) 
								&& (mem_wd_i == reg1_addr_o)) begin
			reg1_o <= mem_wdata_i; 			
	  end else if(reg1_read_o == 1'b1) begin
	  	reg1_o <= reg1_data_i;
	  end else if(reg1_read_o == 1'b0) begin
	  	reg1_o <= imm;
	  end else begin
	    reg1_o <= `ZeroWord;
	  end
	end
	
	always @ (*) begin
			stallreq_for_reg2_loadrelate <= `NoStop;
		if(rst == `RstEnable) begin
			op2_out <= `ZeroWord;
		end else if(pre_inst_is_load == 1'b1 && ex_wd_i == reg2_addr_o 
								&& reg2_read_o == 1'b1 ) begin
		  stallreq_for_reg2_loadrelate <= `Stop;			
		end else if((reg2_read_o == 1'b1) && (ex_wreg_i == 1'b1) 
								&& (ex_wd_i == reg2_addr_o)) begin
			op2_out <= ex_wdata_i; 
		end else if((reg2_read_o == 1'b1) && (mem_wreg_i == 1'b1) 
								&& (mem_wd_i == reg2_addr_o)) begin
			op2_out <= mem_wdata_i;			
	  end else if(reg2_read_o == 1'b1) begin
	  	op2_out <= reg2_data_i;
	  end else if(reg2_read_o == 1'b0) begin
	  	op2_out <= imm;
	  end else begin
	    op2_out <= `ZeroWord;
	  end
	end

	always @ (*) begin
		if(rst == `RstEnable) begin
			isInDelaySlotOut <= `NotInDelaySlot;
		end else begin
		  isInDelaySlotOut <= isInDelaySlot;		
	  end
	end

endmodule