`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 08/19/2019 06:28:28 PM
// Design Name: 
// Module Name: Debounce_Signals
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


module Debounce_Signals #(parameter threshold =1000000)
(
    input clk,//input clock
    input btn, //input buttons for transmit and reset
    output reg transmit //transmit signa;
    );
    
    reg button_ff1=0; //button FF for synchronization, initially set to 0
    reg button_ff2=0; //button FF for synchronization, initially set to 0
    reg [30:0] count=0; //20 bitsc count for increment and decerement when button is pressed or released.
    
    //First use two FF to synchronize the button signal, "clk", clock domain
    
    always @(posedge clk)
    begin
    button_ff1<=btn;
    button_ff2<=button_ff1;
    end
    
    //when push button is pressed or released, we increment or decrement the counter
   
 always @(posedge clk)
 begin
 if (button_ff2) // if button_ff2 is high
 begin
 if (~&count)//if it isn't at the count limit, make sure you won't count up at the limit. First AND all count and then not the AND
 count<=count+1; //when btn is pressed, count up
 end
 else begin
 if (|count) // if count has at least 1 in it, making sure no subtract when count is 0
 count<=count-1; //when btn is released, count down 
 end
 if (count>threshold) //if the count is larger than the threshhold
 transmit<=1; //debounced signal is 1
 else
 transmit<=0; //debounced signal is 0
 end
 endmodule
    
