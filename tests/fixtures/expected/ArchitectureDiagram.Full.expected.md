:::mermaid
classDiagram
direction LR
class flow22222222-2222-2222-2222-222222222222["[CLOUD] Child Flow"]:::Flow {
    Notify(shared_office365)
}
class flow23232323-2323-2323-2323-232323232323["[CLOUD] Cloud HTTP profile flow"]:::Flow {
    [String]
}
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
class ppc_canvas_sales_0001["Sales Canvas App"]:::CanvasApp
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
    [lookup]ppc_supplier
    [lookup]ppc_techspec
    [datetime]createdon
}
class ppc_orderlines["ppc_OrderLine"]:::Entity {
    [int]ppc_quantity
    [status]statuscode
}
class ppc_productpricespecifications["ppc_ProductPriceSpecification"]:::Entity {
    [nvarchar]ppc_name
    [decimal]ppc_price
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
class ppc_ModelApp["Sales Model App"]:::ModelDrivenApp {
  [Entities]ppc_order
  [Entities]ppc_orderline
  [Entities]ppc_supplier
  [Entities]ppc_productpricespecification
  [Business Process Flows]11111111-1111-1111-1111-111111111111
  [Sitemap]ppc_ModelApp
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
ppc_ApiBaseUrl ..> flow11111111-1111-1111-1111-111111111111:ppc_ApiBaseUrl
shared_commondataserviceforapps --> flow11111111-1111-1111-1111-111111111111:shared_commondataserviceforapps
flow11111111-1111-1111-1111-111111111111 --> ppc_orders:ppc_order
flow11111111-1111-1111-1111-111111111111 --> flow22222222-2222-2222-2222-222222222222:Call_Child_Workflow
shared_office365 --> flow11111111-1111-1111-1111-111111111111:shared_office365
flow11111111-1111-1111-1111-111111111111 --> ppc_orders:ppc_orders
flow11111111-1111-1111-1111-111111111111 --> ppc_orderlines:ppc_orderlines
shared_commondataserviceforapps --> ppc_canvas_sales_0001:shared_commondataserviceforapps
shared_office365 --> ppc_canvas_sales_0001:shared_office365
ppc_canvas_sales_0001 --> ppc_orderlines:OrderLines
ppc_canvas_sales_0001 --> ppc_orders:Orders
ppc_canvas_sales_0001 --> systemuser:SystemUsers
ppc_orderlines --> ppc_orders:ppc_OrderLine-OneToMany
ppc_orders --> systemuser:ManyToOne
ppc_orders --> ppc_suppliers:ppc_Order-OneToMany
ppc_orders --> ppc_techspecs:ppc_Order-OneToMany
ppc_orders --> ppc_script_OrderForm_js:Script
ppc_ModelApp --> flow11111111-1111-1111-1111-111111111111:Flow
ppc_ModelApp --> ppc_orders:Entity
ppc_ModelApp --> ppc_orderlines:Entity
ppc_ModelApp --> ppc_productpricespecifications:Entity
ppc_ModelApp --> ppc_suppliers:Entity
ppc_script_OrderForm_js --> ppc_script_Shared_js:Dependency
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