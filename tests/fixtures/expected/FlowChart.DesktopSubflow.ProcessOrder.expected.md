:::mermaid
flowchart TB
action0["SET"]
action1["External.InvokeCloudConnector (shared_office365.SendEmailV2)"]
action2["CALL SendAudit"]
action0 -- Succeeded --> action1
action1 -- Succeeded --> action2
:::
