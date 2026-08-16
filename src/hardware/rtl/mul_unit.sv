module muldiv_unit
import rv32i_types::*;
(
    input  logic [31:0] a,
    input  logic [31:0] b,
    input  logic [2:0]  mulop,
    output logic [31:0] mulout
);

  logic signed   [31:0] as;
  logic signed   [31:0] bs;
  logic unsigned [31:0] au;
  logic unsigned [31:0] bu;

  assign as =   signed'(a);
  assign bs =   signed'(b);
  assign au = unsigned'(a);
  assign bu = unsigned'(b);

  logic [63:0] product;
  logic [31:0] quotient;
  logic [31:0] remainder;

  always_comb begin
    product = as * bs;
    mulout = '0;
    quotient = '0;
    remainder = '0;

    unique case (mulop)
      mul: mulout = product[31:0];

      mulh: mulout = product[63:32];

      mulhsu: begin
        product = as * bu;
        mulout = product[63:32];
      end

      mulhu: begin
        product = au * bu;
        mulout = product[63:32];
      end

      div: begin
        if (b == 0) begin
          mulout = '1;
        end else begin
          quotient = as / bs;
          mulout = quotient;
        end
      end

      divu: begin
        if (b == 0) begin
          mulout = '1;
        end else begin
          quotient = au / bu;
          mulout = quotient;
        end
      end

      rem: begin
        if (b == 0) begin
          mulout = a;
        end else if ((a == 32'h80000000) && (b == 32'hFFFFFFFF)) begin
            mulout = 32'b0;
        end else begin
          remainder = as % bs;
          mulout = remainder;
        end
      end

      remu: begin
        if (b == 0) begin
          mulout = a;
        end else begin
          remainder = au % bu;
          mulout = remainder;
        end
      end

      default: mulout = 'x;

    endcase
  end

endmodule