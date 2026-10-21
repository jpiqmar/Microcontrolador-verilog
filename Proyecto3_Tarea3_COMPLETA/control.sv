
module control (
  input  logic [6:0] instruction, // opcode inst[6:0]
  output logic Branch, MemRead, MemtoReg, MemWrite, ALUSrc, RegWrite,
  output logic [2:0] ALUOp,
  output logic [1:0] AuipcLui,
  // + nuevas salidas:
  output logic Jump,
  output logic isJalr
);
  always_comb begin
    {Branch, MemRead, MemtoReg, MemWrite, ALUSrc, RegWrite} = 6'b0;
    ALUOp = 3'b000; AuipcLui = 2'b10; Jump = 1'b0; isJalr = 1'b0;
    case (instruction)
      7'b0110011: begin RegWrite = 1'b1; ALUOp = 3'b000; end // R
      7'b0010011: begin RegWrite = 1'b1; ALUSrc = 1'b1; ALUOp = 3'b100; end // I
      7'b0000011: begin RegWrite = 1'b1; MemRead = 1'b1; MemtoReg = 1'b1; ALUSrc = 1'b1; ALUOp = 3'b001; end // LW
      7'b0100011: begin MemWrite = 1'b1; ALUSrc = 1'b1; ALUOp = 3'b010; end // SW
      7'b1100011: begin Branch = 1'b1; ALUOp = 3'b011; end // Branches
      7'b0110111: begin RegWrite = 1'b1; ALUSrc = 1'b1; AuipcLui = 2'b01; ALUOp = 3'b101; end // LUI
      7'b0010111: begin RegWrite = 1'b1; ALUSrc = 1'b1; AuipcLui = 2'b00; ALUOp = 3'b110; end // AUIPC
      7'b1101111: begin RegWrite = 1'b1; Jump = 1'b1; ALUSrc = 1'b1; ALUOp = 3'b111; end // JAL
      7'b1100111: begin RegWrite = 1'b1; Jump = 1'b1; isJalr = 1'b1; ALUSrc = 1'b1; ALUOp = 3'b111; end // JALR
      default: ;
    endcase
  end
endmodule
