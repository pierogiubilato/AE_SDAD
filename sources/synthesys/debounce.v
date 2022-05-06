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
// The debounce module receives a single-bit transition from a mechanical switch 
// or button, and "moves" it only if stable fore more than C_Interval ms, to 
// avoid spurious signals. I works for either LTH and HTL transisions.


// -----------------------------------------------------------------------------
// --                                PARAMETERS                               --
// -----------------------------------------------------------------------------
//
// C_CLK_FRQ:       frequency of the clock in [cycles per second] {100000000}. 
// C_INTERVAL:      the time interval the signal must be stable to pass through
//					and reach the fabric. [ms] {10}.


// -----------------------------------------------------------------------------
// --                                I/O PORTS                                --
// -----------------------------------------------------------------------------
//
// rstb:            INPUT, synchronous reset, ACTIVE LOW. 
// clk:             INPUT, master clock.
// in:             	INPUT, the signal from the meachanical switch.
// out:           	OUTPUT: the signal toward the fabric.


// Tool timescale.
`timescale 1 ns / 1 ps

// Behavioural.
module  debounce # (
		parameter C_CLK_FRQ = 100000000,  	// Clock frequency [Hz].
		parameter C_INTERVAL = 0.010   		// Wait interval [ms].
	) (
		input rstb,
		input clk,
		input in,			// Inputs from switch/button.
		output reg out		// Output to fabric.
	);


	// =========================================================================
    // ==                       Parameters derivation                         ==
    // =========================================================================

    // Prepare the counter size so that full counting would take two times the
	// C_INTERVAL to wait for. By checking the counter MSB, it will be equivalent
	// to wait for C_INTERVAL time. 
    localparam C_CYCLES = 2 * C_CLK_FRQ * C_INTERVAL / 1000;
    localparam C_CYCLES_WIDTH = $clog2(C_CYCLES);
   

   	// =========================================================================
    // ==                        Registers and wires                          ==
    // =========================================================================

	// Counters.
	reg [C_CYCLES_WIDTH - 1 : 0] rCount;
	
	// Input fflops.
	reg DFF1, DFF2;
	
	// Control flags.
	wire wClear;		// Clear the counter if '=1';		
	wire wEnable;		// Enable the counter while '=1';


	// =========================================================================
    // ==                      Asynchronous assignments                       ==
    // =========================================================================

	// XOR of the thwo FF to generate counter reset signal.
	assign wClear = (DFF1  ^ DFF2);
	
	// Enable signal, makes the output FF latch the signal from FF2. Inverted,
	// it is also used to stop the counter.
	assign wEnable = (rCount[C_CYCLES_WIDTH - 1]);
	

	// =========================================================================
    // ==                        Synchronous counters                         ==
    // =========================================================================

	// Move the input signal through the two FFs, unless reset forces them clear.
	always @ (posedge clk) begin
		
		// Reset everything to initial condition.
		if (rstb ==  1'b0) begin
			DFF1 <= 1'b0;
			DFF2 <= 1'b0;
		end else begin
			DFF1 <= in;
			DFF2 <= DFF1;
		end
	end

	// Increments the counter if the signal is stable
	always @ (posedge clk) begin
		
		// Reset the counter.
		if (rstb ==  1'b0 || wClear == 1'b1) begin
			rCount <= { C_CYCLES_WIDTH {1'b0} };

		// Count only when the output is not enabled.
		end else begin
			rCount <= (wEnable) ? rCount : rCount + 1;
		end
	end


	// =========================================================================
    // ==                        Synchronous outputs                          ==
    // =========================================================================

	// Synchronous output. Move DFF2 value to the output only when 'wEnable' is
	// driven high (C_CYCLES clks have been counted).
	always @ (posedge clk) begin
		out <= (wEnable) ? DFF2 : out;
	end

endmodule


