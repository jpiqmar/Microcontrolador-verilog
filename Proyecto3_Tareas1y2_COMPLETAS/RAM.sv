module RAM
#(
    parameter ADDR_WIDTH = 10,        // 1024 posiciones
    parameter DATA_WIDTH = 32
)
(
    input  wire                    clk,
    input  wire                    MemWrite,  // señal de escritura
    input  wire [ADDR_WIDTH-1:0]   addr,      // dirección de palabra
    input  wire [DATA_WIDTH-1:0]   write_data,
    output wire [DATA_WIDTH-1:0]   read_data
);

    // Memoria
    reg [DATA_WIDTH-1:0] memoria [0:(2**ADDR_WIDTH)-1];

    initial begin
	for(int i = 0; i < 1024; i = i+1) begin
		memoria[i] = 32'b0;
	end
    end

    // Escritura síncrona
    always @(posedge clk) begin
        if (MemWrite) begin
            memoria[addr] <= write_data;
        end
    end

    // Lectura asíncrona
    assign read_data = memoria[addr];


    

endmodule



