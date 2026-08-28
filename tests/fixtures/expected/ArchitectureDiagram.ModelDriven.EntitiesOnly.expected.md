:::mermaid
classDiagram
direction LR
class ppc_orders["ppc_Order"]:::Entity {
    [string]ppc_name
    [lookup]ppc_supplier
    [lookup]ppc_techspec
}
class ppc_orderlines["ppc_OrderLine"]:::Entity {
    [int]ppc_quantity
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
class ppc_ModelApp["Sales Model App"]:::ModelDrivenApp {
  [Entities]ppc_order
  [Entities]ppc_orderline
  [Entities]ppc_supplier
  [Entities]ppc_productpricespecification
  [Business Process Flows]11111111-1111-1111-1111-111111111111
  [Sitemap]ppc_ModelApp
}
ppc_orders --> ppc_suppliers:ppc_Order-OneToMany
ppc_orders --> ppc_techspecs:ppc_Order-OneToMany
ppc_orderlines --> ppc_orders:ppc_OrderLine-OneToMany
ppc_ModelApp --> ppc_orders:Entity
ppc_ModelApp --> ppc_orderlines:Entity
ppc_ModelApp --> ppc_productpricespecifications:Entity
ppc_ModelApp --> ppc_suppliers:Entity
classDef default fill:red,stroke:#5E5B52
classDef Entity fill:#B56784,stroke:#5E5B52
classDef ModelDrivenApp fill:#7BAFD4,stroke:#5E5B52
:::