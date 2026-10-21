module hazard_detection (
    input  logic [4:0] ID_EX_rd,
    input  logic [4:0] IF_ID_rs1,
    input  logic [4:0] IF_ID_rs2,
    input  logic       ID_EX_MemRead,
    output logic       stall_pc,
    output logic       stall_if_id,
    output logic       sel_stall_control
);
    always_comb begin
        // Riesgo de carga: LW seguido de uso de ese registro
        if (ID_EX_MemRead && ((ID_EX_rd == IF_ID_rs1) || (ID_EX_rd == IF_ID_rs2))) begin
            stall_pc          = 1'b1; // Congelar PC
            stall_if_id       = 1'b1; // Congelar instrucción en ID
            sel_stall_control = 1'b1; // Inyectar burbuja (NOP) en EX
        end else begin
            stall_pc          = 1'b0;
            stall_if_id       = 1'b0;
            sel_stall_control = 1'b0;
        end
    end
endmodule
