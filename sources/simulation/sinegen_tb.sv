/*#############################################################################\
##                                                                            ##
##       APPLIED ELECTRONICS - Physics Department - University of Padova      ##
##                                                                            ## 
##       ---------------------------------------------------------------      ##
##                                                                            ##
##             Sigma Delta Analogue to Digital didactical example             ##
##                                                                            ##
\#############################################################################*/


// Set timescale (default time unit if not otherwise specified).
`timescale 1us / 1ns

// Define Module for Test Fixture
module sinegen_tb ();

    // ==========================================================================
    // ==                               Parameters                             ==
    // ==========================================================================
    
    // Timing properties.
    parameter C_CLK_FRQ         = 100000000;    // Main clock frequency [Hz].
    parameter C_CLK_JTR         = 50;           // Main clock jitter [ps].
    localparam real C_CLK_PERIOD = 1E9 / C_CLK_FRQ;  // Master clock period [ns].
        
    
    // ==========================================================================
    // ==                              Seeding                                 ==
    // ==========================================================================
    
    // Seeding for (repeatable) random number generation.
    static int seed = $urandom + 0;


    // ==========================================================================
    // ==                                Signals                               ==
    // ==========================================================================
    
    // Timing signal.
    reg rRstb;
    reg rClk;
    
    // Data in.
    reg [7 : 0] rFrq;

    // Data out.
    wire [7 : 0] wData;



    // ==========================================================================
    // ==                                 DUTs                                 ==
    // ==========================================================================

    // Instantiate the UUT
    sinegen #(
        .C_CLK_FRQ(C_CLK_FRQ)
    ) DUT (
        .rstb(rRstb), 
        .clk(rClk), 
        .frq({rFrq[3:0], 10'b0000000000}), 
        .data(wData)
    );


    // Initialize Inputs
    initial begin
		$display ($time, " << Starting the Simulation >> ");
        rRstb = 1'b0;
		rClk = 1'b0;
        #200 rRstb = 1'b1;
        rFrq <= 1;
    end

    // Main clock generation. This process generates a clock with period equal to 
    // C_CLK_PERIOD. It also add a pseudorandom jitter, normally distributed 
    // with mean 0 and standard deviation equal to 'kClockJitter'.  
    always begin
        #(0.001 * $dist_normal(seed, 1000.0 * C_CLK_PERIOD / 2, C_CLK_JTR));
        rClk = ! rClk;
    end  
	
    // Pseudosequence.
	always begin
		
        // Set a frequency.
        rFrq <= 10;
        #1000ms;
        
        // Set a frequency.
        rFrq <= 100;
        #1000ms;
        
        // Wait.
        rFrq <= 200;
        #1000ms;
		
		// Stop simulation.
        $finish;
	end

endmodule