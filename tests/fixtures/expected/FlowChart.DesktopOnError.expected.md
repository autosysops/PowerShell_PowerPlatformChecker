:::mermaid
flowchart TB
action0["WAIT for 5 seconds"]
action1["CALL Subflow_Address_NotAvailable"]
action2["WRITE"]
action0 -- Succeeded --> action2
action0 -- TimeoutError --> action1
:::