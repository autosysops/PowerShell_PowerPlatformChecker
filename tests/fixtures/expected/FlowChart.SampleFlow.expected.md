:::mermaid
flowchart TB
action0(["When_a_row_is_added"])
action1["Call_Child_Workflow"]
action2["Send_an_email"]
action3["Update_row"]
action4{"Condition_Check_Order"}
action5["Create_orderline"]
action6["Parallel_A"]
action7["Parallel_B"]
action4 -- Succeeded/Failed/TimedOut/Skipped --> action1
action4 -- True --> action2
action4 -- False --> action3
action5 -- Succeeded/Failed --> action4
action0 --> action5
action5 -- Succeeded --> action6
action5 -- Succeeded --> action7
:::
