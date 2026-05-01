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
        
        wire A_is_signed = (opcode == 3'b001 || opcode == 3'b010 || opcode == 3'b100 || opcode == 3'b110);
        wire B_is_signed = (opcode == 3'b001 || opcode == 3'b100 || opcode == 3'b110);
        
        wire Asign = A[31] & A_is_signed;
        wire Bsign = B[31] & B_is_signed;
        wire Psign = Asign ^ Bsign; 
        
        wire [31:0 ] Amag = (Asign ? ~A + 32'b1 : A);
        wire [31:0] Bmag = (Bsign ? ~B + 32'b1 : B);
        
        wire [32:0] sum = {1'b0, accumulator[63:32]} + {1'b0, multiplicand};
        wire [32:0] diff = {1'b0, accumulator [62:31]} - {1'b0, multiplicand};
        
        wire [63:0] product = (Psign ? ~accumulator + 64'b1 : accumulator);
        
        wire [31:0] raw_quotient = accumulator[31:0];
        wire [31:0] quotient = Psign ? (~raw_quotient + 32'd1) : raw_quotient;
        wire [31:0] raw_remainder = accumulator[63:32];
        wire [31:0] remainder = Asign ? (~raw_remainder + 32'd1) : raw_remainder;
        
        wire isDiv = opcode[2];
        wire isDivZero = isDiv & (B == 0);
        wire isSignOverflow = (opcode == 3'b100 || opcode == 3'b110) & (A == 32'h80000000) & (B == 32'hFFFFFFFF);
        
        always @ (posedge clk) begin
        
        
        if(start) begin
        
            counter <= 6'b0;
        
            if(isDivZero) begin
                done <= 1'b1;
                busy <= 1'b0;
                result <= (opcode[1] ? A : 32'hFFFFFFFF);
            end
            
            else if(isSignOverflow) begin
                done <= 1'b1;
                busy <= 1'b0;
                result <= (opcode[1] ? 32'b0 : 32'h80000000);
            end
            
            else begin
        
            done <= 1'b0;
            busy <= 1'b1;
            
            multiplicand <= (isDiv ? Bmag : Amag);
            accumulator[31:0] <= (isDiv? Amag : Bmag);
            
            accumulator[63:32] <= 32'b0;
            
            end
            
        end
        
        else if (busy) begin
        
            if (counter < 6'd32) begin
            
                if(isDiv) begin
                
                    if(diff[32] == 1'b1) begin
                        accumulator <= {accumulator[62:0], 1'b0} ;
                    end
                
                    else begin
                        accumulator <= {diff[31:0], accumulator[30:0], 1'b1};
                    end
                
                end
                
                else begin
                
                    if(accumulator[0]) begin
                        accumulator <= {sum, accumulator[31:1]};
                    end
                    
                    else begin
                        accumulator <= {1'b0, accumulator[63:1]};
                    end
                               
                end
                
                counter <= counter + 1'b1;
           
            end
            
            if(counter == 6'd32) begin
                busy <= 1'b0;
                done <= 1'b1;
                
                case (opcode)
                    3'b000 : result <= accumulator[31:0];
                    3'b001 : result <= product[63:32];
                    3'b010 : result <= product[63:32];
                    3'b011 : result <= product[63:32];
                    3'b100 : result <= quotient;
                    3'b101 : result <= raw_quotient;   
                    3'b110 : result <= remainder;
                    3'b111 : result <= raw_remainder;
                endcase
            end
            
        end
        
        end
        
endmodule
