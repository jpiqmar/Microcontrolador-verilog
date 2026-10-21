
`timescale 1ns/1ps

module tb_alu;

  logic [31:0] A, B;
  logic [3:0]  op;
  logic [31:0] RES;
  logic        zero;

  // Instancia del DUT
  alu dut (
    .A(A),
    .B(B),
    .op(op),
    .RES(RES),
    .zero(zero)
  );

  initial begin
    $display("=== Inicio Testbench ALU ===");

    // -------- Basicos --------
    // ADD
    A = 32'd10; B = 32'd5; op = 4'b0000; #1;
    assert(RES == 32'd15) else $error("ADD fallo: RES=%0d", RES);
    assert(zero == 1'b0);

    // SUB
    A = 32'd10; B = 32'd5; op = 4'b0001; #1;
    assert(RES == 32'd5) else $error("SUB fallo: RES=%0d", RES);
    assert(zero == 1'b0);

    // AND
    A = 32'hF0F0F0F0; B = 32'h0FF00FF0; op = 4'b0010; #1;
    assert(RES == (32'hF0F0F0F0 & 32'h0FF00FF0)) else $error("AND fallo");
    assert(zero == 1'b0);

    // OR
    A = 32'hF0F0F0F0; B = 32'h0FF00FF0; op = 4'b0011; #1;
    assert(RES == (32'hF0F0F0F0 | 32'h0FF00FF0)) else $error("OR fallo");

    // XOR
    A = 32'h12345678; B = 32'h87654321; op = 4'b0100; #1;
    assert(RES == (32'h12345678 ^ 32'h87654321)) else $error("XOR fallo");

    // SLL
    A = 32'h0000_0001; B = 32'd4; op = 4'b0101; #1;
    assert(RES == (32'h0000_0001 << 4)) else $error("SLL fallo");

    // SRL
    A = 32'h8000_0000; B = 32'd4; op = 4'b0110; #1;
    assert(RES == (32'h8000_0000 >> 4)) else $error("SRL fallo");

    // SRA
    A = 32'hFFFF_FF00; B = 32'd4; op = 4'b0111; #1;
    assert(RES == 32'hFFFF_FFF0) else $error("SRA fallo");

    // SLT (signed)
    A = -32'sd5; B = 32'sd10; op = 4'b1000; #1;
    assert(RES == 32'd1) else $error("SLT fallo");

    // SLTU (unsigned)
    A = 32'd5; B = 32'd10; op = 4'b1001; #1;
    assert(RES == 32'd1) else $error("SLTU fallo");

    // -------- Branch-ops (salida 0 si se cumple, activa zero=1) --------
    // BEQ
    A = 32'd7; B = 32'd7; op = 4'b1010; #1;
    assert(RES == 32'd0) else $error("BEQ (igual) fallo");
    assert(zero == 1'b1);

    A = 32'd7; B = 32'd9; op = 4'b1010; #1;
    assert(RES == 32'd1) else $error("BEQ (distinto) fallo");
    assert(zero == 1'b0);

    // BNE
    A = 32'd7; B = 32'd9; op = 4'b1011; #1;
    assert(RES == 32'd0) else $error("BNE (distinto) fallo");
    assert(zero == 1'b1);

    A = 32'd7; B = 32'd7; op = 4'b1011; #1;
    assert(RES == 32'd1) else $error("BNE (igual) fallo");
    assert(zero == 1'b0);

    // BLT (signed): ($signed(A) < $signed(B)) ? 0 : 1
    // Se cumple -> RES=0, zero=1
    A = -32'sd16; B = 32'sd0; op = 4'b1100; #1;
    assert(RES == 32'd0) else $error("BLT signed (-16<0) fallo");
    assert(zero == 1'b1);

    // NO se cumple -> RES=1, zero=0
    A = 32'sd5; B = 32'sd0; op = 4'b1100; #1;
    assert(RES == 32'd1) else $error("BLT signed (5<0?) fallo");
    assert(zero == 1'b0);

    // BLTU (unsigned): (A < B) ? 0 : 1
    // Se cumple -> RES=0, zero=1
    A = 32'd5; B = 32'd10; op = 4'b1101; #1;
    assert(RES == 32'd0) else $error("BLTU (5<10) fallo");
    assert(zero == 1'b1);

    // NO se cumple -> RES=1, zero=0
    A = 32'hFFFF_FFF0; B = 32'd10; op = 4'b1101; #1;
    assert(RES == 32'd1) else $error("BLTU (0xFFFF_FFF0<10?) fallo");
    assert(zero == 1'b0);

    // BGE (signed): ($signed(A) >= $signed(B)) ? 0 : 1
    // Se cumple -> equal -> RES=0, zero=1
    A = -32'sd10; B = -32'sd10; op = 4'b1110; #1;
    assert(RES == 32'd0) else $error("BGE signed (-10>=-10) fallo");
    assert(zero == 1'b1);

    // NO se cumple -> RES=1, zero=0
    A = -32'sd11; B = -32'sd10; op = 4'b1110; #1;
    assert(RES == 32'd1) else $error("BGE signed (-11>=-10?) fallo");
    assert(zero == 1'b0);

    // BGEU (unsigned): (A >= B) ? 0 : 1
    // Se cumple -> equal -> RES=0, zero=1
    A = 32'd10; B = 32'd10; op = 4'b1111; #1;
    assert(RES == 32'd0) else $error("BGEU (10>=10) fallo");
    assert(zero == 1'b1);

    // NO se cumple -> RES=1, zero=0
    A = 32'd9; B = 32'd10; op = 4'b1111; #1;
    assert(RES == 32'd1) else $error("BGEU (9>=10?) fallo");
    assert(zero == 1'b0);

    // Se cumple -> mayor -> RES=0, zero=1
    A = 32'hFFFF_FFF0; B = 32'd10; op = 4'b1111; #1;
    assert(RES == 32'd0) else $error("BGEU (0xFFFF_FFF0>=10) fallo");
    assert(zero == 1'b1);

    $display("=== Todas las pruebas PASARON ===");
    $stop;
  end

endmodule
