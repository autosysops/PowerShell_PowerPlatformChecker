:::mermaid
classDiagram
direction TB
class flow11111111-1111-1111-1111-111111111111["[CLOUD] Sample Flow"]:::Flow {
    [String]ppc_ApiBaseUrl
    When_a_row_is_added(shared_commondataserviceforapps)
    When_a_row_is_added(ppc_orders)
    Send_an_email(shared_office365)
    Update_row(shared_commondataserviceforapps)
    Update_row(ppc_orders)
    Create_orderline(shared_commondataserviceforapps)
    Create_orderline(ppc_orderlines)
}
class ppc_ApiBaseUrl:::EnvVar {
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
class ppc_orders["ppc_Order"]:::Entity {
    [string]ppc_name
    [lookup]ppc_supplier
    [lookup]ppc_techspec
}
class ppc_orderlines["ppc_OrderLine"]:::Entity {
    [int]ppc_quantity
}
class ppc_suppliers["ppc_Supplier"]:::Entity {
    [nvarchar]ppc_suppliername
    [nvarchar]ppc_suppliernumber
}
class ppc_techspecs["ppc_TechSpec"]:::Entity {
    [nvarchar]ppc_code
    [nvarchar]ppc_description
}
class systemuser:::DefaultEntity
ppc_ApiBaseUrl ..> flow11111111-1111-1111-1111-111111111111:ppc_ApiBaseUrl
shared_commondataserviceforapps --> flow11111111-1111-1111-1111-111111111111:shared_commondataserviceforapps
flow11111111-1111-1111-1111-111111111111 --> ppc_orders:ppc_order
shared_office365 --> flow11111111-1111-1111-1111-111111111111:shared_office365
flow11111111-1111-1111-1111-111111111111 --> ppc_orders:ppc_orders
flow11111111-1111-1111-1111-111111111111 --> ppc_orderlines:ppc_orderlines
ppc_orders --> systemuser:ManyToOne
ppc_orders --> ppc_suppliers:ppc_Order-OneToMany
ppc_orders --> ppc_techspecs:ppc_Order-OneToMany
ppc_orderlines --> ppc_orders:ppc_OrderLine-OneToMany
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