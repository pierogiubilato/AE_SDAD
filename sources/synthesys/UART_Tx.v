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
// error:           OUTPUT, ####################################################
//                  ############################################################.
// tx:              OUTPUT, the bit-line controlling the UART communication.
//


// -----------------------------------------------------------------------------
// --                                Libraries                                --
// -----------------------------------------------------------------------------


`timescale 1 ns / 1 ps


// Behavioural.
module UART_Tx # (
        parameter C_CLK_FRQ = 100000000,    // Input clock frequency.
        parameter C_UART_RATE = 1000000,    // Transmission BAUD rate.
        parameter C_UART_DATA_WIDTH = 8,    // Transmission word size.
        parameter C_UART_PARITY = 1,        // Transmisison check for parity.
        parameter C_UART_STOP = 1           // Transmisison stop bits.

    ) (
        input rstb,                 // Reset, active low.
        input clk,                  // Reference input clock.
        input send,                 // Send command.
        input [C_UART_DATA_WIDTH - 1:0] data,       // Data word.
        output reg busy = 1'b1,     // Status flag.
        output reg error = 1'b0,    // Error flag.
        output reg tx = 1'b1        // Output serial line.
    );
    
    
    // =========================================================================
    // ==                       Parameters derivation                         ==
    // =========================================================================

    // Derives the clock cycles corresponding to 1 bit transmission duration.
    localparam C_PERIOD = C_CLK_FRQ / C_UART_RATE;
    localparam C_PERIOD_WIDTH = $clog2(C_PERIOD);

    // Number of bits per packet. 1 start bit, the data word, {0,1} parity bit,
    // and [n] stop bits.
    localparam C_PACKET_SIZE = 1 + C_UART_DATA_WIDTH + C_UART_PARITY + C_UART_STOP;
    localparam C_PACKET_SIZE_WIDTH = $clog2(C_PACKET_SIZE);

    // Defines the SM states.
    localparam sIDLE  = 2'b00;
    localparam sWAIT  = 2'b01;
	localparam sSEND  = 2'b10;
    localparam sERROR = 2'b11;


    // =========================================================================
    // ==                        Registers and wires                          ==
    // =========================================================================

    // SM registers
    reg [1:0] rState = sIDLE;
    reg [1:0] rNext;
    
    // Defines the support registers used by the module.
    reg [C_PERIOD_WIDTH - 1 : 0] rCycles;       // Clock cycles counter.
    reg [C_PACKET_SIZE - 1 : 0] rPacket;        // Whole data packet.
    reg [C_PACKET_SIZE_WIDTH - 1 : 0] rBits;    // Packet  bits counter.
    
    // Packet, parity and stop.
    wire [C_PACKET_SIZE - 1 : 0] wPacket;       // Whole data packet
    wire wParity;                               // Parity value.
        
    
    // =========================================================================
    // ==                      Asynchronous assignments                       ==
    // =========================================================================

    // This assignment generates thewhole packet to be sent (start, data, parity,
    // stop), depending on the parity parameter value.
    generate
        
        // Code using parity.
        if (C_UART_PARITY != 0) begin
            
            // This asignment calculates the parity of the data word.
            assign wParity = ^data[C_UART_DATA_WIDTH - 1 : 0];

            // Build the whole packet including parity.
            assign wPacket = {1'b0, data, wParity, {C_UART_STOP{1'b1}}};
        
        // Code NOT using parity.
        end else begin
            
            // Build the whole packet WITHOUT considering parity.
            assign wPacket = {1'b0, data, {C_UART_STOP{1'b1}}};
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

    // SM next state (async) logic.
    always @(rState, send, rCycles, rBits) begin

        // Failsafe assignment (no state change).
        rNext <= rState;
        
        // Select next state depending on current state.
        case (rState)

            // Idle. Jump to load if 'send' is high.
            sIDLE: begin
                if (send) rNext <= sWAIT;
                else rNext <= sIDLE;
            end

            // Wait for a full transmission cycle.
            sWAIT: begin
                if (rCycles >= C_PERIOD) rNext <= sSEND;
                else rNext <= sWAIT;
            end

            // Send the bit. Verify the number of loaded bits, stop in case.
            sSEND: begin
                if (rBits >= C_PACKET_SIZE) rNext <= sIDLE;
                else rNext <= sWAIT;
            end

            // Error.
            sERROR: begin
                rNext <= sIDLE;
            end
        endcase    
    end


    // =========================================================================
    // ==                        Synchronous counters                         ==
    // =========================================================================

    always @(posedge clk) begin  
        
        // UART bit period counter. Count the main clock cycles necessary to
        // account for one transmission cycle.
        rCycles <= (rState == sWAIT) ? rCycles + 1 : { {(C_PERIOD_WIDTH - 1){1'b0}}, 1'b1};;
            
        // UART bit counter. Count the number of bit sent through the line.
        if (rState == sSEND) rBits <= rBits + 1;
        else if (rState == sWAIT) rBits <= rBits;
        else  rBits <= {{(C_PACKET_SIZE_WIDTH - 1){1'b0}}, 1'b1};
    end

    // =========================================================================
    // ==                        Synchronous inputs                           ==
    // =========================================================================

    always @(posedge clk) begin  
        
        // Input data latch. Latches the data only when 'send' signal is high.
        rPacket <= (send) ? wPacket : rPacket;
    end


    // =========================================================================
    // ==                        Synchronous outputs                          ==
    // =========================================================================

    always @(posedge clk) begin  
        
        // Busy flag.
        busy <= (rState == sIDLE) ? 1'b0 : 1'b1;        
    
        // Transmission line. Outputs the current bit from the packet.
        tx <=  (rState == sWAIT || rState == sSEND) ? rPacket[C_PACKET_SIZE - rBits] : 1'b1;
    end

endmodule