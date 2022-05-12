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
// The pwm module generates a pulse train which duty cycle corresponds to the
// input 'level' value. The 'C_MIN_PULSE' defines the minimum duration of a
// single pulse.


// -----------------------------------------------------------------------------
// --                                PARAMETERS                               --
// -----------------------------------------------------------------------------
//
// C_CLK_FRQ:       frequency of the clock in [cycles per second] {100000000}. 
// C_MIN_PULSE:     the time interval the signal must be stable to pass through
//					and reach the fabric. [ms] {10}.
// C_LEVEL_WIDTH:   the 'level' width, indicating the number of bits used to
//                  calculate the pulse duty cycle.

// -----------------------------------------------------------------------------
// --                                I/O PORTS                                --
// -----------------------------------------------------------------------------
//
// rstb:            INPUT, synchronous reset, ACTIVE LOW. 
// clk:             INPUT, master clock.
// level:          	INPUT, the signal indicating the duty cycle. The signal duty
//                  cycle will result equal to 'level / (2^C_LEVEL_WIDTH - 1)'.
// out:           	OUTPUT: the pulsed signal.


// Tool timescale.
`timescale 1 ns / 1 ps

// Behavioural.
module  pwm # (
		parameter C_CLK_FRQ = 100000000,  	// Clock frequency [Hz].
		parameter C_MIN_PULSE = 1000,       // Minimum pulse width [ns].
        parameter C_LEVEL_WIDTH = 8         // Level range.        
	) (
		input rstb,
		input clk,
		input [C_LEVEL_WIDTH-1 : 0] level,  // The modulation level.
		output reg out		                // The modulated output.
	);  


   	// =========================================================================
    // ==                        Registers and wires                          ==
    // =========================================================================

	// Counters.
	reg [C_LEVEL_WIDTH - 1 : 0] rCount;
	

	// =========================================================================
    // ==                        Synchronous counters                         ==
    // =========================================================================

	// Increments the counter if the signal is stable
	always @ (posedge clk) begin
		
		// Reset or count.
    	rCount <= (rstb ==  1'b0) ? { C_LEVEL_WIDTH {1'b0} } : rCount + 1;
    end


	// =========================================================================
    // ==                        Synchronous outputs                          ==
    // =========================================================================

	// Set the output high for 'level' clock cycles.
	always @ (posedge clk) begin
		out <= (rCount <= level) ? 1'b1 : 1'b0;
	end

endmodule


