:::mermaid
flowchart TB
action0(["Manual"])
action1["After_conditions"]
subgraph action3_group
direction TB
action2["First_true_action"]
action3{"First_condition"}
action3 -- True --> action2
end
subgraph action5_group
direction TB
action4["Second_true_action"]
action5{"Second_condition"}
action5 -- True --> action4
end
action0 --> action3_group
action3_group -- Succeeded --> action5_group
action5_group -- Succeeded --> action1
:::