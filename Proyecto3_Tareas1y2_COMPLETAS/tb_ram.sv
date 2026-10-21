`timescale 1ns/1ns
module tb_ram;
    parameter T = 10;
    logic clk;
    logic MemWrite;
    logic [9:0] addr; // 10 bits para 1024 posiciones
    logic [31:0] write_data;
    logic [31:0] read_data;

    RAM dut (
        .clk(clk),
        .MemWrite(MemWrite),
        .addr(addr),
        .write_data(write_data),
        .read_data(read_data)
    );

    initial begin
	   clk = 1'b0;
	   forever #(T/2) clk = ~clk;
	 end

    initial begin
        clk = 0; MemWrite = 0;
        $display("=== TEST RAM ===");

        // Escritura en 3 posiciones
        addr = 0; write_data = 32'hAAAA_AAAA; MemWrite = 1; #(T*2) MemWrite = 0;
        addr = 4; write_data = 32'hBBBB_BBBB; MemWrite = 1; #(T*2) MemWrite = 0;
        addr = 8; write_data = 32'hCCCC_CCCC; MemWrite = 1; #(T*2) MemWrite = 0;

        // Lectura y verificación
        addr = 0; #(T) assert(read_data == 32'hAAAA_AAAA) else $error("Error en addr 0");
        addr = 4; #(T) assert(read_data == 32'hBBBB_BBBB) else $error("Error en addr 4");
        addr = 8; #(T) assert(read_data == 32'hCCCC_CCCC) else $error("Error en addr 8");

        $display("RAM OK");
        $stop;
    end
endmodule