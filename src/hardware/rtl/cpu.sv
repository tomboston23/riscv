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
logic dmem_req, dmem_req_pending;

assign dmem_req = |(ex_mem_reg.mem_rmask | ex_mem_reg.mem_wmask);
logic [3:0] dmem_rmask_ex;
logic [3:0] dmem_wmask_ex;
logic [31:0] dmem_addr_ex, dmem_wdata_ex;
  
assign dmem_stall = ex_mem_reg.valid & dmem_req & ~dmem_resp;

always_comb begin

    if (!global_stall) begin
        dmem_rmask = dmem_rmask_ex;
        dmem_wmask = dmem_wmask_ex;
        dmem_wdata = dmem_wdata_ex;
        dmem_addr = dmem_addr_ex;
    end else begin
        dmem_rmask = ex_mem_reg.mem_rmask;
        dmem_wmask = ex_mem_reg.mem_wmask;
        dmem_wdata = ex_mem_reg.mem_wdata;
        dmem_addr = ex_mem_reg.mem_addr;
    end

end

assign global_stall = if_stall | dmem_stall;

logic [31:0] pc, pc_next;
if_id_t if_id_reg, if_id_reg_next;
id_ex_t id_ex_reg, id_ex_reg_next;
ex_mem_t ex_mem_reg, ex_mem_reg_next;
mem_wb_t mem_wb_reg, mem_wb_reg_next;

logic jmp;
logic [31:0] jmp_pc;

assign pc_next = jmp ? jmp_pc : pc + 4;

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

            if (jmp) begin
                if_id_reg.valid <= '0;
                id_ex_reg.valid <= '0;
            end else if (load_hazard) begin
                id_ex_reg.valid <= '0;
                if_id_reg <= if_id_reg;
                pc <= pc;
            end
        end
    end
end

logic [4:0] rs1_s, rs2_s, rd_s, csr_rs_s, csr_rd_s;
logic [31:0] rs1_v, rs2_v, rd_v, csr_rdata, csr_wdata;

logic regf_we, csr_we;

// forwarding logic / hazard
logic load_hazard;
fwd_t ex_mem_fwd, mem_wb_fwd;

always_comb begin
    ex_mem_fwd.rd_s = ex_mem_reg.valid ? ex_mem_reg.rd_s : '0;
    ex_mem_fwd.rd_v = ex_mem_reg.rd_v;
    ex_mem_fwd.csr_rd_s = ex_mem_reg.valid ? ex_mem_reg.csr_rd_s : '0;
    ex_mem_fwd.csr_rd_v = ex_mem_reg.csr_wdata;

    mem_wb_fwd.rd_s = mem_wb_reg.valid ? mem_wb_reg.rd_s : '0;
    mem_wb_fwd.rd_v = mem_wb_reg.rd_v;
    mem_wb_fwd.csr_rd_s = mem_wb_reg.valid ? mem_wb_reg.csr_rd_s : '0;
    mem_wb_fwd.csr_rd_v = mem_wb_reg.csr_wdata;
end

