:::mermaid
flowchart TB
action0(["Manual"])
action1["Final_Update"]
action2["Initialize_materieelnummer"]
subgraph action6_group
direction TB
action6{"Is_Material"}
subgraph action5_group["Try_Adding_or_Updating_Material"]
direction TB
action3["Calculate_Prijs"]
action4["Genereer_materieelnummer"]
action4 -- Succeeded --> action3
end
action6 -- True --> action5_group
end
action0 --> action2
action2 -- Succeeded --> action6_group
action6_group -- Succeeded --> action1
:::