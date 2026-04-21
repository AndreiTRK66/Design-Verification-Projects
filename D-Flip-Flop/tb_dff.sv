`timescale 1ns / 1ps



class transaction;
    logic din;
    logic dout = 1'b0;
    
    function transaction copy();
        copy = new();
        copy.din = this.din;
        copy.dout = this.dout;
    endfunction
    function void display(input string s);
        $display("[%s] din: %0b | dout: %0b",s,din,dout);
    endfunction
endclass

class generator;
    transaction tr;
    mailbox #(transaction) mbx;
    mailbox #(transaction) mbxref;
    int count;
    event sconext;
    event done;
    function new(mailbox #(transaction) mbx, mailbox #(transaction) mbxref);
        this.mbx = mbx;
        this.mbxref = mbxref;
        tr = new();
    endfunction
    
    task run();
        //tr = new();
        repeat(count) begin
           // assert(tr.randomize()) else $display("Ranzomization failed");
            tr.din = 1'bx;
            mbx.put(tr.copy());
            mbxref.put(tr.copy());
            tr.display("GEN");
            @(sconext);
        end
        ->done;
    endtask

endclass

class driver;
    transaction tr;
    virtual dff_if vif;
    mailbox #(transaction) mbx;
    
    function new(mailbox #(transaction) mbx);
        this.mbx = mbx;
    endfunction
    
    task reset();
        vif.rst <= 1'b1;
        repeat(5) @(posedge vif.clk);
        vif.rst <= 1'b0;
        @(posedge vif.clk);
        $display("[DRV] RESET DONE");      
    endtask
    
    task run();
        forever begin
            mbx.get(tr);
            vif.din <= tr.din;
            @(posedge vif.clk);
            tr.display("DRV");
            vif.din <= 1'b0;
            @(posedge vif.clk);
        end
    endtask

endclass

class monitor;
    transaction tr;
    mailbox #(transaction) mbx;
    virtual dff_if vif;
    
    function new(mailbox #(transaction) mbx);
        this.mbx = mbx;
    endfunction
    
    task run();
    forever begin
        tr = new();
        repeat(2) @(posedge vif.clk);
        tr.dout = vif.dout;
        mbx.put(tr);
        tr.display("MON");    
    end
    endtask

endclass

class scoreboard;
transaction tr;
transaction trref;
mailbox #(transaction) mbx;
mailbox #(transaction) mbxref;

event sconext;
function new(mailbox #(transaction) mbx, mailbox #(transaction) mbxref);
    this.mbx = mbx;
    this.mbxref = mbxref;
endfunction

task run();
logic expected_dout;
    forever begin
        mbx.get(tr);
        mbxref.get(trref);
        tr.display("SCO");
        trref.display("REF");
        
        if(trref.din ===1'bx) begin
            expected_dout = 1'b0;
            end
            else begin
            expected_dout = trref.din;
        end
        
        if(tr.dout === expected_dout)
            $display("[SCO]: DATA MATCHED");
        else
            $display("[SCO]: DATA MISMATCHED");
        $display("-----------------------");
        ->sconext;    
    end
endtask

endclass

class enviroment;
    generator gen;
    driver drv;
    scoreboard sco;
    monitor mon;
    event next;
    
    mailbox #(transaction) gdmbx; //gen -drv
    mailbox #(transaction) msmbx; //mon - sco
    mailbox #(transaction) mbxref; //gen - sco
    
    virtual dff_if vif;
    
    function new(virtual dff_if vif);
        gdmbx = new();
        mbxref = new();
        msmbx = new();
        
        gen = new(gdmbx, mbxref);
        drv = new(gdmbx);
        mon = new(msmbx);
        sco = new(msmbx, mbxref);
        
        this.vif = vif;
        
        drv.vif = this.vif;
        mon.vif = this.vif;
        
        gen.sconext = next;
        sco.sconext = next;
    endfunction
    
    task pre_test();
        drv.reset();    
    endtask
    
    task test();
        fork
            gen.run();
            drv.run();
            mon.run();
            sco.run();
        join_any
    endtask
    
    task post_test();
        wait(gen.done.triggered);
        $finish();
    endtask
    
    task run();
        pre_test();
        test();
        post_test();
    endtask
endclass

module tb_dff(

    );
    dff_if vif();
    dff dut(vif);
    initial begin
        vif.clk <= 0;
        
    end
    always #10 vif.clk = ~vif.clk;
    enviroment env;
    
    initial begin
        env = new(vif);
        env.gen.count = 5;
        env.run();
       
    end
      
endmodule
