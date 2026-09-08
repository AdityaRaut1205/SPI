`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Engineer: Aditya Raut
// Design Name: spi_monitor
// Description:
//   Passive UVM Monitor observing SPI parallel exchanges and bus activity.
//////////////////////////////////////////////////////////////////////////////////

`ifndef SPI_MONITOR_SV
`define SPI_MONITOR_SV

import uvm_pkg::*;
`include "uvm_macros.svh"

class spi_monitor #(parameter int DATA_WIDTH = 8) extends uvm_monitor;
    `uvm_component_param_utils(spi_monitor #(DATA_WIDTH))

    virtual spi_interface #(DATA_WIDTH) vif;
    uvm_analysis_port #(spi_transaction #(DATA_WIDTH)) item_collected_port;

    function new(string name = "spi_monitor", uvm_component parent = null);
        super.new(name, parent);
        item_collected_port = new("item_collected_port", this);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(virtual spi_interface #(DATA_WIDTH))::get(this, "", "vif", vif))
            `uvm_fatal("MONITOR", "Failed to retrieve vif from uvm_config_db")
    endfunction

    task run_phase(uvm_phase phase);
        spi_transaction #(DATA_WIDTH) tr;

        wait (vif.rst == 1'b0);
        @(posedge vif.clk);

        forever begin
            @(posedge vif.clk);
            if (vif.start) begin
                tr = spi_transaction#(DATA_WIDTH)::type_id::create("tr");
                tr.cpol           = vif.cpol;
                tr.cpha           = vif.cpha;
                tr.master_tx_data = vif.master_tx_data;
                tr.slave_tx_data  = vif.slave_tx_data;

                wait (vif.master_done == 1'b1);
                @(posedge vif.clk);
                tr.master_rx_data = vif.master_rx_data;
                tr.slave_rx_data  = vif.slave_rx_data;

                `uvm_info("MONITOR", $sformatf("Captured SPI Transaction: %s", tr.convert2string()), UVM_HIGH)
                item_collected_port.write(tr);
            end
        end
    endtask

endclass

`endif // SPI_MONITOR_SV
