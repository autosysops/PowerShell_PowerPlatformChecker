:::mermaid
classDiagram
direction LR
class flow22222222-2222-2222-2222-222222222222["Child Flow"]:::Flow {
    Notify(shared_office365)
}
class shared_office365:::Connection {
  ConnectionReference
  Office 365 Outlook - Test()
}
class ppc_ModelApp["Sales Model App"]:::ModelDrivenApp
class ppc_script_OrderForm_js["Order Form Script"]:::WebResource
class ppc_script_Shared_js["ppc_script/Shared.js"]:::WebResource
shared_office365 --> flow22222222-2222-2222-2222-222222222222:shared_office365
ppc_ModelApp --> flow11111111-1111-1111-1111-111111111111:Flow
ppc_ModelApp --> ppc_orders:Entity
ppc_ModelApp --> ppc_orderlines:Entity
ppc_ModelApp --> ppc_script_OrderForm_js:Script
ppc_script_Shared_js --> ppc_script_OrderForm_js:Dependency
classDef default fill:red,stroke:#010203
classDef EnvVar fill:#DF9A57,stroke:#010203
classDef Connection fill:#FCD757,stroke:#010203
classDef Entity fill:#B56784,stroke:#010203
classDef DefaultEntity fill:#71374D,stroke:#010203
classDef Flow fill:#123456,stroke:#010203
classDef CanvasApp fill:#8BC34A,stroke:#010203
classDef ModelDrivenApp fill:#7BAFD4,stroke:#010203
classDef WebResource fill:#D7C8F3,stroke:#010203
:::
