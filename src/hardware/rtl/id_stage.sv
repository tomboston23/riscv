module id_stage
import rv32i_types::*; 
(
    input if_id_t if_id_reg,
    output id_ex_t id_ex_reg_next,

    input [31:0] rs1_v, rs2_v,
    output logic [4:0] rs1_s, rs2_s,

    input [31:0] csr_v,
    output logic [4:0] csr_s
);

logic [6:0] opcode;
logic [2:0] funct3;
logic [11:0] csr_addr;
logic [4:0] csr_s_decode;
assign csr_addr = if_id_reg.inst[31:20];

always_comb begin
    case (csr_addr)
        csr_sstatus:    csr_s_decode = csr_sstatus_reg;
        csr_sie:        csr_s_decode = csr_sie_reg;
        csr_stvec:      csr_s_decode = csr_stvec_reg;
        csr_sscratch:   csr_s_decode = csr_sscratch_reg;
        csr_sepc:        csr_s_decode = csr_sepc_reg;
        csr_scause:      csr_s_decode =csr_scause_reg;
        csr_stval:       csr_s_decode = csr_stval_reg;
        csr_sip:         csr_s_decode = csr_sip_reg;
        
        csr_mstatus:    csr_s_decode = csr_mstatus_reg;
        csr_mie:        csr_s_decode = csr_mie_reg;
        csr_mtvec:      csr_s_decode = csr_mtvec_reg;
        csr_mscratch:   csr_s_decode = csr_mscratch_reg;
        csr_mepc:       csr_s_decode = csr_mepc_reg;
        csr_mcause:     csr_s_decode = csr_mcause_reg;
        csr_mtval:      csr_s_decode = csr_mtval_reg;
        csr_mip:        csr_s_decode = csr_mip_reg;

        csr_mnscratch:  csr_s_decode = csr_mnscratch_reg;
        csr_mnepc:      csr_s_decode = csr_mnepc_reg;
        csr_mncause:    csr_s_decode = csr_mncause_reg;
        csr_mnstatus:   csr_s_decode = csr_mnstatus_reg;

        default: csr_s_decode = '0;
    endcase
end
    
logic [4:0] rd, rs1, rs2;
assign rd = if_id_reg.inst[11:7];
assign rs1 = if_id_reg.inst[19:15];
assign rs2 = if_id_reg.inst[24:20];
assign opcode = if_id_reg.inst[6:0];
assign funct3 = if_id_reg.inst[14:12];


always_comb begin
    id_ex_reg_next = '0;
    id_ex_reg_next.valid = if_id_reg.valid;
    id_ex_reg_next.pc = if_id_reg.pc;
    id_ex_reg_next.pc_next = if_id_reg.pc_next;
    id_ex_reg_next.inst = if_id_reg.inst;

    rs1_s = '0;
    rs2_s = '0;
    csr_s = '0;

    case(opcode)
        op_lui, op_auipc, op_jal: // rd_s only
        begin
            id_ex_reg_next.rd_s = rd;
        end

        op_imm, op_load, op_jalr: // rd_s and rs1
        begin
            id_ex_reg_next.rd_s = rd;
            id_ex_reg_next.rs1_s = if_id_reg.inst[19:15];
            id_ex_reg_next.rs1_v = rs1_v;
            rs1_s = rs1;
        end

        op_store, op_br: // rs1 and rs2
        begin
            id_ex_reg_next.rs1_v = rs1_v;
            id_ex_reg_next.rs2_v = rs2_v;
            id_ex_reg_next.rs1_s = if_id_reg.inst[19:15];
            id_ex_reg_next.rs2_s = if_id_reg.inst[24:20];
            rs1_s = rs1;
            rs2_s = rs2;
        end

        op_reg: // rd_s, rs1, rs2
        begin
            id_ex_reg_next.rd_s = rd;
            id_ex_reg_next.rs1_v = rs1_v;
            id_ex_reg_next.rs2_v = rs2_v;
            id_ex_reg_next.rs1_s = if_id_reg.inst[19:15];
            id_ex_reg_next.rs2_s = if_id_reg.inst[24:20];
            rs1_s = rs1;
            rs2_s = rs2;
        end

        op_system: // rd_s, rs1
        begin
            case (funct3)
                3'b000: // ecall / ebreak
                begin
                    id_ex_reg_next.trap = '1;
                end
                3'b001:  // csrrw
                begin
                    if (rd == '0) begin // no CSR read
                        id_ex_reg_next.csr_rdata = '0; // no need to read since there is no rd
                    end else begin
                        csr_s = csr_s_decode;
                        id_ex_reg_next.csr_rdata = csr_v;
                    end
                    id_ex_reg_next.csr_rd_s = csr_s_decode;
                    id_ex_reg_next.rd_s  = rd;
                    id_ex_reg_next.rs1_s = if_id_reg.inst[19:15];
                    id_ex_reg_next.rs1_v = rs1_v;
                    rs1_s = rs1;
                    id_ex_reg_next.csr_we = 1'b1;
                    if (csr_s_decode == '0) begin
                        id_ex_reg_next.valid = '0;
                    end
                end
                3'b101:  // csrrwi - same as csrrw but without rs1
                begin
                    if (rd == '0) begin // no CSR read
                        id_ex_reg_next.csr_rdata = '0; // no need to read since there is no rd
                    end else begin
                        csr_s = csr_s_decode;
                        id_ex_reg_next.csr_rdata = csr_v;
                    end
                    id_ex_reg_next.csr_rd_s = csr_s_decode;
                    id_ex_reg_next.rd_s  = rd;
                    id_ex_reg_next.csr_we = 1'b1;
                    if (csr_s_decode == '0) begin
                        id_ex_reg_next.valid = '0;
                    end
                end
                3'b010, 3'b011: // csrrs / csrrc - same behavior
                begin
                    id_ex_reg_next.rs1_s = if_id_reg.inst[19:15];
                    id_ex_reg_next.rs1_v = rs1_v;
                    rs1_s = rs1;
                    id_ex_reg_next.csr_rd_s = csr_s_decode;
                    if (rs1 == '0) begin // no CSR write
                        id_ex_reg_next.csr_we = '0;
                        id_ex_reg_next.csr_rdata = '0;
                    end else begin
                        id_ex_reg_next.csr_we = '1;
                        csr_s = csr_s_decode;
                        id_ex_reg_next.csr_rdata = csr_v;
                    end

                    if (csr_s_decode == '0) begin
                        id_ex_reg_next.valid = '0;
                    end
                end
                3'b110, 3'b111: // csrrsi / csrrci - same as csrrs / csrrc but without rs1
                begin
                    if (rs1 == '0) begin // no CSR write
                        id_ex_reg_next.csr_we = '0;
                        id_ex_reg_next.csr_rdata = '0;
                    end else begin
                        id_ex_reg_next.csr_we = '1;
                        csr_s = csr_s_decode;
                        id_ex_reg_next.csr_rdata = csr_v;
                    end

                    id_ex_reg_next.csr_rd_s = csr_s_decode;
                    if (csr_s_decode == '0) begin
                        id_ex_reg_next.valid = '0;
                    end
                end
                default: id_ex_reg_next.valid = 1'b0;
            endcase

        end

        default:
        begin
            id_ex_reg_next.valid = 1'b0;
        end
    endcase
end

endmodule
