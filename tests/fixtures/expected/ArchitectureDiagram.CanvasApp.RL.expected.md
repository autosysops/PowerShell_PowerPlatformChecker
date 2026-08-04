:::mermaid
classDiagram
direction RL
class ppc_canvas_sales_0001["Sales Canvas App"]:::CanvasApp
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
}
class ppc_orderlines["ppc_OrderLine"]:::Entity {
    [int]ppc_quantity
}
class systemuser:::DefaultEntity
class ppc_script_OrderForm_js["Order Form Script"]:::WebResource
class ppc_script_Shared_js["ppc_script/Shared.js"]:::WebResource
shared_commondataserviceforapps --> ppc_canvas_sales_0001:shared_commondataserviceforapps
shared_office365 --> ppc_canvas_sales_0001:shared_office365
ppc_canvas_sales_0001 --> ppc_orderlines:OrderLines
ppc_canvas_sales_0001 --> ppc_orders:Orders
ppc_canvas_sales_0001 --> systemuser:SystemUsers
ppc_orderlines --> ppc_orders:ppc_OrderLine-OneToMany
ppc_orders --> systemuser:ManyToOne
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
