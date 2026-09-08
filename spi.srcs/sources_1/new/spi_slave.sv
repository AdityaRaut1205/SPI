`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Engineer: Aditya Raut
// Design Name: spi_slave
// Module Name: spi_slave
// Project Name: spi
// Description:
//   Parameterized SPI Slave Peripheral.
//   Supports configurable DATA_WIDTH and dynamic/parameterized CPOL & CPHA modes.
//   Features tri-stated MISO (high-impedance '1'bz') when CS_N is deasserted.
//   Includes synchronous edge sampling logic and parallel RX/TX handshake.
//////////////////////////////////////////////////////////////////////////////////

module spi_slave #(
    parameter int DATA_WIDTH   = 8,
    parameter bit DEFAULT_CPOL = 1'b0,
    parameter bit DEFAULT_CPHA = 1'b0
)(
    input  logic                  clk,
    input  logic                  rst,
    input  logic                  cpol,
    input  logic                  cpha,
    input  logic [DATA_WIDTH-1:0] slave_tx_data,
    input  logic                  slave_tx_load,
    output logic [DATA_WIDTH-1:0] slave_rx_data,
    output logic                  slave_rx_valid,
    // SPI Physical Bus
    input  logic                  spi_sclk,
    input  logic                  spi_mosi,
    output logic                  spi_miso,
    input  logic                  spi_cs_n
);

    // 2-stage synchronizers for external SPI bus signals
    logic [1:0] sclk_sync;
    logic [1:0] mosi_sync;
    logic [1:0] cs_n_sync;

    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            sclk_sync <= {2{DEFAULT_CPOL}};
            mosi_sync <= 2'b00;
            cs_n_sync <= 2'b11;
        end else begin
            sclk_sync <= {sclk_sync[0], spi_sclk};
            mosi_sync <= {mosi_sync[0], spi_mosi};
            cs_n_sync <= {cs_n_sync[0], spi_cs_n};
        end
    end

    wire sclk_rising   = (sclk_sync == 2'b01);
    wire sclk_falling  = (sclk_sync == 2'b10);
    wire cs_n_active   = (cs_n_sync[1] == 1'b0);
    wire cs_n_asserted = (cs_n_sync == 2'b10);
    wire cs_n_deassert = (cs_n_sync == 2'b01);

    // Determine leading and trailing edges based on CPOL
    wire leading_edge  = (cpol == 1'b0) ? sclk_rising : sclk_falling;
    wire trailing_edge = (cpol == 1'b0) ? sclk_falling : sclk_rising;

    // Determine sample and shift edges based on CPHA
    wire sample_edge   = (cpha == 1'b0) ? leading_edge : trailing_edge;
    wire shift_edge    = (cpha == 1'b0) ? trailing_edge : leading_edge;

    logic [DATA_WIDTH-1:0] tx_shift;
    logic [DATA_WIDTH-1:0] rx_shift;
    logic [$clog2(DATA_WIDTH+1)-1:0] bit_cnt;
    logic miso_drive;

    // Tri-state MISO when unselected
    assign spi_miso = cs_n_active ? miso_drive : 1'bz;

    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            tx_shift       <= '0;
            rx_shift       <= '0;
            slave_rx_data  <= '0;
            slave_rx_valid <= 1'b0;
            bit_cnt        <= '0;
            miso_drive     <= 1'b0;
        end else begin
            slave_rx_valid <= 1'b0;

            if (slave_tx_load) begin
                tx_shift <= slave_tx_data;
            end

            if (cs_n_asserted) begin
                bit_cnt  <= '0;
                rx_shift <= '0;
                tx_shift <= slave_tx_data;

                // For CPHA = 0, slave must drive MSB immediately when CS asserts
                if (!cpha) begin
                    miso_drive <= slave_tx_data[DATA_WIDTH-1];
                end else begin
                    miso_drive <= 1'b0;
                end
            end else if (cs_n_active) begin
                // Shift logic
                if (shift_edge) begin
                    if (cpha == 1'b0) begin
                        miso_drive <= tx_shift[DATA_WIDTH-2];
                        tx_shift   <= {tx_shift[DATA_WIDTH-2:0], 1'b0};
                    end else begin
                        miso_drive <= tx_shift[DATA_WIDTH-1];
                        tx_shift   <= {tx_shift[DATA_WIDTH-2:0], 1'b0};
                    end
                end

                // Sample logic
                if (sample_edge) begin
                    rx_shift <= {rx_shift[DATA_WIDTH-2:0], mosi_sync[1]};
                    if (bit_cnt == DATA_WIDTH - 1) begin
                        slave_rx_data  <= {rx_shift[DATA_WIDTH-2:0], mosi_sync[1]};
                        slave_rx_valid <= 1'b1;
                        bit_cnt        <= '0;
                    end else begin
                        bit_cnt <= bit_cnt + 1'b1;
                    end
                end
            end else if (cs_n_deassert) begin
                bit_cnt <= '0;
            end
        end
    end

endmodule
