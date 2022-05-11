/*#############################################################################\
##                                                                            ##
##       APPLIED ELECTRONICS - Physics Department - University of Padova      ##
##                                                                            ## 
##       ---------------------------------------------------------------      ##
##                                                                            ##
##             Sigma Delta Analogue to Digital didactical example             ##
##                                                                            ##
\#############################################################################*/

// INFO
// The registry module implements a superminimal registers set for debug.


// -----------------------------------------------------------------------------
// --                                PARAMETERS                               --
// -----------------------------------------------------------------------------
//
// C_UART_DATA_WIDTH: transmission word width [bit] {8}.


// -----------------------------------------------------------------------------
// --                                I/O PORTS                                --
// -----------------------------------------------------------------------------
//
// rstb:            INPUT, synchronous reset, ACTIVE LOW. Asserting 'rstb' while
//                  'busy' is high will likely corrupt the communication channel.
// clk:             INPUT, master clock. Defines the timing of the transmission.
// ack:             INPUT, ACTIVE HIGH. Tells the module the 'data' port has been
//                  read and/or the 'error' condition has been acknowledged. The 
//                  module will not parse further data until the 'ack' is asserted.
// [x:0] data:      INPUT, data byte. The received data byte. It will stay valid
//                  until 'ack' is asserted. If other arrives before 'ack' is
//                  asserted, they will be lost and an error will generate.
//                  available for at All bits must be settled by the 'clk'
//                  rising edge when 'send' is high, and must remain valid for
//                  the entire clock cycle.
// valid:           INPUT, indicates when the data on the 'data' port are valid.


// -----------------------------------------------------------------------------
// --                                Libraries                                --
// -----------------------------------------------------------------------------


`timescale 1 ns / 1 ps

// Behavioural.
module registry # (
        parameter C_UART_DATA_WIDTH = 8,    // Transmission word size.
        parameter C_REG_WIDTH = 4,          // Register width.
        
        // Derive the number of registers.
        localparam C_REG_COUNT_WIDTH = C_UART_DATA_WIDTH - C_REG_WIDTH, 
        localparam C_REG_COUNT = 2**C_REG_COUNT_WIDTH,
        localparam C_REG_PORT_WIDTH = C_REG_COUNT * C_REG_WIDTH
    ) (
        
        // IOs
        input rstb,             // Reset, active low.
        input clk,              // Reference input clock.
        input valid,            // Valid flag from the UART_Rx module.
        input [C_UART_DATA_WIDTH - 1 : 0] data, // UART data.
        output reg ack,         // Acknowledge flag toward the UART_Rx.
        //output [63 : 0] register // Registers outputs.
        output [C_REG_PORT_WIDTH - 1 : 0] register // Registers outputs.
    );
    
    
    // =========================================================================
    // ==                       Parameters derivation                         ==
    // =========================================================================

    // Defines the SM states.
    localparam sIDLE = 2'b00;
	localparam sGET  = 2'b01;
    localparam sACK  = 2'b10;


    // =========================================================================
    // ==                        Registers and wires                          ==
    // =========================================================================

     // SM registers
    reg [1:0] rState = sIDLE;
    reg [1:0] rNext;
   
    // The actual registers.
    reg [C_REG_WIDTH - 1 : 0] rRegister [C_REG_COUNT - 1 : 0];

// Address and data wires,
//wire [C_REG_COUNT_WIDTH - 1 : 0] wAddress;
//wire [C_REG_WIDTH - 1 : 0] wData;


    // =========================================================================
    // ==                      Asynchronous assignments                       ==
    // =========================================================================

    // Maps the registers array into the linear 1D output.
    genvar i;
    generate
        for (i = 0; i < C_REG_COUNT; i = i + 1) begin
            assign register[(i + 1) * C_REG_WIDTH - 1: i * C_REG_WIDTH] = rRegister[i];
        end
    endgenerate
    

    // =========================================================================
    // ==                        State Machine Logic                          ==
    // =========================================================================

    // SM sync process.
    always @(posedge clk) begin  
        
        // Reset.
        if (rstb == 1'b0) begin
            rState <= sIDLE;
        
        // Next state.
        end else begin
            rState <= rNext;
        end
    end

    // SM next state logic.
    always @(rState, valid) begin

        // Failsafe assignment (no state change).
        rNext <= rState;
        
        // Select next state depending on current state.
        case (rState)

            // Idle. Wait for valid data available at the input.
            sIDLE: begin
                rNext <= (valid == 1'b1) ? sGET : sIDLE; 
            end

            // Sample the input data and store it in the register(s).
            sGET: begin
                rNext <= sACK;
            end

            // Acknowledge the data reception.
            sACK: begin
                rNext <= sIDLE;
            end
        endcase    
    end


    // =========================================================================
    // ==                       Synchronous assignments                       ==
    // =========================================================================

    // Move data from the 'data' port into the correct register.
    always @(posedge clk) begin  
        if (rState == sGET) begin
            rRegister [data[C_UART_DATA_WIDTH - 1 : C_REG_WIDTH]] <= data[C_REG_WIDTH - 1 : 0];
        end
    end


    // =========================================================================
    // ==                        Synchronous outputs                          ==
    // =========================================================================

    // Asserts the ack flag once data have been latched.
    always @(posedge clk) begin  
        ack <= (rState == sGET) ? 1'b1 : 1'b0;
    end
    
endmodule