:::mermaid
flowchart TB
action1["CALL Subflow_SendErrorEmail"]
action2["THROW"]
action4["Logging.LogMessage"]
action5["External.InvokeCloudConnector (shared_office365.SendEmailV2)"]
action6["WRITE"]
subgraph action0_group["Scope: Try executing the flow"]
direction TB
action3["WebAutomation.PopulateTextField.PopulateTextFieldCloseDialog"]
end
action0_group -- Error --> action1
action0_group -- Succeeded --> action4
action1 -- Succeeded --> action2
action4 -- Succeeded --> action5
action5 -- Succeeded --> action6
:::