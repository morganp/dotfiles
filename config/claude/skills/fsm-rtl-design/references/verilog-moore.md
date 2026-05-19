# Verilog Moore FSM Template

Use this when the output values are determined by state and a registered output latency is acceptable. Outputs are decoded from `state_d` so `state_q` and the registered outputs align after the same clock edge.

```verilog
module fsm_moore (
    input  wire clk,
    input  wire rst_n,
    input  wire start,
    input  wire ack,
    output reg  busy,
    output reg  done
);

    localparam [1:0]
        S_IDLE = 2'b00,
        S_RUN  = 2'b01,
        S_DONE = 2'b10;

    reg [1:0] state_q, state_d;
    reg       busy_d, done_d;

    // State and output registers
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state_q <= S_IDLE;
            busy    <= 1'b0;
            done    <= 1'b0;
        end else begin
            state_q <= state_d;
            busy    <= busy_d;
            done    <= done_d;
        end
    end

    // Next-state logic
    always @* begin
        state_d = state_q;

        case (state_q)
            S_IDLE: begin
                if (start)
                    state_d = S_RUN;
            end

            S_RUN: begin
                if (ack)
                    state_d = S_DONE;
            end

            S_DONE: begin
                state_d = S_IDLE;
            end

            default: begin
                state_d = S_IDLE;
            end
        endcase
    end

    // Moore output decode. Decode from state_d to keep outputs aligned
    // with state_q after the clock edge.
    always @* begin
        busy_d = 1'b0;
        done_d = 1'b0;

        case (state_d)
            S_IDLE: begin
                busy_d = 1'b0;
                done_d = 1'b0;
            end

            S_RUN: begin
                busy_d = 1'b1;
                done_d = 1'b0;
            end

            S_DONE: begin
                busy_d = 1'b0;
                done_d = 1'b1;
            end

            default: begin
                busy_d = 1'b0;
                done_d = 1'b0;
            end
        endcase
    end

endmodule
```

## Notes

- `busy` and `done` are registered, so they are glitch-free.
- The `done` pulse is asserted for one clock while the FSM enters `S_DONE`.
- If the design requires outputs to reflect the old/current state before the transition, decode from `state_q` instead of `state_d` and document the one-cycle alignment difference.
- If using SystemVerilog, replace `localparam` plus raw `reg` state vectors with `typedef enum logic` and use `always_ff`/`always_comb`.
