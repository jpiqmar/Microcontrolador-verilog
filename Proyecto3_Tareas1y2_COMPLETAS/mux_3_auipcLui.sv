module mux_3_auipcLui(
	input logic [31:0] pc_out,
	input logic [31:0] read_data1,
	input logic [1:0] AuipcLui, //entrada de seleccion del mux
	output logic [31:0] salida //salida del mux
);

always_comb begin 
	case (AuipcLui)
		2'd0 : salida = pc_out;
		2'd1 : salida = 32'b0;
		2'd2 : salida = read_data1;
		default : salida = 32'b0;
		
	endcase
	
end

endmodule
	