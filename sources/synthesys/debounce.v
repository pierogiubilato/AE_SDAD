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
// The debounce module receives a single-bit signal from a mechanical switch or
// button and samples it to avoid instability.


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
		output reg 	out		// Output to fabric.
	);

	 // =========================================================================
    // ==                       Parameters derivation                         ==
    // =========================================================================

    // Get the 1 bit transmission period cycle in terms of main clock cycles.
    localparam C_CYCLES = C_CLK_FRQ * C_INTERVAL / 1000;
    localparam C_CYCLES_WIDTH = $clog2(C_CYCLES);
   

   	// =========================================================================
    // ==                        Registers and wires                          ==
    // =========================================================================

	// Counters.
	reg  [C_CYCLES_WIDTH - 1 : 0] q_reg;
	reg  [C_CYCLES_WIDTH - 1 : 0] q_next;
	
	// Input fflops.
	reg DFF1, DFF2;
	
	// Control flags.
	wire q_add;
	wire q_reset;



	// =========================================================================
    // ==                      Asynchronous assignments                       ==
    // =========================================================================

	//contenious assignment for counter control
	assign q_reset = (DFF1  ^ DFF2);			// xor input FF to look for level chage to reset counter
	assign q_add = ~(q_reg[C_CYCLES_WIDTH - 1]);	// add to counter when q_reg msb is equal to 0
	

	// =========================================================================
    // ==                        Synchronous counters                         ==
    // =========================================================================

	// Combo counter to manage q_next	
	always @ (q_reset, q_add, q_reg) begin
		case( {q_reset , q_add} )
			2'b00 :
				q_next <= q_reg;
			2'b01 :
				q_next <= q_reg + 1;
			default :
				q_next <= { C_CYCLES_WIDTH {1'b0} };
		endcase 	
	end
	
	// Flip flop inputs and q_reg update
	always @ (posedge clk) begin
		if (rstb ==  1'b0) begin
			DFF1 <= 1'b0;
			DFF2 <= 1'b0;
			q_reg <= { C_CYCLES_WIDTH {1'b0} };
		end else begin
			DFF1 <= in;
			DFF2 <= DFF1;
			q_reg <= q_next;
		end
	end
	
	
	// =========================================================================
    // ==                        Synchronous outputs                          ==
    // =========================================================================

	// Synchronous output.
	always @ (posedge clk) begin
		out <= (q_reg[C_CYCLES_WIDTH - 1] == 1'b1) ? DFF2 : out;
	end

endmodule


