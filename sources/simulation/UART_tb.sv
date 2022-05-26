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
module UART_tb();
    
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
                   
    // Wire from the 2nd Tx DUT.
    wire wTx2;                  // Output serial line from the DUT.       
    wire wTx2Busy;              // DUTY busy flag.
    wire wTx2Err;               // DUT error line.
    
    // Wire from the Rx DUT.
    wire wRxValid;              // DUTY busy flag.
    wire wRxErr;                // DUT error line.
    
    // Registers to the Tx DUT.
    reg [C_UART_DATA_WIDTH - 1 : 0] rTxData; // Data word input to the Tx DUT.
    reg rTxSend;                // trigger send signal to the DUT.

    // Registers to the Rx DUT.
    wire [C_UART_DATA_WIDTH - 1 : 0] wRxData; // Data word output from the Rx DUT.
    reg rRxAck;                 // trigger send signal to the DUT.
    reg [C_UART_DATA_WIDTH - 1 : 0] rRxData;    // Acquired rx data.
    
    // Wires and register from the mirror toward the UART modules.
    wire wMirSend;
    wire wMirAck;
    wire wMirBusy;
    wire wMirValid;
    wire wMirErrTx;
    wire wMirErrRx;
    wire [C_UART_DATA_WIDTH - 1 : 0] wMirDataIn;
    wire [C_UART_DATA_WIDTH - 1 : 0] wMirDataOut;
    
    
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
    ) DUT_Tx0 (
        .rstb(rRstb),
        .clk(rClk),
        .data(rTxData),
        .send(rTxSend),
        .busy(wTxBusy),
        .error(wTxErr),
        .tx(wTxRx)
    );
    
    // The following modules are the two within the FPGA.
    
    
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
        .data(wMirDataIn),
        .valid(wMirValid),
        .ack(wMirAck),
        .error(wMirErrRx),
        .rx(wTxRx)
    );
    
    // Instantiate the 2nd UART_Tx module.
    UART_Tx #(
        .C_CLK_FRQ(C_CLK_FRQ),
        .C_UART_RATE(C_UART_RATE),
        .C_UART_DATA_WIDTH(C_UART_DATA_WIDTH),
        .C_UART_PARITY(C_UART_PARITY),
        .C_UART_STOP(C_UART_STOP) 
    ) DUT_Tx2 (
        .rstb(rRstb),
        .clk(rClk),
        .data(wMirDataOut),
        .send(wMirSend),
        .busy(wMirBusy),
        .error(wMirErrTx),
        .tx(wTx2)
    );
    
    
    // Instantiate the MIRROR module.
    UART_Mirror #(
        .C_UART_DATA_WIDTH(C_UART_DATA_WIDTH)
    ) DUT_Mirror (
        .rstb(rRstb),
        .clk(rClk),
        .enable(1'b1),
        
        // IOs (passive) of the UART_Rx IOs.
        .dataRx(wRxData),
        .validRx(wRxValid),
        .ackRx(rRxAck),
        .errRx(wRxErr),
        
        // IOs (passive) of the UART_Tx IOs
        .dataTx(),
        .sendTx(),
        .busyTx(),
        .errTx(wTx2Err),
        
        // IOs toward the UART_Tx, UART_Rx modules.
        .txBusy(wMirBusy),
        .txSend(wMirSend),
        .rxValid(wMirValid),
        .rxAck(wMirAck),
        .rxData(wMirDataIn),
        .txData(wMirDataOut),
        .txErr(wMirErrTx),
        .rxErr(wMirErrRx)
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
    
        
    
    // ==========================================================================
    // ==                           UART Tx Stimuli                            ==
    // ==========================================================================
        
    // Data sender process feeding the UART_Tx DUT
    always begin
        
        // Wait a random amount of time.
        #(5 * C_UART_PERIOD);
        #($dist_normal(seed, 10 * C_UART_PERIOD, 2 * C_UART_PERIOD));
                
        // Check if the DUT is free, in case send data.
        if (wTxBusy == 1'b0) begin
            
            // Wait for a clock to occur.
            @(posedge rClk);
            
            // Set data and send flag.
            rTxData <= $urandom_range(0, 255);
            #1 rTxSend <= 1'b1;
        
            // Wait for the busy flag to rise
            wait(wTxBusy == 1'b1);
            @(posedge rClk);
            #1 rTxSend <= 1'b0;
        end
    end
   
   
   
    // ==========================================================================
    // ==                           UART Rx Stimuli                            ==
    // ==========================================================================

    // Data retriever process interrogating the UART_Rx DUT
    always@ (wRxValid) begin
        
        // Check if the DUT has valid data, read them.
        if (wRxValid == 1'b1) begin
            
            // Wait for a clock to occur.
            @(posedge rClk);
            
            // Store the received data.
            rRxData <= wRxData;
            
            // Assert the ack.
            rRxAck <= 1'b1;
        
            // Wait for the valid to drop and reset the ack.
            wait(wRxValid == 1'b0);
            @(posedge rClk);
            #1 rRxAck <= 1'b0;
        end

        // Wait a random amount of time. This on purpose will make missing some
        // received data.
        #($dist_normal(seed, 2 * C_UART_PERIOD, C_UART_PERIOD));
    end
           
endmodule