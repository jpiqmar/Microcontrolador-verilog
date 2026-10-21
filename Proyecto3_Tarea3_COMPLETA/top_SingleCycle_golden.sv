//Proyecto 3. Partes 1 y 2:
//Integrantes:
//Jorge Lopez Martorell
//Marc Zaragoza García
//Mónica Blazquez Femenía
//Jaime Piqueras Marsal
//Paula García Badenas
//Gonzalo López de Villata Hernández

module top_SingleCycle_golden (
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
    control_golden control_inst (
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
    alu_control_golden alu_control_inst (
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
 

 

module alu_control_golden (
    input  logic [3:0] instruction, // Funct3 (código de función de la instrucción)
    input  logic [2:0] ALUOp,       // ALUOp (código de operación de la ALU)
    output logic [3:0] op           // Señal de control para la ALU
);

    always_comb begin
        case (ALUOp)
            // Para instrucciones tipo R (operaciones aritmético-lógicas)
            3'b000: begin
                case (instruction)
                    4'b0000: op = 4'b0000; // ADD
                    4'b1000: op = 4'b0001; // SUB
                    4'b0001: op = 4'b0101; // SLL
                    4'b0010: op = 4'b1000; // SLT
                    4'b0011: op = 4'b1001; // SLTU
                    4'b0100: op = 4'b0100; // XOR
                    4'b0101: op = 4'b0110; // SRL
                    4'b1101: op = 4'b0111; // SRA
                          4'b0110: op = 4'b0011; // OR
                    4'b0111: op = 4'b0010; // AND
                    default: op = 4'b0000; // Default case: ADD
                endcase
            end

            // Para instrucciones tipo I (inmediato)
            3'b100: begin
                case (instruction)
                    4'b0000: op = 4'b0000; // ADDI
                          4'b0001: op = 4'b0101; // SLLI
                    4'b0010: op = 4'b1000; // SLTI
                    4'b0011: op = 4'b1001; // SLTIU
                          4'b0100: op = 4'b0100; // XORI
                          4'b0101: op = 4'b0110; // SRLI
                          4'b1101: op = 4'b0111; // SRAI
                          4'b0110: op = 4'b0011; // ORI
                    4'b0111: op = 4'b0010; // ANDI
                    default: op = 4'b0000; // Default case: ADDI
                endcase
            end

            // Para instrucciones tipo B (branching)
            3'b011: begin
                case (instruction)
                    4'b0000: op = 4'b1010; // BEQ
                    4'b0001: op = 4'b1011; // BNE
                    4'b0100: op = 4'b1100; // BLT
                    4'b0101: op = 4'b1110; // BGE
                          4'b0110: op = 4'b1101; // BLTU
                    4'b0111: op = 4'b1111; // BGEU
                    default: op = 4'b0000; // Default: No operation
                endcase
            end

            // Para instrucciones tipo U (LUI, AUIPC)
            3'b101: op = 4'b0000;  // LUI
            3'b110: op = 4'b0000; // AUIPC
                3'b111: op = 4'b0010; // JAL,JALR

            // Caso por defecto (instrucción no válida)
            default: op = 4'b0000; // No operation
        endcase
    end

endmodule
 

 

module control_golden (
    input  logic [6:0] instruction,
    output logic       Branch,
    output logic       MemRead,
    output logic       MemtoReg,
    output logic       MemWrite,
    output logic       ALUSrc,
    output logic       RegWrite,
    output logic [2:0] ALUOp,    
    output logic [1:0] AuipcLui
);

    always_comb begin
        // Defaults (evita latches)
        Branch   = 1'b0;
        MemRead  = 1'b0;
        MemtoReg = 1'b0;
        MemWrite = 1'b0;
        ALUSrc   = 1'b0;
        RegWrite = 1'b0;
        ALUOp    = 3'b000;
        AuipcLui = 2'b00;

        unique case (instruction)
            // R-type 
            7'b0110011: begin
                RegWrite = 1'b1;
                AuipcLui   = 2'b10;
                ALUOp    = 3'b000;
            end

            // I-type
            7'b0010011: begin
                RegWrite = 1'b1;
                ALUSrc   = 1'b1;
                ALUOp    = 3'b100;
                     AuipcLui   = 2'b10;
            end

            // Load
            7'b0000011: begin
                RegWrite = 1'b1;
                MemRead  = 1'b1;
                MemtoReg = 1'b1;
                ALUSrc   = 1'b1;
                ALUOp    = 3'b001;
                     AuipcLui   = 2'b10;
            end

            // Store
            7'b0100011: begin
                MemWrite = 1'b1;
                ALUSrc   = 1'b1;
                ALUOp    = 3'b010;
                     AuipcLui   = 2'b10;
            end

            // Branch
            7'b1100011: begin
                Branch = 1'b1;
                AuipcLui   = 2'b10;
                ALUOp  = 3'b011; 
            end


            // LUI
            7'b0110111: begin
                RegWrite = 1'b1;
                     ALUSrc = 1'b1;
                AuipcLui = 2'b01;
                ALUOp    = 3'b101;
            end

            // AUIPC
            7'b0010111: begin
                RegWrite = 1'b1;
                AuipcLui = 2'b00;
                ALUSrc   = 1'b1;
                ALUOp    = 3'b110;
            end
                //JAL
                7'b1101111: begin
                     MemtoReg = 1'b1;
                     RegWrite = 1'b1;
                Branch = 1'b1;
                AuipcLui   = 2'b01;
                ALUOp  = 3'b111;
            end
                //JALR
                7'b1100111: begin
                Branch = 1'b1;
                AuipcLui   = 2'b01;
                ALUOp  = 3'b111;
                     MemtoReg = 1'b1;
                     RegWrite = 1'b1;
            end

            default: begin
                // defaults ya cubren
            end
        endcase
    end

endmodule


module mux_3_auipcLui(
	input logic [31:0] pc_out,
	input logic [31:0] read_data1,
	input logic [1:0] AuipcLui, //entrada de seleccion del mux
	output logic [31:0] salida //salida del mux
);

always_comb begin 
	case (AuipcLui)
		2'd0 : salida = pc_out;
		2'd1 : salida = 32'b0;
		2'd2 : salida = read_data1;
		default : salida = 32'b0;
		
	endcase
	
end

endmodule


module mux_2_aluSrc(
	input logic [31:0] read_data2,
	input logic [31:0] InmGen,
	input logic  AluSrc, //entrada de seleccion del mux
	output logic [31:0] salida //salida del mux
);

always_comb begin 
	case (AluSrc)
		1'd0 : salida = read_data2;
		1'd1 : salida = InmGen;
		default : salida = 32'b0;
		
	endcase
	
end

endmodule
