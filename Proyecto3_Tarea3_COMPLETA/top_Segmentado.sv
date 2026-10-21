
module top_Segmentado (
  input  logic        clk,
  input  logic        reset,

  // Instruction memory
  input  logic [31:0] idata,
  output logic [9:0]  iaddr,        // palabra: pc[11:2]

  // Data memory
  input  logic [31:0] ddata_r,
  output logic [9:0]  daddr,        // palabra: alu_res[11:2]
  output logic [31:0] ddata_w,
  output logic        d_rw,         // 1: write

  // Debug
  output logic [31:0] pc_out,
  output logic [31:0] instruction_out
);

  // -------- Señales internas --------
  logic [31:0] pc, next_pc, pc_plus_4;
  logic [31:0] instruction;
  logic [31:0] read_data1, read_data2, write_data, salida_ins;

  // ALU / EX
  logic [31:0] A_alu, B_alu, ALU_result;
  logic [31:0] branch_target_ex, jump_target_ex;
  logic [31:0] fwd_rs1, fwd_rs2;
  logic        zero;
  logic [3:0]  alu_op_wire;

  // Control
  logic Branch, MemRead, MemtoReg, MemWrite, ALUSrc, RegWrite;
  logic [2:0] ALUOp;
  logic [1:0] AuipcLui;

  // NUEVO para jumps
  logic Jump, isJalr;

  // Forwarding
  logic [1:0] ForwardA, ForwardB;

  // Stalls/flush
  logic stall_pc, stall_if_id, sel_stall_control;
  logic PCSrc_branch, Flush;

  // -------- Registros de segmentación --------
  // IF/ID
  logic [31:0] IF_ID_pc, IF_ID_instruction;

  // ID/EX
  logic [31:0] ID_EX_pc, ID_EX_read_data1, ID_EX_read_data2, ID_EX_salida_ins;
  logic [4:0]  ID_EX_rd, ID_EX_rs1, ID_EX_rs2;
  logic [3:0]  ID_EX_funct_bits;
  logic        ID_EX_Branch, ID_EX_MemRead, ID_EX_MemWrite, ID_EX_MemtoReg;
  logic        ID_EX_RegWrite, ID_EX_ALUSrc;
  logic [2:0]  ID_EX_ALUOp;
  logic [1:0]  ID_EX_AuipcLui;

  // NUEVO: control de saltos en pipe
  logic        ID_EX_Jump, ID_EX_isJalr;

  // EX/MEM
  logic [31:0] EX_MEM_ALU_result, EX_MEM_read_data2;
  logic [4:0]  EX_MEM_rd;
  logic        EX_MEM_MemWrite, EX_MEM_MemtoReg, EX_MEM_RegWrite;

  // NUEVO: info para writeback de JAL/JALR
  logic [31:0] EX_MEM_link_addr;
  logic        EX_MEM_Jump;

  // MEM/WB
  logic [31:0] MEM_WB_ALU_result, MEM_WB_read_data_mem;
  logic [4:0]  MEM_WB_rd;
  logic        MEM_WB_MemtoReg, MEM_WB_RegWrite;

  // NUEVO: propagate link/jump a WB
  logic [31:0] MEM_WB_link_addr;
  logic        MEM_WB_Jump;

  /* ===================== IF ===================== */
  assign pc_plus_4    = pc + 32'd4;
  assign PCSrc_branch = (ID_EX_Branch && zero);

  // Flush si hay branch tomado o jump (sincrono en los registros IF/ID, ID/EX, EX/MEM)
  assign Flush = (PCSrc_branch || ID_EX_Jump);

  // Destinos
  assign branch_target_ex = ID_EX_pc + ID_EX_salida_ins;

  // Dirección de instrucción (palabra)
  assign iaddr = pc[11:2];

  // --------- PC con reset asíncrono (único lugar con reset en sensibilidad) ---------
  // <-- Esto evita el error 10200 de Quartus
  always_ff @(posedge clk or posedge reset) begin
    if (reset)            pc <= 32'b0;
    else if (!stall_pc)   pc <= next_pc;
  end

  // Mux del siguiente PC
  // Jump tiene prioridad sobre pc+4; branch tomado sobre ambos
  // jump_target_ex se define en EX (más abajo)
  assign next_pc = PCSrc_branch ? branch_target_ex
                  : (ID_EX_Jump ? jump_target_ex
                                : pc_plus_4);

  // IF/ID (reset y flush sincronos)
  always_ff @(posedge clk) begin
    if (reset) begin
      IF_ID_instruction <= 32'h0000_0013; // NOP
      IF_ID_pc          <= 32'b0;
    end else if (Flush) begin
      IF_ID_instruction <= 32'h0000_0013; // NOP al tomar branch/jump
      IF_ID_pc          <= 32'b0;
    end else if (!stall_if_id) begin
      IF_ID_pc          <= pc;
      IF_ID_instruction <= idata;
    end
  end

  /* ===================== ID ===================== */
  always_comb
  instruction = IF_ID_instruction;

  hazard_detection hazard_unit (
    .ID_EX_rd          (ID_EX_rd),
    .IF_ID_rs1         (instruction[19:15]),
    .IF_ID_rs2         (instruction[24:20]),
    .ID_EX_MemRead     (ID_EX_MemRead),
    .stall_pc          (stall_pc),
    .stall_if_id       (stall_if_id),
    .sel_stall_control (sel_stall_control)
  );

  register register_inst (
    .clk        (clk),
    .RegWrite   (MEM_WB_RegWrite),
    .rs1        (instruction[19:15]),
    .rs2        (instruction[24:20]),
    .rd         (MEM_WB_rd),
    .write_data (write_data),
    .read_data1 (read_data1),
    .read_data2 (read_data2)
  );

  InmGen inmgen_inst (.entrada_ins(instruction), .salida_ins(salida_ins));

  // **** CONTROL actualizado: debe exponer Jump e isJalr ****
  control control_inst (
    .instruction (instruction[6:0]),
    .Branch      (Branch),
    .MemRead     (MemRead),
    .MemtoReg    (MemtoReg),
    .MemWrite    (MemWrite),
    .ALUSrc      (ALUSrc),
    .RegWrite    (RegWrite),
    .ALUOp       (ALUOp),
    .AuipcLui    (AuipcLui),
    .Jump        (Jump),     // NUEVO
    .isJalr      (isJalr)    // NUEVO
  );

  // ID/EX (reset/flush/burbuja sincronos)
  always_ff @(posedge clk) begin
    if (reset || Flush || sel_stall_control) begin
      {ID_EX_Branch, ID_EX_MemRead, ID_EX_MemWrite, ID_EX_MemtoReg,
       ID_EX_RegWrite, ID_EX_ALUSrc, ID_EX_ALUOp, ID_EX_AuipcLui} <= '0;
      ID_EX_rd           <= 5'b0;
      ID_EX_Jump         <= 1'b0; // NUEVO
      ID_EX_isJalr       <= 1'b0; // NUEVO

      ID_EX_pc           <= 32'b0;
      ID_EX_read_data1   <= 32'b0;
      ID_EX_read_data2   <= 32'b0;
      ID_EX_salida_ins   <= 32'b0;
      ID_EX_rs1          <= 5'b0;
      ID_EX_rs2          <= 5'b0;
      ID_EX_funct_bits   <= 4'b0;
    end else begin
      ID_EX_pc           <= IF_ID_pc;
      ID_EX_read_data1   <= read_data1;
      ID_EX_read_data2   <= read_data2;
      ID_EX_salida_ins   <= salida_ins;
      ID_EX_rd           <= instruction[11:7];
      ID_EX_rs1          <= instruction[19:15];
      ID_EX_rs2          <= instruction[24:20];
      ID_EX_funct_bits   <= {instruction[30], instruction[14:12]};
      {ID_EX_Branch, ID_EX_MemRead, ID_EX_MemWrite, ID_EX_MemtoReg,
       ID_EX_RegWrite, ID_EX_ALUSrc, ID_EX_ALUOp, ID_EX_AuipcLui} <=
      {Branch,     MemRead,     MemWrite,     MemtoReg,
       RegWrite,   ALUSrc,      ALUOp,        AuipcLui};
      ID_EX_Jump   <= Jump;     // NUEVO
      ID_EX_isJalr <= isJalr;   // NUEVO
    end
  end

  /* ===================== EX ===================== */
  // Forwarding: prioridad MEM > WB
  always_comb begin
    if (EX_MEM_RegWrite && (EX_MEM_rd != 0) && (EX_MEM_rd == ID_EX_rs1)) ForwardA = 2'b10;
    else if (MEM_WB_RegWrite && (MEM_WB_rd != 0) && (MEM_WB_rd == ID_EX_rs1)) ForwardA = 2'b01;
    else ForwardA = 2'b00;

    if (EX_MEM_RegWrite && (EX_MEM_rd != 0) && (EX_MEM_rd == ID_EX_rs2)) ForwardB = 2'b10;
    else if (MEM_WB_RegWrite && (MEM_WB_rd != 0) && (MEM_WB_rd == ID_EX_rs2)) ForwardB = 2'b01;
    else ForwardB = 2'b00;
  end

  // Entradas ALU (AUIPC/LUI usan A=pc o 0)
  assign A_alu = (ID_EX_AuipcLui == 2'b00) ? ID_EX_pc :
                 (ID_EX_AuipcLui == 2'b01) ? 32'b0 :
                 (ForwardA == 2'b10) ? EX_MEM_ALU_result :
                 (ForwardA == 2'b01) ? write_data      : ID_EX_read_data1;

  assign B_alu = ID_EX_ALUSrc ? ID_EX_salida_ins :
                 (ForwardB == 2'b10) ? EX_MEM_ALU_result :
                 (ForwardB == 2'b01) ? write_data      : ID_EX_read_data2;

  // Para JALR necesitamos rs1 con forwarding (fwd_rs1)
  always_comb begin
    unique case (ForwardA)
      2'b10: fwd_rs1 = EX_MEM_ALU_result;
      2'b01: fwd_rs1 = write_data;
      default: fwd_rs1 = ID_EX_read_data1;
    endcase
    unique case (ForwardB)
      2'b10: fwd_rs2 = EX_MEM_ALU_result;
      2'b01: fwd_rs2 = write_data;
      default: fwd_rs2 = ID_EX_read_data2;
    endcase
  end

  // Control de la ALU
  alu_control alu_ctrl_inst (.instruction(ID_EX_funct_bits), .ALUOp(ID_EX_ALUOp), .op(alu_op_wire));
  alu         alu_inst      (.A(A_alu), .B(B_alu), .op(alu_op_wire), .RES(ALU_result), .zero(zero));

  // Destino de JUMP: JAL -> pc+imm ; JALR -> (rs1+imm) con bit0=0
  assign jump_target_ex = ID_EX_isJalr
                        ? ((fwd_rs1 + ID_EX_salida_ins) & 32'hFFFF_FFFE)
                        : (ID_EX_pc + ID_EX_salida_ins);
  
	// EX/MEM (reset sincrono))
	always_ff @(posedge clk) begin
	  if (reset) begin
		 {EX_MEM_RegWrite, EX_MEM_MemWrite, EX_MEM_MemtoReg} <= '0;
		 EX_MEM_rd        <= 5'b0;
		 EX_MEM_Jump      <= 1'b0;
		 EX_MEM_link_addr <= 32'b0;
		 EX_MEM_ALU_result<= 32'b0;
		 EX_MEM_read_data2<= 32'b0;
	  end else begin
		 EX_MEM_ALU_result <= ALU_result;
		 // dato para SW (con forwarding)
		 EX_MEM_read_data2 <= (ForwardB == 2'b10) ? EX_MEM_ALU_result :
									 (ForwardB == 2'b01) ? write_data : ID_EX_read_data2;
		 EX_MEM_rd         <= ID_EX_rd;
		 EX_MEM_MemWrite   <= ID_EX_MemWrite;
		 EX_MEM_MemtoReg   <= ID_EX_MemtoReg;
		 EX_MEM_RegWrite   <= ID_EX_RegWrite;

		 // Info de JAL/JALR
		 EX_MEM_Jump       <= ID_EX_Jump;
		 EX_MEM_link_addr  <= ID_EX_pc + 32'd4; // rd = pc+4
	  end
	end


  /* ===================== MEM & WB ===================== */
  assign daddr   = EX_MEM_ALU_result[11:2];
  assign ddata_w = EX_MEM_read_data2;
  assign d_rw    = EX_MEM_MemWrite;

  always_ff @(posedge clk) begin
    if (reset) begin
      MEM_WB_ALU_result    <= 32'b0;
      MEM_WB_read_data_mem <= 32'b0;
      MEM_WB_rd            <= 5'b0;
      MEM_WB_MemtoReg      <= 1'b0;
      MEM_WB_RegWrite      <= 1'b0;
      MEM_WB_Jump          <= 1'b0;
      MEM_WB_link_addr     <= 32'b0;
    end else begin
      MEM_WB_ALU_result    <= EX_MEM_ALU_result;
      MEM_WB_read_data_mem <= ddata_r;
      MEM_WB_rd            <= EX_MEM_rd;
      MEM_WB_MemtoReg      <= EX_MEM_MemtoReg;
      MEM_WB_RegWrite      <= EX_MEM_RegWrite;
      MEM_WB_Jump          <= EX_MEM_Jump;      // NUEVO
      MEM_WB_link_addr     <= EX_MEM_link_addr; // NUEVO
    end
  end

  // Writeback: si es JAL/JALR, escribir pc+4
  assign write_data = MEM_WB_Jump ? MEM_WB_link_addr
                     : (MEM_WB_MemtoReg ? MEM_WB_read_data_mem
                                        : MEM_WB_ALU_result);

  // Debug
  assign pc_out          = pc;
  assign instruction_out = idata;

endmodule
