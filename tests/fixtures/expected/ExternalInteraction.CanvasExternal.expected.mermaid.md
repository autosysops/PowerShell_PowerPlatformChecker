:::mermaid
graph LR;
solution_canvas_external_solution["canvas-external-solution"]:::Solution
externaldomain_https_contoso_sharepoint_com["contoso.sharepoint.com"]:::ExternalDomain
shared_sharepointonline["shared_sharepointonline"]:::Connection
solution_canvas_external_solution -->|App-01 GET| externaldomain_https_contoso_sharepoint_com
solution_canvas_external_solution -->|App-01 SET| externaldomain_https_contoso_sharepoint_com
solution_canvas_external_solution -->|App-01 GET C01 DomainUnresolved| shared_sharepointonline
solution_canvas_external_solution -->|App-01 SET C01 DomainUnresolved| shared_sharepointonline
classDef default fill:red,stroke:#5E5B52
classDef Connection fill:#FCD757,stroke:#5E5B52
classDef Entity fill:#B56784,stroke:#5E5B52
classDef DefaultEntity fill:#71374D,stroke:#5E5B52
classDef Flow fill:#DBE4EE,stroke:#5E5B52
classDef CanvasApp fill:#8BC34A,stroke:#5E5B52
classDef ModelDrivenApp fill:#7BAFD4,stroke:#5E5B52
classDef WebResource fill:#D7C8F3,stroke:#5E5B52
classDef ExternalDomain fill:#E6D3A3,stroke:#5E5B52
classDef Solution fill:#f5f5fa,stroke:#1A1A1A,stroke-width:2px;
:::