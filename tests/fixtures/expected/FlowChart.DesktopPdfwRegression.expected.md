:::mermaid
flowchart TB
action1["CALL Subflow_SendErrorEmail"]
action2["THROW"]
action12["Logging.LogMessage_2"]
action13["External.InvokeCloudConnector (shared_office365.SendEmailV2)"]
action14["WRITE"]
subgraph action0_group["Scope: Try executing the flow"]
direction TB
action3["Variables.CreateNewDatatable"]
action4["Logging.LogMessage"]
action5["DISABLE"]
action6["SET"]
action7["THROW_2"]
action8["Variables.ConvertJsonToCustomObject"]
action9["WebAutomation.LaunchChrome.LaunchChrome"]
action10["WAIT for web page content (contain element in state)"]
action11["WebAutomation.PressButton.PressButton"]
action10 -- Succeeded --> action11
action3 -- Succeeded --> action4
action4 -- Succeeded --> action5
action5 -- Error --> action6
action5 -- Succeeded --> action8
action6 -- Succeeded --> action7
action8 -- Succeeded --> action9
action9 -- Succeeded --> action10
end
action0_group -- Error --> action1
action0_group -- Succeeded --> action12
action1 -- Succeeded --> action2
action12 -- Succeeded --> action13
action13 -- Succeeded --> action14
:::