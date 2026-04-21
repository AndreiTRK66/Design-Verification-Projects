`timescale 1ns / 1ps


interface dff_if;
    logic clk;
    logic rst;
    logic din;
    logic dout;
endinterface

/* module dff(dff_if vif);

always @(posedge vif.clk)
    begin
        if(vif.rst == 1'b1)
            vif.dout <= 1'b0;
        else
            vif.dout <= vif.din;
            
       end
endmodule

*/
module dff (dff_if vif);
  
  always@(posedge vif.clk)
    begin
      if(vif.rst == 1'b1)
        vif.dout <= 1'b0;
      else if (vif.din >= 1'b0)
         vif.dout <= vif.din;
      else
         vif.dout <= 1'b0;
    end
  
endmodule
