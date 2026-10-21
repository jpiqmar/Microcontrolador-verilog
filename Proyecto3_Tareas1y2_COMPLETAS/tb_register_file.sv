`timescale 1ns/1ns
module tb_register_file;
    parameter T = 10;
    logic clk;
    logic [4:0] read_reg1, read_reg2, write_reg;
    logic [31:0] write_data;
    logic reg_write;
    logic [31:0] read_data1, read_data2;

    // Instancia del DUT
    register dut (
        .clk(clk), 
        .rs1(read_reg1), 
		  .rs2(read_reg2),
        .rd(write_reg), 
		  .write_data(write_data),
        .RegWrite(reg_write),
        .read_data1(read_data1), 
		  .read_data2(read_data2)
    );

    initial begin
	   clk = 1'b0;
	   forever #(T/2) clk = ~clk;
	 end

    initial begin
        clk = 0; reg_write = 0;

        $display("=== TEST BANCO DE REGISTROS ===");

        // Test 1: Escritura en posición 0
        write_reg = 0; write_data = 32'hAAAA_AAAA; reg_write = 1;
        #(T*2) reg_write = 0;
        read_reg1 = 0;
        #(T) assert(read_data1 == 32'h0000_0000) else $error("Error en posición 0");

        // Test 2: Escritura en 3 posiciones
        write_reg = 1; write_data = 32'h1111_1111; reg_write = 1; #(T) reg_write = 0;
        write_reg = 2; write_data = 32'h2222_2222; reg_write = 1; #(T) reg_write = 0;
        write_reg = 3; write_data = 32'h3333_3333; reg_write = 1; #(T) reg_write = 0;

        // Lectura y verificación
        read_reg1 = 1; read_reg2 = 2;
        #(T) assert(read_data1 == 32'h1111_1111 && read_data2 == 32'h2222_2222)
            else $error("Error en lectura múltiple");

        $display("Banco de registros OK");
	$stop;
    end
endmodule