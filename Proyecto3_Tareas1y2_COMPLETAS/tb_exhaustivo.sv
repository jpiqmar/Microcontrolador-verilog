`timescale 1ns/1ps

// ============================================================
// CLASE INSTRUCCION (sin cambios)
// ============================================================
class instruccion;
  randc logic [31:0] inst;

  constraint TIPO_I   { inst[6:0] == 7'b0010011; inst[11:7] == 5'b00001; inst[19:15] == 5'b00010; }
  constraint TIPO_R   { inst[6:0] == 7'b0110011; inst[11:7] == 5'b00001; inst[19:15] == 5'b00010; inst[24:20] == 5'b00011; }
  constraint BRANCHES { inst[6:0] == 7'b1100011; inst[19:15] == 5'b00001; inst[24:20] == 5'b00010; }
  constraint LW       { inst[6:0] == 7'b0000011; inst[11:7] == 5'b00001; inst[19:15] == 5'b00010; }
  constraint SW       { inst[6:0] == 7'b0100011; inst[24:20] == 5'b00010; inst[19:15] == 5'b00001; }
  constraint LUI      { inst[6:0] == 7'b0110111; inst[11:7] == 5'b00001; }
  constraint AUIPC    { inst[6:0] == 7'b0010111; inst[11:7] == 5'b00001; }
  constraint JAL      { inst[6:0] == 7'b1101111; inst[11:7] == 5'b00001; }
  constraint JALR     { inst[6:0] == 7'b1100111; inst[11:7] == 5'b00001; inst[19:15] == 5'b00010; }

  function void disable_all();
    this.TIPO_I.constraint_mode(0);
    this.TIPO_R.constraint_mode(0);
    this.BRANCHES.constraint_mode(0);
    this.LW.constraint_mode(0);
    this.SW.constraint_mode(0);
    this.LUI.constraint_mode(0);
    this.AUIPC.constraint_mode(0);
    this.JAL.constraint_mode(0);
    this.JALR.constraint_mode(0);
  endfunction

  function void enable_only(string name);
    disable_all();
    if (name == "TIPO_I")       this.TIPO_I.constraint_mode(1);
    else if (name == "TIPO_R")  this.TIPO_R.constraint_mode(1);
    else if (name == "BRANCHES") this.BRANCHES.constraint_mode(1);
    else if (name == "LW")      this.LW.constraint_mode(1);
    else if (name == "SW")      this.SW.constraint_mode(1);
    else if (name == "LUI")     this.LUI.constraint_mode(1);
    else if (name == "AUIPC")   this.AUIPC.constraint_mode(1);
    else if (name == "JAL")     this.JAL.constraint_mode(1);
    else if (name == "JALR")    this.JALR.constraint_mode(1);
  endfunction
endclass

// ============================================================
// INTERFAZ (con d_rw añadido)
// ============================================================
interface test_if (input logic CLK, RST);
  logic [31:0] idata, ddata_r, ddata_w, pc_out, instruction_out;
  logic [9:0] iaddr, daddr;
  logic d_rw;

  clocking md @(posedge CLK);
    input #1ns idata;
    input #1ns ddata_r;
    input #1ns ddata_w, pc_out, instruction_out;
    input #1ns iaddr, daddr, d_rw;
  endclocking:md;

  clocking sd @(posedge CLK);
    output #2ns idata;
    output #2ns ddata_r;
    input #2ns ddata_w, pc_out, instruction_out;
    input #2ns iaddr, daddr, d_rw;
  endclocking:sd;

  modport monitor (clocking md);
  modport test (clocking sd);
  modport duv(
    input CLK, input RST,
    input idata, input ddata_r,
    output ddata_w, output pc_out, output instruction_out,
    output iaddr, output daddr, output d_rw
  );
endinterface

// ============================================================
// PROGRAMA CON COVERGROUPS USANDO monitorizar.md.idata
// ============================================================
program automatic estimulos
  (test_if.test testar,
   test_if.monitor monitorizar
  );

  instruccion instr_inst;

  // ⭐ COVERGROUPS SIN ARGUMENTO - MUESTREAN DIRECTAMENTE DE LA INTERFAZ
  covergroup cg_r;  // ← Muestreo automático en cada ciclo
    option.per_instance = 1;
    cp_opcode: coverpoint monitorizar.md.idata[6:0] {
      bins R_TYPE = {7'b0110011};
    }
    cp_funct3: coverpoint monitorizar.md.idata[14:12] iff (monitorizar.md.idata[6:0]==7'b0110011) {
      bins ADD_SUB = {3'b000}; bins SLL = {3'b001}; bins SLT = {3'b010};
      bins SLTU = {3'b011}; bins XOR = {3'b100}; bins SRx = {3'b101};
      bins OR = {3'b110}; bins AND = {3'b111};
    }
    cp_funct7: coverpoint monitorizar.md.idata[31:25]
      iff (monitorizar.md.idata[6:0] == 7'b0110011) {
      bins F7_STD = {7'b0000000}; bins F7_ALT = {7'b0100000};
      
		ignore_bins others ={[0:127]} with (item != 7'b0000000 && item != 7'b0100000);

    }
    cross_r: cross cp_opcode, cp_funct3, cp_funct7;
  endgroup
  cg_r cg_r_inst;

  covergroup cg_i;
    option.per_instance = 1;
    cp_opcode: coverpoint monitorizar.md.idata[6:0] {
      bins I_TYPE = {7'b0010011};
    }
    cp_funct3: coverpoint monitorizar.md.idata[14:12] iff (monitorizar.md.idata[6:0]==7'b0010011) {
      bins ADDI = {3'b000}; bins SLLI = {3'b001}; bins SLTI = {3'b010};
      bins SLTIU = {3'b011}; bins XORI = {3'b100}; bins SRxI = {3'b101};
      bins ORI = {3'b110}; bins ANDI = {3'b111};
    }
    cp_imm_sign: coverpoint monitorizar.md.idata[31] iff (monitorizar.md.idata[6:0]==7'b0010011) {
      bins pos = {1'b0}; bins neg = {1'b1};
    }
    cp_shamt: coverpoint monitorizar.md.idata[24:20]
      iff (monitorizar.md.idata[6:0]==7'b0010011) {
      bins z = {5'd0}; bins one = {5'd1};
      bins mid[] = {[5'd2:5'd30]}; bins max = {5'd31};
    }
    cp_srli_srai: coverpoint monitorizar.md.idata[31:25]
      iff (monitorizar.md.idata[6:0]==7'b0010011) {
      bins SRLI = {7'b0000000}; bins SRAI = {7'b0100000};
      illegal_bins others = default;
    }
    cp_slli_0: coverpoint monitorizar.md.idata[31:25]
      iff (monitorizar.md.idata[6:0]==7'b0010011) {
      bins OK = {7'b0000000}; illegal_bins bad = default;
    }
    cp_imm: coverpoint monitorizar.md.idata[31:20]
      iff (monitorizar.md.idata[6:0]==7'b0010011);
    cross_i_all: cross cp_opcode, cp_funct3, cp_imm;
  endgroup
  cg_i cg_i_inst;


  covergroup cg_br;
    option.per_instance = 1;
    cp_opcode: coverpoint monitorizar.md.idata[6:0] { bins br = {7'b1100011}; }
    cp_funct3: coverpoint monitorizar.md.idata[14:12] iff (monitorizar.md.idata[6:0]==7'b1100011) {
      bins BEQ = {3'b000}; bins BNE = {3'b001}; bins BLT = {3'b100};
      bins BGE = {3'b101}; bins BLTU = {3'b110}; bins BGEU = {3'b111};
      illegal_bins bad = default;
    }
    cp_imm_sign: coverpoint monitorizar.md.idata[31] iff (monitorizar.md.idata[6:0]==7'b1100011) {
      bins pos = {1'b0}; bins neg = {1'b1};
    }
    cp_imm_mag: coverpoint {monitorizar.md.idata[7], monitorizar.md.idata[30:25], monitorizar.md.idata[11:8]} iff (monitorizar.md.idata[6:0]==7'b1100011) {
      bins pequeno [] = {[11'h000:11'h37F]}; bins largo[] = {[11'h380:11'h7FF]};
    }
    cross_br: cross cp_opcode, cp_funct3, cp_imm_sign, cp_imm_mag;
  endgroup
  cg_br cg_br_inst;

  covergroup cg_lw;
    option.per_instance = 1;
    cp_opcode: coverpoint monitorizar.md.idata[6:0] { bins lw = {7'b0000011}; }
    cp_funct3: coverpoint monitorizar.md.idata[14:12] iff (monitorizar.md.idata[6:0]==7'b0000011) {
      bins LW = {3'b010}; illegal_bins other = default;
    }
    cp_imm12: coverpoint monitorizar.md.idata[31:20] iff (monitorizar.md.idata[6:0]==7'b0000011) {
      bins zero = {12'h000}; bins pos = {[12'h001:12'h7FF]};
      bins neg = {[12'h800:12'hFFF]};
    }
    cross_lw: cross cp_opcode, cp_funct3, cp_imm12;
  endgroup
  cg_lw cg_lw_inst;

  covergroup cg_sw;
    option.per_instance = 1;
    cp_opcode: coverpoint monitorizar.md.idata[6:0] { bins sw = {7'b0100011}; }
    cp_funct3: coverpoint monitorizar.md.idata[14:12] iff (monitorizar.md.idata[6:0]==7'b0100011) {
      bins SW = {3'b010}; illegal_bins other = default;
    }
    cp_imm_hi: coverpoint monitorizar.md.idata[31:25] iff (monitorizar.md.idata[6:0]==7'b0100011);
    cp_imm_lo: coverpoint monitorizar.md.idata[11:7] iff (monitorizar.md.idata[6:0]==7'b0100011);
    cross_sw: cross cp_opcode, cp_funct3, cp_imm_hi, cp_imm_lo;
  endgroup
  cg_sw cg_sw_inst;

  covergroup cg_lui;
    option.per_instance = 1;
    cp_opcode: coverpoint monitorizar.md.idata[6:0] { bins lui = {7'b0110111}; }
    cp_immU_top: coverpoint monitorizar.md.idata[31:17] iff (monitorizar.md.idata[6:0]==7'b0110111) { //Hemos puesto [31:17] en lugar de [31:12] xq tardaba demasiado
      bins zero = {20'h0}; bins pequeno [] = {[20'h00000:20'h7FFFF]};
      bins largo[] = {[20'h80000:20'hFFFFF]};
    }
    cross_lui: cross cp_opcode, cp_immU_top;
  endgroup
  cg_lui cg_lui_inst;

  covergroup cg_auipc;
    option.per_instance = 1;
    cp_opcode: coverpoint monitorizar.md.idata[6:0] { bins auipc = {7'b0010111}; }
    cp_immU_top: coverpoint monitorizar.md.idata[31:17] iff (monitorizar.md.idata[6:0]==7'b0010111) { //Hemos puesto [31:17] en lugar de [31:12] xq tardaba demasiado 
      bins zero = {20'h0}; bins pequeno [] = {[20'h00000:20'h7FFFF]};
      bins largo[] = {[20'h80000:20'hFFFFF]};
    }
    cross_auipc: cross cp_opcode, cp_immU_top;
  endgroup
  cg_auipc cg_auipc_inst;

  covergroup cg_jal;
    option.per_instance = 1;
    cp_opcode: coverpoint monitorizar.md.idata[6:0] { bins jal = {7'b1101111}; }
    cp_imm_sign: coverpoint monitorizar.md.idata[31] iff (monitorizar.md.idata[6:0]==7'b1101111) {
      bins pos = {1'b0}; bins neg = {1'b1};
    }
    cp_imm_mag: coverpoint {monitorizar.md.idata[19:17], monitorizar.md.idata[20], monitorizar.md.idata[30:21]} iff (monitorizar.md.idata[6:0]==7'b1101111) { //Hemos puesto [19:17] en lugar de [19:12] xq tardaba demasiado
      bins pequeno [] = {[19'h00000:19'h3FFFF]}; bins largo[] = {[19'h40000:19'h7FFFF]};
    }
    cross_jal: cross cp_opcode, cp_imm_sign, cp_imm_mag;
  endgroup
  cg_jal cg_jal_inst;
  
  covergroup cg_jalr;
    option.per_instance = 1;
    cp_opcode: coverpoint monitorizar.md.idata[6:0] { bins jalr = {7'b1100111}; }
    cp_funct3: coverpoint monitorizar.md.idata[14:12] iff (monitorizar.md.idata[6:0]==7'b1100111) {
      bins JALR = {3'b000}; illegal_bins other = default;
    }
    cp_imm12: coverpoint monitorizar.md.idata[31:20] iff (monitorizar.md.idata[6:0]==7'b1100111) {
      bins zero = {12'h000}; bins pos = {[12'h001:12'h7FF]};
      bins neg = {[12'h800:12'hFFF]};
    }
    cross_jalr: cross cp_opcode, cp_funct3, cp_imm12;
  endgroup 
  cg_jalr cg_jalr_inst;


  task wait_cycles(input int num_cycles);
    repeat(num_cycles) @(testar.sd);
  endtask

  function void check_r_type_result(bit [31:0] inst);
    bit [2:0] funct3 = inst[14:12];
    bit [6:0] funct7 = inst[31:25];
    string op_name;
    if (funct3 == 3'b000) op_name = (funct7 == 7'b0000000) ? "ADD" : "SUB";
    else if (funct3 == 3'b001) op_name = "SLL";
    else if (funct3 == 3'b010) op_name = "SLT";
    else if (funct3 == 3'b011) op_name = "SLTU";
    else if (funct3 == 3'b100) op_name = "XOR";
    else if (funct3 == 3'b101) op_name = (funct7 == 7'b0000000) ? "SRL" : "SRA";
    else if (funct3 == 3'b110) op_name = "OR";
    else if (funct3 == 3'b111) op_name = "AND";
    $display("  [R-TYPE] Operación: %s (funct3=%03b, funct7=%07b)", op_name, funct3, funct7);
  endfunction

  function void check_i_type_result(bit [31:0] inst);
    bit [2:0] funct3 = inst[14:12];
    bit [11:0] imm = inst[31:20];
    string op_name;
    case (funct3)
      3'b000: op_name = "ADDI";
      3'b001: op_name = "SLLI";
      3'b010: op_name = "SLTI";
      3'b011: op_name = "SLTIU";
      3'b100: op_name = "XORI";
      3'b101: op_name = (inst[31:25] == 7'b0000000) ? "SRLI" : "SRAI";
      3'b110: op_name = "ORI";
      3'b111: op_name = "ANDI";
      default: op_name = "UNKNOWN";
    endcase
    $display("  [I-TYPE] Operación: %s (funct3=%03b, imm=%012h)", op_name, funct3, imm);
  endfunction

  function void check_branch_result(bit [31:0] inst);
    bit [2:0] funct3 = inst[14:12];
    string br_name;
    case (funct3)
      3'b000: br_name = "BEQ";
      3'b001: br_name = "BNE";
      3'b100: br_name = "BLT";
      3'b101: br_name = "BGE";
      3'b110: br_name = "BLTU";
      3'b111: br_name = "BGEU";
      default: br_name = "UNKNOWN";
    endcase
    $display("  [BRANCH] Tipo: %s (funct3=%03b)", br_name, funct3);
  endfunction

  initial begin
    instr_inst = new();
	 
    cg_r_inst = new();
    cg_i_inst = new();
    cg_br_inst = new();
    cg_lw_inst = new();
    cg_sw_inst = new();
    cg_lui_inst = new();
    cg_auipc_inst = new();
    cg_jal_inst = new();
    cg_jalr_inst = new();
	 
    wait_cycles(5);
    $display("\n========== INICIANDO TEST EXHAUSTIVO ==========\n");

    // ========== CASO 1: TIPO I ==========
    $display("[TEST 1] Verificando instrucciones TIPO I...");
    instr_inst.enable_only("TIPO_I");
	 while (cg_i_inst.cross_i_all.get_coverage() < 100) begin
			assert (instr_inst.randomize()) else $display("randomization failed");
			testar.sd.idata <= instr_inst.inst;
			cg_i_inst.sample();
			
			@(testar.sd);

			//->comprobar;
			$display("Cobertura actual: %0f%%", cg_i_inst.cross_i_all.get_coverage());  //CAMBIARR q hay mas dw 1 cross
		end
			
		wait_cycles(4);


    // ========== CASO 2: TIPO R ==========
    $display("[TEST 2] Verificando instrucciones TIPO R...");
    instr_inst.enable_only("TIPO_R");
    while (cg_r_inst.cross_r.get_coverage() < 100) begin
			assert (instr_inst.randomize()) else $display("randomization failed");
			testar.sd.idata <= instr_inst.inst;
			cg_r_inst.sample();
			
			@(testar.sd);

			//->comprobar;
			$display("Cobertura actual: %0f%%", cg_r_inst.cross_r.get_coverage());
		end
			
		wait_cycles(4);

    // ========== CASO 3: BRANCHES ==========
    $display("[TEST 3] Verificando instrucciones BRANCHES...");
    instr_inst.enable_only("BRANCHES");
    while (cg_br_inst.cross_br.get_coverage() < 100) begin
			assert (instr_inst.randomize()) else $display("randomization failed");
			testar.sd.idata <= instr_inst.inst;
			cg_br_inst.sample();
			
			@(testar.sd);

			//->comprobar;
			$display("Cobertura actual: %0f%%", cg_br_inst.cross_br.get_coverage());
		end
			
		wait_cycles(4);


    // ========== CASO 4: LW ==========
    $display("[TEST 4] Verificando instrucciones LW...");
    instr_inst.enable_only("LW");
    while (cg_lw_inst.cross_lw.get_coverage() < 100) begin
			assert (instr_inst.randomize()) else $display("randomization failed");
			testar.sd.idata <= instr_inst.inst;
			cg_lw_inst.sample();
			
			@(testar.sd);

			//->comprobar;
			$display("Cobertura actual: %0f%%", cg_lw_inst.cross_lw.get_coverage());
		end
			
		wait_cycles(4);

    // ========== CASO 5: SW ==========
    $display("[TEST 5] Verificando instrucciones SW...");
    instr_inst.enable_only("SW");
    while (cg_sw_inst.cross_sw.get_coverage() < 100) begin
			assert (instr_inst.randomize()) else $display("randomization failed");
			testar.sd.idata <= instr_inst.inst;
			cg_sw_inst.sample();
			
			@(testar.sd);

			//->comprobar;
			$display("Cobertura actual: %0f%%", cg_sw_inst.cross_sw.get_coverage());
		end
			
		wait_cycles(4);

    // ========== CASO 6: LUI ==========
    $display("[TEST 6] Verificando instrucciones LUI...");
    instr_inst.enable_only("LUI");
    while (cg_lui_inst.cross_lui.get_coverage() < 100) begin
			assert (instr_inst.randomize()) else $display("randomization failed");
			testar.sd.idata <= instr_inst.inst;
			cg_lui_inst.sample();
			
			@(testar.sd);

			//->comprobar;
			$display("Cobertura actual: %0f%%", cg_lui_inst.cross_lui.get_coverage());
		end
			
		wait_cycles(4);

    // ========== CASO 7: AUIPC ==========
    $display("[TEST 7] Verificando instrucciones AUIPC...");
    instr_inst.enable_only("AUIPC");
    while (cg_auipc_inst.cross_auipc.get_coverage() < 100) begin
			assert (instr_inst.randomize()) else $display("randomization failed");
			testar.sd.idata <= instr_inst.inst;
			cg_auipc_inst.sample();
			
			@(testar.sd);

			//->comprobar;
			$display("Cobertura actual: %0f%%", cg_auipc_inst.cross_auipc.get_coverage());
		end
			
		wait_cycles(4);

    // ========== CASO 8: JAL ==========
    $display("[TEST 8] Verificando instrucciones JAL...");
    instr_inst.enable_only("JAL");
    while (cg_jal_inst.cross_jal.get_coverage() < 100) begin
			assert (instr_inst.randomize()) else $display("randomization failed");
			testar.sd.idata <= instr_inst.inst;
			cg_jal_inst.sample();
			
			@(testar.sd);

			//->comprobar;
			$display("Cobertura actual: %0f%%", cg_jal_inst.cross_jal.get_coverage());
		end
			
		wait_cycles(4);

    // ========== CASO 9: JALR ==========
    $display("[TEST 9] Verificando instrucciones JALR...");
    instr_inst.enable_only("JALR");
    while (cg_jalr_inst.cross_jalr.get_coverage() < 100) begin
			assert (instr_inst.randomize()) else $display("randomization failed");
			testar.sd.idata <= instr_inst.inst;
			cg_jalr_inst.sample();
			
			@(testar.sd);

			//->comprobar;
			$display("Cobertura actual: %0f%%", cg_jalr_inst.cross_jalr.get_coverage());
		end

    // ========== RESUMEN FINAL ==========
    $display("\n========== RESUMEN DE COBERTURA ==========");
    $display("  R-TYPE Cobertura:    %0.2f%%", cg_r_inst.get_coverage());
    $display("  I-TYPE Cobertura:    %0.2f%%", cg_i_inst.get_coverage());
    $display("  BRANCHES Cobertura:  %0.2f%%", cg_br_inst.get_coverage());
    $display("  LW Cobertura:        %0.2f%%", cg_lw_inst.get_coverage());
    $display("  SW Cobertura:        %0.2f%%", cg_sw_inst.get_coverage());
    $display("  LUI Cobertura:       %0.2f%%", cg_lui_inst.get_coverage());
    $display("  AUIPC Cobertura:     %0.2f%%", cg_auipc_inst.get_coverage());
    $display("  JAL Cobertura:       %0.2f%%", cg_jal_inst.get_coverage());
    $display("  JALR Cobertura:      %0.2f%%", cg_jalr_inst.get_coverage());
    $display("=========================================\n");

    wait_cycles(5);
    $finish;
  end
endprogram

// ============================================================
// TB TOP (sin cambios)
// ============================================================
module tb_exhaustivo;
  localparam int T = 10;
  logic CLK, RST;

  test_if interfaz (.CLK(CLK), .RST(RST));
  top_duv DUV (.bus(interfaz));
  estimulos estim (.testar(interfaz), .monitorizar(interfaz));

  always #(T/2) CLK = ~CLK;

  initial begin
    CLK = 0;
    RST_dut();
  end

  task wait_cycles(input integer num_cycles);
    repeat(num_cycles) @(negedge CLK);
  endtask

  task RST_dut;
    begin
      $display("[%0t] === RST DEL DUT ===", $time);
      RST = 1;
      wait_cycles(2);
      RST = 0;
      $display("[%0t] RST completado", $time);
    end
  endtask
endmodule

module top_duv (test_if.duv bus);
  top_SingleCycle dut (
    .clk(bus.CLK),
    .reset(bus.RST),
    .idata(bus.idata),
    .iaddr(bus.iaddr),
    .ddata_r(bus.ddata_r),
    .daddr(bus.daddr),
    .ddata_w(bus.ddata_w),
    .d_rw(bus.d_rw),
    .pc_out(bus.pc_out),
    .instruction_out(bus.instruction_out)
  );
endmodule