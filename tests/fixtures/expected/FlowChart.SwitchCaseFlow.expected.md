:::mermaid
flowchart TB
action0(["Manual"])
action1["Finish"]
action10["Initialize_value"]
subgraph action9_group["For_each_item"]
direction TB
subgraph action8_group["Switch_option"]
direction TB
action8{"Switch_option"}
subgraph action3_group["Case_-_Option_A"]
direction TB
action2["Handle_option_A"]
end
subgraph action5_group["Case_-_Option_B"]
direction TB
action4["Handle_option_B"]
end
subgraph action7_group["Case_-_Option_C"]
direction TB
action6["Handle_option_C"]
end
action8 -- Case_-_Option_A --> action3_group
action8 -- Case_-_Option_B --> action5_group
action8 -- Case_-_Option_C --> action7_group
end
end
action0 --> action10
action10 -- Succeeded --> action9_group
action9_group -- Succeeded --> action1
:::