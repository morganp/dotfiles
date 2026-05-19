# Verilog Mealy FSM Templates

Use true Mealy only when an output must respond combinationally inside the current cycle. Prefer registered-Mealy when the output can be sampled on a clock edge.

## True Mealy: 2 Blocks

```verilog
module fsm_mealy_true (
    input  wire clk,
    input  wire rst_n,
    input  wire in_a,
    input  wire in_b,
    output reg  out_pulse
);

    localparam [1:0]
        S_IDLE = 2'b00,
        S_RUN  = 2'b01,
        S_DONE = 2'b10;

    reg [1:0] state_q, state_d;

    // State register
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            state_q <= S_IDLE;
        else
            state_q <= state_d;
    end

    // Next-state and true Mealy output logic
    always @* begin
        state_d   = state_q;
        out_pulse = 1'b0;

        case (state_q)
            S_IDLE: begin
                if (in_a) begin
                    out_pulse = 1'b1;
                    state_d   = S_RUN;
                end
            end

            S_RUN: begin
                if (in_b)
                    state_d = S_DONE;
            end

            S_DONE: begin
                state_d = S_IDLE;
            end

            default: begin
                state_d   = S_IDLE;
                out_pulse = 1'b0;
            end
        endcase
    end

endmodule
```

`out_pulse` can change as soon as `state_q` or `in_a` changes. This is useful for same-cycle response, but the output can glitch and contributes combinational delay to downstream logic.

## Registered Mealy: 4 Blocks

```verilog
module fsm_mealy_registered (
    input  wire clk,
    input  wire rst_n,
    input  wire in_a,
    input  wire in_b,
    output reg  out_pulse
);

    localparam [1:0]
        S_IDLE = 2'b00,
        S_RUN  = 2'b01,
        S_DONE = 2'b10;

    reg [1:0] state_q, state_d;
    reg       out_pulse_d;

    // 1) State register
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            state_q <= S_IDLE;
        else
            state_q <= state_d;
    end

    // 2) Next-state logic
    always @* begin
        state_d = state_q;

        case (state_q)
            S_IDLE: begin
                if (in_a)
                    state_d = S_RUN;
            end

            S_RUN: begin
                if (in_b)
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

    // 3) Next-output logic. Derive from current state plus inputs,
    // not from state_d, to preserve registered-Mealy behavior.
    always @* begin
        out_pulse_d = 1'b0;

        case (state_q)
            S_IDLE: begin
                if (in_a)
                    out_pulse_d = 1'b1;
            end

            default: begin
                out_pulse_d = 1'b0;
            end
        endcase
    end

    // 4) Output register
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            out_pulse <= 1'b0;
        else
            out_pulse <= out_pulse_d;
    end

endmodule
```

Registered-Mealy outputs are glitch-free and update on the clock edge. Use this for enables, handshakes, or outputs that leave the FSM block unless the protocol explicitly requires a combinational response.
