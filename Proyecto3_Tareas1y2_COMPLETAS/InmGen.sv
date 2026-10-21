module InmGen(
	input logic [31:0] entrada_ins,
	output logic [31:0] salida_ins
);

always_comb begin
	
	case (entrada_ins[6:0])
	  // I-format: ADDI, LW, JALR
	  7'b0010011,           // I (ADDI, SLTI, …)
	  7'b0000011,           // LW 
	  7'b1100111:           // JALR
		 salida_ins = {{20{entrada_ins[31]}}, entrada_ins[31:20]}; // I-format

	  // S-format: Store
	  7'b0100011:
		 salida_ins = {{20{entrada_ins[31]}}, entrada_ins[31:25], entrada_ins[11:7]}; // S-format

	  // B-format: Branch
	  7'b1100011:
		 salida_ins = {{20{entrada_ins[31]}}, entrada_ins[7], entrada_ins[30:25], entrada_ins[11:8], 1'b0}; // B-format

	  // U-format: LUI, AUIPC
	  7'b0010111, 7'b0110111:
		 salida_ins = {entrada_ins[31:12], 12'b0}; // U-format

	  // J-format: JAL únicamente
	  7'b1101111:
		 salida_ins = {{12{entrada_ins[31]}}, entrada_ins[19:12], entrada_ins[20], entrada_ins[30:21], 1'b0}; // J-format

	  default:
			 salida_ins = 32'b0;
						
	endcase
end

endmodule
