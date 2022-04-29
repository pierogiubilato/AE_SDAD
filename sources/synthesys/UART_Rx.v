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
// The UART_Rx module receives 1-byte values through a RS232-like single line
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
// read:            INPUT, ACTIVE HIGH. Starts a byte transmission when HIGH at
//                  the 'clk' rising edge. Assert it ONLY when 'busy' is low.
// [7:0] data:      OUTPUT, data byte. The received data byte. It is guaranteed 
//                  to remain valid for one clock cycle after the ''  
//                  available for at All bits must be settled by the 'clk'
//                  rising edge when 'send' is high, and must remain valid for
//                  the entire clock cycle.
// busy:            OUTPUT, indicates when the 'read' signal is not valied.
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
module UART_Rx (
        C_CLK_FRQ = 100000000,  // Input clock frequency.
        C_TRX_RATE = 1000000    // Transmission BAUD rate.
    ) #  (
        input rstb,             // Reset, active low.
        input clk,              // Reference input clock.
        input read,             // Acknowledge the data has been acquired.
        output reg [7:0] data,  // Data byte.
        output reg ready,       // Status flag.
        output reg error,       // Error flag.
        input rx                // Input serial line.
    );

    
    
    // -------------------------------------------------------------------------
    // --                       Parameters derivation                         --
    // -------------------------------------------------------------------------

    // Get the 1 bit transmission period cycle in terms of main clock cycles.
    localparam C_PERIOD = C_CLK_FRQ / C_TRX_RATE;
    localparam C_PERIOD_HALF = C_CLK_FRQ / C_TRX_RATE / 2; // 1/2 period.
    localparam C_PERIOD_WIDTH = $clog2(C_PERIOD);   // Counter bitsize.
    
    // Number of bits per packet. This may be changed if parity has to be used,
    // and/or extra stop bits included.
    localparam C_PACKET_SIZE = 10;
    localparam C_PACKET_SIZE_WIDTH = $clog2(C_PACKET_SIZE);

    // Defines the SM states.
    localparam sIDLE   = 3'b000;
    localparam sWAITH  = 3'b001;
	localparam sWAITF  = 3'b010;
	localparam sSAMPLE = 3'b011;
    localparam sERROR  = 3'b111;



    // -------------------------------------------------------------------------
    // --                        Registers and wires                          --
    // -------------------------------------------------------------------------

    // SM registers
    reg [2:0] rState = sIDLE;
    wire [2:0] wNext;
    
    // Defines the support registers used by the module.
    reg [C_PERIOD_WIDTH - 1 : 0] rCycles;       // Clock cycles counter.
    reg [C_PACKET_SIZE - 1 : 0] rPacket;        // Data packet.
    reg [[C_PACKET_SIZE_WIDTH - 1 : 0] rBits;   // Packet  bits counter.
    reg  rAck;                                  // Data read acknowledgment.
      

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
    always @(rState, negedge rx, rCycles, rBits) begin

        // Failsafe assignment (no state change).
        wNext <= rState;
        
        // Select next state depending on current state.
        case (rState)

            // Idle. Jump to wait if a negative transition on 'rx' is sensed.
            sIDLE: begin
                (rs == 1'b0) ? wNext <= sWAITH : wNext <= sWAITF;
            end

            // After the start transition, wait for half transmission cycle, so
            // to center the sampling point in the most robust position.
            sWAITH: begin
                (rCycles >= C_PERIOD_HALF) ? wNext <= sWAITF : wNext <= stWAITH;
            end

            // Wait for a full transmission cycle.
            sWAITF: begin
                (rCycles >= C_PERIOD) ? wNext <= sSAMPLE : wNext <= stWAITF;
            end

            // Sample the input 'rx' line value. Verify the number of loaded bits, 
            // then stop reading if the stop bit has been reached.
            sSAMPLE: begin
                (rBits >= C_PACKET_SIZE) ? wNext <= sIDLE : wNext <= sWAITF;
            end

            // Error.
            sERROR: begin
                wStateNext <= sIDLE;
            end
        endcase    
    end


    // -------------------------------------------------------------------------
    // --                        Synchronous counters                         --
    // -------------------------------------------------------------------------

    // Bit period time counter. Count the main clock cycles necessary
    // to make up for one transmission cycle.
    always @(posedge clock) begin  
        if (rState == sWAITH || rState == sWAITF) rCycles <= rCycles + 1;
        else rCycles <= 0;
    end

    // Bit counter. Count the number of bits received through the line.
    always @(posedge clock) begin  
        if (rState == sSAMPLE) rBits <= rBits + 1;
        else if (rState == sIDLE) rBits <= 0;    
    end



    // -------------------------------------------------------------------------
    // --                         Synchronous inputs                          --
    // -------------------------------------------------------------------------


    // Transmisison line. Sample the current bit from the packet.
    always @(posedge clock) begin  
        if (rState == sSAMPLE) rPacket[rBits] <= rx;
    end

    // Received acknowledgment. Latch the ack read.
    always @(posedge clock) begin  
        if (rState == sSAMPLE) rPacket[rBits] <= rx;
    end



    // -------------------------------------------------------------------------
    // --                        Synchronous outputs                          --
    // -------------------------------------------------------------------------

    // Busy flag.
    always @(posedge clock) begin  
        (rState == sIDLE) ? busy <= 1'b0 : 1'b1;        
    end
    
    // Input data read. Latches the data if the 'send' signal is high.
    always @(posedge clock) begin  
        if (read) == 1b'1 begin            
            //rPacket <= '0' & data & '1';        
        end        
    end
    
    
endmodule