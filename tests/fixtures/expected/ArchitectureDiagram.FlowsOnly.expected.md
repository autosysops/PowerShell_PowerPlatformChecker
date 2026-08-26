:::mermaid
classDiagram
direction LR
class flow22222222-2222-2222-2222-222222222222["[CLOUD] Child Flow"]:::Flow
class flow23232323-2323-2323-2323-232323232323["[CLOUD] Cloud HTTP profile flow"]:::Flow
class flow11111111-1111-1111-1111-111111111111["[CLOUD] Sample Flow"]:::Flow
flow11111111-1111-1111-1111-111111111111 --> flow22222222-2222-2222-2222-222222222222:Call_Child_Workflow
classDef default fill:red,stroke:#5E5B52
classDef Flow fill:#DBE4EE,stroke:#5E5B52
:::