assign load_hazard = (((id_ex_reg.rd_s == rs1_s) || (id_ex_reg.rd_s == rs2_s)) && id_ex_reg.inst[6:0] == op_load && id_ex_reg.rd_s != '0);

regfile regfile_inst (
    .clk(clk),
    .rst(rst),
    .regf_we(regf_we),
    .rd_v(rd_v),
    .rs1_s(rs1_s),
    .rs2_s(rs2_s),
    .rd_s(rd_s),
    .rs1_v(rs1_v),
    .rs2_v(rs2_v)
);

csr_regfile csr_regfile_inst (
    .clk(clk),
    .rst(rst),
    .csr_we(csr_we),
    .csr_rs(csr_rs_s),
    .csr_rd(csr_rd_s),
    .data_out(csr_rdata),
    .data_in(csr_wdata),
    .trap('0),
    .priv(priv_mode),
    .trap_pc(mem_wb_reg.pc),
    .trap_cause(mem_wb_reg.trap_cause)
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
    .if_stall(if_stall),
    .load_hazard(load_hazard)
);

id_stage id_stage_inst (
    .if_id_reg(if_id_reg),
    .id_ex_reg_next(id_ex_reg_next),
    .rs1_v(rs1_v),
    .rs2_v(rs2_v),
    .rs1_s(rs1_s),
    .rs2_s(rs2_s),
    .csr_s(csr_rs_s),
    .csr_v(csr_rdata)
);

ex_stage ex_stage_inst (
    .id_ex_reg(id_ex_reg),
    .ex_mem_reg_next(ex_mem_reg_next),
    .mem_addr(dmem_addr_ex),
    .mem_rmask(dmem_rmask_ex),
    .mem_wmask(dmem_wmask_ex),
    .mem_wdata(dmem_wdata_ex),
    .jmp(jmp),
    .pc_next(jmp_pc),
    .ex_mem_fwd(ex_mem_fwd),
    .mem_wb_fwd(mem_wb_fwd)
);

mem_stage mem_stage_inst (
    .ex_mem_reg(ex_mem_reg),
    .mem_wb_reg_next(mem_wb_reg_next),
    .mem_rdata(dmem_rdata)
);

wb_stage wb_stage_inst (
    .mem_wb_reg(mem_wb_reg),
    .regf_we(regf_we),
    .csr_we(csr_we),
    .csr_rd_s(csr_rd_s),
    .csr_wdata(csr_wdata),
    .rd_v(rd_v),
    .rd_s(rd_s)
);

logic [1:0] priv_mode;

always_ff @(posedge clk) begin
    if (rst) begin
        priv_mode <= 2'b11; // Default to machine mode
    end else begin
        // Update privilege mode based on CSR writes
    end
end

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
    commit_intf.valid = mem_wb_reg.valid & !global_stall;
    commit_intf.pc = mem_wb_reg.pc;
    commit_intf.pc_next = mem_wb_reg.pc_next;
    commit_intf.inst = mem_wb_reg.inst;
    commit_intf.rd_s = mem_wb_reg.rd_s;
    commit_intf.rd_v = (mem_wb_reg.rd_s == '0) ? '0 : mem_wb_reg.rd_v;
    commit_intf.rs1_s = mem_wb_reg.rs1_s;
    commit_intf.rs2_s = mem_wb_reg.rs2_s;
    commit_intf.rs1_v = mem_wb_reg.rs1_v;
    commit_intf.rs2_v = mem_wb_reg.rs2_v;
    commit_intf.mem_wmask = mem_wb_reg.mem_wmask;
    commit_intf.mem_rmask = mem_wb_reg.mem_rmask;
    commit_intf.mem_wdata = mem_wb_reg.mem_wdata;
    commit_intf.mem_addr = mem_wb_reg.mem_addr;
    commit_intf.mem_rdata = mem_wb_reg.mem_rdata;
    commit_intf.csr_we = mem_wb_reg.csr_we;
    commit_intf.csr_rd_s = mem_wb_reg.csr_rd_s;
    commit_intf.csr_rdata = mem_wb_reg.csr_rdata;
    commit_intf.csr_wdata = mem_wb_reg.csr_wdata;
end

// debug signals for waveform

logic [31:0] debug_ex_fwd_csr_rd_v, debug_mem_fwd_csr_rd_v;
logic [4:0] debug_ex_fwd_csr_rd_s, debug_mem_fwd_csr_rd_s, debug_id_csr_rd_s;

logic [31:0] debug_ex_csr_wdata, debug_mem_csr_wdata;
logic [4:0] debug_ex_csr_wdata_s, debug_mem_csr_wdata_s;

assign debug_ex_csr_wdata = ex_mem_reg.csr_wdata;
assign debug_mem_csr_wdata = mem_wb_reg.csr_wdata;
assign debug_ex_csr_wdata_s = ex_mem_reg.csr_rd_s;
assign debug_mem_csr_wdata_s = mem_wb_reg.csr_rd_s;
assign debug_ex_fwd_csr_rd_v = ex_mem_fwd.csr_rd_v;
assign debug_ex_fwd_csr_rd_s = ex_mem_fwd.csr_rd_s;
assign debug_mem_fwd_csr_rd_v = mem_wb_fwd.csr_rd_v;
assign debug_mem_fwd_csr_rd_s = mem_wb_fwd.csr_rd_s;
assign debug_id_csr_rd_s = id_ex_reg.csr_rd_s;


endmodule