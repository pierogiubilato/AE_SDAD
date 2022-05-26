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
module UART_Hello_tb();

    
    // ==========================================================================
    // ==                               Parameters                             ==
    // ==========================================================================
    
    // Timing properties.
    parameter C_CLK_FRQ         = 100_000_000;  // Main clock frequency [Hz].
    parameter C_CLK_JTR         = 50;           // Main clock jitter [ps].
    localparam real C_CLK_PERIOD = 1E9 / C_CLK_FRQ;  // Master clock period [ns].
        
    // UART parameters.
    parameter C_UART_RATE       = 921_600;      // UART speed (frequency), [BAUD].
    parameter C_UART_DATA_WIDTH = 8;            // UART data word width [bit].
    parameter C_UART_STOP       = 1;            // UART stop bits, {0,1,2}.
    parameter C_UART_PARITY     = 0;            // UART parity bit, {0,1}.
    localparam real C_UART_PERIOD = 1E9 / C_UART_RATE;  // UART clock period [ns].

    // Hello message.
    parameter C_MSG = "12345";
    parameter C_MSG_LEN = 5;


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
    
    // IOS to/from the Tx DUT.
    wire wTxSend;               // Tx Send trigger.    
    wire wTxBusy;               // Tx busy flag.
    wire [C_UART_DATA_WIDTH - 1 : 0] wTxData; // Data to the Tx module.
    wire wTxErr;                // Tx error line.
    wire wTxRx;                 // Output serial line from the DUT.       
    
    // IOs to/from the Hello DUT.
    reg rHelloSend;             // Trigger to the HEllo module.
    wire wHelloBusy;            // Busy from the Hello module.
    
    // IOs to/from the Rx DUT.
    wire wRxValid;              // DUTY busy flag.
    reg rRxAck;                 // trigger send signal to the DUT.
    wire [C_UART_DATA_WIDTH - 1 : 0] wRxData; // Data word output from the Rx DUT.
    wire wRxErr;                // DUT error line.
    reg [C_UART_DATA_WIDTH - 1 : 0] rRxData;    // Acquired rx data.
    
   
   
    // ==========================================================================
    // ==                                 DUTs                                 ==
    // ==========================================================================

    // Instantiate the UART_Tx module.
    UART_Tx #(
        .C_CLK_FRQ(C_CLK_FRQ),
        .C_UART_RATE(C_UART_RATE),
        .C_UART_DATA_WIDTH(C_UART_DATA_WIDTH),
        .C_UART_PARITY(C_UART_PARITY),
        .C_UART_STOP(C_UART_STOP) 
    ) DUT_Tx (
        .rstb(rRstb),
        .clk(rClk),
        .busy(wTxBusy),
        .send(wTxSend),
        .data(wTxData),
        .error(wTxErr),
        .tx(wTxRx)
    );
    
    // Instantiate the UART_Rx module.
    UART_Rx #(
        .C_CLK_FRQ(C_CLK_FRQ),
        .C_UART_RATE(C_UART_RATE),
        .C_UART_DATA_WIDTH(C_UART_DATA_WIDTH), 
        .C_UART_PARITY(C_UART_PARITY),
        .C_UART_STOP(C_UART_STOP) 
    ) DUT_Rx (
        .rstb(rRstb),
        .clk(rClk),
        .data(wRxData),
        .valid(wRxValid),
        .ack(rRxAck),
        .error(wRxErr),
        .rx(wTxRx)
    );
    
    // Instantiate the Hello module.
    UART_Hello #(
        .C_UART_DATA_WIDTH(C_UART_DATA_WIDTH),
        .C_MSG(C_MSG),
        .C_MSG_LEN(C_MSG_LEN)
    ) DUT_Hello (
        .rstb(rRstb),
        .clk(rClk),
        
        // IOs control.
        .send(rHelloSend),
        .busy(wHelloBusy),
        
        // IOs to/from Tx module.
        .txBusy(wTxBusy),
        .txSend(wTxSend),
        .txData(wTxData),
        .txErr(wTxErr)
    );        
    
    
    // ==========================================================================
    // ==                            Timing Stimuli                            ==
    // ==========================================================================
     
    // Initialization sequence.   
    initial begin 
        
        // Set initial values.
        rRstb = 1'b1;
        rClk = 1'b0; 
        rUART_Clk = 1'b0; 
        rHelloSend = 1'b0;
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
    
        
    
    // ==========================================================================
    // ==                           UART Tx Stimuli                            ==
    // ==========================================================================
        
    // Data sender process triggering the UART_Hello DUT.
    always begin
        
        // Wait a random amount of time.
        #(5 * C_UART_PERIOD);
        #($dist_normal(seed, 10 * C_UART_PERIOD, 2 * C_UART_PERIOD));
                
        // Check if the DUT is free, in case send data.
        if (wHelloBusy == 1'b0) begin
            
            // Wait for a clock to occur.
            @(posedge rClk);
            
            // Trigger the send flag.
            #1 rHelloSend <= 1'b1;
        
            // Wait for the busy flag to rise
            wait(wHelloBusy == 1'b1);
            @(posedge rClk);
            #1 rHelloSend <= 1'b0;
        end
    end
      
   
    // ==========================================================================
    // ==                           UART Rx Stimuli                            ==
    // ==========================================================================

    // Data retriever process interrogating the UART_Rx DUT
    always@ (wRxValid) begin
        
        // Time display format.    
        $timeformat(-9, 0, " ns");
                
        // Check if the DUT has valid data, read them.
        if (wRxValid == 1'b1) begin
            
            $display("\nValid found: %t", $time);
            
            // Wait for a clock to occur.
            @(posedge rClk);
            
            // Store the received data.
            rRxData <= wRxData;
            $display("Data latched: %t", $time);
            
            // Assert the ack.
            rRxAck <= 1'b1;
            $display("Ack asserted: %t", $time);
        
            // Wait for the valid to drop and reset the ack.
            wait(wRxValid == 1'b0);
            $display("Valid released: %t", $time);
        
            // Release ack.
            @(posedge rClk);
            #1 rRxAck <= 1'b0;
            $display("Ack released: %t", $time);
        
        end

        // Wait a random amount of time. This on purpose will make missing some
        // received data.
        #($dist_normal(seed, 2 * C_UART_PERIOD, C_UART_PERIOD));
    end
           
endmodule