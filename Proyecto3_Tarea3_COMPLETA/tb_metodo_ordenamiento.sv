
`timescale 1ns/1ns

module tb_metodo_ordenamiento();

    parameter T = 10;
	 parameter MEM_FILE = "metodo_ordenamiento.txt";

    logic CLK, RST;
    logic [31:0] instruction;
    logic [9:0] PC, RAM_address;
    logic [31:0] data_out, data_in;
    logic mem_write;

    ROM #(.MEM_FILE(MEM_FILE)) memoriaROM (PC, instruction);
    RAM memoriaRAM (CLK, mem_write, RAM_address, data_in, data_out);

    top_SingleCycle top(
        .clk(CLK),
        .reset(RST),
        .idata(instruction),
        .ddata_w(data_in),
        .iaddr(PC),
        .daddr(RAM_address),
        .ddata_r(data_out),
        .d_rw(mem_write),
		  .pc_out(),
		  .instruction_out()
    );

    
	 initial begin
	   CLK = 1'b0;
	   forever #(T/2) CLK = ~CLK;
	 end

	
	 initial begin
        
		  $display("=== INICIO SIMULACIÓN ===");
        RST = 1;
        #(T*2);
        RST = 0;
        $display("Reset desactivado, comienza ejecución...");

        repeat (500) @(posedge CLK);

        $display("=== RESULTADOS EN RAM ===");
        for (int i = 0; i < 8; i++) begin
            $display("RAM[%0d] = %0d", i, memoriaRAM.memoria[i]);
        end

        $stop;

    end
	 
endmodule
