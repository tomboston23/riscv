module ex_stage
import rv32i_types::*; 
(
    input id_ex_t id_ex_reg,
    output ex_mem_t ex_mem_reg_next,

    output logic [31:0] mem_addr,
    output logic [3:0] mem_rmask,
    output logic [3:0] mem_wmask,
    output logic [31:0] mem_wdata,
    output logic jmp,
    output logic [31:0] pc_next,
    input fwd_t ex_mem_fwd, mem_wb_fwd
);

logic   [31:0]  a;
logic   [31:0]  b;
logic   [2:0]   aluop;
logic   [2:0]   cmpop;
logic   [2:0]   mulop;
logic   [31:0]  aluout;
logic   [31:0]  mulout;
logic           cmpout;
logic   [2:0]   funct3; 
logic   [6:0]   funct7;
logic   [6:0]   opcode;

logic [31:0] u_imm;
logic [31:0] i_imm;
logic [31:0] s_imm;
logic [31:0] b_imm;
logic [31:0] j_imm;
logic [31:0] z_imm;

logic [31:0] inst;
assign inst = id_ex_reg.inst;
assign funct7 = inst[31:25];
assign funct3 = inst[14:12];
assign opcode = inst[6:0];

assign u_imm = {inst[31:12], {12{1'b0}}};
assign i_imm = {{21{inst[31]}}, inst[30:20]};
assign s_imm = {{21{inst[31]}}, inst[30:25], inst[11:7]};
assign b_imm = {{20{inst[31]}}, inst[7], inst[30:25], inst[11:8], 1'b0};
assign j_imm = {{12{inst[31]}}, inst[19:12], inst[20], inst[30:25], inst[24:21], 1'b0};
assign z_imm = {{27{1'b0}}, inst[19:15]};

logic [31:0] rs1_v, rs2_v, csr_v;
always_comb begin
    if (id_ex_reg.rs1_s != '0 && id_ex_reg.rs1_s == ex_mem_fwd.rd_s) begin
        rs1_v = ex_mem_fwd.rd_v;
    end else if (id_ex_reg.rs1_s != '0 && id_ex_reg.rs1_s == mem_wb_fwd.rd_s) begin
        rs1_v = mem_wb_fwd.rd_v;
    end else begin
        rs1_v = id_ex_reg.rs1_v;
    end

    if (id_ex_reg.csr_rd_s != '0 && id_ex_reg.csr_rd_s == ex_mem_fwd.csr_rd_s) begin
        csr_v = ex_mem_fwd.csr_rd_v;
    end else if (id_ex_reg.csr_rd_s != '0 && id_ex_reg.csr_rd_s == mem_wb_fwd.csr_rd_s) begin
        csr_v = mem_wb_fwd.csr_rd_v;
    end else begin
        csr_v = id_ex_reg.csr_rdata;
    end

    if (id_ex_reg.rs2_s != '0 && id_ex_reg.rs2_s == ex_mem_fwd.rd_s) begin
        rs2_v = ex_mem_fwd.rd_v;
    end else if (id_ex_reg.rs2_s != '0 && id_ex_reg.rs2_s == mem_wb_fwd.rd_s) begin
        rs2_v = mem_wb_fwd.rd_v;
    end else begin
        rs2_v = id_ex_reg.rs2_v;
    end
end

// Comparator
cmp cmp_i (
    .a      (a),
    .b      (b),
    .cmpop  (cmpop),
    .cmpout (cmpout)
);

// ALU
alu alu(
    .a      (a),
    .b      (b),
    .aluop  (aluop),
    .aluout (aluout)
);

// MULDIV
muldiv_unit muldiv_unit(
    .a      (a),
    .b      (b),
    .mulop  (mulop),
    .mulout (mulout)
);

assign pc_next = ex_mem_reg_next.pc_next;
assign mem_addr = ex_mem_reg_next.mem_addr;
assign mem_wmask = ex_mem_reg_next.mem_wmask;
assign mem_rmask = ex_mem_reg_next.mem_rmask;
assign mem_wdata = ex_mem_reg_next.mem_wdata;

always_comb begin
    ex_mem_reg_next = '0;
    ex_mem_reg_next.valid = id_ex_reg.valid;
    ex_mem_reg_next.rs1_s = id_ex_reg.rs1_s;
    ex_mem_reg_next.rs1_v = rs1_v;
    ex_mem_reg_next.rs2_s = id_ex_reg.rs2_s;
    ex_mem_reg_next.rs2_v = rs2_v;
    ex_mem_reg_next.rd_s = id_ex_reg.rd_s;
    ex_mem_reg_next.pc = id_ex_reg.pc;
    ex_mem_reg_next.inst = id_ex_reg.inst;
    ex_mem_reg_next.csr_we = id_ex_reg.csr_we;
    ex_mem_reg_next.csr_rd_s = id_ex_reg.csr_rd_s;
    ex_mem_reg_next.csr_rdata = id_ex_reg.csr_rdata;

    //defaults
    mulop = mul;
    aluop = alu_add;
    cmpop = beq;
    a = '0;
    b = '0;
    ex_mem_reg_next.mem_wmask = '0;
    ex_mem_reg_next.mem_rmask = '0;
    jmp = '0;

    ex_mem_reg_next.pc_next = id_ex_reg.pc_next;

    case (opcode)
        op_lui: begin
            ex_mem_reg_next.rd_v = u_imm;
        end

        op_auipc: begin
            a = u_imm;
            b = id_ex_reg.pc;
            ex_mem_reg_next.rd_v = aluout;
        end

        op_jal: begin
            ex_mem_reg_next.rd_v = id_ex_reg.pc_next;
            a = id_ex_reg.pc;
            b = j_imm;
            ex_mem_reg_next.pc_next = aluout;
            if (id_ex_reg.valid) jmp = '1;
        end

        op_jalr: begin
            ex_mem_reg_next.rd_v = id_ex_reg.pc_next;
            a = rs1_v;
            b = i_imm;
            ex_mem_reg_next.pc_next = aluout;
            if (id_ex_reg.valid) jmp = '1;
        end    

        op_br: begin
            a = rs1_v;
            b = rs2_v;
            cmpop = funct3;
            if (id_ex_reg.valid) jmp = cmpout;
            if (jmp) ex_mem_reg_next.pc_next = id_ex_reg.pc + b_imm;
        end    

        op_load: begin
            if (id_ex_reg.valid) begin
                a = i_imm;
                b = rs1_v;
                ex_mem_reg_next.mem_addr = {aluout[31:2], 2'b0};

                case (funct3)
                    lb: begin 
                        ex_mem_reg_next.mem_rmask = (4'b0001 << aluout[1:0]);
                        ex_mem_reg_next.sign = '1;
                    end
                    lbu: begin 
                        ex_mem_reg_next.mem_rmask = (4'b0001 << aluout[1:0]);
                        ex_mem_reg_next.sign = '0;
                    end
                    lh: begin
                        ex_mem_reg_next.mem_rmask = (4'b0011 << {aluout[1], 1'b0});
                        ex_mem_reg_next.sign = '1;
                    end 
                    lhu: begin 
                        ex_mem_reg_next.mem_rmask = (4'b0011 << {aluout[1], 1'b0});
                        ex_mem_reg_next.sign = '0;
                    end
                    lw: ex_mem_reg_next.mem_rmask = 4'hF;
                    default: ex_mem_reg_next.valid = '0;
                endcase
            end
        end

        op_store: begin
            if (id_ex_reg.valid) begin
                a = s_imm;
                b = rs1_v;
                ex_mem_reg_next.mem_addr = aluout;

                case (funct3) 
                    sb: begin
                        ex_mem_reg_next.mem_wmask = (4'b0001 << aluout[1:0]);
                        ex_mem_reg_next.mem_wdata = {{24{1'b0}}, rs2_v[7:0]} << (8 * aluout[1:0]);
                    end
                    sh: begin
                        ex_mem_reg_next.mem_addr[0] = '0; // 2-byte align
                        ex_mem_reg_next.mem_wmask = (4'b0011 << {aluout[1], 1'b0});
                        ex_mem_reg_next.mem_wdata = {{16{1'b0}}, rs2_v[15:0]} << (16 * aluout[1]);
                    end
                    sw: begin
                        ex_mem_reg_next.mem_addr[1:0] = '0; // 4-byte align
                        ex_mem_reg_next.mem_wmask = 4'hF;
                        ex_mem_reg_next.mem_wdata = rs2_v;
                    end
                    default:
                        ex_mem_reg_next.valid = '0;
                endcase
            end
        end

        op_imm: begin
            a = rs1_v;
            b = i_imm;
            ex_mem_reg_next.rd_v = aluout;

            case (funct3) 
                add: aluop = alu_add;

                sll: begin
                    b[31:5] = '0;
                    aluop = alu_sll;
                end

                slt: begin
                    cmpop = blt;
                    ex_mem_reg_next.rd_v = cmpout ? 32'b1 : 32'b0;
                end

                sltu: begin
                    cmpop = bltu;
                    ex_mem_reg_next.rd_v = cmpout ? 32'b1 : 32'b0;
                end

                axor: aluop = alu_xor;

                sr: begin
                    b[31:5] = '0;
                    aluop = (funct7 == funct7_srasub) ? alu_sra : alu_srl;
                end

                aor: aluop = alu_or;

                aand: aluop = alu_and;

                default:
                    ex_mem_reg_next.valid = '0;
            endcase
        end

        op_reg: begin
            a = rs1_v;
            b = rs2_v;
            ex_mem_reg_next.rd_v = aluout;

            if (funct7 == funct7_muldiv) begin
                mulop = funct3;
                ex_mem_reg_next.rd_v = mulout;
            end else begin
                case(funct3)
                    add: aluop = (funct7 == funct7_srasub) ? alu_sub : alu_add;

                    sll: begin 
                        aluop = alu_sll;
                        b[31:5] = '0;
                    end

                    slt: begin
                        cmpop = blt;
                        ex_mem_reg_next.rd_v = cmpout ? 32'b1 : 32'b0;
                    end

                    sltu: begin
                        cmpop = bltu;
                        ex_mem_reg_next.rd_v = cmpout ? 32'b1 : 32'b0;
                    end

                    sr: begin
                        b[31:5] = '0;
                        aluop = (funct7 == funct7_srasub) ? alu_sra : alu_srl;
                    end

                    axor: aluop = alu_xor;

                    aor: aluop = alu_or;
                    
                    aand: aluop = alu_and;

                    default: 
                        ex_mem_reg_next.valid = '0;
                endcase
            end
        end

        op_system: begin
            case (funct3)
            
                csrrw: begin // csrrw
                    
                    ex_mem_reg_next.csr_wdata = rs1_v;

                    if (id_ex_reg.rd_s != '0) begin // read CSR
                        ex_mem_reg_next.rd_v = csr_v;
                        ex_mem_reg_next.csr_rdata = csr_v;
                    end
                end
                csrrs: begin // csrrs
                    ex_mem_reg_next.rd_v = csr_v;
                    ex_mem_reg_next.csr_rdata = csr_v;

                    aluop = alu_or;
                    a = rs1_v;
                    b = csr_v;

                    if (id_ex_reg.rs1_s != '0) begin // write CSR
                        ex_mem_reg_next.csr_wdata = aluout;
                    end
                end
                csrrc: begin // csrrc
                    ex_mem_reg_next.rd_v = csr_v;
                    ex_mem_reg_next.csr_rdata = csr_v;

                    aluop = alu_and;
                    a = ~rs1_v;
                    b = csr_v;

                    if (id_ex_reg.rs1_s != '0) begin // write CSR
                        ex_mem_reg_next.csr_wdata = aluout;
                    end
                end
                csrrwi: begin // csrrwi
                    ex_mem_reg_next.csr_wdata = z_imm;

                    if (id_ex_reg.rd_s != '0) begin // read CSR
                        ex_mem_reg_next.csr_rdata = csr_v;
                        ex_mem_reg_next.rd_v = csr_v;
                    end
                end
                csrrsi: begin // csrrsi
                    ex_mem_reg_next.rd_v = csr_v;
                    ex_mem_reg_next.csr_rdata = csr_v;

                    aluop = alu_or;
                    a = z_imm;
                    b = csr_v;

                    if (id_ex_reg.rs1_s != '0) ex_mem_reg_next.csr_wdata = aluout;
                end
                csrrci: begin // csrrci
                    ex_mem_reg_next.rd_v = csr_v;
                    ex_mem_reg_next.csr_rdata = csr_v;

                    aluop = alu_and;
                    a = ~z_imm;
                    b = csr_v;

                    if (id_ex_reg.rs1_s != '0) ex_mem_reg_next.csr_wdata = aluout;
                end
                default: ex_mem_reg_next.valid = '0;
            endcase

            if (id_ex_reg.csr_we) begin
                case (id_ex_reg.csr_rd_s)
                    csr_mstatus_reg: ex_mem_reg_next.csr_wdata = ex_mem_reg_next.csr_wdata & MSTATUS_WMASK.val;
                    csr_mtvec_reg: ex_mem_reg_next.csr_wdata = ex_mem_reg_next.csr_wdata & MTVEC_WMASK; // 4B align
                    csr_stvec_reg: ex_mem_reg_next.csr_wdata = ex_mem_reg_next.csr_wdata & MTVEC_WMASK; // 4B align
                    csr_mepc_reg: ex_mem_reg_next.csr_wdata = ex_mem_reg_next.csr_wdata & ~32'd3; // 4B align
                    csr_sepc_reg: ex_mem_reg_next.csr_wdata = ex_mem_reg_next.csr_wdata & ~32'd3; // 4B align
                    default: ;
                endcase
            end
        end

        default: 
            ex_mem_reg_next.valid = '0;
    endcase
end

endmodule