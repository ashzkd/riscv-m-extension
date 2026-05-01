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
    
    wire A_is_signed = (opcode == 3'b001 || opcode == 3'b010);
    wire B_is_signed = (opcode == 3'b001);
    
    wire Asign = A[31] & A_is_signed;
    wire Bsign = B[31] & B_is_signed;
    wire Psign = Asign ^ Bsign; 
    
    wire [31:0 ] Amag = (Asign ? ~A + 32'b1 : A);
    wire [31:0] Bmag = (Bsign ? ~B + 32'b1 : B);
    
    wire [32:0] sum = {1'b0, accumulator[63:32]} + {1'b0, multiplicand};
    wire [63:0] product = (Psign ? ~accumulator + 32'b1 : accumulator);
    
    always @ (posedge clk) begin
    
    if(start) begin
        counter <= 6'b0;
        done <= 1'b0;
        multiplicand <= Amag;
        accumulator[63:32] <= 32'b0;
        accumulator[31:0] <= Bmag;
        busy <= 1'b1;
    end
    
    else if (busy) begin
    
        if (counter < 6'd32) begin
        
            if(accumulator[0]) begin
                accumulator <= {sum, accumulator[31:1]};
            end
            else begin
                accumulator <= {1'b0, accumulator[63:1]};
            end
            
            counter <= counter + 1'b1;
        end
      
        if(counter == 6'd32) begin
            busy <= 1'b0;
            done <= 1'b1;
            
            case (opcode)
                3'b000 : result <= accumulator[31:0];
                default : result <= product[63:32];
            endcase
        end
        
    end
     
    end
    
endmodule
