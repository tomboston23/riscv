module cpu 
import rv32i_types::*;
#(
    parameter int DEFAULT_PC = 32'h0
)
(
    input  logic clk, rst,
    output logic [31:0]  imem_addr,
    output logic         imem_re,
    input  logic [31:0]  imem_rdata,
    input  logic         imem_resp,

    output logic [31:0]  dmem_addr,
    output logic [3:0]   dmem_rmask,
    output logic [3:0]   dmem_wmask,
    input  logic [31:0]  dmem_rdata,
    output logic [31:0]  dmem_wdata,
    input  logic         dmem_resp,
    
    output commit_intf_t commit_intf
);

logic global_stall;
logic if_stall, dmem_stall;

assign dmem_stall = '0;
assign global_stall = if_stall | dmem_stall;

assign dmem_addr = '0;
assign dmem_wdata = '0;
assign dmem_wmask = '0;
assign dmem_rmask = '0;

logic [31:0] pc, pc_next;
if_id_t if_id_reg, if_id_reg_next;
id_ex_t id_ex_reg, id_ex_reg_next;
ex_mem_t ex_mem_reg, ex_mem_reg_next;
mem_wb_t mem_wb_reg, mem_wb_reg_next;

assign pc_next = pc + 4;

always_ff @(posedge clk) begin
    if (rst) begin
        pc <= DEFAULT_PC;
        if_id_reg.valid <= '0;
        id_ex_reg.valid <= '0;
        ex_mem_reg.valid <= '0;
        mem_wb_reg.valid <= '0;
    end else begin
        pc <= pc_next;
        if_id_reg <= if_id_reg_next;
        id_ex_reg <= id_ex_reg_next;
        ex_mem_reg <= ex_mem_reg_next;
        mem_wb_reg <= mem_wb_reg_next;
    end
end
    
if_stage if_stage_inst (
    .pc(pc),
    .pc_next(pc_next),
    .imem_rdata(imem_rdata),
    .imem_resp(imem_resp),
    .global_stall(global_stall),
    .if_id_next(if_id_reg_next),
    .imem_addr(imem_addr),
    .imem_re(imem_re),
    .if_stall(if_stall)
);

// Initialize the commit interface
logic [31:0] order;

always_ff @(posedge clk) begin
    if (rst) begin
        order <= '0;
    end else if (commit_intf.valid) begin
        order <= order + 1;
    end
end

always_comb begin
    commit_intf = '0;
    commit_intf.valid = if_id_reg.valid & !global_stall;
    commit_intf.pc = if_id_reg.pc;
    commit_intf.pc_next = if_id_reg.pc_next;
    commit_intf.inst = if_id_reg.inst;
end

endmodule