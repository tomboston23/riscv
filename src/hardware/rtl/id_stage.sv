module id_stage
import rv32i_types::*; 
(
    input if_id_t if_id_reg,
    output id_ex_t id_ex_reg_next,

    input [31:0] rs1_v, rs2_v,
    output logic [4:0] rs1_s, rs2_s
);

logic [6:0] opcode;
logic [4:0] rd, rs1, rs2;
assign rd = if_id_reg.inst[11:7];
assign rs1 = if_id_reg.inst[19:15];
assign rs2 = if_id_reg.inst[24:20];
assign opcode = if_id_reg.inst[6:0];

always_comb begin
    id_ex_reg_next = '0;
    id_ex_reg_next.valid = if_id_reg.valid;
    id_ex_reg_next.pc = if_id_reg.pc;
    id_ex_reg_next.pc_next = if_id_reg.pc_next;
    id_ex_reg_next.inst = if_id_reg.inst;

    rs1_s = '0;
    rs2_s = '0;

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

        default:
        begin
            id_ex_reg_next.valid = 1'b0;
        end
    endcase
end

endmodule
