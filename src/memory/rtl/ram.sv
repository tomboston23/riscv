`timescale 1ns / 1ps

`include "global_features.svh"
module ram32_magic 
#(F_INIT_FILE_PRESENT=0)(
    input logic clk,

    // port 1 - read-only, designed for instruction fetch
    input logic [31:0] port1_addr,
    output logic [31:0] port1_dout,
    input logic port1_re,
    output logic port1_resp,

    // port 2 - read/write, designed for data access
    input logic [31:0] port2_addr,
    input logic [31:0] port2_din,
    output logic [31:0] port2_dout,         
    input logic [3:0] port2_wstrb,
    input logic [3:0] port2_rstrb,
    output logic port2_resp
);
    logic [31:0] mem [logic [31:0]];

    initial begin
        if (F_INIT_FILE_PRESENT) begin
            int fd;
            int status;
            logic [31:0] addr, data;

            fd = $fopen(`F_INIT_FILE, "r");
            if (fd == 0)
                $fatal("Couldn't open %s", `F_INIT_FILE);

            while (!$feof(fd)) begin
                status = $fscanf(fd, "%h %h\n", addr, data);
                if (status == 2)
                    mem[addr >> 2] = data;
            end

            $fclose(fd);
        end
    end

    logic [31:0] addr1 = port1_addr >> 2;
    logic [31:0] addr2 = port2_addr >> 2;

    always_ff @(posedge clk) begin    
        port1_dout <= 32'bx;
        port2_dout <= 32'bx;
        port1_resp <= 1'b0;
        port2_resp <= 1'b0;

        if (port1_re) begin
            port1_dout <= mem[addr1];
            port1_resp <= 1'b1;
        end

        if (port2_wstrb != 4'h0) begin
            if (port2_wstrb[0]) mem[addr2][7:0]   <= port2_din[7:0];
            if (port2_wstrb[1]) mem[addr2][15:8]  <= port2_din[15:8];
            if (port2_wstrb[2]) mem[addr2][23:16] <= port2_din[23:16];
            if (port2_wstrb[3]) mem[addr2][31:24] <= port2_din[31:24];
            port2_resp <= 1'b1;
        end else if (port2_rstrb != 4'h0) begin
            port2_dout <= mem[addr2];
            port2_resp <= 1'b1;
        end
    end

    always_ff @(posedge clk) begin
        if (port1_re && port1_addr[1:0] != 2'b00) begin
            $fatal(1, "port1 address must be word-aligned");
        end

        if ((port2_wstrb != 4'h0) && (port2_rstrb != 4'h0)) begin
            $fatal(1, "port2 cannot assert write and read strobes at the same time");
        end

        if (port1_re && port2_wstrb != 4'h0 && (port1_addr[31:2] == port2_addr[31:2])) begin
            $fatal(1, "port1 and port2 cannot access the same address at the same time");
        end
    end

endmodule