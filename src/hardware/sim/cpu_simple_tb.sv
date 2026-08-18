`timescale 1ns / 1ps

`ifndef OUT_HOME
`error "OUT_HOME not defined"
`endif

`include "global_features.svh"

localparam logic [31:0] ELF_ENTRY = 32'h`ELF_ENTRY;
`ifdef F_RISCV_EXIT_INST_PRESENT__0
localparam logic [31:0] TOHOST_ADDR = 32'h`TOHOST_ADDR;
`endif
localparam logic [31:0] PRINT_DUMP_ADDR = 32'h`PRINT_DUMP_ADDR;
string cpu_dumpfile_path = {`OUT_HOME, "/hardware/waves/cpu_simple.vcd"};
string print_dumpfile_path = {`OUT_HOME, "/program/run/print_dump.log"};

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
    output logic [31:0] order,
    output logic commit_csr_we,
    output logic [4:0] commit_csr_rd_s,
    output logic [31:0] commit_csr_rdata,
    output logic [31:0] commit_csr_wdata
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
    output logic [31:0] order,
    output logic commit_csr_we,
    output logic [4:0] commit_csr_rd_s,
    output logic [31:0] commit_csr_rdata,
    output logic [31:0] commit_csr_wdata
);
`endif

    //-------------------------------------------------------------------------
    // Variable declarations
    //-------------------------------------------------------------------------

    logic tb_read_active;

    logic [31:0] cpu_port2_addr;
    logic [3:0]  cpu_port2_rstrb;
    logic [3:0]  cpu_port2_wstrb;
    logic [31:0] cpu_port2_din;
    logic [31:0] cpu_port2_dout;
    logic        cpu_port2_resp;

    logic [31:0] tb_addr;
    logic [3:0]  tb_rstrb;
    logic [31:0] tb_dout;
    logic        tb_resp;

    logic [31:0] port1_addr, port1_dout, port2_addr, port2_din, port2_dout;
    logic port1_re, port1_resp, port2_resp;
    logic [3:0] port2_wstrb, port2_rstrb;
    commit_intf_t commit_intf;

    assign port2_addr  = tb_read_active ? tb_addr  : cpu_port2_addr;
    assign port2_rstrb = tb_read_active ? tb_rstrb : cpu_port2_rstrb;
    assign port2_wstrb = tb_read_active ? 4'h0    : cpu_port2_wstrb;
    assign port2_din   = cpu_port2_din;

    assign cpu_port2_dout = tb_read_active ? 32'h0 : port2_dout;
    assign cpu_port2_resp = tb_read_active ? 1'b0  : port2_resp;

    assign tb_dout = tb_read_active ? port2_dout : 32'h0;
    assign tb_resp = tb_read_active ? port2_resp : 1'b0;

    assign commit_valid = tb_read_active ? '0 : commit_intf.valid;
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
    assign commit_csr_we = commit_intf.csr_we;
    assign commit_csr_rd_s = commit_intf.csr_rd_s;
    assign commit_csr_rdata = commit_intf.csr_rdata;
    assign commit_csr_wdata = commit_intf.csr_wdata;


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
        .dmem_addr(cpu_port2_addr),
        .dmem_wdata(cpu_port2_din),
        .dmem_rdata(cpu_port2_dout),
        .dmem_wmask(cpu_port2_wstrb),
        .dmem_rmask(cpu_port2_rstrb),
        .dmem_resp(cpu_port2_resp),
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

    task automatic read_from_port2(
        input logic [31:0] addr,
        input logic [3:0] rstrb,
        output logic [31:0] data_out
    );
    begin
        tb_read_active = '1;
        @ (posedge clk);
        // $display("[%0t] READ START addr=%08h strb=%h",
        //         $time, addr, rstrb);

        while (tb_resp)
            @(posedge clk);

        tb_addr  = addr;
        tb_rstrb = rstrb;

        @(posedge clk);

        tb_rstrb = 4'h0;

        while (!tb_resp)
            @(posedge clk);

        // $display("[%0t] READ RESPONSE addr=%08h dout=%08h",
        //         $time, addr, tb_dout);

        data_out = tb_dout;

        // $display("[%0t] READ DATA_OUT=%08h",
        //         $time, tb_dout);
        tb_read_active = '0;
    end
    endtask

    task automatic get_print_dump();
        begin
            logic [31:0] print_dump_start = PRINT_DUMP_ADDR + 'd4;
            logic [31:0] print_dump_end;

            integer fd;
            logic [31:0] addr;
            logic [31:0] aligned_addr;
            logic [1:0] lane;
            logic [3:0] rstrb;
            logic [31:0] word, word_data;
            logic [7:0] byte_data;

            read_from_port2(PRINT_DUMP_ADDR, 4'hF, print_dump_end);

            fd = $fopen(print_dumpfile_path, "w");
            if (fd == 0) begin
                $display("ERROR: could not open print dump file: %s", print_dumpfile_path);
            end else begin
                if (print_dump_end <= print_dump_start) begin
                    $display("PRINT DUMP empty (start=%0h end=%0h)", print_dump_start, print_dump_end);
                end else begin
                    for (addr = print_dump_start; addr < print_dump_end; addr = addr + 1) begin
                        aligned_addr = addr & 32'hFFFFFFFC; // word-aligned base
                        lane = addr[1:0];
                        rstrb = 4'h1 << lane; // select the byte lane
                        read_from_port2(aligned_addr, rstrb, word);
                        word_data = (word >> (8*lane));
                        byte_data = word_data[7:0];
                        $fwrite(fd, "%c", byte_data);
                    end
                end
                $fclose(fd);
            end
        end
    endtask

    //-------------------------------------------------------------------------
    // Test Sequence
    //-------------------------------------------------------------------------

    initial begin
        logic done = '0;

        tb_read_active = '0;
`ifdef F_RISCV_EXIT_INST_PRESENT__1
        while (!done) begin
            #1;
            if (commit_intf.valid && commit_intf.inst == `F_RISCV_EXIT_INST) begin // check for exit instruction
                done = '1;
            end
        end
        $display("=== EXIT instruction hit; finished ===");
`endif // F_RISCV_EXIT_INST_PRESENT__1

`ifdef F_RISCV_EXIT_INST_PRESENT__0
        while (!done) begin
            #1;
            if (commit_intf.valid && |commit_intf.mem_wmask && commit_intf.mem_addr == TOHOST_ADDR) begin // check for tohost write
                done = '1;
            end
        end
        $display("=== TOHOST hit; finished ===");
`endif // F_RISCV_EXIT_INST_PRESENT__0
        get_print_dump();
        $finish();

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

    // always @ (posedge clk) begin
    //     if (port2_wstrb != '0 && port2_addr == PRINT_DUMP_ADDR) begin
    //         $display ("print dump modified to %8h", port2_din);
    //     end
    // end
endmodule
