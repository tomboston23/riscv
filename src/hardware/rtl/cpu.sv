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

logic [31:0] pc, pc_next;
if_id_t if_id_reg, if_id_reg_next;
id_ex_t id_ex_reg, id_ex_reg_next;
ex_mem_t ex_mem_reg, ex_mem_reg_next;
mem_wb_t mem_wb_reg, mem_wb_reg_next;

logic jmp;
logic [31:0] jmp_pc;

assign pc_next = pc + 4;

always_ff @(posedge clk) begin
    if (rst) begin
        pc <= DEFAULT_PC;
        if_id_reg.valid <= '0;
        id_ex_reg.valid <= '0;
        ex_mem_reg.valid <= '0;
        mem_wb_reg.valid <= '0;
    end else begin
        if (!global_stall) begin
            pc <= pc_next;
            if_id_reg <= if_id_reg_next;
            id_ex_reg <= id_ex_reg_next;
            ex_mem_reg <= ex_mem_reg_next;
            mem_wb_reg <= mem_wb_reg_next;
        end
    end
end

logic [4:0] rs1_s, rs2_s;
logic [31:0] rs1_v, rs2_v;

regfile regfile_inst (
    .clk(clk),
    .rst(rst),
    .regf_we(commit_intf.valid),
    .rd_v(commit_intf.rd_v),
    .rs1_s(rs1_s),
    .rs2_s(rs2_s),
    .rd_s(commit_intf.rd_s),
    .rs1_v(rs1_v),
    .rs2_v(rs2_v)
);
    
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

id_stage id_stage_inst (
    .if_id_reg(if_id_reg),
    .id_ex_reg_next(id_ex_reg_next),
    .rs1_v(rs1_v),
    .rs2_v(rs2_v),
    .rs1_s(rs1_s),
    .rs2_s(rs2_s)
);

ex_stage ex_stage_inst (
    .id_ex_reg(id_ex_reg),
    .ex_mem_reg_next(ex_mem_reg_next),
    .mem_addr(dmem_addr),
    .mem_rmask(dmem_rmask),
    .mem_wmask(dmem_wmask),
    .mem_wdata(dmem_wdata),
    .jmp(jmp),
    .pc_next(jmp_pc)
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
    commit_intf.order = order;
    commit_intf.valid = ex_mem_reg.valid & !global_stall;
    commit_intf.pc = ex_mem_reg.pc;
    commit_intf.pc_next = ex_mem_reg.pc_next;
    commit_intf.inst = ex_mem_reg.inst;
    commit_intf.rd_s = ex_mem_reg.rd_s;
    commit_intf.rd_v = ex_mem_reg.rd_v;
    commit_intf.rs1_s = ex_mem_reg.rs1_s;
    commit_intf.rs2_s = ex_mem_reg.rs2_s;
    commit_intf.rs1_v = ex_mem_reg.rs1_v;
    commit_intf.rs2_v = ex_mem_reg.rs2_v;
    commit_intf.mem_wmask = ex_mem_reg.mem_wmask;
    commit_intf.mem_rmask = ex_mem_reg.mem_rmask;
    commit_intf.mem_wdata = ex_mem_reg.mem_wdata;
    commit_intf.mem_addr = ex_mem_reg.mem_addr;
end

endmodule