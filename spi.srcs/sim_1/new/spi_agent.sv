`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Engineer: Aditya Raut
// Design Name: spi_agent
// Description:
//   UVM Agent encapsulating Driver, Sequencer, Monitor, and Coverage.
//////////////////////////////////////////////////////////////////////////////////

`ifndef SPI_AGENT_SV
`define SPI_AGENT_SV

import uvm_pkg::*;
`include "uvm_macros.svh"

class spi_agent #(parameter int DATA_WIDTH = 8) extends uvm_agent;
    `uvm_component_param_utils(spi_agent #(DATA_WIDTH))

    spi_driver    #(DATA_WIDTH) driver;
    spi_sequencer #(DATA_WIDTH) sequencer;
    spi_monitor   #(DATA_WIDTH) monitor;
    spi_coverage  #(DATA_WIDTH) coverage;

    function new(string name = "spi_agent", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        monitor = spi_monitor#(DATA_WIDTH)::type_id::create("monitor", this);
        coverage = spi_coverage#(DATA_WIDTH)::type_id::create("coverage", this);

        if (get_is_active() == UVM_ACTIVE) begin
            driver    = spi_driver#(DATA_WIDTH)::type_id::create("driver", this);
            sequencer = spi_sequencer#(DATA_WIDTH)::type_id::create("sequencer", this);
        end
    endfunction

    function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        if (get_is_active() == UVM_ACTIVE) begin
            driver.seq_item_port.connect(sequencer.seq_item_export);
        end
        monitor.item_collected_port.connect(coverage.analysis_export);
    endfunction

endclass

`endif // SPI_AGENT_SV
