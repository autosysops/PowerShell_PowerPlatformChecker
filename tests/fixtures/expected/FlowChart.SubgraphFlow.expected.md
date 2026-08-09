:::mermaid
flowchart TB
action0(["Manual"])
action4["Compose"]
action5["Initialize_materieelnummer"]
action6["Parse_Input_A"]
action7["Parse_Input_B"]
action8["Parse_Input_C"]
action13["Update_a_row"]
subgraph action3_group[" "]
direction TB
action1["Maintain_status"]
action2["Set_status_to_Ready_for_approval"]
action3{"Check_is_approval_is_needed"}
action3 -- False --> action2
action3 -- True --> action1
end
subgraph action12_group["Try_Supplier_check"]
direction TB
action11["List_Supplier"]
subgraph action10_group[" "]
direction TB
action9["Add_a_new_supplier"]
action10{"Check_if_Supplier_exists_in_dataverse"}
action10 -- False --> action9
end
action11 -- Succeeded --> action10_group
end
action0 --> action6
action12_group -- Succeeded --> action5
action3_group -- Succeeded --> action13
action4 -- Succeeded --> action3_group
action5 -- Succeeded --> action4
action6 -- Succeeded --> action7
action7 -- Succeeded --> action8
action8 -- Succeeded --> action12_group
:::
