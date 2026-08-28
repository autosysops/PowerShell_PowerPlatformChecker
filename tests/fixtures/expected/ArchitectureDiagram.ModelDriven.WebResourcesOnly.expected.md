:::mermaid
classDiagram
direction LR
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
ppc_ModelApp --> ppc_script_OrderForm_js:Script
ppc_script_OrderForm_js --> ppc_script_Shared_js:Dependency
classDef default fill:red,stroke:#5E5B52
classDef ModelDrivenApp fill:#7BAFD4,stroke:#5E5B52
classDef WebResource fill:#D7C8F3,stroke:#5E5B52
:::