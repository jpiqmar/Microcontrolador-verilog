module ROM
#(
    parameter ADDR_WIDTH = 10,        // 2^10 = 1024 posiciones
    parameter DATA_WIDTH = 32,
    parameter MEM_FILE   = "serie_fibonachi.txt"
)
(
    input  logic [ADDR_WIDTH-1:0] addr,  // Dirección de palabra (no de byte)
    output logic  [DATA_WIDTH-1:0] data   // Instrucción leída
);

    // Memoria
    reg [DATA_WIDTH-1:0] memoria [0:(1<<ADDR_WIDTH)-1]; //definimos el tamaño de las direcciones (DATA_WIDTH) y el numero d direcciones 

    // Inicialización desde fichero
    initial begin
        // Usa readmemh si el fichero está en binario
		  $readmemh(MEM_FILE, memoria);
    end

    // Lectura asíncrona
    assign data = memoria[addr];

endmodule

