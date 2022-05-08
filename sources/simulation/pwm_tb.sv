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
`timescale 1ns / 1ps

// Define Module for Test Fixture
module pwm_tb ();

    // ==========================================================================
    // ==                               Parameters                             ==
    // ==========================================================================
    
    // Timing properties.
    parameter C_CLK_FRQ         = 100000000;    // Main clock frequency [Hz].
    parameter C_CLK_JTR         = 50;           // Main clock jitter [ps].
    localparam real C_CLK_PERIOD = 1E9 / C_CLK_FRQ;  // Master clock period [ns].
        
    // PWM propeties.
    parameter C_LEVEL_WIDTH     = 8;            // PWM range width.

    
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
    reg [C_LEVEL_WIDTH - 1 : 0] rLevel;

    // DAta out.
    wire wOut;



    // ==========================================================================
    // ==                                 DUTs                                 ==
    // ==========================================================================

    // Instantiate the UUT
    pwm #(
        .C_CLK_FRQ(C_CLK_FRQ),
        .C_LEVEL_WIDTH(C_LEVEL_WIDTH)
    ) DUT (
        .rstb(rRstb), 
        .clk(rClk), 
        .level(rLevel), 
        .out(wOut)
    );


    // Initialize Inputs
    initial begin
		$display ($time, " << Starting the Simulation >> ");
        rRstb = 1'b0;
		rClk = 1'b0;
        #200 rRstb = 1'b1;
        rLevel = 1'b0;
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
		
        for (int i = 0; i <= C_LEVEL_WIDTH; i++) begin
            rLevel = 2**i - 1;
            #100us; 
		end
		
		// Stop simulation.
        $finish;
	end

endmodule