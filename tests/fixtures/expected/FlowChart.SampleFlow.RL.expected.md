:::mermaid
flowchart RL
action0(["When_a_row_is_added"])
action1["Call_Child_Workflow"]
action5["Create_orderline"]
action6["Parallel_A"]
action7["Parallel_B"]
subgraph action4_group
direction RL
action2["Send_an_email"]
action3["Update_row"]
action4{"Condition_Check_Order"}
action4 -- False --> action3
action4 -- True --> action2
end
action0 --> action5
action4_group -- Succeeded/Failed/TimedOut/Skipped --> action1
action5 -- Succeeded --> action6
action5 -- Succeeded --> action7
action5 -- Succeeded/Failed --> action4_group
:::