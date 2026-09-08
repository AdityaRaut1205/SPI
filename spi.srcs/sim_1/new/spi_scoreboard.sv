`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Engineer: Aditya Raut
// Design Name: spi_scoreboard
// Description:
//   Self-checking UVM Scoreboard for SPI protocol verification.
//////////////////////////////////////////////////////////////////////////////////

`ifndef SPI_SCOREBOARD_SV
`define SPI_SCOREBOARD_SV

import uvm_pkg::*;
`include "uvm_macros.svh"

class spi_scoreboard #(parameter int DATA_WIDTH = 8) extends uvm_scoreboard;
    `uvm_component_param_utils(spi_scoreboard #(DATA_WIDTH))

    uvm_analysis_imp #(spi_transaction #(DATA_WIDTH), spi_scoreboard #(DATA_WIDTH)) item_export;

    int num_transactions = 0;
    int mosi_matches     = 0;
    int mosi_mismatches  = 0;
    int miso_matches     = 0;
    int miso_mismatches  = 0;
    int mode_counts[4];

    function new(string name = "spi_scoreboard", uvm_component parent = null);
        super.new(name, parent);
        item_export = new("item_export", this);
        for (int i=0; i<4; i++) mode_counts[i] = 0;
    endfunction

    virtual function void write(spi_transaction #(DATA_WIDTH) tr);
        bit mosi_ok, miso_ok;
        int mode_idx;

        num_transactions++;
        mode_idx = {tr.cpol, tr.cpha};
        mode_counts[mode_idx]++;

        // 1. Verify MOSI Path: Master TX -> Slave RX
        if (tr.master_tx_data === tr.slave_rx_data) begin
            mosi_matches++;
            mosi_ok = 1'b1;
        end else begin
            mosi_mismatches++;
            mosi_ok = 1'b0;
            `uvm_error("SCB_MOSI_MISMATCH", $sformatf("[FAIL MOSI] MasterTX: 0x%02h != SlaveRX: 0x%02h (Mode %0d)",
                       tr.master_tx_data, tr.slave_rx_data, mode_idx))
        end

        // 2. Verify MISO Path: Slave TX -> Master RX
        if (tr.slave_tx_data === tr.master_rx_data) begin
            miso_matches++;
            miso_ok = 1'b1;
        end else begin
            miso_mismatches++;
            miso_ok = 1'b0;
            `uvm_error("SCB_MISO_MISMATCH", $sformatf("[FAIL MISO] SlaveTX: 0x%02h != MasterRX: 0x%02h (Mode %0d)",
                       tr.slave_tx_data, tr.master_rx_data, mode_idx))
        end

        if (mosi_ok && miso_ok) begin
            `uvm_info("SCB_PASS", $sformatf("[PASS] Mode %0d (CPOL=%0b, CPHA=%0b) | MOSI: 0x%02h==0x%02h | MISO: 0x%02h==0x%02h",
                      mode_idx, tr.cpol, tr.cpha, tr.master_tx_data, tr.slave_rx_data, tr.slave_tx_data, tr.master_rx_data), UVM_LOW)
        end
    endfunction

    virtual function void report_phase(uvm_phase phase);
        super.report_phase(phase);
        `uvm_info("SPI_SCB_REPORT", "--------------------------------------------------------", UVM_NONE)
        `uvm_info("SPI_SCB_REPORT", "               SPI VERIFICATION REPORT                  ", UVM_NONE)
        `uvm_info("SPI_SCB_REPORT", "--------------------------------------------------------", UVM_NONE)
        `uvm_info("SPI_SCB_REPORT", $sformatf(" Total SPI Transactions : %0d", num_transactions), UVM_NONE)
        `uvm_info("SPI_SCB_REPORT", $sformatf(" Mode 0 (0,0) Count     : %0d", mode_counts[0]), UVM_NONE)
        `uvm_info("SPI_SCB_REPORT", $sformatf(" Mode 1 (0,1) Count     : %0d", mode_counts[1]), UVM_NONE)
        `uvm_info("SPI_SCB_REPORT", $sformatf(" Mode 2 (1,0) Count     : %0d", mode_counts[2]), UVM_NONE)
        `uvm_info("SPI_SCB_REPORT", $sformatf(" Mode 3 (1,1) Count     : %0d", mode_counts[3]), UVM_NONE)
        `uvm_info("SPI_SCB_REPORT", "--------------------------------------------------------", UVM_NONE)
        `uvm_info("SPI_SCB_REPORT", $sformatf(" MOSI Path Matches      : %0d", mosi_matches), UVM_NONE)
        `uvm_info("SPI_SCB_REPORT", $sformatf(" MOSI Path Mismatches   : %0d", mosi_mismatches), UVM_NONE)
        `uvm_info("SPI_SCB_REPORT", $sformatf(" MISO Path Matches      : %0d", miso_matches), UVM_NONE)
        `uvm_info("SPI_SCB_REPORT", $sformatf(" MISO Path Mismatches   : %0d", miso_mismatches), UVM_NONE)
        `uvm_info("SPI_SCB_REPORT", "--------------------------------------------------------", UVM_NONE)

        if (mosi_mismatches == 0 && miso_mismatches == 0 && num_transactions > 0) begin
            `uvm_info("SPI_SCB_REPORT", "  *** ALL SPI TRANSACTIONS MATCHED SUCCESSFULLY! ***   ", UVM_NONE)
        end else begin
            `uvm_error("SPI_SCB_REPORT", "  *** SPI VERIFICATION FAILED - CHECK ERROR LOGS ***    ")
        end
        `uvm_info("SPI_SCB_REPORT", "--------------------------------------------------------", UVM_NONE)
    endfunction

endclass

`endif // SPI_SCOREBOARD_SV
