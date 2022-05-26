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
// The UART_Hello sends an hardcoded message through the UART_Tx module.


// -----------------------------------------------------------------------------
// --                                PARAMETERS                               --
// -----------------------------------------------------------------------------
//

// C_UART_DATA_WIDTH: transmission word width [bit] {8}.
// C_MESSAGE: the hardcoded message [string].



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

// Tool timescale.
`timescale 1 ns / 1 ps

// Behavioural.
module  UART_Hello # (
        parameter C_UART_DATA_WIDTH = 8, // Transmission word size.
        parameter C_MSG = "Hello",
        parameter C_MSG_LEN = 5
    ) (
        
        // IOs
        input rstb,             // Reset, active low.
        input clk,              // Reference input clock.
            
        // Control IOs.
        input send,             // Send command.
        output reg busy,        // Busy status.
        
        // IOs toward a Tx module.
        input txBusy,
        output reg txSend,
        output [C_UART_DATA_WIDTH - 1 : 0] txData,
        input txErr
    );
    
    
    // =========================================================================
    // ==                       Parameters derivation                         ==
    // =========================================================================

    // Defines the SM states.
    localparam sIDLE    = 2'b00;
    localparam sWAIT    = 2'b01;
    localparam sCOUNT   = 2'b10;
	localparam sSEND    = 2'b11;
	
	// Derive message length.
	localparam C_MSG_LEN_WIDTH = $clog2(C_MSG_LEN);
	
	
    // =========================================================================
    // ==                        Registers and wires                          ==
    // =========================================================================

    // SM registers
    reg [1:0] rState = sIDLE;
    reg [1:0] rNext;
    
    // Character counter.
    reg [C_MSG_LEN_WIDTH - 1 : 0] rCharCount = {(C_MSG_LEN_WIDTH){1'b0}};
    
    // Internal hardcoded registers for the message.
    reg [8 * C_MSG_LEN - 1 : 0] rMsg = C_MSG;
    
    
    // =========================================================================
    // ==                      Asynchronous assignments                       ==
    // =========================================================================

    // Data line.
    assign txData = rMsg[8 * (C_MSG_LEN - rCharCount) +: 8];
    

    
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
    always @(rState, txBusy, send) begin

        // Failsafe assignment (no state change).
        rNext <= rState;
        
        // Select next state depending on current state.
        case (rState)

            // Idle. Jump to wait if send goes high.
            sIDLE: begin
                rNext <= (send == 1'b1) ? sWAIT : sIDLE; 
            end

            // Wait for the transmission module to be available.
            sWAIT: begin
                rNext <= (txBusy == 1'b1) ? sWAIT : sCOUNT;
            end

            // Send, then go back waiting or idling, depending 
            // whether the whole message has been sent or not.
            sCOUNT: begin
                rNext <= (rCharCount < C_MSG_LEN) ? sSEND : sIDLE;
            end
            
            // Send, then go back waiting or idling, depending 
            // whether the whole message has been sent or not.
            sSEND: begin
                rNext <= (txBusy) ? sWAIT : sSEND;
            end
        endcase    
    end
    
    // =========================================================================
    // ==                        Synchronous counters                         ==
    // =========================================================================

    always @(posedge clk) begin  
        
        // Char counter.
        if (rState == sCOUNT) rCharCount <= rCharCount + 1;
        //else if (rState == sWAIT) rCharCount <= rCharCount;
        //else  rCharCoun <= {(C_MSG_LEN){1'b0}};
        else if (rState == sIDLE) rCharCount <= {(C_MSG_LEN){1'b0}};
    end
    
    
    // =========================================================================
    // ==                       Synchronous assignments                       ==
    // =========================================================================

    
    // =========================================================================
    // ==                        Synchronous outputs                          ==
    // =========================================================================

    // Clock-synchronous outputs.
    always @(posedge clk) begin  
        
        // Busy.
        busy <= (rState == sIDLE) ? 1'b0 : 1'b1;
        
        // Send line.
        txSend <= (rState == sSEND) ? 1'b1 : 1'b0;
        
    end

endmodule