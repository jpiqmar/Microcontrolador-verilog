//Proyecto 3. Partes 1 y 2:
//Integrantes:
//Jorge Lopez Martorell
//Marc Zaragoza García
//Mónica Blazquez Femenía
//Jaime Piqueras Marsal
//Paula García Badenas
//Gonzalo López de Villata Hernández

module top_SingleCycle (
    input  logic        clk,
    input  logic        reset,

    // ROM (instruction memory)
    input  logic [31:0] idata,         // instrucción leída desde la ROM/IMEM
    output logic [9:0] iaddr,         // dirección enviada a la ROM/IMEM

    // RAM (data memory)
    input  logic [31:0] ddata_r,       // datos leídos desde la RAM/DMEM
    output logic [9:0] daddr,         // dirección enviada a la RAM/DMEM
    output logic [31:0] ddata_w,       // datos a escribir en la RAM/DMEM
    output logic        d_rw,          // write enable (1=escribir) — ojo lectura

    // Observabilidad
    output logic [31:0] pc_out,
    output logic [31:0] instruction_out
);

    // -------- Señales internas
    logic [31:0] pc;
    logic [31:0] instruction;

    logic [31:0] read_data1, read_data2;
    logic [31:0] write_data;
    logic [31:0] A, B;
    logic [31:0] ALU_result;
    logic        zero;
    logic [3:0]  op;      
    logic        Branch, MemRead, MemtoReg, MemWrite, ALUSrc, RegWrite;
    logic [2:0]  ALUOp;
    logic [1:0]  AuipcLui;
    logic [31:0] salida_ins;
    logic [31:0] Sum;

    // -------- PC registro
    assign Sum = pc + salida_ins;

    always_ff @(posedge clk or posedge reset) begin
        if (reset)
            pc <= 32'b0;
        else if (Branch && zero)
				if (instruction[6:0]==7'b1100111) //JALR
						pc = read_data1 + salida_ins;
				else
						pc <= Sum;
        else
            pc <= pc + 32'd4;
    end

    assign pc_out = pc;

    // -------- Fetch
    assign iaddr       = pc[11:2];
    assign instruction = idata;
    assign instruction_out = instruction;

    // -------- Inmediato
    InmGen inmgen_inst (
        .entrada_ins(instruction),
        .salida_ins(salida_ins)
    );

    // -------- Regfile
    register register_inst (
        .clk(clk),
        .RegWrite(RegWrite),
        .rs1(instruction[19:15]),
        .rs2(instruction[24:20]),
        .rd (instruction[11:7]),
        .write_data(write_data),
        .read_data1(read_data1),
        .read_data2(read_data2)
    );

    // -------- Mux A (AUIPC/LUI/rs1)
    mux_3_auipcLui mux_3_auipcLui_inst (
        .pc_out(pc),                 // usa pc directo
        .read_data1(read_data1),
        .AuipcLui(AuipcLui),
        .salida(A)
    );

    // -------- Mux B (rs2/inmediato)
    mux_2_aluSrc mux_2_aluSrc_inst (
        .read_data2(read_data2),
        .InmGen(salida_ins),
        .AluSrc(ALUSrc),
        .salida(B)
    );

    // -------- ALU
    alu alu_inst (
        .A(A),
        .B(B),
        .op(op),
        .RES(ALU_result),
        .zero(zero)
    );

    // -------- Control principal
    control control_inst (
        .instruction(instruction[6:0]),
        .Branch(Branch),
        .MemRead(MemRead),
        .MemtoReg(MemtoReg),
        .MemWrite(MemWrite),
        .ALUSrc(ALUSrc),
        .RegWrite(RegWrite),
        .ALUOp(ALUOp),
        .AuipcLui(AuipcLui)
    );

    // -------- ALU control
    alu_control alu_control_inst (
        .instruction({instruction[30], instruction[14:12]}),
        .ALUOp(ALUOp),
        .op(op)
    );


    // -------- DMEM
    assign daddr   = ALU_result[11:2];
    assign ddata_w = read_data2;
    assign d_rw    = MemWrite;

    // -------- Escritura
    always_comb begin
        if (MemtoReg)
				if (instruction[6:0]==7'b1101111 || instruction[6:0]==7'b1100111) //JAL y JALR
						write_data = pc + 32'd4;
					else
						write_data = ddata_r; 
        else
				write_data = ALU_result;
    end

endmodule
