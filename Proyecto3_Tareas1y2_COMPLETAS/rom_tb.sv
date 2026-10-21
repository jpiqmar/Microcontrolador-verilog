
`timescale 1ns/1ns

module rom_tb;

  // Par�metros del DUT
  localparam int ADDR_WIDTH = 10;
  localparam int DATA_WIDTH = 32;
  localparam string MEM_FILE = "serie_fibonacci.txt"; // cambia aqu� si has renombrado el fichero

  // Se�ales TB
  logic [ADDR_WIDTH-1:0] addr;
  logic [DATA_WIDTH-1:0] data;

  // DUT: tu ROM exacta (asumo lectura combinacional y $readmemh en el interior)
  ROM #(
    .ADDR_WIDTH(ADDR_WIDTH),
    .DATA_WIDTH(DATA_WIDTH),
    .MEM_FILE(MEM_FILE)
  ) dut (
    .addr(addr),
    .data(data)
  );

  // Vector esperado (17 palabras: 0..16)
  logic [31:0] expected [0:16];

  // Inicializa el vector esperado seg�n tu fichero (todas 8 hex d�gitos = 32 bits)
  initial begin
    expected[0]  = 32'h01400093;
    expected[1]  = 32'h00100f13;
    expected[2]  = 32'h00000113;
    expected[3]  = 32'h00000213;
    expected[4]  = 32'h00222023;
    expected[5]  = 32'h00100193;
    expected[6]  = 32'h00420213;
    expected[7]  = 32'h00322023;
    expected[8]  = 32'h02008063;
    expected[9]  = 32'h41e080b3;
    expected[10] = 32'h003102b3;
    expected[11] = 32'h00300133;
    expected[12] = 32'h005001b3;
    expected[13] = 32'h00420213;
    expected[14] = 32'h00522023;
    expected[15] = 32'hfe0002e3;
    expected[16] = 32'h00000013;
  end

  // Est�mulos: barrer direcciones y verificar contenido
  initial begin
    $display("=== INICIO TB ROM ===");
    $display("[TB] Intentando cargar desde '%s' ...", MEM_FILE);

    // Espera breve para que $readmemh del DUT se ejecute
    // (si la ROM carga en un initial dentro del m�dulo)
    #1;

    // Recorrer las primeras 17 palabras (0..16)
    for (int i = 0; i < 17; i++) begin
      addr = i[ADDR_WIDTH-1:0];
      #1; // permitir que la lectura combinacional se estabilice

      // Mostrar lo le�do
      $display("ROM[%0d] = %h (esperado %h)", i, data, expected[i]);

      // Chequeos
      if (^data === 1'bX) begin
        $error("Dato en X en ROM[%0d]. Posible fallo en carga del fichero '%s' o addr no v�lida.", i, MEM_FILE);
        $fatal(1);
      end

      if (data !== expected[i]) begin
        $error("Mismatch en ROM[%0d]: le�do %h, esperado %h", i, data, expected[i]);
        $fatal(2);
      end
    end

    $display("=== FIN TB ROM (todo OK) ===");
    $stop;
  end

endmodule

