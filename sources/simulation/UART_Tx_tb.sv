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
module UART_Tx_tb();
    
    // ==========================================================================
    // ==                               Parameters                             ==
    // ==========================================================================
    
    // Timing properties.
    parameter C_CLK_FRQ         = 100000000;    // Main clock frequency [Hz].
    parameter C_CLK_JTR         = 50;           // Main clock jitter [ps].
    localparam real C_CLK_PERIOD = 1E9 / C_CLK_FRQ;  // Master clock period [ns].
        
    // UART parameters.
    parameter C_UART_RATE       = 1000000;      // RS232 speed (frequency), [BAUD].
    parameter C_UART_DATA_WIDTH = 8;            // RS232 data word width [bit].
    parameter C_UART_PARITY     = 0;            // RS232 parity bit, {0,1}.
    parameter C_UART_STOP       = 1;            // RS232 stop bits, {0,1,2}.
    localparam real C_UART_PERIOD = 1E9 / C_UART_RATE;  // UART clock period [ns].



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
    reg rUART_Clk;              // UART Clock.
    
    // Wire from the Tx DUT.
    wire wTxRx;                 // Output serial line from the DUT.       
    wire wTxBusy;               // DUTY busy flag.
    wire wTxErr;                // DUT error line.
                   
    // Wire from the Rx DUT.
    wire wRxValid;              // DUTY busy flag.
    wire wRxErr;                // DUT error line.
    
    // Registers to the Tx DUT.
    reg [C_UART_DATA_WIDTH - 1:0] rData; // Data word input to the Tx DUT.
    reg rTxSend;                // trigger send signal to the DUT.

    // Registers to the Rx DUT.
    wire [C_UART_DATA_WIDTH - 1:0] wData; // Data word output from the Rx DUT.
    reg rRxAck;                 // trigger send signal to the DUT.

    



    // ==========================================================================
    // ==                                 DUTs                                 ==
    // ==========================================================================

    // Instantiate the UART_Tx module.
    UART_Tx #(
        .C_CLK_FRQ(C_CLK_FRQ),
        .C_UART_RATE(C_UART_RATE),
        .C_UART_DATA_WIDTH(C_UART_DATA_WIDTH) 
    ) DUT (
        .rstb(rRstb),
        .clk(rClk),
        .data(rTxData),
        .send(rTxSend),
        .busy(wTxBusy),
        .error(wTxErr),
        .tx(wTxRx)
    );
    
    // Instantiate the UART_Rx module.
    UART_Rx #(
        .C_CLK_FRQ(C_CLK_FRQ),
        .C_UART_RATE(C_UART_RATE),
        .C_UART_DATA_WIDTH(C_UART_DATA_WIDTH) 
    ) DUT (
        .rstb(rRstb),
        .clk(rClk),
        .data(wRxData),
        .valid(wRxValid),
        .ack(rRxAck),
        .error(wRxErr),
        .rx(wTxRx)
    );
    
        
    // ==========================================================================
    // ==                                Stimuli                               ==
    // ==========================================================================
    
    // Initialization sequence.   
    initial begin 
        
        // Set initial values.
        rRstb = 1'b1;
        rClk = 1'b0; 
        rUART_Clk = 1'b0; 
        rTxSend = 1'b0;
        rRxAck = 1'b0;
             
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
    
    // UART clock generation (with no jitter, as it is super-slow).
    always begin
        #(C_UART_PERIOD / 2);
        rUART_Clk <= ! rUART_Clk;
    end      
    
    // Data sender process feeding the UART_Tx DUT.
    always begin //@(posedge rClk)
        
        // Wait a random amount of time.
        #($dist_normal(seed, 2 * C_UART_PERIOD, C_UART_PERIOD));
                
        // Check if the DUT is free, in case send data.
        if (wTxBusy == 1'b0) begin
            
            // Wait for a clock to occur.
            @(posedge rClk);
            
            // Set data and send flag.
            rData <= $urandom_range(0, 255);
            #1 rTxSend <= 1'b1;
        
            // Wait for the busy flag to rise
            wait(wTxBusy == 1'b1);
            @(posedge rClk);
            #1 rTxSend <= 1'b0;
        end
   end        
endmodule