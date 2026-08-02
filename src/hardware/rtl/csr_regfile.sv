module csr_regfile
import rv32i_types::*;
(
    input logic clk,
    input logic rst,

    // normal CSR instructions
    input logic csr_we,
    input logic [4:0] csr_rs, csr_rd,
    input logic [31:0] data_in,
    output logic [31:0] data_out,

    // traps
    input logic trap,
    input logic [1:0]  priv,
    input logic [31:0] trap_pc,
    input logic [31:0] trap_cause
);

logic [31:0] csr_regfile [NUM_CSR_REGS];

always_comb begin
    if (rst) begin
        data_out = 'x;
    end

    // transparency
    else begin
        if (csr_rs == '0) begin
            data_out = '0;
        end else if (csr_rd == csr_rs && csr_we) begin
            data_out = data_in;
        end else begin
            data_out = csr_regfile[csr_rs];
        end
    end
end

always_ff @(posedge clk) begin
    if (rst) begin
        for (int i = 0; i < NUM_CSR_REGS; i++) begin
            csr_regfile[i] <= 0;
        end
    end else begin
        if (csr_we) begin
            csr_regfile[csr_rd] <= data_in;
        end 
        if (trap) begin
            if (priv == 2'b11) begin // machine mode
                csr_regfile[csr_mscratch_reg] <= trap_pc;
                csr_regfile[csr_mcause_reg] <= trap_cause;
            end else if (priv == 2'b01) begin // supervisor mode
                csr_regfile[csr_sscratch_reg] <= trap_pc;
                csr_regfile[csr_scause_reg] <= trap_cause;
            end
        end
    end
end

endmodule