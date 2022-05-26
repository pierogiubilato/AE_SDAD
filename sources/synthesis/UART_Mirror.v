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
// The UART_Mirror module receives a RS232-like single line RX transmission and
// bounces it back through the TX line, acting as a repeater when enabled.
// When disabled, it is a completely transparent, passive connection for the 
// UARTT_Rx and UART_Tx modules.


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
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//

// Tool timescale.
`timescale 1 ns / 1 ps

// Behavioural.
module  UART_Mirror # (
	   parameter C_UART_DATA_WIDTH = 8 // Transmission word size.
    ) (
        
        // IOs
        input rstb,                 // Reset, active low.
        input clk,                  // Reference input clock.
        input enable,               // Enable the mirroring.
            
        // IOs (passive) of the UART_Rx IOs.
        output validRx,
        input ackRx,
        output [C_UART_DATA_WIDTH - 1 : 0] dataRx,
        output errRx,
        
        // IOs (passive) of the UART_Tx IOs
        output busyTx,
        input sendTx,
        input [C_UART_DATA_WIDTH - 1 : 0] dataTx,
        output errTx,
            
        // IOs toward the UART_Rx module.
        input rxValid,              // Valid from the Rx module.
        output rxAck,               // Acknowledge flag toward the Rx Module.
        input [C_UART_DATA_WIDTH - 1 : 0] rxData,   // UART data IN.
        input rxErr,                // Error from Rx module.
        
        // IOs toward the UART_Tx module.
        input txBusy,               // Busy from the Tx module
        output txSend,              // Send flag to the Tx module.
        output [C_UART_DATA_WIDTH - 1 : 0] txData, // UART data OUT.
        input txErr                 // Error from Tx module.
        
    );
    
    
    // =========================================================================
    // ==                       Parameters derivation                         ==
    // =========================================================================

    // Defines the SM states.
    localparam sIDLE    = 2'b00;
    localparam sACK     = 2'b01;
	localparam sWAIT    = 2'b10;
	
    // =========================================================================
    // ==                        Registers and wires                          ==
    // =========================================================================

    // SM registers
    reg [1:0] rState = sIDLE;
    reg [1:0] rNext;
    
    // Internal registers for UART handshake.
    reg rMirAck;
    reg rMirSend;
    

    
    // =========================================================================
    // ==                      Asynchronous assignments                       ==
    // =========================================================================

    // To/from Rx/Tx modules.
    assign validRx = rxValid;
    assign rxAck = (enable) ? rMirAck : ackRx;
    assign busyTx = (enable) ? 1'b1 : txBusy;
    assign txSend = (enable) ? rMirSend : sendTx;
    assign errTx = (enable) ? 1'b0 : txErr;
    
    // Data mirroring.
    assign txData = (enable) ? rxData : dataTx;

    // Fixed bridges.
    assign dataRx = rxData;
    assign errRx = rxErr;



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
    always @(rState, rxValid) begin

        // Failsafe assignment (no state change).
        rNext <= rState;
        
        // Select next state depending on current state.
        case (rState)

            // Idle. Jump to ack if valid goes high.
            sIDLE: begin
                rNext <= (rxValid == 1'b1) ? sACK : sIDLE; 
            end

            // Just use this state to issue single-clock flags.
            sACK: begin
                rNext <= sWAIT;
            end

            // Wait for the Rx module to reset.
            sWAIT: begin
                rNext <= (rxValid == 1'b0) ? sIDLE : sWAIT;
            end

        endcase    
    end
    
    // =========================================================================
    // ==                       Synchronous assignments                       ==
    // =========================================================================


    // =========================================================================
    // ==                        Synchronous outputs                          ==
    // =========================================================================

    // Clock-synchronous outputs.
    always @(posedge clk) begin  
        
        // Ack Line.
        rMirAck <= (rState == sACK) ? 1'b1 : 1'b0;
        
        // Send line.
        rMirSend <= (rState == sACK) ? 1'b1 : 1'b0;
        
    end

endmodule