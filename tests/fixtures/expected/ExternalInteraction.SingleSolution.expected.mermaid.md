:::mermaid
graph LR;
solution_anonymized_solution["anonymized-solution"]:::Solution
externaldomain_internet["internet"]:::ExternalDomain
shared_commondataserviceforapps["shared_commondataserviceforapps"]:::Connection
shared_office365["shared_office365"]:::Connection
externaldomain_internet -->|Flow-01 INBOUND| solution_anonymized_solution
externaldomain_internet -->|Flow-03 INBOUND C01| solution_anonymized_solution
solution_anonymized_solution -->|App-01 Unknown C01 DomainUnresolved| shared_commondataserviceforapps
solution_anonymized_solution -->|App-01 Unknown C02 DomainUnresolved| shared_office365
classDef default fill:red,stroke:#5E5B52
classDef Connection fill:#FCD757,stroke:#5E5B52
classDef Entity fill:#B56784,stroke:#5E5B52
classDef DefaultEntity fill:#71374D,stroke:#5E5B52
classDef Flow fill:#DBE4EE,stroke:#5E5B52
classDef CanvasApp fill:#8BC34A,stroke:#5E5B52
classDef ModelDrivenApp fill:#7BAFD4,stroke:#5E5B52
classDef WebResource fill:#D7C8F3,stroke:#5E5B52
classDef Solution fill:#f5f5f5,stroke:#111111,stroke-width:2px;
classDef ExternalDomain fill:#E6D3A3,stroke:#5E5B52
:::
