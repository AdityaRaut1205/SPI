`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Engineer: Aditya Raut
// Design Name: spi_sequencer
// Description: UVM Sequencer for SPI Transactions.
//////////////////////////////////////////////////////////////////////////////////

`ifndef SPI_SEQUENCER_SV
`define SPI_SEQUENCER_SV

import uvm_pkg::*;
`include "uvm_macros.svh"

class spi_sequencer #(parameter int DATA_WIDTH = 8) extends uvm_sequencer #(spi_transaction #(DATA_WIDTH));
    `uvm_component_param_utils(spi_sequencer #(DATA_WIDTH))

    function new(string name = "spi_sequencer", uvm_component parent = null);
        super.new(name, parent);
    endfunction
endclass

`endif // SPI_SEQUENCER_SV
