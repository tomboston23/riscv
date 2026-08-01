module wb_stage 
import rv32i_types::*; 
(
    input mem_wb_t mem_wb_reg,
    output logic regf_we,
    output logic [31:0] rd_v,
    output logic [4:0]  rd_s
);

always_comb begin 
    regf_we = '0;
    rd_v = '0;
    rd_s = '0;

    if (mem_wb_reg.valid) begin
        regf_we = (mem_wb_reg.rd_s != '0);
        rd_v = mem_wb_reg.rd_v;
        rd_s = mem_wb_reg.rd_s;
    end
end

endmodule