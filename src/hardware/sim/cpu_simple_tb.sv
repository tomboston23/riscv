`timescale 1ns / 1ps

`ifndef OUT_HOME
`error "OUT_HOME not defined"
`endif

`include "global_features.svh"

localparam logic [31:0] ELF_ENTRY = 32'h`ELF_ENTRY;
string cpu_dumpfile_path = {`OUT_HOME, "/hardware/waves/cpu_simple.vcd"};

import rv32i_types::*;

`ifdef TB_DRIVE_CLOCKS
module cpu_simple_tb(
    output logic        commit_valid,
    output logic [31:0] commit_pc,
    output logic [31:0] commit_pc_next,
    output logic [31:0] commit_inst,
    output logic [4:0] commit_rd_s,
    output logic [31:0] commit_rd_v,
    output logic [4:0] commit_rs1_s,
    output logic [31:0] commit_rs1_v,
    output logic [4:0] commit_rs2_s,
    output logic [31:0] commit_rs2_v,
    output logic [3:0] commit_mem_wmask,
    output logic [3:0] commit_mem_rmask,
    output logic [31:0] commit_mem_addr,
    output logic [31:0] commit_mem_rdata,
    output logic [31:0] commit_mem_wdata,
    output logic [31:0] order
);

    logic clk = '0;
    logic rst = '1;

    initial begin
        repeat (5) begin
            @(posedge clk);
        end
        rst = '0;
    end

    always begin
        #5ns;
        clk = ~clk;
    end
`else
module cpu_simple_tb(
    input  logic clk,
    input  logic rst,
    output logic        commit_valid,
    output logic [31:0] commit_pc,
    output logic [31:0] commit_pc_next,
    output logic [31:0] commit_inst,
    output logic [4:0] commit_rd_s,
    output logic [31:0] commit_rd_v,
    output logic [4:0] commit_rs1_s,
    output logic [31:0] commit_rs1_v,
    output logic [4:0] commit_rs2_s,
    output logic [31:0] commit_rs2_v,
    output logic [3:0] commit_mem_wmask,
    output logic [3:0] commit_mem_rmask,
    output logic [31:0] commit_mem_addr,
    output logic [31:0] commit_mem_rdata,
    output logic [31:0] commit_mem_wdata,
    output logic [31:0] order
);
`endif

    //-------------------------------------------------------------------------
    // Variable declarations
    //-------------------------------------------------------------------------

    logic [31:0] port1_addr, port1_dout, port2_addr, port2_din, port2_dout;
    logic port1_re, port1_resp, port2_resp;
    logic [3:0] port2_wstrb, port2_rstrb;
    commit_intf_t commit_intf;

    assign commit_valid = commit_intf.valid;
    assign commit_pc = commit_intf.pc;
    assign commit_pc_next = commit_intf.pc_next;
    assign commit_inst = commit_intf.inst;
    assign commit_rd_s = commit_intf.rd_s;
    assign commit_rd_v = commit_intf.rd_v;
    assign commit_rs1_s = commit_intf.rs1_s;
    assign commit_rs1_v = commit_intf.rs1_v;
    assign commit_rs2_s = commit_intf.rs2_s;
    assign commit_rs2_v = commit_intf.rs2_v;
    assign commit_mem_wmask = commit_intf.mem_wmask;
    assign commit_mem_addr = commit_intf.mem_addr;
    assign commit_mem_wdata = commit_intf.mem_wdata;
    assign commit_mem_rmask = commit_intf.mem_rmask;
    assign commit_mem_rdata = commit_intf.mem_rdata;
    assign order = commit_intf.order;


    //-------------------------------------------------------------------------
    // Instantiate the DUT
    // -------------------------------------------------------------------------
`ifdef F_MAGIC_MEMORY__1
    ram32_magic #(.F_INIT_FILE_PRESENT(1'b1)) ram (
        .clk(clk),
        .rst(rst),
        .port1_addr(port1_addr),
        .port1_dout(port1_dout),
        .port1_re(port1_re),
        .port1_resp(port1_resp),
        .port2_addr(port2_addr),
        .port2_din(port2_din),
        .port2_dout(port2_dout),
        .port2_wstrb(port2_wstrb),
        .port2_rstrb(port2_rstrb),
        .port2_resp(port2_resp)
    );
`endif

`ifdef F_MAGIC_MEMORY__0
    ram32 #(.F_INIT_FILE_PRESENT(1'b1), .RAM_CLK_DELAY(`F_RAM_DELAY)) ram (
        .clk(clk),
        .rst(rst),
        .port1_addr(port1_addr),
        .port1_dout(port1_dout),
        .port1_re(port1_re),
        .port1_resp(port1_resp),
        .port2_addr(port2_addr),
        .port2_din(port2_din),
        .port2_dout(port2_dout),
        .port2_wstrb(port2_wstrb),
        .port2_rstrb(port2_rstrb),
        .port2_resp(port2_resp)
    );
`endif

    cpu #(.DEFAULT_PC(ELF_ENTRY)) dut (
        .clk(clk),
        .rst(rst),
        .imem_addr(port1_addr),
        .imem_rdata(port1_dout),
        .imem_re(port1_re),
        .imem_resp(port1_resp),
        .dmem_addr(port2_addr),
        .dmem_wdata(port2_din),
        .dmem_rdata(port2_dout),
        .dmem_wmask(port2_wstrb),
        .dmem_rmask(port2_rstrb),
        .dmem_resp(port2_resp),
        .commit_intf(commit_intf)
    );

    //-------------------------------------------------------------------------
    // Define sub-tasks for common operations
    //-------------------------------------------------------------------------

    task automatic cause_fail();
        begin
            $display("=== Causing Intentional Failure ===");
            $fatal(1, "Intentional failure for testing purposes.");
        end
    endtask
    //-------------------------------------------------------------------------
    // Test Sequence
    //-------------------------------------------------------------------------

    initial begin
        logic done = '0;
`ifdef F_RISCV_EXIT_INST_PRESENT__1
        while (!done) begin
            #1;
            if (commit_intf.valid && commit_intf.inst == `F_RISCV_EXIT_INST) begin // check for exit instruction
                done = '1;
            end
        end

        $display("=== RISCV Exit Instruction Detected ===");
        $finish;
`endif // F_RISCV_EXIT_INST_PRESENT__1

    end

    //-------------------------------------------------------------------------
    // Optional Timeout
    //-------------------------------------------------------------------------

    initial begin
        #1ms;
        $fatal(1, "Simulation timed out.");
    end

    //-------------------------------------------------------------------------
    // Waveform Dump
    //-------------------------------------------------------------------------

    initial begin
        $dumpfile(cpu_dumpfile_path);
        $dumpvars(0, cpu_simple_tb);
        $dumpvars(0, cpu_simple_tb.dut);
    `ifdef F_MAGIC_MEMORY__1
        $dumpvars(0, cpu_simple_tb.ram);
    `endif
    end

endmodule
