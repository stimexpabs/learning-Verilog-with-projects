`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 08/19/2019 06:44:36 PM
// Design Name: 
// Module Name: Top_Module
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


module Top_Module(
    input [7:0] data,
    input clk,
    input transmit,
    input reset,
    output TxD,
    output TxD_debug,
    output transmit_debug,
    output btn_debug,
    output clk_debug
    );
    
    wire transmit_out;
    
     assign Tx_debug = TxD;
       assign transmit_debug = transmit_out;
       assign btn_debug = reset;
       assign clk_debug = clk;
       
    
    Transmitter T1(clk, reset, transmit, data, TxD);
    Debounce_Signals DB(clk, reset, transmit_out);
    
       
endmodule
