:::mermaid
classDiagram
direction LR
class flow11111111-1111-1111-1111-111111111111["Sample Flow"]:::Flow {
    [String]ppc_ApiBaseUrl
    When_a_row_is_added(shared_commondataserviceforapps)
    When_a_row_is_added(ppc_order)
    Send_an_email(shared_office365)
    Update_row(shared_commondataserviceforapps)
    Update_row(ppc_orders)
    Create_orderline(shared_commondataserviceforapps)
    Create_orderline(ppc_orderlines)
}
class ppc_ApiBaseUrl:::EnvVar {
  EnvironmentalVariable
}
class ppc_NotificationEmail:::EnvVar {
  EnvironmentalVariable
}
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
class ppc_orders["ppc_Order"]:::Entity {
    [string]ppc_name
    [datetime]createdon
}
class ppc_orderlines["ppc_OrderLine"]:::Entity {
    [int]ppc_quantity
    [status]statuscode
}
class systemuser:::DefaultEntity
class ppc_ModelApp["Sales Model App"]:::ModelDrivenApp
class ppc_script_OrderForm_js["Order Form Script"]:::WebResource
class ppc_script_Shared_js["ppc_script/Shared.js"]:::WebResource
ppc_ApiBaseUrl ..> flow11111111-1111-1111-1111-111111111111:ppc_ApiBaseUrl
shared_commondataserviceforapps --> flow11111111-1111-1111-1111-111111111111:shared_commondataserviceforapps
flow11111111-1111-1111-1111-111111111111 --> ppc_order:ppc_order
flow11111111-1111-1111-1111-111111111111 --> flow22222222-2222-2222-2222-222222222222:Call_Child_Workflow
shared_office365 --> flow11111111-1111-1111-1111-111111111111:shared_office365
flow11111111-1111-1111-1111-111111111111 --> ppc_orders:ppc_orders
flow11111111-1111-1111-1111-111111111111 --> ppc_orderlines:ppc_orderlines
ppc_orderlines --> ppc_orders:ppc_OrderLine-OneToMany
ppc_orders --> systemuser:ManyToOne
ppc_ModelApp --> flow11111111-1111-1111-1111-111111111111:Flow
ppc_ModelApp --> ppc_orders:Entity
ppc_ModelApp --> ppc_orderlines:Entity
ppc_ModelApp --> ppc_script_OrderForm_js:Script
ppc_script_Shared_js --> ppc_script_OrderForm_js:Dependency
classDef default fill:red,stroke:#5E5B52
classDef EnvVar fill:#DF9A57,stroke:#5E5B52
classDef Connection fill:#FCD757,stroke:#5E5B52
classDef Entity fill:#B56784,stroke:#5E5B52
classDef DefaultEntity fill:#71374D,stroke:#5E5B52
classDef Flow fill:#DBE4EE,stroke:#5E5B52
classDef CanvasApp fill:#8BC34A,stroke:#5E5B52
classDef ModelDrivenApp fill:#7BAFD4,stroke:#5E5B52
classDef WebResource fill:#D7C8F3,stroke:#5E5B52
:::
