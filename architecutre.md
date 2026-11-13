```mermaid
flowchart TB
    A["Developer / GitHub Actions"]
    B["Deploy to Inactive Environment"]
    C["Health Check"]
    D["Production Approval"]
    E["Traffic Switch / Rollback"]
    F["Caddy Reverse Proxy"]
    G["Blue Container - Port 4000"]
    H["Green Container - Port 4001"]
    I["Production Users"]

    A --> B --> C --> D --> E
    E -. "Updates routing" .-> F
    I --> F
    F -->|"Blue active"| G
    F -. "Green standby" .-> H
    E -. "Rollback to previous" .-> F
  ```