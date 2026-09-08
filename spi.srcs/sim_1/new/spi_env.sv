`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Engineer: Aditya Raut
// Design Name: spi_env
// Description:
//   Top-level UVM Environment containing Agent and Scoreboard.
//////////////////////////////////////////////////////////////////////////////////

`ifndef SPI_ENV_SV
`define SPI_ENV_SV

import uvm_pkg::*;
`include "uvm_macros.svh"

class spi_env #(parameter int DATA_WIDTH = 8) extends uvm_env;
    `uvm_component_param_utils(spi_env #(DATA_WIDTH))

    spi_agent      #(DATA_WIDTH) agent;
    spi_scoreboard #(DATA_WIDTH) scoreboard;

    function new(string name = "spi_env", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        agent      = spi_agent#(DATA_WIDTH)::type_id::create("agent", this);
        scoreboard = spi_scoreboard#(DATA_WIDTH)::type_id::create("scoreboard", this);
    endfunction

    function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        agent.monitor.item_collected_port.connect(scoreboard.item_export);
    endfunction

endclass

`endif // SPI_ENV_SV
