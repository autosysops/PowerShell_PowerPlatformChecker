:::mermaid
flowchart TB
action1["CALL Subflow_SendErrorEmail"]
action2["THROW"]
action4["WRITE"]
subgraph action0_group["Scope: Try executing the flow"]
direction TB
action3["Variables.ConvertJsonToCustomObject"]
end
action0_group -- Error --> action1
action0_group -- Succeeded --> action4
action1 -- Succeeded --> action2
:::