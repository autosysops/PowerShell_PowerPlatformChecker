:::mermaid
classDiagram
direction LR
class flow22222222-2222-2222-2222-222222222222["Child Flow"]:::Flow {
    Notify(shared_office365)
}
class flow11111111-1111-1111-1111-111111111111["Sample Flow"]:::Flow {
    When_a_row_is_added(shared_commondataserviceforapps)
    Send_an_email(shared_office365)
    Update_row(shared_commondataserviceforapps)
    Create_orderline(shared_commondataserviceforapps)
}
class ppc_canvas_sales_0001["Sales Canvas App"]:::CanvasApp
class shared_commondataserviceforapps:::Connection {
  ConnectionReference
  Dataverse - Test()
}
class shared_office365:::Connection {
  ConnectionReference
  Office 365 Outlook - Test()
}
class shared_todo:::Connection {
  ConnectionReference
  Unused Connector()
}
class ppc_script_OrderForm_js["Order Form Script"]:::WebResource {
  [Script]JavaScript
  [Script]onLoad
}
class ppc_script_Shared_js["Shared Script"]:::WebResource {
  [Script]JavaScript
  [Script]setTabVisibility
}
shared_office365 --> flow22222222-2222-2222-2222-222222222222:shared_office365
shared_commondataserviceforapps --> flow11111111-1111-1111-1111-111111111111:shared_commondataserviceforapps
flow11111111-1111-1111-1111-111111111111 --> flow22222222-2222-2222-2222-222222222222:Call_Child_Workflow
shared_office365 --> flow11111111-1111-1111-1111-111111111111:shared_office365
shared_commondataserviceforapps --> ppc_canvas_sales_0001:shared_commondataserviceforapps
shared_office365 --> ppc_canvas_sales_0001:shared_office365
ppc_script_OrderForm_js --> ppc_script_Shared_js:Dependency
classDef default fill:red,stroke:#5E5B52
classDef Connection fill:#FCD757,stroke:#5E5B52
classDef Flow fill:#DBE4EE,stroke:#5E5B52
classDef CanvasApp fill:#8BC34A,stroke:#5E5B52
classDef WebResource fill:#D7C8F3,stroke:#5E5B52
:::
