module alu_control (
    input  logic [3:0] instruction, // Funct3 (código de función de la instrucción)
    input  logic [2:0] ALUOp,       // ALUOp (código de operación de la ALU)
    output logic [3:0] op           // Señal de control para la ALU
);

    always_comb begin
        case (ALUOp)
            // Para instrucciones tipo R (operaciones aritmético-lógicas)
            3'b000: begin
                case (instruction)
                    4'b0000: op = 4'b0000; // ADD
                    4'b1000: op = 4'b0001; // SUB
                    4'b0001: op = 4'b0101; // SLL
                    4'b0010: op = 4'b1000; // SLT
                    4'b0011: op = 4'b1001; // SLTU
                    4'b0100: op = 4'b0100; // XOR
                    4'b0101: op = 4'b0110; // SRL
                    4'b1101: op = 4'b0111; // SRA
						  4'b0110: op = 4'b0011; // OR
                    4'b0111: op = 4'b0010; // AND
                    default: op = 4'b0000; // Default case: ADD
                endcase
            end

            // Para instrucciones tipo I (inmediato)
            3'b100: begin
                case (instruction)
                    4'b0000: op = 4'b0000; // ADDI
						  4'b0001: op = 4'b0101; // SLLI
                    4'b0010: op = 4'b1000; // SLTI
                    4'b0011: op = 4'b1001; // SLTIU
						  4'b0100: op = 4'b0100; // XORI
						  4'b0101: op = 4'b0110; // SRLI
						  4'b1101: op = 4'b0111; // SRAI
						  4'b0110: op = 4'b0011; // ORI
                    4'b0111: op = 4'b0010; // ANDI
                    default: op = 4'b0000; // Default case: ADDI
                endcase
            end

            // Para instrucciones tipo B (branching)
            3'b011: begin
                case (instruction)
                    4'b0000: op = 4'b1010; // BEQ
                    4'b0001: op = 4'b1011; // BNE
                    4'b0100: op = 4'b1100; // BLT
                    4'b0101: op = 4'b1110; // BGE
						  4'b0110: op = 4'b1101; // BLTU
                    4'b0111: op = 4'b1111; // BGEU
                    default: op = 4'b0000; // Default: No operation
                endcase
            end

            // Para instrucciones tipo U (LUI, AUIPC)
            3'b101: op = 4'b0000;  // LUI
            3'b110: op = 4'b0000; // AUIPC
				3'b111: op = 4'b0010; // JAL,JALR

            // Caso por defecto (instrucción no válida)
            default: op = 4'b0000; // No operation
        endcase
    end

endmodule
