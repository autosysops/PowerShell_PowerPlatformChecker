:::mermaid
flowchart TB
action0["WAIT for 5 seconds"]
action1["WAIT for web page content (contain element)"]
action4["WRITE"]
subgraph action2_group["LOOP FOREACH CurrentItem IN Items"]
direction TB
action3["CALL Subflow_ProcessItem"]
end
action0 -- Succeeded --> action1
action1 -- Succeeded --> action2_group
action2_group -- Succeeded --> action4
:::