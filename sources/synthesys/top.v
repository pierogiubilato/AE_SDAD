/*#############################################################################\
##                                                                            ##
##       APPLIED ELECTRONICS - Physics Department - University of Padova      ##
##                                                                            ## 
##       ---------------------------------------------------------------      ##
##                                                                            ##
##             Sigma Delta Analogue to Digital didactical example             ##
##                                                                            ##
\#############################################################################*/

// The top module is the topmost wrapper of the whole project, and contains
// all the I/O ports used by the FPGA.


// -----------------------------------------------------------------------------
// --                                PARAMETERS                               --
// -----------------------------------------------------------------------------
//
// C_CLK_FRQ:       frequency of the clock in [cycles per second] {100000000}. 
// C_TRX_RATE:      transmission bit frequency [BAUD] {1000000}.
// C_DBC_INTERVAL:  debouncing interval on external "mech" inputs [ms].


// -----------------------------------------------------------------------------
// --                                I/O PORTS                                --
// -----------------------------------------------------------------------------
//
// rstb:            INPUT, synchronous reset, ACTIVE LOW. Asserting 'rstb' while
//                  'busy' is high will likely corrupt the communication channel.
// clk:             INPUT, master clock. Defines the timing of the transmission.
// ack:             INPUT, ACTIVE HIGH. Tells the module the 'data' port has been
//                  read and/or the 'error' condition has been acknowledged. The 
//                  module will not parse further data until the 'ack' is asserted.
// [7:0] data:      OUTPUT, data byte. The received data byte. It will stay valid
//                  until 'ack' is asserted. If other arrives before 'ack' is
//                  asserted, they will be lost and an error will generate.
//                  available for at All bits must be settled by the 'clk'
//                  rising edge when 'send' is high, and must remain valid for
//                  the entire clock cycle.
// valid:           OUTPUT, indicates when the data on the 'data' port are valid.
// rx:              INPUT, the bit-line carrying the UART communication.
// error:           OUTPUT: either a parity error or missed input data. The
//                  error condition will stop the module from receiving further
//                  data, until it is cleared through an 'ack' assertion.
//


// -----------------------------------------------------------------------------
// --                                Libraries                                --
// -----------------------------------------------------------------------------

/*============================================================================*\
||                                                                            ||
||                            WARNING: PROTOTYPE!                             ||
||                                                                            ||
/*============================================================================*/


// Tool timescale.
`timescale 1 ns / 1 ps

// Behavioural.
module top # (
        
        // Timing.
        parameter C_SYSCLK_FRQ = 100_000_000,   // SYstem clock frequency.
        parameter C_DBC_INTERVAL = 10,          // Debouncing interval [ms].              
        
        // UART properties.
        parameter C_UART_DATA_WIDTH = 8,
        parameter C_UART_PARITY = 1,
        parameter C_UART_STOP = 1
    ) (
        
        // Timing.
        input sysRstb,                  // System reset, active low.
        input sysClk,                   // System clock, SE input.
                
        // External switches and buttons inputs.
        input [3:0] sw,                 // Switches.
        input [3:0] btn,                // Push buttons.
        
        // Standard LEDs outputs.
        output [3:0] led,   
        output [2:0] ledRGB_0,
        output [2:0] ledRGB_1,
        output [2:0] ledRGB_2,
        output [2:0] ledRGB_3,
        
        // RGB LEDs output, it is an array of 4 vectors of 3 bit each.
        //output reg [2:0] rLedRGB [0 : 3],   

        // UART iterface (reference direction is controller toward FPGA).
        input UART_Rx,              // Data from the controller toward the FPGA.
        output UART_Tx              // Data from the FPGA toward the controller.
    );
    

    // =========================================================================
    // ==                                Wires                                ==
    // =========================================================================
    
    // Timing.
    wire wSysRstb;      // System reset (from the board push-button).
    wire wSysClk;       // System clock (from the board oscillator).
        
    // Wires from the debouncer(s) toward the fabric.
    wire [3:0] wSw;     // Switches.
    wire [3:0] wBtn;    // Push buttons.
    
        
    
    // =========================================================================
    // ==                            I/O buffering                            ==
    // =========================================================================
    
    // System clock buffer. The IBUFG primitive ensures a clock network is 
    // connected to the buffer output.
    IBUFG clk_inst (
        .O(wSysClk),
        .I(sysClk)
    );
    
    // Input debouncer(s).
    // -------------------------------------------------------------------------
    genvar i;
    
    // Reset button.
    //debounce #(
    //    .C_CLK_FRQ(C_SYSCLK_FRQ),
    //    .C_INTERVAL(C_DBC_INTERVAL)
    //) DBC_BTN (
    //    .rstb(1'b1),    // Note that the reset debouncer never reset!
    //    .clk(wSysClk),
    //    .in(sysRstb),
    //    .out(wSysRst)
    //);
    assign wSysRstb = sysRstb;
 
    
    // Buttons.
    generate 
        for (i = 0; i < 4; i=i+1) begin
            debounce #(
                .C_CLK_FRQ(C_SYSCLK_FRQ),
                .C_INTERVAL(C_DBC_INTERVAL)
            ) DBC_BTN (
                .rstb(wSysRstb),
                .clk(wSysClk),
                .in(btn[i]),
                .out(wBtn[i])
            );
        end
    endgenerate
    
    // Switches.
    generate 
        for (i = 0; i < 4; i=i+1) begin
            debounce #(
                .C_CLK_FRQ(C_SYSCLK_FRQ),
                .C_INTERVAL(C_DBC_INTERVAL)
            ) DBC_SW (
                .rstb(wSysRstb),
                .clk(wSysClk),
                .in(sw[i]),
                .out(wSw[i])
            );
        end
    endgenerate
    
    
    // =========================================================================
    // ==                              Routing                                ==
    // =========================================================================
    
    
    
    assign led[1] = wBtn[1];
    assign led[2] = wBtn[2];
    assign led[3] = wBtn[3];
    
    assign ledRGB_0[0] = wSw[0];
    assign ledRGB_0[1] = wSw[1];
    assign ledRGB_0[2] = wSw[2];
    
    // Static
    reg [23:0] rCount = 0;
    
    assign led[0] = rCount[23];
    
    // Simple process
    always @ (posedge(wSysClk)) begin
        rCount <= rCount + 1;
    end

endmodule
