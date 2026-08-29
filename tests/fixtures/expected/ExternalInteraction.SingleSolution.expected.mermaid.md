:::mermaid
graph LR;
solution_anonymized_solution["anonymized-solution"]:::Solution
externaldomain_internet["internet"]:::ExternalDomain
externaldomain_https_api_contoso_example["https://api.contoso.example"]:::ExternalDomain
shared_commondataserviceforapps["shared_commondataserviceforapps"]:::Connection
shared_office365["shared_office365"]:::Connection
externaldomain_internet -->|Flow-01 INBOUND Manual| solution_anonymized_solution
externaldomain_internet -->|Flow-02 INBOUND manual| solution_anonymized_solution
solution_anonymized_solution -->|Flow-02 GET CallApi_https| externaldomain_https_api_contoso_example
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
classDef Solution fill:#f5f5fa,stroke:#1A1A1A,stroke-width:2px;
classDef ExternalDomain fill:#E6D3A3,stroke:#5E5B52
:::