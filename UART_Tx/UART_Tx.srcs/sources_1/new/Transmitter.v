`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 08/19/2019 05:51:11 PM
// Design Name: 
// Module Name: Transmitter
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module Transmitter(
    input clk,
    input [7:0] data,
    input transmit,
    input reset,
    output reg TxD
    );
    
    //internal variables
    
    reg [3:0] bit_counter;//Counter to count the 10 bits
    reg [13:0] baudrate_counter; //10,415, counter=clock(100 Mhz) / BR (9600)
    reg [9:0] shiftright_register; //10 bits that will be serially transmitted through UART to the Basys 3 Board
    reg state, next_state; //idle mode and transmitting mode
    reg shift; //shift signal to start shifting the bits in the UART
    reg load;// load signal to start loading the data into the shiftright register, and add start and stop bits
    reg clear;//reset the bit_counter for UART transmission
    
    //UART transmission
    
    always @(posedge clk)
    begin
    if (reset)
    begin
    state<=0; //state is idle
    bit_counter<=0; //counter for bit transmission is reset to 0
    baudrate_counter<=0;
    end
    else begin
    baudrate_counter<=baudrate_counter+1;
    if (baudrate_counter==10415)
    begin
    state<=next_state; //state changes from idle to transmitting
    baudrate_counter<=0;//resetting counter
    if (load) //if load is asserted
    shiftright_register<={1'b1, data,1'b0};//the data is loaded into the register, 10-bits
    if (clear)//if clear is asserted
    bit_counter<=0;
    if (shift)//if shift signal is asserted
    begin
    shiftright_register<=shiftright_register>>1;//start shifting the data and transmitting bit by bit
    bit_counter<=bit_counter+1;
    end
    end
    end
    end
    //Mealy Machine, State Machine
    always @(posedge clk)
    begin
    load<=0; //setting load equal to 0
    shift<=0; //initially 0
    clear<=0; //initially 0
    TxD<=1; //when set to 1, there is no transmission in progress
    
    case(state) //idle state
    0: begin
    if (transmit) //transmit button is pressed
    begin 
    next_state<=1; //it moves/swtcihes to transmission state
    load<=1; //start loading the bits
    shift<=0; //no shift at this point;
    clear<=0; // to avoid any clearing of any counter
    end

    else begin //if transmit button is not asserted/pressed
    next_state<=0; //stays at the idle mode
    TxD<=1; //no transmission
    end
    end
    
    1: begin //transmitting state
    if (bit_counter==10)
    begin
    next_state<=0; //it should switch from transmission mode to idle mode
    clear<=1; //clear all the counters
   end
    else begin
    next_state<=1; //stay in the transmit state
    TxD<=shiftright_register[0];
    shift<=1;//continue shifting the data, new bit arrives at the RMB
    end
    end
    default: next_state<=0;
    endcase
          
     end
endmodule
