module if_stage 
import rv32i_types::*;
(
    input  logic [31:0] pc,
    input  logic [31:0] pc_next,
    input  logic [31:0] imem_rdata,
    input  logic        imem_resp,
    input  logic        global_stall,
    output if_id_t      if_id_next,
    output logic [31:0] imem_addr,
    output logic        imem_re,
    output logic        if_stall
);

always_comb begin

    if_id_next.valid = imem_resp;
    if_id_next.inst = imem_rdata;
    if_id_next.pc = pc;
    if_id_next.pc_next = pc_next;

    if (global_stall) begin
        imem_addr = pc;
    end else begin
        imem_addr = pc_next;
    end

    imem_re = '1;

    if_stall = ~imem_resp;

end

endmodule