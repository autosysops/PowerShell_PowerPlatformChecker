:::mermaid
classDiagram
direction LR
class flow23232323-3434-4545-5656-676767676767["[DESKTOP] Desktop external profile flow"]:::Flow
class flow77777777-7777-7777-7777-777777777777["[DESKTOP] Desktop Sample Flow"]:::Flow {
    [INPUT]runtimeInput
    [OUTPUT]result
    [string]ppc_desktop_baseurl
    ConnectionReference(shared_desktopautomation)
    ConnectionReference(shared_uiflow)
}
class flow88888888-8888-8888-8888-888888888888["[DESKTOP] Desktop Quoted Metadata Flow"]:::Flow {
    [INPUT]account
}
class flow99999999-9999-9999-9999-999999999999["[DESKTOP] Desktop Manifest Connector Flow"]:::Flow {
    [OUTPUT]result
    ConnectionReference(shared_office365)
}
class ppc_desktop_baseurl:::EnvVar {
  EnvironmentalVariable
}
class shared_desktopautomation:::Connection {
  ConnectionReference
  shared_desktopautomation()
}
class shared_uiflow:::Connection {
  ConnectionReference
  shared_uiflow()
}
class shared_office365:::Connection {
  ConnectionReference
  shared_office365()
}
ppc_desktop_baseurl ..> flow77777777-7777-7777-7777-777777777777:ppc_desktop_baseurl
shared_desktopautomation --> flow77777777-7777-7777-7777-777777777777:shared_desktopautomation
shared_uiflow --> flow77777777-7777-7777-7777-777777777777:shared_uiflow
shared_office365 --> flow99999999-9999-9999-9999-999999999999:shared_office365
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