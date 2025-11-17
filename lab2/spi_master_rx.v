// --------------------------------------------------------------------------
// spi_master.v
// Протокол: SPI Master (Mode 0: CPOL=0, CPHA=0)
// Мова: Verilog
// --------------------------------------------------------------------------
module spi_master (
    // Системні порти
    input wire clk,             // Системна тактова частота (наприклад, 100 МГц)
    input wire reset_n,         // Асинхронний активний низький скидання

    // Дані користувача
    input wire start_transfer,  // Сигнал початку передачі (активний високий)
    input wire [7:0] tx_data_in,// 8-бітові дані для передачі
    output reg [7:0] rx_data_out, // 8-бітові прийняті дані
    output reg data_received,   // Сигнал, що дані прийнято

    // SPI порти
    output reg SCK,             // Serial Clock (генерується Master)
    output reg MOSI,            // Master Out Slave In
    output reg SS_n,            // Slave Select (активний низький)
    input wire MISO             // Master In Slave Out
);

// Параметри тактового дільника (визначення швидкості SCK)
// Приклад: CLK=100МГц. Для SCK=10МГц потрібно (100МГц / (2*10МГц)) - 1 = 4.
// COUNT_MAX = 4 (дільник на 5) -> SCK = 100МГц / 10 = 10 МГц.
parameter CLK_DIV_MAX = 4;
localparam DATA_WIDTH = 8; // Кількість бітів у пакеті

// Регістри FSM
localparam [1:0] 
    IDLE       = 2'b00,
    START      = 2'b01,
    TRANSFER   = 2'b10,
    END_CYCLE  = 2'b11;

reg [1:0] state, next_state;
reg [DATA_WIDTH-1:0] tx_shift_reg;
reg [DATA_WIDTH-1:0] rx_shift_reg;
reg [$clog2(DATA_WIDTH)-1:0] bit_counter;
reg [$clog2(CLK_DIV_MAX):0] clk_div_counter;
reg sck_int; // Проміжний сигнал для генерації SCK

// --------------------------------------------------------------------------
// 1. Генерація тактового сигналу SCK
// --------------------------------------------------------------------------
always @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
        clk_div_counter <= 0;
        sck_int <= 0;
    end else begin
        // Генеруємо SCK лише у стані TRANSFER
        if (state == TRANSFER) begin
            if (clk_div_counter == CLK_DIV_MAX) begin
                clk_div_counter <= 0;
                sck_int <= ~sck_int; // Перемикання SCK
            end else begin
                clk_div_counter <= clk_div_counter + 1;
            end
        end else begin
            clk_div_counter <= 0;
            sck_int <= 0; // SCK=0 в стані спокою (Mode 0)
        end
    end
end

assign SCK = sck_int;

// --------------------------------------------------------------------------
// 2. FSM (Діаграма станів)
// --------------------------------------------------------------------------
// Логіка наступного стану
always @(*) begin
    next_state = state;
    case (state)
        IDLE:
            if (start_transfer)
                next_state = START;
        START:
            next_state = TRANSFER;
        TRANSFER:
            // Перевіряємо, чи завершено 8 бітів і чи SCK знову низький (наприкінці циклу)
            if (bit_counter == DATA_WIDTH - 1 && SCK == 0)
                next_state = END_CYCLE;
        END_CYCLE:
            next_state = IDLE;
        default:
            next_state = IDLE;
    endcase
end

// Логіка переходу станів та вихідні сигнали
always @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
        state <= IDLE;
        SS_n <= 1'b1;        // SS неактивний
        MOSI <= 1'b0;
        bit_counter <= 0;
        data_received <= 1'b0;
    end else begin
        data_received <= 1'b0; // Скидаємо сигнал прийняття

        case (next_state)
            IDLE: begin
                state <= IDLE;
                SS_n <= 1'b1; // SS неактивний
                bit_counter <= 0;
                // Очистка регістрів
                rx_data_out <= 8'h00;
            end
            START: begin
                state <= START;
                SS_n <= 1'b0; // SS активний
                tx_shift_reg <= tx_data_in; // Завантажуємо дані
            end
            TRANSFER: begin
                state <= TRANSFER;
                // Передача даних (на позитивному фронті SCK)
                if (SCK == 1'b0 && sck_int == 1'b1) begin // Позитивний фронт SCK
                    MOSI <= tx_shift_reg[DATA_WIDTH-1]; // MSB first
                    tx_shift_reg <= tx_shift_reg << 1;
                end
                
                // Прийом даних (на негативному фронті SCK, для Mode 0)
                if (SCK == 1'b1 && sck_int == 1'b0) begin // Негативний фронт SCK
                    rx_shift_reg <= {rx_shift_reg[DATA_WIDTH-2:0], MISO}; // Зсув вліво
                    bit_counter <= bit_counter + 1;
                end
            end
            END_CYCLE: begin
                state <= END_CYCLE;
                SS_n <= 1'b1; // Деактивуємо SS
                rx_data_out <= rx_shift_reg; // Зберігаємо прийняті дані
                data_received <= 1'b1;
            end
        endcase
    end
end

endmodule