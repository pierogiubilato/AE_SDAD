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

// Testbench.
module registry_tb();
    
    // ==========================================================================
    // ==                               Parameters                             ==
    // ==========================================================================
    
    // Timing properties.
    parameter C_CLK_FRQ         = 100000000;    // Main clock frequency [Hz].
    parameter C_CLK_JTR         = 50;           // Main clock jitter [ps].
    localparam real C_CLK_PERIOD = 1E9 / C_CLK_FRQ;  // Master clock period [ns].
        
    // UART parameters.
    parameter C_UART_DATA_WIDTH = 8;            // UART data word width [bit].

    // Registry parameters.
    parameter C_REG_WIDTH = 5;                  // Register(s) width [bit].

    // Derived registry parameters.
    localparam C_REG_COUNT_WIDTH = C_UART_DATA_WIDTH - C_REG_WIDTH; 
    localparam C_REG_COUNT = 2**C_REG_COUNT_WIDTH;
    localparam C_REG_PORT_WIDTH = C_REG_COUNT * C_REG_WIDTH;



    // ==========================================================================
    // ==                              Seeding                                 ==
    // ==========================================================================
        
    // Seeding for (repeatable) random number generation.
    static int seed = $urandom + 0;
    
    
    // ==========================================================================
    // ==                                Signals                               ==
    // ==========================================================================
    
    // Timing signal.
    reg rRstb;                  // Reset (active low).
    reg rClk;                   // Clock.
        
    // DUT I/Os
    reg [C_UART_DATA_WIDTH - 1 : 0] rData;      // Data word input to the registry.
    reg rValid;                                 // Valid flag to the DUT.
    wire wAck;                                  // Acknowledge from the DUT.
    wire [C_REG_WIDTH - 1 : 0] wRegister [C_REG_COUNT - 1 : 0];  // Register(s) output.
    
    // Local mapping.
    wire [C_REG_PORT_WIDTH - 1 : 0] wRegPort;
    genvar i;
    generate
        for (i = 0; i < C_REG_COUNT; i = i + 1) begin
            assign wRegister[i] = wRegPort[(i + 1) *C_REG_WIDTH - 1 : i * C_REG_WIDTH];    
        end
    endgenerate

    // Support mapping: make address and data explicit to help debug.
    wire [C_UART_DATA_WIDTH - C_REG_WIDTH : 0] wAdd;
    wire [C_REG_WIDTH : 0] wDta;
    assign wAdd = rData[C_UART_DATA_WIDTH - 1 : C_REG_WIDTH];
    assign wDta = rData[C_REG_WIDTH - 1 : 0];
    

    // ==========================================================================
    // ==                                  DUT                                 ==
    // ==========================================================================

    // Instantiate the UART_Tx module.
    registry #(
        .C_UART_DATA_WIDTH(C_UART_DATA_WIDTH),
        .C_REG_WIDTH(C_REG_WIDTH)
    ) DUT (
        .rstb(rRstb),
        .clk(rClk),
        .data(rData),
        .valid(rValid),
        .ack(wAck),
        .register(wRegPort)
    );
    
        
    // ==========================================================================
    // ==                            Timing Stimuli                            ==
    // ==========================================================================
    
    // Initialization sequence.   
    initial begin 
        
        // Set initial values.
        rRstb = 1'b1;
        rClk = 1'b0; 
        rValid = 1'b0;
                     
        // Generate first reset.
        #(2 * C_CLK_PERIOD) rRstb <= 1'b0;
        #(10 * C_CLK_PERIOD) rRstb <= 1'b1;
    end
    
    // Main clock generation. This process generates a clock with period equal to 
    // C_CLK_PERIOD. It also add a pseudorandom jitter, normally distributed 
    // with mean 0 and standard deviation equal to 'kClockJitter'.  
    always begin
        #(0.001 * $dist_normal(seed, 1000.0 * C_CLK_PERIOD / 2, C_CLK_JTR));
        rClk = ! rClk;
    end      
    
   
    // ==========================================================================
    // ==                          registry stimuli                            ==
    // ==========================================================================
        
    // Data sender process feeding the UART_Tx DUT
    always begin
        
        // Wait a random amount of time.
        #($dist_normal(seed, 10 * C_CLK_PERIOD, 2 * C_CLK_PERIOD));
                
        // Wait for a clock to occur.
        @(posedge rClk);
            
        // Set data and send flag.
        rData <= $urandom_range(0, 255);
        #1 rValid <= 1'b1;
        
        // Wait for the ack flag to rise.
        wait(wAck == 1'b1);
            
        // Reset the 'valid' flack at clock transiiton.
        @(posedge rClk);
        #1 rValid <= 1'b0;

    end

           
endmodule