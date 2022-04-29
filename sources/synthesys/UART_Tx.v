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
// The UART_Tx module transmits 1-byte values through a RS232-like single line
// communication channel.


// -----------------------------------------------------------------------------
// --                                PARAMETERS                               --
// -----------------------------------------------------------------------------
//
// C_CLK_FRQ:       frequency of the clock in [cycles per second] {100000000}. 
// C_TRX_RATE:      transmission bit frequency [BAUD] {1000000}.
//


// -----------------------------------------------------------------------------
// --                                I/O PORTS                                --
// -----------------------------------------------------------------------------
//
// rstb:            INPUT, synchronous reset, ACTIVE LOW. Asserting 'rstb' while
//                  'busy' is high will likely corrupt the communication channel.
// clk:             INPUT, master clock. Defines the timing of the transmission.
// send:            INPUT, ACTIVE HIGH. Starts a byte transmission when HIGH at
//                  the 'clk' rising edge. Assert it ONLY when 'busy' is low.
// [7:0] data:      INPUT, data byte. All bits must be settled by the 'clk'
//                  rising edge when 'send' is high, and must remain valid for
//                  the entire clock cycle.
// busy:            OUTPUT, indicates when the 'send' signal cannot be asserted.
//                  Asserting 'send' while 'busy' is high is an error condition.
// tx:              OUTPUT, the bit-line controlling the UART communication.
//


// -----------------------------------------------------------------------------
// --                                Libraries                                --
// -----------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.std_logic_unsigned.all;


// -----------------------------------------------------------------------------
// --                                  CODE                                   --
// -----------------------------------------------------------------------------

// Module behavioural.
module UART_Tx (
        C_CLK_FRQ = 100000000,  // Input clock frequency.
        C_TRX_RATE = 1000000    // Transmission BAUD rate.
    ) #  (
        input rstb,             // Reset, active low.
        input clk,              // Reference input clock.
        input send,             // Send command.
        input [7:0] data,       // Data byte.
        output reg busy,        // Status flag.
        output reg tx           // Output serial line.
    );

    
    
    // -------------------------------------------------------------------------
    // --                       Parameters derivation                         --
    // -------------------------------------------------------------------------

    // Derives the clock cycles corresponding to 1 bit transmission duration.
    localparam C_PERIOD = C_CLK_FRQ / C_TRX_RATE;
    localparam C_PERIOD_WIDTH = $clog2(C_PERIOD);

    // Number of bits per packet. This may be changed if parity has to be used,
    // and/or extra stop bits included.
    localparam C_PACKET_SIZE = 10;
    localparam C_PACKET_SIZE_WIDTH = $clog2(C_PACKET_SIZE);

    // Defines the SM states.
    localparam sIDLE  = 2'b00;
    localparam sWAIT  = 2'b01;
	localparam sSEND  = 2'b10;
    localparam sERROR = 2'b11;



    // -------------------------------------------------------------------------
    // --                        Registers and wires                          --
    // -------------------------------------------------------------------------

    // SM registers
    reg [1:0] rState = sIDLE;
    wire [1:0] wNext;
    
    // Defines the support registers used by the module.
    reg [C_PERIOD_WIDTH - 1 : 0] rCycles;       // Clock cycles counter.
    reg [C_PACKET_SIZE - 1 : 0] rPacket;        // Data packet.
    reg [[C_PACKET_SIZE_WIDTH - 1 : 0] rBits;   // Packet  bits counter.
    

    // -------------------------------------------------------------------------
    // --                        State Machine Logic                          --
    // -------------------------------------------------------------------------

    // SM sync process.
    always @(posedge clock) begin  
        
        // Reset.
        if (rstb == 1'b0) begin
            rState <= sIDLE;
        
        // Next state.
        end else begin
            rState <= wNext;
        end
    end

    // SM next state (async) logic.
    always @(rState, rCycles, rBits) begin

        // Failsafe assignment (no state change).
        wNext <= rState;
        
        // Select next state depending on current state.
        case (rState)

            // Idle. Jump to load if 'send' is high.
            sIDLE: begin
                (send) ? wNext <= sWAIT : wNext <= sIDLE;
            end

            // Wait for a full transmission cycle.
            sWAIT: begin
                (rCycles >= C_PERIOD) ? wNext <= sWAIT : wNext <= sSEND;
            end

            // Send the bit. Verify the number of loaded bits, stop in case.
            sSEND: begin
                (rBits >= C_PACKET_SIZE) ? wNext <= sIDLE : wNext <= sWAIT;
            end

            // Error.
            sERROR: begin
                wNext <= sIDLE;
            end
        endcase    
    end


    // -------------------------------------------------------------------------
    // --                        Synchronous counters                         --
    // -------------------------------------------------------------------------

    // Load time counter. Count the main clock cycles necessary
    // to make up for one transmission cycle.
    always @(posedge clock) begin  
        if (rState == sWAIT) rCycles <= rCycles + 1;
        else rCycles <= 0;
    end

    // Bit counter. Count the number of bit sent through the line.
    always @(posedge clock) begin  
        if (rState == sSEND) rBits <= rBits + 1;
        else if (rState == sIDLE) rBits <= 0;    
    end


    // -------------------------------------------------------------------------
    // --                        Synchronous outputs                          --
    // -------------------------------------------------------------------------

    // Busy flag.
    always @(posedge clock) begin  
        (rState == sIDLE) ? busy <= 1'b0 : 1'b1;        
    end
    
    // Imput data latch. Latches the data if the 'send' signal is high.
    always @(posedge clock) begin  
        if (send) begin            
            rPacket <= '0' & data & '1';        
        end        
    end
    
    // Transmisison line. Outputs the current bit from the packet.
    always @(posedge clock) begin  
        if (rState == sWAIT) tx <= rPacket[rBits];
        else if (rState == sIDLE) tx <= 1'b1;
    end

endmodule