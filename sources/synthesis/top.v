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
// Timing
// C_CLK_FRQ:       frequency of the clock in [cycles per second] {100000000}. 
// C_DBC_INTERVAL:  debouncing interval on external "mech" inputs [ms].
//
// UART interface
// C_UART_RATE:     transmission bit frequency [BAUD] {1000000}.
// C_UART_DATA_WIDTH: transmission word width [bit] {8}.
// C_UART_PARITY:   transmission parity bit [bit] {0, 1}.
// C_UART_STOP:     transmission stop bit(s) [bit] {0, 1, 2}.



// -----------------------------------------------------------------------------
// --                                I/O PORTS                                --
// -----------------------------------------------------------------------------
//
// sysRstb:         INPUT, synchronous reset, ACTIVE LOW.
// sysClk:          INPUT, master clock. Defines the timing of the transmission.
//
// [3:0] sw:        INPUT, connected to the board switches.
// [3:0] btn:       INPUT, connected to the board push buttons.
// [3:0] led:       OUTPUT, connected to the board LEDs.
// [11:0] ledRGB:   INPUT, connected to the board RGB LEDs, grouped by 3 for
//                  each LED: [11:9] = R,G,B for led 3, [8:6] = R,G,B for led 2,
//                  [5:3] = R,G,B for led 1, [2:0] = R,G,B for led 0,
//
// UART_Rx:         INPUT, the bit-line carrying the UART communication.
// UART_Tx:         OUTPUT, the bit-line sourcing the UART communication.




// -----------------------------------------------------------------------------
// --                            DEBUG FEATURES                               --
// -----------------------------------------------------------------------------

