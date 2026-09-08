`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Engineer: Aditya Raut
// Design Name: spi_transaction
// Description:
//   UVM Sequence Item representing an SPI full-duplex transaction.
//////////////////////////////////////////////////////////////////////////////////

`ifndef SPI_TRANSACTION_SV
`define SPI_TRANSACTION_SV

import uvm_pkg::*;
`include "uvm_macros.svh"

class spi_transaction #(parameter int DATA_WIDTH = 8) extends uvm_sequence_item;

    // Stimulus fields
    rand bit [DATA_WIDTH-1:0] master_tx_data;
    rand bit [DATA_WIDTH-1:0] slave_tx_data;
    rand bit                  cpol;
    rand bit                  cpha;
    rand int unsigned         delay;

    // Response / Observation fields
    bit [DATA_WIDTH-1:0]      master_rx_data;
    bit [DATA_WIDTH-1:0]      slave_rx_data;

    // Constraints
    constraint c_delay { delay inside {[0:10]}; }

    function new(string name = "spi_transaction");
        super.new(name);
    endfunction

    `uvm_object_param_utils_begin(spi_transaction #(DATA_WIDTH))
        `uvm_field_int(master_tx_data, UVM_ALL_ON | UVM_HEX)
        `uvm_field_int(slave_tx_data,  UVM_ALL_ON | UVM_HEX)
        `uvm_field_int(cpol,           UVM_ALL_ON)
        `uvm_field_int(cpha,           UVM_ALL_ON)
        `uvm_field_int(master_rx_data, UVM_ALL_ON | UVM_HEX)
        `uvm_field_int(slave_rx_data,  UVM_ALL_ON | UVM_HEX)
        `uvm_field_int(delay,          UVM_ALL_ON | UVM_DEC)
    `uvm_object_utils_end

    virtual function string convert2string();
        return $sformatf("CPOL=%0b CPHA=%0b [Mode %0d] | MasterTX=0x%02h -> SlaveRX=0x%02h | SlaveTX=0x%02h -> MasterRX=0x%02h",
                         cpol, cpha, {cpol, cpha}, master_tx_data, slave_rx_data, slave_tx_data, master_rx_data);
    endfunction

endclass

`endif // SPI_TRANSACTION_SV
