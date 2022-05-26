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
// C_UART_RATE:     transmission bit frequency [BAUD] {1000000}.
// C_UART_DATA_WIDTH: transmission word width [bit] {8}.
// C_UART_PARITY:   transmission parity bit [bit] {0, 1}.
// C_UART_STOP:     transmission stop bit(s) [bit] {0, 1, 2}.


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
// [x:0] data:      OUTPUT, data byte. The received data byte. It will stay valid
//                  until 'ack' is asserted. If other arrives before 'ack' is
//                  asserted, they will be lost and an error will generate.
//                  available for at All bits must be settled by the 'clk'
//                  rising edge when 'send' is high, and must remain valid for
//                  the entire clock cycle.
// valid:           OUTPUT, indicates when the data on the 'data' port are valid.
// rx:              INPUT, the bit-line carrying the UART communication.
// error:           OUTPUT: either a parity error or missed input data. The
//                  error condition will stop the module from receiving further
//                  data, until it is cleared through an 'ack' assertion.
//


// -----------------------------------------------------------------------------
// --                                Libraries                                --
// -----------------------------------------------------------------------------


`timescale 1 ns / 1 ps

// Behavioural.
module UART_Rx # (
        parameter C_CLK_FRQ = 100_000_000,  // Input clock frequency.
        parameter C_UART_RATE = 1_000_000,  // Transmission BAUD rate.
        parameter C_UART_DATA_WIDTH = 8,    // Transmission word size.
        parameter C_UART_PARITY = 1,        // Transmisison check for parity.
        parameter C_UART_STOP = 1           // Transmisison stop bits.
    ) (
        input rstb,             // Reset, active low.
        input clk,              // Reference input clock.
        input ack,              // Acknowledge the data has been acquired.
        output reg [C_UART_DATA_WIDTH - 1 : 0] data,  // Data byte.
        output reg valid = 1'b0,    // Status flag.
        output reg error = 1'b0,    // Error flag.
        input rx                // Input serial line.
    );
    
    
    // =========================================================================
    // ==                       Parameters derivation                         ==
    // =========================================================================

    // Get the 1 bit transmission period cycle in terms of main clock cycles.
    localparam C_PERIOD = C_CLK_FRQ / C_UART_RATE;
    localparam C_PERIOD_HALF = C_PERIOD / 2; // 1/2 period.
    localparam C_PERIOD_WIDTH = $clog2(C_PERIOD);   // Counter bitsize.
    
    // Number of bits per packet. This may be changed if parity has to be used,
    // and/or extra stop bits included.
    localparam C_PACKET_SIZE = 1 + C_UART_DATA_WIDTH + C_UART_PARITY + C_UART_STOP;
    localparam C_PACKET_SIZE_WIDTH = $clog2(C_PACKET_SIZE);

    // Defines the SM states.
    localparam sIDLE   = 3'b000;
    localparam sWAITH  = 3'b001;
	localparam sWAITF  = 3'b010;
	localparam sSAMPLE = 3'b011;
	localparam sVERIFY = 3'b100;
    localparam sVALID  = 3'b101;
    localparam sERROR  = 3'b111;


    // =========================================================================
    // ==                        Registers and wires                          ==
    // =========================================================================

    // SM registers
    reg [2:0] rState = sIDLE;
    reg [2:0] rNext;
    
    // Defines the support registers used by the module.
    reg [C_PERIOD_WIDTH - 1 : 0] rCycles;       // Clock cycles counter.
    reg [C_PACKET_SIZE - 1 : 0] rPacket;        // Whole data packet.
    reg [C_PACKET_SIZE_WIDTH - 1 : 0] rBits;    // Packet  bits counter.
            
    // Parity status.
    wire wParity;                               // Parity calculation outcome.
    reg rParityErr = 1'b0;                      // Parity error flag: {0=ok,1=err}


    // =========================================================================
    // ==                      Asynchronous assignments                       ==
    // =========================================================================

    // This aasignment calculates the parity of the received data.
    assign wParity = ^rPacket[C_PACKET_SIZE - 2 : C_PACKET_SIZE - C_UART_DATA_WIDTH - 1];


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
    always @(rState, rx, ack, rCycles, rBits) begin

        // Failsafe assignment (no state change).
        rNext <= rState;
        
        // Select next state depending on current state.
        case (rState)

            // Idle. Jump to wait if a negative transition on 'rx' is sensed.
            sIDLE: begin
                rNext <= (rx == 1'b0) ? sWAITH : sIDLE; 
            end

            // After the start transition, wait for half transmission cycle, so
            // to center the first sampling point in the most robust position.
            sWAITH: begin
                rNext <= (rCycles >= C_PERIOD_HALF - 1) ? sSAMPLE : sWAITH;
            end

            // Wait for a full transmission cycle for the next sampling point.
            sWAITF: begin
                rNext <= (rCycles >= C_PERIOD) ? sSAMPLE : sWAITF;
            end

            // Sample the input 'rx' line value. Verify the number of loaded bits, 
            // then stop reading if the stop bit has been reached.
            sSAMPLE: begin
                rNext <= (rBits < C_PACKET_SIZE - 1) ? sWAITF : sVERIFY;
            end

            // Data received. Assert the ready valid and check the parity.
            sVERIFY: begin
                rNext <= (rParityErr == 0) ? sVALID : sERROR;
            end

            // Data validated. Wait for the ack, raise an error if a new
            // char reception starts before the ack has been asserted.
            sVALID: begin
                if (rx == 1'b0) begin
                    rNext <= sERROR;                                    
                end else begin
                    rNext <= (ack) ? sIDLE : sVALID;
                end
            end

            // Error. Raises the error, the go to IDLE. The flag will stay
            // High until the reception restarts.
            sERROR: begin
                //rNext <= (ack) ? sIDLE : sERROR;
                rNext <= sIDLE;
            end
        endcase    
    end


    // =========================================================================
    // ==                        Synchronous counters                         ==
    // =========================================================================

    always @(posedge clk) begin  
        
        // UART bit period time counter. Count the main clock cycles necessary
        // to make up for one transmission cycle. Note that the counter starts
        // at '1' instead of '0' to streamline coding.
        rCycles <= (rState == sWAITH || rState == sWAITF) ? rCycles + 1 : 0;
    
        // UART bit counter. Count the number of bits received through the line.
        if (rState == sSAMPLE) rBits <= rBits + 1;
        else if (rState == sIDLE) rBits <= {(C_PACKET_SIZE_WIDTH - 1){1'b0}};  //{{(C_PACKET_SIZE_WIDTH - 1){1'b0}}, 1'b1};
        else rBits <= rBits;
    end


    // =========================================================================
    // ==                       Synchronous assignments                       ==
    // =========================================================================

    // Parity checking only if parity is used.
    generate
        
        // Code using parity.
        if (C_UART_PARITY != 0) begin
            always @(posedge clk) begin  

                // Verify whether the calculated parity and the received parity 
                // matches or not. Set the parity error flag if they do not.
                if (rState == sVERIFY) begin
                    rParityErr <= wParity ^ (rPacket[C_UART_STOP]);
                end
            
                // Check that no further data are arriving while waiting for the
                // the acknowledgment flag. Otherwise, raise an error.
                if (rState == sVALID) begin
                    rParityErr <= wParity ^ (rPacket[C_UART_STOP]);
                end
            end
        end
    endgenerate


    // =========================================================================
    // ==                        Synchronous outputs                          ==
    // =========================================================================

    // Clock-synchronous outputs.
    always @(posedge clk) begin  
        
        // Packet sampling. Note that the indexing exploits the fact the 'rBits'
        // conter starts on purpose at '1'.
        rPacket[rBits] <= (rState == sSAMPLE) ? rx : rPacket[rBits];
        
        // Data word.
        data <= (rState == sSAMPLE) ? rPacket[C_PACKET_SIZE - 1 : C_PACKET_SIZE - 1 - C_UART_DATA_WIDTH] : data;

        // Valid flag.
        valid <= (rState == sVALID) ? 1'b1 : 1'b0;

        // Error flag.
        if (rState == sERROR) error <= 1'b1;
        else if (rState == sIDLE) error <= error; 
        else error <= 1'b0;
        
        //error <= (rState == sERROR) ? 1'b1 : 1'b0;
    end
    
endmodule