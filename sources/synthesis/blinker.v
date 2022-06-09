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
// The blinker module generates a 50% duty cycle square-wave of a given period.


// -----------------------------------------------------------------------------
// --                                PARAMETERS                               --
// -----------------------------------------------------------------------------
//
// C_CLK_FRQ:       frequency of the clock in [cycles per second] {100000000}. 
// C_PERIOD:        the wave period, expressed in [ms].


// -----------------------------------------------------------------------------
// --                                I/O PORTS                                --
// -----------------------------------------------------------------------------
//
// rstb:            INPUT, synchronous reset, ACTIVE LOW. 
// clk:             INPUT, master clock.
// out:           	OUTPUT: the signal toward the fabric.


// Tool timescale.
`timescale 1 ns / 1 ps

// Behavioural.
module  blinker # (
		parameter C_CLK_FRQ = 100_000_000, 	// Clock frequency [Hz].
		parameter C_PERIOD = 100   		// Wait interval [ms].
	) (
		input rstb,
		input clk,
		output out		
	);


	// =========================================================================
    // ==                       Parameters derivation                         ==
    // =========================================================================

    // Prepare the counter size so that full counting would take the C_PERIOD to
    // wait for. By checking the counter MSB, it will be equivalent
	// to wait for half period time. 
    localparam C_CYCLES = C_CLK_FRQ * C_PERIOD / 1000;
    localparam C_CYCLES_WIDTH = $clog2(C_CYCLES);
   

   	// =========================================================================
    // ==                        Registers and wires                          ==
    // =========================================================================

	// Counters.
	reg [C_CYCLES_WIDTH - 1 : 0] rCount;
	
	
	// =========================================================================
    // ==                      Asynchronous assignments                       ==
    // =========================================================================

	// XOR of the thwo FF to generate counter reset signal.
	assign out = rCount[C_CYCLES_WIDTH - 1];
	
	
	// =========================================================================
    // ==                        Synchronous counters                         ==
    // =========================================================================

	// Increments the counter if the signal is stable
	always @ (posedge clk) begin
		
		// Reset the counter.
		if (rstb ==  1'b0) begin
			rCount <= { C_CYCLES_WIDTH {1'b0} };
        
		// Count.
		end else begin
			rCount <= rCount + 1;
		end
	end

endmodule