// LEDs
// led[3]:          Blinks when the firmware is loaded.
// led[2]:          
// led[1]:          
// led[0]:          If ON indicates the UART mirroring is enabled.
//
// Switches:
// sw[3]:           
// sw[2]:           
// sw[1]:           
// sw[0]:           MIRROR: enables UART mirroring (for debug).
//
//
// Buttons:
// btn[3]:          
// btn[2]:          
// btn[1]:          
// btn[0]:          Send "Hello": send "Hhllo" through the UART Tx line.



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
        parameter C_SYSCLK_FRQ = 100_000_000,   // System clock frequency [Hz].
        parameter C_DBC_INTERVAL = 10,          // Debouncing interval [ms].              
        parameter C_BLINK_PERIOD = 100,         // Blinking period [ms].              
        
        // UART properties.
        parameter C_UART_RATE = 115_200,        // UART BAUD rate.
        //parameter C_UART_RATE = 921_600,        // UART BAUD rate.
        parameter C_UART_DATA_WIDTH = 8,        // UART word width.
        parameter C_UART_PARITY = 0,            // UART parity bits {0, 1, 2}.
        parameter C_UART_STOP = 1,              // UART stop bits {0, 1}.

        // Hello message 
        parameter C_HELLO_MSG = "Hello World! ",
        parameter C_HELLO_MSG_LEN = 13,
                
        // Debug registers.
        parameter C_REG_WIDTH = 4               // Registry register width [bit].
    ) (
       // Timing.
        input sysRstb,                  // System reset, active low.
        input sysClk,                   // System clock, SE input.
                
        // External switches and buttons inputs.
        input [3:0] sw,                 // Switches.
        input [3:0] btn,                // Push buttons.
        
        // Standard LEDs outputs.
        output [3:0] led,   
        output [11:0] ledRGB,
        
        // Reference outputs.
        output PWM_Out_p,                 // Programmable PWM out, positive.
        output PWM_Out_n,                 // Programmable PWM out, negative.
        
        // UART iterface (reference direction is controller toward FPGA).
        output UART_Rx_cpy,             // Data from the controller toward the FPGA.
        output UART_Tx_cpy,             // Data from the FPGA toward the controller.
                
        // UART iterface (reference direction is controller toward FPGA).
        input UART_Rx,              // Data from the controller toward the FPGA.
        output UART_Tx              // Data from the FPGA toward the controller.
    );
    

    // =========================================================================
    // ==                          Derived parameters                         ==
    // =========================================================================
    
    // Registry mapping.
    localparam C_REG_COUNT_WIDTH = C_UART_DATA_WIDTH - C_REG_WIDTH;
    localparam C_REG_COUNT = 2**C_REG_COUNT_WIDTH;
        
    
    // =========================================================================
    // ==                                Wires                                ==
    // =========================================================================
    
    // Timing.
    wire wSysRstb;      // System reset (from the board push-button).
    wire wSysClk;       // System clock (from the board oscillator).
        
    // Wires from the debouncer(s) toward the fabric.
    wire [3:0] wSw;     // Switches.
    wire [3:0] wBtn;    // Push buttons.


    // Wires from the UART Rx toward the registry module.
    //wire wRxRegData;
    //wire wRxRegValid;
    //wire wRegRxAck;
    
    // Registry mapping wires.
    //wire [C_REG_WIDTH * C_REG_COUNT - 1 : 0] wRegPort;
    //wire [C_REG_WIDTH - 1 : 0] wRegReg [C_REG_COUNT - 1 : 0];    
    
    
    // -------------------------------------------------------------------------
    // --                           UART wiring                               --
    // -------------------------------------------------------------------------
    
    // Wires from the mirror toward the controlling modules.
    wire wMirBusyTx;
    wire wMirValidRx;
    wire wMirErrTx;
    wire wMirErrRx;
    
    // Wires from the mirror toward the Rx and Tx modules.
    wire wMirTxSend;
    wire wMirRxAck;
    wire [C_UART_DATA_WIDTH - 1 : 0] wMirTxData;
    
    // Wires from UART TX module.       
    wire wTxBusy;
    wire wTxErr;
    
    // Wires from UART Rx module.
    wire wRxValid;
    wire [C_UART_DATA_WIDTH - 1 : 0] wRxData;
    wire wRxErr;
    
    // Wires from the Hello module to the mirror one.
    wire wHelloBusy;
    wire wHelloSend;
    wire [C_UART_DATA_WIDTH - 1 : 0] wHelloData;
        
    // UART
    wire wRx;
    wire wTx;
    
    
    // -------------------------------------------------------------------------
    // --                      DEBUG / Facilities wiring                      --
    // -------------------------------------------------------------------------
    
    // Data from the sinewave generator.
    wire [7 : 0] wSineDAta;
    
    // PWM.
    wire wPWM;
    
    // DEBUG blinker.
    wire wBlink;
    
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
    debounce #(
        .C_CLK_FRQ(C_SYSCLK_FRQ),
        .C_INTERVAL(C_DBC_INTERVAL)
    ) DBC_BTN (
        .rstb(1'b1),    // Note that the reset debouncer never reset!
        .clk(wSysClk),
        .in(sysRstb),
        .out(wSysRstb)
    );
    
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
    // ==                          UART interface                             ==
    // =========================================================================
    
    // UART Rx.
    UART_Rx #(
        .C_CLK_FRQ(C_SYSCLK_FRQ),
        .C_UART_RATE(C_UART_RATE),
        .C_UART_DATA_WIDTH(C_UART_DATA_WIDTH),
        .C_UART_PARITY(C_UART_PARITY),
        .C_UART_STOP(C_UART_STOP)
    ) URx (
        .rstb(wSysRstb),
        .clk(wSysClk),
        
        .valid(wRxValid),
        .ack(wMirRxAck),
        .data(wRxData),
        .error(wRxErr),
        .rx(wRx)
    );    

    // UART Tx.
    UART_Tx #(
        .C_CLK_FRQ(C_SYSCLK_FRQ),
        .C_UART_RATE(C_UART_RATE),
        .C_UART_DATA_WIDTH(C_UART_DATA_WIDTH),
        .C_UART_PARITY(C_UART_PARITY),
        .C_UART_STOP(C_UART_STOP)
    ) UTx (
        .rstb(wSysRstb),
        .clk(wSysClk),
        
        .busy(wTxBusy),
        .send(wMirTxSend),
        .data(wMirTxData),
        .error(wTxErr),
        .tx(wTx)
    );    

    // UART mirroring module (used for debug).
    UART_Mirror #(
        .C_UART_DATA_WIDTH(C_UART_DATA_WIDTH)
    ) UMir (
        .rstb(wSysRstb),
        .clk(wSysClk),
        .enable(wSw[0]),    // sw[0] controls the mirror module.
        
        // IOs pass-through of the UART_Rx IOs.
        .validRx(),
        .ackRx(),
        .dataRx(),
        .errRx(),
        
        // IOs pass-through from/to the UART_Tx.
        .busyTx(wMirBusy),
        .sendTx(wHelloSend),
        .dataTx(wHelloData),
        .errTx(wMirErrTx),
        
        // IOs toward the UART_Rx module.
        .rxValid(wRxValid),
        .rxAck(wMirRxAck),
        .rxData(wRxData),
        .rxErr(wRxErr),
        
        // IOs toward the UART_Tx module.
        .txBusy(wTxBusy),
        .txSend(wMirTxSend),
        .txData(wMirTxData),
        .txErr(wTxErr)
    ); 
    
    // UART hello module (used for debug).
    UART_Hello #(
        .C_UART_DATA_WIDTH(C_UART_DATA_WIDTH),
        .C_MSG(C_HELLO_MSG),
        .C_MSG_LEN(C_HELLO_MSG_LEN)
    ) UHello (
        .rstb(wSysRstb),
        .clk(wSysClk),
        
        // IOs control.
        .send(wBtn[0] && ~wHelloBusy),
        .busy(wHelloBusy),
                        
        // IOs toward the UART mirror.
        .txBusy(wMirBusy),
        .txSend(wHelloSend),
        .txData(wHelloData),
        .txErr(wMirErrTx)
    );    
    

    // =========================================================================
    // ==                   SINE generator and PWM modulator                  ==
    // =========================================================================
    
    // SINE generator.
    sinegen # (
        .C_CLK_FRQ(C_SYSCLK_FRQ)
    ) SINE (
        .rstb(wSysRstb),
		.clk(wSysClk),
		.frq({16'b0000_0000_0010_0000}),    // Use Rx line to set the frequency, multiplied by 128.
		.data(wSineData)  // Connects the output directly to the PMOD pin.  
    );
    
    
    // PWM modulator.
    pwm # (
        .C_CLK_FRQ(C_SYSCLK_FRQ),
        .C_LEVEL_WIDTH(8)
    ) PWM (
        .rstb(wSysRstb),
		.clk(wSysClk),
		.level((wSw[1]) ? wSineData : wRxData),    // Use Rx line to set the level.
		.out(wPWM)            // Connects the output directly to the PMOD pin.  
    );
        
    
    // =========================================================================
    // ==                           DEBUG services                            ==
    // =========================================================================
    
    blinker #(
        .C_CLK_FRQ(C_SYSCLK_FRQ),
        .C_PERIOD(C_BLINK_PERIOD)
    ) BLINK (
        .rstb(wSysRstb),
        .clk(wSysClk),
        .out(wBlink)
    );
      
    
    // =========================================================================
    // ==                          DEBUG Registry                             ==
    // =========================================================================
