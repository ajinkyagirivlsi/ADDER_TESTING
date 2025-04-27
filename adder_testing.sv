//...................//11111111111111111111111111111\\.........................
//Adder complete testing : https://www.edaplayground.com/x/cgc5
//copy file at : https://www.edaplayground.com/x/XTGY
//build dut for adder.
//test plan :
		//For 8-bit comb : 256 values, single agent needed. Lets do it !!!
			//	Scenarios --> a. All values : done, b. Corner cases(MSB/LSB): done, c. Extreme case(signed): done.
				
				
/////////////////banckup code ////////////////

module adder(
  input logic [7:0] in1, in2,
  output logic [8:0] out
);
  
  assign out = in1 + in2;
endmodule

interface dut_intf;
  logic [7:0] in1;
  logic [7:0] in2;
  logic [8:0] out;
  
  modport mp_dut(
  	input in1,
    input in2,
    output out
    
  );
  
  modport mp_tb(
  	output in1,
    output in2,
    input out
    
  );
  
endinterface


-------------------------

//test-bench for simple adder
import uvm_pkg::*;
`include "uvm_macros.svh"

module top;
  
  //interface instantiation
  dut_intf dut_iff();
  
  //dut instantiation
  adder dut( .in1(dut_iff.in1),
          	 .in2(dut_iff.in2),
         	 .out(dut_iff.out)
           );
  //////////////////////////////////////
  
  ////////////////////add_seq start/////////////////////////
  
  class add_seq_item extends uvm_sequence_item;
    //`uvm_object_utils(add_seq_item)
    
    //randc logic signed [7:0] in1;
    randc logic [7:0] in1;
  	randc logic [7:0] in2;
  	logic [8:0] out;
    
    `uvm_object_utils_begin(add_seq_item)
    	`uvm_field_int(in1, UVM_ALL_ON)
    	`uvm_field_int(in2, UVM_ALL_ON)
    	`uvm_field_int(out, UVM_ALL_ON)
    `uvm_object_utils_end
    
    
    constraint msb_feature{
      in1[7] == 1;
      in2[7] == 1;
    }
    
    constraint signed_feature{
      in1 < 0;
      in2 == 8'hFF;
    }
    
    function new(string name = "add_seq_item");
      super.new(name);
      
    endfunction
    
  endclass : add_seq_item
  ////////////////////add_seq_item end//////////////////////
  
  ////////////////////add_seq start/////////////////////////
  
  class add_seq extends uvm_sequence#(add_seq_item);
    `uvm_object_utils(add_seq)
    
    add_seq_item seq_item;
    
    function new(string name = "add_seq");
      super.new(name);
    endfunction
    
    task body();
      seq_item = add_seq_item::type_id::create("seq_item");
      repeat(256) begin
        seq_item.signed_feature.constraint_mode(0);
        seq_item.msb_feature.constraint_mode(1);
        start_item(seq_item);
        if(!seq_item.randomize())
          `uvm_error(get_name,"Item randomization failure !!!")
        else begin
          `uvm_info(get_name, "Seq_items randomized value....here update", UVM_LOW)
        end
        finish_item(seq_item);
      end
      
      
    endtask
    
  endclass : add_seq
  ////////////////////add_seq end/////////////////////////
  
  ////////////////////add_scb start/////////////////////////
  
  class add_scb extends uvm_scoreboard;
    `uvm_component_utils(add_scb)
    
    
    uvm_analysis_imp#(add_seq_item, add_scb) recv;
    logic [8:0] computed_sum;
    
    function new(string name = "add_scb", uvm_component parent = null);
      super.new(name, parent);
    endfunction
    
    virtual function void build_phase(uvm_phase phase);
      super.build_phase(phase);
      recv = new("recv", this);
      
    endfunction : build_phase
    
    virtual function void connect_phase(uvm_phase phase);
      super.connect_phase(phase);
      
    endfunction : connect_phase
    
    virtual task run_phase(uvm_phase phase);
      `uvm_info(get_name, "Comparison computation started...", UVM_HIGH);
      
    endtask
    
    function void write(add_seq_item seq_item);
      `uvm_info(get_full_name(), $sformatf("SCOREBOARD RECEIVED: in1=%0d, in2=%0d, out=%0d", 
                                           seq_item.in1, seq_item.in2, seq_item.out), UVM_NONE)
      
      computed_sum = seq_item.in1 + seq_item.in2;
      `uvm_info(get_name, $sformatf("Computed sum: %0d", computed_sum), UVM_NONE)
      
      `uvm_info(get_name, $sformatf("BIN: in1=%b, in2=%b, out=%b, expected=%b",seq_item.in1, seq_item.in2, seq_item.out, computed_sum), UVM_NONE)
      
      if(seq_item.out == computed_sum)
        `uvm_info(get_name, "Test stimuli matched --> Test passed :)", UVM_NONE)
      else
        `uvm_error(get_name, $sformatf("Test stimuli unmatched for out = %0d, in1 = %0d, in2 = %0d --> Test failed :(",seq_item.out, seq_item.in1, seq_item.in2));
        
    endfunction
    
  endclass : add_scb
  ////////////////////add_scb end/////////////////////////
  
  ////////////////////add_monitor start/////////////////////////
  
  class add_monitor extends uvm_monitor;
    `uvm_component_utils(add_monitor)
    
    virtual dut_intf vif;
    add_seq_item seq_item_m;
    uvm_analysis_port#(add_seq_item) send;
    
    function new(string name = "add_monitor", uvm_component parent = null);
      super.new(name, parent);
    endfunction
    
    virtual function void build_phase(uvm_phase phase);
      super.build_phase(phase);
      if(!uvm_config_db#(virtual dut_intf)::get(this, "", "iff", vif))
        `uvm_fatal(get_name, "config db is not getting properly.")
        
      send = new("send",this);
    endfunction : build_phase
    
    virtual task run_phase(uvm_phase phase);
      super.run_phase(phase);
      
      forever begin
        seq_item_m = add_seq_item::type_id::create("seq_item_m");
      
        #10; //delay added as post drv delay
        `uvm_info(get_name, "sampling started", UVM_MEDIUM);
        sampling();
        `uvm_info(get_name, "sampling completed", UVM_MEDIUM);
        send.write(seq_item_m);        
      end
    endtask : run_phase
      
      task sampling();
        seq_item_m.in1 = vif.in1;
        seq_item_m.in2 = vif.in2;
        seq_item_m.out = vif.out;
      endtask
    
  endclass : add_monitor
  ////////////////////add_monitor end/////////////////////////
  
  ////////////////////add_driver start/////////////////////////
  
  class add_driver extends uvm_driver#(add_seq_item);
    `uvm_component_utils(add_driver)
    
    virtual dut_intf vif;
    add_seq_item seq_item;
    
    function new(string name = "add_driver", uvm_component parent = null);
      super.new(name, parent);
    endfunction
    
    virtual function void build_phase(uvm_phase phase);
      super.build_phase(phase);
      if(!uvm_config_db#(virtual dut_intf)::get(this, "", "iff", vif))
        `uvm_fatal(get_name, "config db is not getting properly.")
      
    endfunction : build_phase
    
    virtual task run_phase(uvm_phase phase);
      super.run_phase(phase);
      seq_item = add_seq_item::type_id::create("seq_item");
      forever begin
        seq_item_port.get_next_item(seq_item);
      
        //drive logic
        `uvm_info(get_name, "drive logic started", UVM_MEDIUM);
        drive();
        `uvm_info(get_name, "drive logic completed", UVM_MEDIUM);
      
        seq_item_port.item_done();
      end
    endtask : run_phase
      
      task drive();
        vif.in1 <= seq_item.in1;
        vif.in2 <= seq_item.in2;
        #10;//delay added
      endtask
    
  endclass : add_driver
  ////////////////////add_driver end/////////////////////////
  
  ////////////////////add_agent start/////////////////////////
  
  class add_agent extends uvm_agent;
    `uvm_component_utils(add_agent)
    
    add_driver drv;
    add_monitor mon;
    uvm_sequencer#(add_seq_item) seqr;
    
    function new(string name = "add_agent", uvm_component parent = null);
      super.new(name, parent);
    endfunction
    
    virtual function void build_phase(uvm_phase phase);
      super.build_phase(phase);
      seqr = uvm_sequencer#(add_seq_item)::type_id::create("seqr", this);
      drv = add_driver::type_id::create("add_drv", this);
      mon = add_monitor::type_id::create("mon", this);
      
    endfunction : build_phase
    
    virtual function void connect_phase(uvm_phase phase);
      super.connect_phase(phase);
      //need to connect drv port with seqr export
      drv.seq_item_port.connect(seqr.seq_item_export);
      
    endfunction : connect_phase
    
  endclass : add_agent
  ////////////////////add_agent end/////////////////////////
  
  ////////////////////add_env start/////////////////////////
  
  class add_env extends uvm_env;
    `uvm_component_utils(add_env)
    
    add_agent agent;
    add_scb scb;
    //coverage_collector ***
    
    function new(string name = "add_env", uvm_component parent = null);
      super.new(name, parent);
    endfunction
    
    virtual function void build_phase(uvm_phase phase);
      super.build_phase(phase);
      agent = add_agent::type_id::create("agent", this);
      scb = add_scb::type_id::create("scb", this);
      
    endfunction : build_phase
    
    virtual function void connect_phase(uvm_phase phase);
      super.connect_phase(phase);
      agent.mon.send.connect(scb.recv);
      
    endfunction : connect_phase
    
  endclass : add_env
  ////////////////////add_env end/////////////////////////
  
  ////////////////////add_test start/////////////////////////
  
  class add_test extends uvm_test;
    `uvm_component_utils(add_test)
    
    add_env env;
    add_seq seq;
    
    function new(string name = "add_test", uvm_component parent = null);
      super.new(name, parent);
    endfunction
    
    virtual function void build_phase(uvm_phase phase);
      super.build_phase(phase);
      env = add_env::type_id::create("env", this);
      seq = add_seq::type_id::create("seq");
      
    endfunction : build_phase
    
    virtual function void connect_phase(uvm_phase phase);
      super.connect_phase(phase);
      //connection remaining with sequencer export
      
      
    endfunction : connect_phase
    
    virtual task run_phase(uvm_phase phase);
      super.run_phase(phase);
      phase.raise_objection(this);
      `uvm_info(get_name, "seq is going to started ...", UVM_MEDIUM);
      seq.start(env.agent.seqr);
      `uvm_info(get_name, "seq is ended :)", UVM_MEDIUM);
      phase.drop_objection(this);
      
    endtask
    
  endclass : add_test
  ////////////////////add_test end/////////////////////////
  
  
  //////////////////////////////////////
  
  
  initial begin
    uvm_config_db#(virtual dut_intf)::set(null, "*", "iff", dut_iff);
    `uvm_info("top", "Starting test ...", UVM_LOW);
    
    run_test("add_test");
    
    `uvm_info("top", "Test completed !!!", UVM_LOW);
  end
      
  initial begin
    $dumpfile("file.vcd");
  	$dumpvars;
    #500;
    $finish;
  end
  
endmodule