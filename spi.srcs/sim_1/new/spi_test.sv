`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Engineer: Aditya Raut
// Design Name: spi_test
// Description:
//   UVM Tests for SPI.
//////////////////////////////////////////////////////////////////////////////////

`ifndef SPI_TEST_SV
`define SPI_TEST_SV

import uvm_pkg::*;
`include "uvm_macros.svh"

// 1. Master Comprehensive Regression Test (Default)
class spi_test extends uvm_test;
    `uvm_component_utils(spi_test)

    spi_env #(8) env;
    spi_regression_sequence #(8) seq;

    function new(string name = "spi_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        env = spi_env#(8)::type_id::create("env", this);
    endfunction

    task run_phase(uvm_phase phase);
        phase.raise_objection(this);
        phase.phase_done.set_drain_time(this, 10_000);

        `uvm_info("SPI_TEST", ">>> Starting Master SPI Regression Test <<<", UVM_LOW)
        seq = spi_regression_sequence#(8)::type_id::create("seq");
        seq.start(env.agent.sequencer);

        phase.drop_objection(this);
    endtask
endclass

// 2. Specialized Random Test
class spi_rand_test extends uvm_test;
    `uvm_component_utils(spi_rand_test)

    spi_env #(8) env;
    spi_random_sequence #(8) seq;

    function new(string name = "spi_rand_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        env = spi_env#(8)::type_id::create("env", this);
    endfunction

    task run_phase(uvm_phase phase);
        phase.raise_objection(this);
        phase.phase_done.set_drain_time(this, 10_000);

        `uvm_info("SPI_RAND_TEST", ">>> Starting SPI Random Test <<<", UVM_LOW)
        seq = spi_random_sequence#(8)::type_id::create("seq");
        seq.num_transactions = 50;
        seq.start(env.agent.sequencer);

        phase.drop_objection(this);
    endtask
endclass

// 3. Dedicated Modes Test (Mode 0, 1, 2, 3)
class spi_modes_test extends uvm_test;
    `uvm_component_utils(spi_modes_test)

    spi_env #(8) env;
    spi_modes_sequence #(8) seq;

    function new(string name = "spi_modes_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        env = spi_env#(8)::type_id::create("env", this);
    endfunction

    task run_phase(uvm_phase phase);
        phase.raise_objection(this);
        phase.phase_done.set_drain_time(this, 10_000);

        `uvm_info("SPI_MODES_TEST", ">>> Starting SPI 4-Modes Test <<<", UVM_LOW)
        seq = spi_modes_sequence#(8)::type_id::create("seq");
        seq.start(env.agent.sequencer);

        phase.drop_objection(this);
    endtask
endclass

`endif // SPI_TEST_SV
