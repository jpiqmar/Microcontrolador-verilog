module register(
    input  logic         clk,
    input  logic         RegWrite,
    input  logic [4:0]   rs1,
    input  logic [4:0]   rs2,
    input  logic [4:0]   rd,
    input  logic [31:0]  write_data,
    output logic [31:0]  read_data1,
    output logic [31:0]  read_data2
);

    // Banco de 32 registros de 32 bits
    logic [31:0] registers [31:0];

    initial begin
	for(int i = 0; i < 32; i = i+1) begin
		registers[i] = 32'b0;
	end
    end


    // Lectura asíncrona
    assign read_data1 = (rs1 == 5'd0) ? 32'd0 : registers[rs1];
    assign read_data2 = (rs2 == 5'd0) ? 32'd0 : registers[rs2];

    // Escritura síncrona
    always @(posedge clk) begin
        if (RegWrite && rd != 5'd0) begin
            registers[rd] <= write_data;
        end
    end

endmodule





