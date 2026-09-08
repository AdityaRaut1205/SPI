`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Engineer: Aditya Raut
// Design Name: spi_driver
// Description:
//   UVM Driver for SPI verification.
//////////////////////////////////////////////////////////////////////////////////

`ifndef SPI_DRIVER_SV
`define SPI_DRIVER_SV

import uvm_pkg::*;
`include "uvm_macros.svh"

class spi_driver #(parameter int DATA_WIDTH = 8) extends uvm_driver #(spi_transaction #(DATA_WIDTH));
    `uvm_component_param_utils(spi_driver #(DATA_WIDTH))

    virtual spi_interface #(DATA_WIDTH) vif;

    function new(string name = "spi_driver", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(virtual spi_interface #(DATA_WIDTH))::get(this, "", "vif", vif))
            `uvm_fatal("DRIVER", "Failed to retrieve vif from uvm_config_db")
    endfunction

    task run_phase(uvm_phase phase);
        spi_transaction #(DATA_WIDTH) tr;

        vif.start          <= 1'b0;
        vif.cpol           <= 1'b0;
        vif.cpha           <= 1'b0;
        vif.master_tx_data <= '0;
        vif.slave_tx_data  <= '0;
        vif.slave_tx_load  <= 1'b0;

        wait (vif.rst == 1'b0);
        repeat (10) @(posedge vif.clk);
        `uvm_info("DRIVER", "Reset released. Driver is ready.", UVM_LOW)

        forever begin
            seq_item_port.get_next_item(tr);

            if (tr.delay > 0) begin
                repeat (tr.delay) @(posedge vif.clk);
            end

            while (vif.master_busy) begin
                @(posedge vif.clk);
            end

            // Step 1: Configure clock mode and preload slave data
            @(posedge vif.clk);
            vif.cpol          <= tr.cpol;
            vif.cpha          <= tr.cpha;
            vif.slave_tx_data <= tr.slave_tx_data;
            vif.slave_tx_load <= 1'b1;

            @(posedge vif.clk);
            vif.slave_tx_load <= 1'b0;

            // Allow clock polarity to settle into slave synchronizers
            repeat (6) @(posedge vif.clk);

            // Step 2: Assert start pulse with master data
            vif.master_tx_data <= tr.master_tx_data;
            vif.start          <= 1'b1;
            `uvm_info("DRIVER", $sformatf("Driving SPI: Mode %0d (CPOL=%0b, CPHA=%0b) | MasterTX=0x%02h, SlaveTX=0x%02h",
                      {tr.cpol, tr.cpha}, tr.cpol, tr.cpha, tr.master_tx_data, tr.slave_tx_data), UVM_HIGH)

            @(posedge vif.clk);
            vif.start <= 1'b0;

            // Wait for transfer completion
            wait (vif.master_done == 1'b1);
            repeat (2) @(posedge vif.clk);

            seq_item_port.item_done();
        end
    endtask

endclass

`endif // SPI_DRIVER_SV
