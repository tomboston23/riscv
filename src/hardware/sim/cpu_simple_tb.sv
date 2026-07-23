`timescale 1ns / 1ps

`ifndef OUT_HOME
`error "OUT_HOME not defined"
`endif

`include "global_features.svh"

localparam string OUT_HOME_STR = `OUT_HOME;
localparam logic [31:0] ELF_ENTRY = 32'h`ELF_ENTRY;
string dumpfile_path = {OUT_HOME_STR, "/hardware/waves/cpu_simple.vcd"};

import rv32i_types::*;

module cpu_simple_tb(
    input  logic clk,
    input  logic rst,
    output logic        commit_valid,
    output logic [31:0] commit_pc,
    output logic [31:0] commit_inst
);

    //-------------------------------------------------------------------------
    // Variable declarations
    //-------------------------------------------------------------------------

    logic [31:0] port1_addr, port1_dout, port2_addr, port2_din, port2_dout;
    logic port1_re, port1_resp, port2_resp;
    logic [3:0] port2_wstrb, port2_rstrb;
    commit_intf_t commit_intf;

    assign commit_valid = commit_intf.valid;
    assign commit_pc = commit_intf.pc;
    assign commit_inst = commit_intf.inst;

    //-------------------------------------------------------------------------
    // Instantiate the DUT
    // -------------------------------------------------------------------------
`ifdef F_MAGIC_MEMORY
    ram32_magic #(.F_INIT_FILE_PRESENT(1'b1)) ram (
        .clk(clk),
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
`ifdef F_RISCV_EXIT_INST
        if (commit_intf.valid && commit_intf.inst == `F_RISCV_EXIT_INST) begin // check for exit instruction
            $display("=== RISCV Exit Instruction Detected ===");
            $finish;
        end
`endif // F_RISCV_EXIT_INST_PRESENT

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
        $dumpfile(dumpfile_path);
        $dumpvars(0, cpu_simple_tb);
    end

endmodule