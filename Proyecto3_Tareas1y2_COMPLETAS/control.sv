module control (
    input  logic [6:0] instruction,
    output logic       Branch,
    output logic       MemRead,
    output logic       MemtoReg,
    output logic       MemWrite,
    output logic       ALUSrc,
    output logic       RegWrite,
    output logic [2:0] ALUOp,    
    output logic [1:0] AuipcLui
);

    always_comb begin
        // Defaults (evita latches)
        Branch   = 1'b0;
        MemRead  = 1'b0;
        MemtoReg = 1'b0;
        MemWrite = 1'b0;
        ALUSrc   = 1'b0;
        RegWrite = 1'b0;
        ALUOp    = 3'b000;
        AuipcLui = 2'b00;

        unique case (instruction)
            // R-type 
            7'b0110011: begin
                RegWrite = 1'b1;
                AuipcLui   = 2'b10;
                ALUOp    = 3'b000;
            end

            // I-type
            7'b0010011: begin
                RegWrite = 1'b1;
                ALUSrc   = 1'b1;
                ALUOp    = 3'b100;
					 AuipcLui   = 2'b10;
            end

            // Load
            7'b0000011: begin
                RegWrite = 1'b1;
                MemRead  = 1'b1;
                MemtoReg = 1'b1;
                ALUSrc   = 1'b1;
                ALUOp    = 3'b001;
					 AuipcLui   = 2'b10;
            end

            // Store
            7'b0100011: begin
                MemWrite = 1'b1;
                ALUSrc   = 1'b1;
                ALUOp    = 3'b010;
					 AuipcLui   = 2'b10;
            end

            // Branch
            7'b1100011: begin
                Branch = 1'b1;
                AuipcLui   = 2'b10;
                ALUOp  = 3'b011; 
            end


            // LUI
            7'b0110111: begin
                RegWrite = 1'b1;
					 ALUSrc = 1'b1;
                AuipcLui = 2'b01;
                ALUOp    = 3'b101;
            end

            // AUIPC
            7'b0010111: begin
                RegWrite = 1'b1;
                AuipcLui = 2'b00;
                ALUSrc   = 1'b1;
                ALUOp    = 3'b110;
            end
				//JAL
				7'b1101111: begin
					 MemtoReg = 1'b1;
					 RegWrite = 1'b1;
                Branch = 1'b1;
                AuipcLui   = 2'b01;
                ALUOp  = 3'b111;
            end
				//JALR
				7'b1100111: begin
                Branch = 1'b1;
                AuipcLui   = 2'b01;
                ALUOp  = 3'b111;
					 MemtoReg = 1'b1;
					 RegWrite = 1'b1;
            end

            default: begin
                // defaults ya cubren
            end
        endcase
    end

endmodule

