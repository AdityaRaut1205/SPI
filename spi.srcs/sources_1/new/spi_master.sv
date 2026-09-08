`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Engineer: Aditya Raut
// Design Name: spi_master
// Module Name: spi_master
// Project Name: spi
// Description:
//   Parameterized SPI Master Controller.
//   Supports configurable DATA_WIDTH (8/16/32), programmable clock divider (CLK_DIV),
//   and all 4 SPI Modes (CPOL = 0/1, CPHA = 0/1).
//   Guarantees clean CS_N setup (T_CSS) and hold (T_CSH) framing with full-duplex shifting.
//////////////////////////////////////////////////////////////////////////////////

module spi_master #(
    parameter int DATA_WIDTH   = 8,
    parameter int CLK_DIV      = 4,
    parameter bit DEFAULT_CPOL = 1'b0,
    parameter bit DEFAULT_CPHA = 1'b0
)(
    input  logic                  clk,
    input  logic                  rst,
    input  logic                  start,
    input  logic                  cpol,
    input  logic                  cpha,
    input  logic [DATA_WIDTH-1:0] tx_data,
    output logic [DATA_WIDTH-1:0] rx_data,
    output logic                  busy,
    output logic                  done,
    // SPI Physical Bus
    output logic                  spi_sclk,
    output logic                  spi_mosi,
    output logic                  spi_cs_n,
    input  logic                  spi_miso
);

    typedef enum logic [2:0] {
        IDLE      = 3'b000,
        CS_SETUP  = 3'b001,
        TRANSFER  = 3'b010,
        CS_HOLD   = 3'b011,
        COMPLETED = 3'b100
    } state_t;

    state_t state;

    localparam int TOTAL_EDGES   = 2 * DATA_WIDTH;
    localparam int CLK_CNT_WIDTH = (CLK_DIV <= 1) ? 1 : $clog2(CLK_DIV);
    localparam int EDGE_CNT_WIDTH = $clog2(TOTAL_EDGES + 2);

    logic [CLK_CNT_WIDTH-1:0]  clk_cnt;
    logic [EDGE_CNT_WIDTH-1:0] edge_cnt;
    logic [DATA_WIDTH-1:0]     tx_shift;
    logic [DATA_WIDTH-1:0]     rx_shift;
    logic                      sclk_reg;
    logic                      mosi_reg;
    logic                      cs_n_reg;
    logic                      cfg_cpol;
    logic                      cfg_cpha;

    assign spi_sclk = sclk_reg;
    assign spi_mosi = mosi_reg;
    assign spi_cs_n = cs_n_reg;

    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            state     <= IDLE;
            clk_cnt   <= '0;
            edge_cnt  <= '0;
            tx_shift  <= '0;
            rx_shift  <= '0;
            rx_data   <= '0;
            busy      <= 1'b0;
            done      <= 1'b0;
            cs_n_reg  <= 1'b1;
            sclk_reg  <= DEFAULT_CPOL;
            mosi_reg  <= 1'b0;
            cfg_cpol  <= DEFAULT_CPOL;
            cfg_cpha  <= DEFAULT_CPHA;
        end else begin
            done <= 1'b0;

            case (state)
                IDLE: begin
                    busy     <= 1'b0;
                    cs_n_reg <= 1'b1;
                    sclk_reg <= cpol;
                    cfg_cpol <= cpol;
                    cfg_cpha <= cpha;

                    if (start) begin
                        busy     <= 1'b1;
                        cfg_cpol <= cpol;
                        cfg_cpha <= cpha;
                        sclk_reg <= cpol;
                        tx_shift <= tx_data;
                        rx_shift <= '0;
                        clk_cnt  <= '0;
                        edge_cnt <= '0;
                        cs_n_reg <= 1'b0;

                        // For CPHA = 0, first MSB must be placed on line immediately upon CS assertion
                        if (!cpha) begin
                            mosi_reg <= tx_data[DATA_WIDTH-1];
                        end else begin
                            mosi_reg <= 1'b0;
                        end

                        state <= CS_SETUP;
                    end
                end

                CS_SETUP: begin
                    if (clk_cnt == CLK_DIV - 1) begin
                        clk_cnt <= '0;
                        // Leading edge (Edge 1): toggle SCLK to active level
                        sclk_reg <= ~sclk_reg;
                        edge_cnt <= 1;

                        if (cfg_cpha == 1'b0) begin
                            // CPHA=0: Edge 1 is leading edge -> SAMPLE edge
                            rx_shift <= {rx_shift[DATA_WIDTH-2:0], spi_miso};
                        end else begin
                            // CPHA=1: Edge 1 is leading edge -> SHIFT edge (drive MSB)
                            mosi_reg <= tx_shift[DATA_WIDTH-1];
                            tx_shift <= {tx_shift[DATA_WIDTH-2:0], 1'b0};
                        end

                        state <= TRANSFER;
                    end else begin
                        clk_cnt <= clk_cnt + 1'b1;
                    end
                end

                TRANSFER: begin
                    if (clk_cnt == CLK_DIV - 1) begin
                        clk_cnt <= '0;

                        if (edge_cnt < TOTAL_EDGES) begin
                            sclk_reg <= ~sclk_reg;
                            edge_cnt <= edge_cnt + 1'b1;

                            // If next edge is even (2, 4, 6...): TRAILING EDGE
                            if (edge_cnt[0] == 1'b1) begin
                                if (cfg_cpha == 1'b0) begin
                                    // CPHA=0: Trailing edge is SHIFT edge
                                    mosi_reg <= tx_shift[DATA_WIDTH-2];
                                    tx_shift <= {tx_shift[DATA_WIDTH-2:0], 1'b0};
                                end else begin
                                    // CPHA=1: Trailing edge is SAMPLE edge
                                    rx_shift <= {rx_shift[DATA_WIDTH-2:0], spi_miso};
                                end
                            end else begin
                                // If next edge is odd (3, 5, 7...): LEADING EDGE
                                if (cfg_cpha == 1'b0) begin
                                    // CPHA=0: Leading edge is SAMPLE edge
                                    rx_shift <= {rx_shift[DATA_WIDTH-2:0], spi_miso};
                                end else begin
                                    // CPHA=1: Leading edge is SHIFT edge
                                    mosi_reg <= tx_shift[DATA_WIDTH-1];
                                    tx_shift <= {tx_shift[DATA_WIDTH-2:0], 1'b0};
                                end
                            end
                        end else begin
                            // All TOTAL_EDGES complete: park clock at idle
                            sclk_reg <= cfg_cpol;
                            rx_data  <= rx_shift;
                            state    <= CS_HOLD;
                        end
                    end else begin
                        clk_cnt <= clk_cnt + 1'b1;
                    end
                end

                CS_HOLD: begin
                    if (clk_cnt == CLK_DIV - 1) begin
                        clk_cnt  <= '0;
                        cs_n_reg <= 1'b1;
                        state    <= COMPLETED;
                    end else begin
                        clk_cnt <= clk_cnt + 1'b1;
                    end
                end

                COMPLETED: begin
                    busy  <= 1'b0;
                    done  <= 1'b1;
                    state <= IDLE;
                end

                default: state <= IDLE;
            endcase
        end
    end

endmodule
