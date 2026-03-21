# mermaid-draw Test Samples

## Flowchart (LR)

```mermaid
graph LR
A --> B --> C
B --> D
D --> C
E --> A
```

## Flowchart (TD)

```mermaid
graph TD
A --> B
A --> C
B --> D
C --> D
```

## Sequence Diagram

```mermaid
sequenceDiagram
Alice->>Bob: Hello Bob!
Bob-->>Alice: Hi Alice!
Alice->>Bob: How are you?
Bob-->>Alice: Fine, thanks!
```

## Labeled Edges

```mermaid
graph LR
A -->|start| B
B -->|success| C
B -->|failure| D
D -->|retry| A
C -->|done| E
```

## Complex Flowchart (Multiple Paths)

```mermaid
graph TD
A --> B
A --> C
A --> D
B --> E
B --> F
C --> F
C --> G
D --> G
D --> H
E --> I
F --> I
G --> J
H --> J
I --> K
J --> K
```

## Complex Sequence Diagram (3-Party Communication)

```mermaid
sequenceDiagram
Client->>Server: POST /api/request
Server->>Database: SELECT * FROM users
Database-->>Server: rows
Server->>Cache: SET key value
Cache-->>Server: OK
Server-->>Client: 200 OK
Client->>Server: GET /api/status
Server-->>Client: 200 OK
```

## Self Messages + Multiple Participants

```mermaid
sequenceDiagram
participant UI
participant API
participant Worker
UI->>API: submit job
API->>API: validate input
API->>Worker: enqueue task
Worker->>Worker: process
Worker-->>API: result
API-->>UI: job complete
```