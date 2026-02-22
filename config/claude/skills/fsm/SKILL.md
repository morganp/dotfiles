---
name: fsm
description: Generate Finite State Machine (FSM) diagrams from natural language descriptions or structured specs. Use this skill whenever the user mentions state machines, FSMs, statecharts, state diagrams, control flow between states, or asks about things like "draw the states for...", "show me the FSM for...", "diagram the transitions", or describes how a system moves between modes/phases. Also trigger for hardware RTL FSMs, protocol state machines, UI flows, and parser state machines.
---

# FSM Skill

## Overview

This skill produces **Mermaid `stateDiagram-v2`** — the cleanest text-based format for FSM diagrams — from plain-English descriptions or structured specs. The output can be pasted directly into the [Mermaid Live Editor](https://mermaid.live), renders natively in GitHub/GitLab Markdown, and can be exported to SVG/PNG via the Mermaid CLI.

For hardware/RTL contexts (where Graphviz DOT is more conventional), see **DOT Output** below.

## Workflow

1. **Identify the states** — enumerate distinct modes, phases, or conditions the system can be in
2. **Identify the transitions** — for each state, what events or conditions cause a state change, and what actions occur
3. **Identify initial and final states** — `[*]` is used for both
4. **Choose complexity level** — flat FSM, hierarchical (nested states), or concurrent (parallel regions)
5. **Compose the diagram** — write the Mermaid stateDiagram-v2 block
6. **Output a fenced code block** using ` ```mermaid ` so it renders cleanly, then explain what it shows
7. **Optionally render to a file** — if the user wants SVG/PNG, offer to run `mmdc` (see **Rendering to Image Files**)

## Mermaid stateDiagram-v2 Reference

### Basic structure

```
stateDiagram-v2
    [*] --> Idle
    Idle --> Running : start
    Running --> Idle : stop
    Running --> Error : fault
    Error --> Idle : reset
    Idle --> [*]
```

### States

```
stateDiagram-v2
    %% Plain state (name is the label)
    Idle

    %% State with a display label (name used internally, label shown)
    state "Waiting for ACK" as WaitAck

    %% Initial pseudostate
    [*] --> Idle

    %% Final pseudostate
    Done --> [*]
```

### Transitions

```
stateDiagram-v2
    %% Transition with event label
    A --> B : event

    %% Transition with event and action
    A --> B : event / action()

    %% Transition with guard condition
    A --> B : [condition]

    %% Combined
    A --> B : event [guard] / action()

    %% Unlabelled transition (useful from [*])
    [*] --> Init
```

### Composite (nested) states

```
stateDiagram-v2
    [*] --> Active

    state Active {
        [*] --> Idle
        Idle --> Processing : request
        Processing --> Idle : done
    }

    Active --> Stopped : shutdown
    Stopped --> [*]
```

### Choice pseudostate (branching)

```
stateDiagram-v2
    [*] --> Check

    state Check <<choice>>
    Check --> Authorized : [valid credentials]
    Check --> Denied : [invalid credentials]

    Authorized --> Session
    Denied --> [*]
```

### Fork and join (parallel split/merge)

```
stateDiagram-v2
    [*] --> Fork1

    state Fork1 <<fork>>
    Fork1 --> DownloadA
    Fork1 --> DownloadB

    state Join1 <<join>>
    DownloadA --> Join1
    DownloadB --> Join1

    Join1 --> Done
    Done --> [*]
```

### Concurrent regions (parallel states)

Use `--` to split a composite state into parallel regions:

```
stateDiagram-v2
    state Active {
        state "Audio" as Audio {
            [*] --> Muted
            Muted --> Playing : unmute
            Playing --> Muted : mute
        }
        --
        state "Video" as Video {
            [*] --> Paused
            Paused --> Streaming : play
            Streaming --> Paused : pause
        }
    }
```

### Notes

```
stateDiagram-v2
    Idle --> Running : start
    note right of Running
        CPU usage increases here.
        Monitor for thermal throttling.
    end note
```

### Direction

```
stateDiagram-v2
    direction LR    %% Left-to-right (good for sequential flows)
    %% Default is top-to-bottom
```

### Comments and styling

```
stateDiagram-v2
    %% This is a comment

    classDef error fill:#f55,color:#fff
    class Error error
```

## Common Patterns

### Traffic light

```mermaid
stateDiagram-v2
    direction LR
    [*] --> Red
    Red --> Green : timer
    Green --> Yellow : timer
    Yellow --> Red : timer
```

### Login flow

```mermaid
stateDiagram-v2
    [*] --> LoggedOut

    LoggedOut --> Authenticating : submit credentials
    Authenticating --> LoggedIn : [valid] / create session
    Authenticating --> LoggedOut : [invalid] / show error

    state LoggedIn {
        [*] --> Browse
        Browse --> Checkout : add to cart
        Checkout --> Browse : cancel
        Checkout --> OrderPlaced : confirm
        OrderPlaced --> Browse : continue shopping
    }

    LoggedIn --> LoggedOut : logout / destroy session
    LoggedOut --> [*]
```

### Vending machine

```mermaid
stateDiagram-v2
    [*] --> Idle
    Idle --> Collecting : insert coin
    Collecting --> Collecting : insert coin / add credit
    Collecting --> Idle : cancel / return coins
    Collecting --> Dispensing : select item [credit >= price] / dispense + return change
    Collecting --> Collecting : select item [credit < price] / show balance
    Dispensing --> Idle : item delivered
```

### TCP connection states

```mermaid
stateDiagram-v2
    direction LR
    [*] --> CLOSED

    CLOSED --> LISTEN : passive open
    CLOSED --> SYN_SENT : active open / send SYN
    LISTEN --> SYN_RCVD : receive SYN / send SYN+ACK
    SYN_SENT --> ESTABLISHED : receive SYN+ACK / send ACK
    SYN_RCVD --> ESTABLISHED : receive ACK
    ESTABLISHED --> FIN_WAIT_1 : close / send FIN
    ESTABLISHED --> CLOSE_WAIT : receive FIN / send ACK
    CLOSE_WAIT --> LAST_ACK : close / send FIN
    LAST_ACK --> CLOSED : receive ACK
    FIN_WAIT_1 --> FIN_WAIT_2 : receive ACK
    FIN_WAIT_2 --> TIME_WAIT : receive FIN / send ACK
    TIME_WAIT --> CLOSED : timeout
```

### Hardware RTL FSM (Moore, use DOT for this — see below)

For Mermaid:
```mermaid
stateDiagram-v2
    direction LR
    [*] --> IDLE

    IDLE --> FETCH : start / pc_inc=0
    FETCH --> DECODE : mem_ready / ir_load=1
    DECODE --> EXECUTE : decode_done
    EXECUTE --> WRITEBACK : alu_done / reg_write=1
    WRITEBACK --> IDLE : done
    WRITEBACK --> FETCH : !done / pc_inc=1
```

## DOT Output (Hardware/RTL Context)

Graphviz DOT is the conventional choice for RTL documentation — pairs naturally with WaveDrom, produces minimal clean diagrams, and is programmatically easy to generate from code.

### Basic DOT FSM

```dot
digraph FSM {
    rankdir=LR
    node [shape=circle fontname="monospace"]
    edge [fontname="monospace" fontsize=10]

    // Initial arrow
    __start [shape=point width=0.2]
    __start -> IDLE

    // States (double circle = accepting/final)
    IDLE [shape=doublecircle]

    // Transitions
    IDLE   -> FETCH     [label="start"]
    FETCH  -> DECODE    [label="mem_ready"]
    DECODE -> EXECUTE   [label="decoded"]
    EXECUTE -> IDLE     [label="done"]
    EXECUTE -> FETCH    [label="!done / pc++"]
}
```

### Mealy vs Moore annotation in DOT

```dot
digraph Moore {
    // Moore: outputs labeled inside state nodes
    IDLE   [label="IDLE\nout=0"]
    ACTIVE [label="ACTIVE\nout=1"]
    IDLE -> ACTIVE [label="en"]
    ACTIVE -> IDLE [label="!en"]
}

digraph Mealy {
    // Mealy: outputs on transition labels
    IDLE -> ACTIVE [label="en / out=1"]
    ACTIVE -> IDLE [label="!en / out=0"]
}
```

Render DOT with:
```bash
dot -Tsvg fsm.dot -o fsm.svg
dot -Tpng fsm.dot -o fsm.png
```

## Output Format

Always output the diagram as a fenced code block. For Mermaid:

````
```mermaid
stateDiagram-v2
    ...
```
````

For DOT:

````
```dot
digraph FSM {
    ...
}
```
````

After the code block, briefly explain:
- What states exist and what each represents
- Key transitions or decision points
- How to use it: paste at https://mermaid.live (for Mermaid) or https://dreampuf.github.io/GraphvizOnline/ (for DOT)

If the description is ambiguous about exact transitions or guards, make a reasonable assumption, note it, and offer to adjust.

## Rendering to Image Files

### Mermaid CLI (`mmdc`)

```bash
# Install (requires Node.js)
npm install -g @mermaid-js/mermaid-cli

# Save diagram
cat > fsm.mmd << 'EOF'
stateDiagram-v2
    [*] --> Idle
    Idle --> Running : start
EOF

# Render
mmdc -i fsm.mmd -o fsm.svg          # SVG (best for docs)
mmdc -i fsm.mmd -o fsm.png          # PNG
mmdc -i fsm.mmd -o fsm.pdf          # PDF
```

### Graphviz

```bash
# Install: brew install graphviz  OR  apt install graphviz
dot -Tsvg fsm.dot -o fsm.svg
dot -Tpng fsm.dot -o fsm.png
```

### When to offer rendering

- User asks to "save", "export", or "generate" a file
- User mentions embedding in a document or slides
- Bash tool access is available — check with `which mmdc` or `which dot` and suggest install if missing

## Choosing the Right Format

| Situation | Use |
|---|---|
| Software FSM, web docs, GitHub README | Mermaid `stateDiagram-v2` |
| Hardware / RTL / FPGA documentation | Graphviz DOT |
| Need to simulate or execute the FSM | XState JSON (mention https://stately.ai/viz) |
| Mixed UML diagram suite | PlantUML (mention as alternative) |
