//module alu (
//    input logic [31:0] A,       // Operando 1
//    input logic [31:0] B,       // Operando 2
//    input logic [3:0] op,      // Código de operación de la ALU
//    output logic [31:0] RES,    // Resultado de la operación
//    output logic zero            // Flag de cero
//);
//
//    // Definir las operaciones de la ALU
//    always_comb begin
//        case (op)
//            4'b0000: RES = A + B;                                         // ADD
//            4'b0001: RES = A - B;                                         // SUB
//            4'b0010: RES = A & B;                                         // AND
//            4'b0011: RES = A | B;                                         // OR
//            4'b0100: RES = A ^ B;                                         // XOR
//            4'b0101: RES = A << B[4:0];                                   // SLL
//            4'b0110: RES = A >> B[4:0];                                   // SRL
//            4'b0111: RES = $signed(A) >>> B[4:0];                         // SRA
//            4'b1000: RES = ($signed(A) < $signed(B)) ? 32'd1 : 32'd0;     // SLT (signed)
//            4'b1001: RES = (A < B) ? 32'd1 : 32'd0;                       // SLTU (unsigned)
//            4'b1010: RES = (A == B) ? 32'd0 : 32'd1;                      // BEQ
//            4'b1011: RES = (A != B) ? 32'd0 : 32'd1;                      // BNE
//            4'b1100: RES = ($signed(A) < $signed(B)) ? 32'd0 : 32'd1;     // BLT (signed)
//            4'b1101: RES = (A < B) ? 32'd0 : 32'd1;                       // BLTU (unsigned)
//            4'b1110: RES = ($signed(A) >= $signed(B)) ? 32'd0 : 32'd1;    // BGE (signed)
//            4'b1111: RES = (A >= B) ? 32'd0 : 32'd1;                      // BGEU (unsigned)
//            default: RES = 32'd1;
//        endcase
//
//        zero = (RES == 0);  // Flag de cero
//    end
//
//endmodule
//
module alu (
    input  logic [31:0] A, B,
    input  logic [3:0]  op,
    output logic [31:0] RES,
    output logic        zero
);
    always_comb begin
        case (op)
            4'b0000: RES = A + B;                      // ADD / ADDI / LW / SW
            4'b0001: RES = A - B;                      // SUB
            4'b0010: RES = A & B;                      // AND
            4'b0011: RES = A | B;                      // OR
            4'b0100: RES = A ^ B;                      // XOR
            4'b0101: RES = A << B[4:0];                // SLL
            4'b0110: RES = A >> B[4:0];                // SRL
            4'b0111: RES = $signed(A) >>> B[4:0];      // SRA
            4'b1000: RES = ($signed(A) < $signed(B)) ? 32'd1 : 32'd0; // SLT
            4'b1001: RES = (A < B) ? 32'd1 : 32'd0;    // SLTU
            
            // Lógica de Saltos: RES=0 (zero=1) si la condición es VERDADERA
            4'b1010: RES = (A == B) ? 32'd0 : 32'd1;   // BEQ
            4'b1011: RES = (A != B) ? 32'd0 : 32'd1;   // BNE
            4'b1100: RES = ($signed(A) < $signed(B)) ? 32'd0 : 32'd1; // BLT
            4'b1110: RES = ($signed(A) >= $signed(B)) ? 32'd0 : 32'd1; // BGE
            4'b1101: RES = (A < B) ? 32'd0 : 32'd1;    // BLTU
            4'b1111: RES = (A >= B) ? 32'd0 : 32'd1;   // BGEU
            
            default: RES = 32'b0;
        endcase
        zero = (RES == 32'b0); 
    end
endmodule
