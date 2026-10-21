module mux_2_aluSrc(
	input logic [31:0] read_data2,
	input logic [31:0] InmGen,
	input logic  AluSrc, //entrada de seleccion del mux
	output logic [31:0] salida //salida del mux
);

always_comb begin 
	case (AluSrc)
		1'd0 : salida = read_data2;
		1'd1 : salida = InmGen;
		default : salida = 32'b0;
		
	endcase
	
end

endmodule