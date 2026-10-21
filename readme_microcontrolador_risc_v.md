# Microcontrolador RISC-V Monociclo 💻

## Descripción General
Este proyecto presenta el diseño completo y la implementación desde cero de un **Microcontrolador RISC-V** funcional, desarrollado en **SystemVerilog**. Ha sido diseñado de forma colaborativa por un equipo de 5 estudiantes de ingeniería.

## Arquitectura y Módulos
El diseño sigue una arquitectura monociclo e incluye la implementación estructural y la interconexión de todos los módulos principales:
*   **ALU (Unidad Aritmético Lógica):** Capaz de ejecutar las operaciones estándar del repertorio de instrucciones RISC-V.
*   **Unidad de Control:** Encargada de decodificar las instrucciones y orquestar las rutas de datos.
*   **Módulos de Memoria (RAM y ROM):** Bloques de memoria totalmente sintetizables, inicializados con código máquina para ejecutar programas de prueba (ej. sucesión de Fibonacci, algoritmos de ordenamiento).
*   **Banco de Registros (Register File):** Arquitectura de almacenamiento interno para el procesamiento temporal de datos.

## Stack Tecnológico
*   **Lenguaje de Descripción de Hardware:** SystemVerilog (`.sv`)
*   **Entorno de Desarrollo:** Intel Quartus Prime
*   **Simulación:** Se incluyen *testbenches* exhaustivos (`tb_*.sv`) para cada módulo con el fin de verificar la corrección lógica antes de la síntesis.

## Estructura del Repositorio
Todos los archivos `.sv` representan el diseño de hardware puro y los entornos de prueba (*testbenches*). El proyecto está completamente modularizado, actuando `top_SingleCycle.sv` como la entidad principal de interconexión. Puedes encontrar documentación detallada sobre la arquitectura y la implementación en el informe PDF adjunto.