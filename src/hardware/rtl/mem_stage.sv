module mem_stage 
import rv32i_types::*;
(
    input ex_mem_t ex_mem_reg,
    output mem_wb_t mem_wb_reg_next,

    input logic [31:0] mem_rdata
);

always_comb begin
    mem_wb_reg_next = '0;
    mem_wb_reg_next.valid = ex_mem_reg.valid;
    mem_wb_reg_next.pc = ex_mem_reg.pc;
    mem_wb_reg_next.pc_next = ex_mem_reg.pc_next;
    mem_wb_reg_next.inst = ex_mem_reg.inst;
    mem_wb_reg_next.rd_s = ex_mem_reg.rd_s;
    mem_wb_reg_next.rd_v = ex_mem_reg.rd_v;
    mem_wb_reg_next.rs1_s = ex_mem_reg.rs1_s;
    mem_wb_reg_next.rs2_s = ex_mem_reg.rs2_s;
    mem_wb_reg_next.rs1_v = ex_mem_reg.rs1_v;
    mem_wb_reg_next.rs2_v = ex_mem_reg.rs2_v;
    mem_wb_reg_next.mem_addr = ex_mem_reg.mem_addr;
    mem_wb_reg_next.mem_wdata = ex_mem_reg.mem_wdata;
    mem_wb_reg_next.mem_rmask = ex_mem_reg.mem_rmask;
    mem_wb_reg_next.mem_wmask = ex_mem_reg.mem_wmask;

    mem_wb_reg_next.csr_we = ex_mem_reg.csr_we;
    mem_wb_reg_next.csr_rd_s = ex_mem_reg.csr_rd_s;
    mem_wb_reg_next.csr_rdata = ex_mem_reg.csr_rdata;
    mem_wb_reg_next.csr_wdata = ex_mem_reg.csr_wdata;

    if (ex_mem_reg.inst[6:0] == op_load) begin
        case (ex_mem_reg.mem_rmask)
            4'b0001: begin 
                mem_wb_reg_next.mem_rdata = {24'h0, mem_rdata[7:0]};
                mem_wb_reg_next.rd_v = {{24{ex_mem_reg.sign & mem_rdata[7]}}, mem_rdata[7:0]};
            end

            4'b0010: begin 
                mem_wb_reg_next.mem_rdata = {16'h0, mem_rdata[15:8], 8'h0};
                mem_wb_reg_next.rd_v = {{24{ex_mem_reg.sign & mem_rdata[15]}}, mem_rdata[15:8]};
            end

            4'b0100: begin 
                mem_wb_reg_next.mem_rdata = {8'h0, mem_rdata[23:16], 16'h0};
                mem_wb_reg_next.rd_v = {{24{ex_mem_reg.sign & mem_rdata[23]}}, mem_rdata[23:16]};
            end

            4'b1000: begin 
                mem_wb_reg_next.mem_rdata = {mem_rdata[31:24], 24'h0};
                mem_wb_reg_next.rd_v = {{24{ex_mem_reg.sign & mem_rdata[31]}}, mem_rdata[31:24]};
            end

            4'b0011: begin
                mem_wb_reg_next.mem_rdata = {16'h0, mem_rdata[15:0]};
                mem_wb_reg_next.rd_v = {{16{ex_mem_reg.sign & mem_rdata[15]}}, mem_rdata[15:0]};
            end

            4'b1100: begin
                mem_wb_reg_next.mem_rdata = {mem_rdata[31:16], 16'h0};
                mem_wb_reg_next.rd_v = {{16{ex_mem_reg.sign & mem_rdata[31]}}, mem_rdata[31:16]};
            end

            4'b1111: begin
                mem_wb_reg_next.mem_rdata = mem_rdata;
                mem_wb_reg_next.rd_v = mem_rdata;
            end

            default: begin
                mem_wb_reg_next.valid = '0;
            end
        endcase
    end else if (ex_mem_reg.inst[6:0] == op_store) begin
        mem_wb_reg_next.rd_v = '0;
    end
end

endmodule