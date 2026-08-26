:::mermaid
classDiagram
direction LR
class flow22222222-2222-2222-2222-222222222222["[CLOUD] Child Flow"]:::Flow {
    Notify(shared_office365)
}
class shared_office365:::Connection {
  ConnectionReference
  Office 365 Outlook - Test()
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
ppc_script_OrderForm_js --> ppc_script_Shared_js:Dependency
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
