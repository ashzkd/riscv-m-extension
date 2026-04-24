`timescale 1ns / 1ps

module md_unit(
    input clk,
    input [31:0] A, B,
    input start,
    output reg [31:0] result,
    input [2:0] opcode,
    output reg done
    );
    
    reg [31:0] multiplicand;
    reg [63:0] accumulator;
    reg [5:0] counter;
    reg busy;
    
    wire [32:0] sum = {1'b0, accumulator[63:32]} + {1'b0, multiplicand};
    
    always @ (posedge clk) begin
    
    if(start) begin
        counter <= 6'b0;
        done <= 1'b0;
        multiplicand <= A;
        accumulator[63:32] <= 32'b0;
        accumulator[31:0] <= B;
        busy <= 1'b1;
    end
    
    else if (busy) begin
        if(accumulator[0]) begin
            accumulator <= {sum, accumulator[31:1]};
        end
        else begin
            accumulator <= {1'b0, accumulator[63:1]};
        end
        
        counter <= counter + 1'b1;
        
        if(counter == 6'd32) begin
            busy <= 1'b0;
            done <= 1'b1;
            result <= accumulator[31:0];
        end
        
    end
    
    end
    
endmodule
