`timescale 1ns / 1ps

`ifndef OUT_HOME
`error "OUT_HOME not defined"
`endif

localparam string OUT_HOME_STR = `OUT_HOME;
string dumpfile_path = {OUT_HOME_STR, "/memory/waves/wave.vcd"};

module memory_simple_tb;

    //-------------------------------------------------------------------------
    // Clock & Reset
    //-------------------------------------------------------------------------

    logic clk = 0;
    logic rst = 1;

    localparam CLK_PERIOD = 10ns;

    always #(CLK_PERIOD/2) clk = ~clk;

    //-------------------------------------------------------------------------
    // Variable declarations
    //-------------------------------------------------------------------------

    logic [31:0] port1_addr, port1_dout, port2_addr, port2_din, port2_dout;
    logic port1_re, port1_resp, port2_resp;
    logic [3:0] port2_wstrb, port2_rstrb;

    //-------------------------------------------------------------------------
    // Instantiate the DUT
    // -------------------------------------------------------------------------

    ram32_magic dut (
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

    //-------------------------------------------------------------------------
    // Reset Sequence
    //-------------------------------------------------------------------------

    initial begin
        rst = 1;
        repeat (5) @(posedge clk);
        rst = 0;
    end

    //-------------------------------------------------------------------------
    // Define sub-tasks for common operations
    //-------------------------------------------------------------------------
    task automatic write_to_port2(input logic [31:0] addr, input logic [31:0] data, input logic [3:0] wstrb);
        begin
            port2_addr = addr;
            port2_din = data;
            port2_wstrb = wstrb;
            @(posedge clk);
            port2_wstrb = 4'h0;

            while (!port2_resp) @(posedge clk); // Wait for write response
        end
    endtask

    task automatic read_from_port2(input logic [31:0] addr, input logic [3:0] rstrb, output logic [31:0] data_out);
        begin
            port2_addr = addr;
            port2_rstrb = rstrb;
            @(posedge clk);
            port2_rstrb = 4'h0;

            while (!port2_resp) @(posedge clk); // Wait for read response
            data_out = port2_dout;
        end
    endtask

    task automatic read_from_port1(input logic [31:0] addr, output logic [31:0] data_out);
        begin
            port1_addr = addr;
            port1_re = 1'b1;
            @(posedge clk);
            port1_re = 1'b0;

            while (!port1_resp) @(posedge clk); // Wait for read response
            data_out = port1_dout;
        end
    endtask

    //-------------------------------------------------------------------------
    // Test Sequence
    //-------------------------------------------------------------------------

    initial begin

        $display("=== Starting Simulation ===");

        // Wait until reset completes
        @(negedge rst);

        // TODO: Apply stimulus here

        $display("=== Starting Test 1 ===");
        // Test 1: Simple port2 test: single write and read back
        write_to_port2(32'h00000004, 32'hDEADBEEF, 4'hF);
        read_from_port2(32'h00000004, 4'hF, port2_dout);
        assert(port2_dout == 32'hDEADBEEF) else $fatal(1, "Data read back does not match data written!");
    
        $display("=== Starting Test 2 ===");

        // Test 2: Complex port2 test: multiple interleaved writes and reads
        write_to_port2(32'h00000008, 32'hCAFEBABE, 4'hF);
        read_from_port2(32'h00000008, 4'hF, port2_dout);
        assert(port2_dout == 32'hCAFEBABE) else $fatal(1, "Data read back does not match data written!");

        write_to_port2(32'h0000000C, 32'hFEEDFACE, 4'hF);
        read_from_port2(32'h0000000C, 4'hF, port2_dout);
        assert(port2_dout == 32'hFEEDFACE) else $fatal(1, "Data read back does not match data written!");

        read_from_port2(32'h00000008, 4'hF, port2_dout);
        assert(port2_dout == 32'hCAFEBABE) else $fatal(1, "Data read back does not match data written!");

        read_from_port2(32'h0000000C, 4'hF, port2_dout);
        assert(port2_dout == 32'hFEEDFACE) else $fatal(1, "Data read back does not match data written!");
    
        write_to_port2(32'h00000010, 32'h12345678, 4'hF);
        read_from_port2(32'h00000010, 4'hF, port2_dout);
        assert(port2_dout == 32'h12345678) else $fatal(1, "Data read back does not match data written!");

        read_from_port2(32'h0000000C, 4'hF, port2_dout);
        assert(port2_dout == 32'hFEEDFACE) else $fatal(1, "Data read back does not match data written!");
        read_from_port2(32'h00000008, 4'hF, port2_dout);
        assert(port2_dout == 32'hCAFEBABE) else $fatal(1, "Data read back does not match data written!");

        $display("=== Starting Test 3 ===");

        //Test 3: Port2 Strobe Tests: Write and Read with different strobes
        write_to_port2(32'h00000014, 32'hAABBCCDD, 4'b0011); // Write lower half
        write_to_port2(32'h00000014, 32'h11223344, 4'b1100); // Write upper half
        read_from_port2(32'h00000014, 4'hF, port2_dout);
        assert(port2_dout == 32'h3344CCDD) else $fatal(1, "Data read back does not match data written!");

        $display("=== Simulation Complete ===");
        $finish;
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
        $dumpvars(0, memory_simple_tb);
    end

endmodule