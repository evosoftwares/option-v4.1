# 📊 Template de Diagramas Mermaid

## 🎯 Objetivo
Template padronizado para criar diagramas Mermaid consistentes em toda a documentação.

## 📋 Tipos de Diagramas

### 1. Fluxo de Processo (Flowchart)
```mermaid
graph TD
    A[Início] --> B{Condição?}
    B -->|Sim| C[Processo 1]
    B -->|Não| D[Processo 2]
    C --> E[Fim]
    D --> E
```

### 2. Sequência de Interações (Sequence)
```mermaid
sequenceDiagram
    participant User
    participant App
    participant API
    participant Database
    
    User->>App: Solicita ação
    App->>API: Envia request
    API->>Database: Consulta dados
    Database-->>API: Retorna dados
    API-->>App: Processa response
    App-->>User: Mostra resultado
```

### 3. Arquitetura do Sistema (C4 Model)
```mermaid
graph TB
    subgraph "Frontend"
        A[Web App]
        B[Mobile App]
    end
    
    subgraph "Backend"
        C[API Gateway]
        D[Auth Service]
        E[Business Logic]
    end
    
    subgraph "Data"
        F[(Database)]
        G[Cache]
    end
    
    A --> C
    B --> C
    C --> D
    C --> E
    E --> F
    E --> G
```

### 4. Estados de Componente (State)
```mermaid
stateDiagram-v2
    [*] --> Idle
    Idle --> Loading: User action
    Loading --> Success: Request OK
    Loading --> Error: Request failed
    Success --> Idle
    Error --> Idle: Retry
```

### 5. Relacionamento de Dados (ER)
```mermaid
erDiagram
    USER ||--o{ TRIP : takes
    USER ||--o{ PAYMENT : makes
    TRIP ||--|| PAYMENT : has
    DRIVER ||--o{ TRIP : completes
    
    USER {
        string id PK
        string name
        string email
        string phone
    }
    
    TRIP {
        string id PK
        string user_id FK
        string driver_id FK
        datetime start_time
        datetime end_time
        decimal fare
    }
```

## 🎨 Padrões Visuais

### Cores por Tipo
- **Frontend**: `#4CAF50` (Verde)
- **Backend**: `#2196F3` (Azul)
- **Database**: `#FF9800` (Laranja)
- **External**: `#9C27B0` (Roxo)

### Ícones e Labels
- **Usuário**: 👤 User
- **Sistema**: 🖥️ System
- **API**: 🔌 API
- **Database**: 🗄️ DB
- **Cache**: ⚡ Cache

## 📝 Guia de Estilo

### Nomenclatura
- Use nomes descritivos em inglês
- Evite abreviações
- Use PascalCase para componentes
- Use camelCase para variáveis

### Organização
- Agrupe componentes relacionados
- Use subgraphs para contexto
- Mantenha fluxo da esquerda para direita
- Limite a 10 elementos por diagrama

## 🔄 Templates Prontos

### Template: Fluxo de Autenticação
```mermaid
graph TD
    A[Usuário abre app] --> B{Tem conta?}
    B -->|Sim| C[Tela de login]
    B -->|Não| D[Tela de registro]
    
    C --> E[Digita credenciais]
    D --> F[Preenche formulário]
    
    E --> G{Valida credenciais}
    F --> H{Valida dados}
    
    G -->|Válido| I[Login bem-sucedido]
    G -->|Inválido| J[Mostra erro]
    
    H -->|Válido| K[Cria conta]
    H -->|Inválido| L[Mostra erro]
    
    I --> M[Dashboard]
    K --> M
    J --> C
    L --> D
```

### Template: Fluxo de Viagem
```mermaid
sequenceDiagram
    participant P as Passageiro
    participant A as App
    participant S as Servidor
    participant D as Motorista
    
    P->>A: Solicita viagem
    A->>S: Envia request
    S->>D: Notifica motoristas
    D->>S: Aceita corrida
    S->>A: Confirma motorista
    A->>P: Mostra detalhes
    P->>A: Confirma
    A->>D: Inicia navegação
    D->>P: Inicia viagem
    P->>D: Finaliza viagem
    D->>S: Envia resumo
    S->>A: Processa pagamento
    A->>P: Mostra recibo
```

## 🎨 Personalização

### Adicionar Cores Personalizadas
```mermaid
graph TD
    classDef green fill:#4CAF50,stroke:#2E7D32
    classDef blue fill:#2196F3,stroke:#1565C0
    classDef orange fill:#FF9800,stroke:#E65100
    
    A[Start] --> B[Process 1]
    B --> C[Process 2]
    
    class A green
    class B blue
    class C orange
```

### Adicionar Ícones
```mermaid
graph TD
    A["📱 Mobile App"] --> B["🌐 API Gateway"]
    B --> C["🗄️ Database"]
    C --> D["⚡ Cache"]
```

## 🔧 Ferramentas Úteis

### Editores Online
- [Mermaid Live Editor](https://mermaid.live)
- [Mermaid Chart](https://mermaidchart.com)

### VS Code Extensions
- **Mermaid Preview**: Preview em tempo real
- **Markdown All in One**: Atalhos úteis
- **Mermaid Markdown Syntax Highlighting**: Colorização de sintaxe

## ✅ Checklist de Qualidade

Antes de publicar um diagrama:
- [ ] Todos os textos estão em português
- [ ] Cores seguem o padrão definido
- [ ] Fluxo é claro e lógico
- [ ] Não há mais de 10 elementos
- [ ] Legenda está incluída quando necessário
- [ ] Diagrama é responsivo
- [ ] Testado no modo escuro

## 📚 Exemplos Completos

Veja exemplos reais em:
- [Fluxo de Registro](../technical/flows/auth/user-registration.md)
- [Fluxo de Viagem](../technical/flows/trip/trip-request.md)
- [Arquitetura do Sistema](../technical/architecture/overview.md)

---

<div align="center">
  
**[← Voltar aos templates](./)** | **[Ver exemplos práticos →](../technical/flows/)**

</div>