/*    registry #(
        .C_UART_DATA_WIDTH(C_UART_DATA_WIDTH),
        .C_REG_WIDTH(C_REG_WIDTH)
    ) REG (
        .rstb(wSysRstb),
        .clk(wSysClk),
        .data(wRxRegData),
        .valid(wRxRegValid),
        .ack(wRegRxAck),
        .register(wRegPort),
        .dataRaw(wRxDataWord)
    );
    
    // Remap registry output.
    generate 
        for (i = 0; i < C_REG_COUNT; i=i+1) begin
            assign wRegReg[i] = wRegPort[(i+1) * C_REG_WIDTH - 1 : i * C_REG_WIDTH];
        end
    endgenerate
*/    
    
    

    // =========================================================================
    // ==                              Routing                                ==
    // =========================================================================
    
    // UART.
    assign wRx = UART_Rx;
    assign UART_Tx = wTx;
    
    // Debug UART copies.
    assign UART_Rx_cpy = wRx;
    assign UART_Tx_cpy = wTx;
    
    // LEDs.
    assign led[3] = wBlink;         // Blinking LED.
    assign led[2] = wBtn[1];
    assign led[1] = wSw[1];         // Switch between PWM level and sine.
    assign led[0] = wSw[0];         // UART Mirror enabled.
  
    // PWM Ground.
    assign PWM_Out_p = wPWM;
    assign PWM_Out_n = 1'b0;
    
    // Connect registers 0,1,2,3 LSBs to RGB LEDs.  
    //assign ledRGB = {wRegReg[3][2:0], wRegReg[2][2:0], wRegReg[1][2:0], wRegReg[0][2:0]};
    //assign ledRGB[11 : 8] = wSw;
    //assign ledRGB[7 : 0] = wRxData; 
    assign ledRGB[7 : 0] = wSineData;
    
//    // Blinking LED register.
//    reg [23:0] rCount = 0;
     
//    // Simple counter process.
//    always @ (posedge(wSysClk)) begin
//        rCount <= rCount + 1;
//    end

endmodule
