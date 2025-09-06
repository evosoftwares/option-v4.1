# Diagramas Técnicos - OneSignal Integration

## Diagrama de Arquitetura Atual

```mermaid
graph TB
    subgraph "Application Layer"
        A[main.dart]
        B[OneSignalService]
        C[TokenManagementService]
        D[LocalNotificationService]
    end
    
    subgraph "External Services"
        E[OneSignal SDK]
        F[Supabase]
        G[SharedPreferences]
        H[Firebase]
    end
    
    subgraph "UI Layer"
        I[TestNotificationScreen]
        J[PassengerHomeScreen]
        K[DriverHomeScreen]
    end
    
    subgraph "Error Handling"
        L[ErrorLoggingService]
        M[ErrorNotificationService]
        N[GlobalErrorHandler]
    end
    
    A --> B
    A --> H
    B --> E
    B --> C
    B --> D
    B --> L
    B --> M
    C --> F
    C --> G
    I --> B
    J -.-> B
    K -.-> B
    L --> N
    M --> N
```

## Diagrama de Fluxo de Erros

```mermaid
flowchart TD
    A[Inicialização OneSignal] --> B{Plataforma?}
    B -->|Web| C[Setup Web Handlers]
    B -->|Mobile| D[Setup Mobile]
    
    C --> E{Sucesso?}
    D --> F{Sucesso?}
    
    E -->|Sim| G[Web Limitada]
    E -->|Não| H[Erro Web Genérico]
    
    F -->|Sim| I[Configurar Handlers]
    F -->|Não| J[Erro Mobile Genérico]
    
    I --> K[Registrar Player Data]
    K --> L{Sincronização?}
    
    L -->|Sucesso| M[✅ Inicializado]
    L -->|Falha| N[❌ Erro Silencioso]
    
    H --> O[Log Error]
    J --> O
    N --> O
    
    O --> P[Usuário não notificado]
```

## Diagrama de Estados Proposto

```mermaid
stateDiagram-v2
    [*] --> CheckingDependencies
    CheckingDependencies --> DependenciesMet : All OK
    CheckingDependencies --> DependenciesMissing : Missing
    
    DependenciesMissing --> RetryDependencies : Retry
    RetryDependencies --> DependenciesMet : Success
    RetryDependencies --> FailedDependencies : Max retries
    
    DependenciesMet --> Initializing
    Initializing --> WaitingPermissions
    
    WaitingPermissions --> PermissionsGranted : User allows
    WaitingPermissions --> PermissionsDenied : User denies
    
    PermissionsGranted --> RegisteringDevice
    PermissionsDenied --> LimitedFunctionality : Limited mode
    
    RegisteringDevice --> SyncingWithBackend
    SyncingWithBackend --> Ready : Success
    SyncingWithBackend --> SyncFailed : Retry
    
    Ready --> Active : User logged in
    Ready --> Inactive : User logged out
    
    Active --> ProcessingNotification : Notification received
    ProcessingNotification --> Active : Processed
    
    LimitedFunctionality --> Ready : Permissions granted later
    
    FailedDependencies --> ErrorState : Show error
    SyncFailed --> ErrorState : Show retry
    ErrorState --> [*] : App restart required
```

## Diagrama de Componentes Proposto

```mermaid
graph LR
    subgraph "Core Services"
        OS[OneSignalService]
        TM[TokenManager]
        NM[NotificationManager]
        AM[AnalyticsManager]
    end
    
    subgraph "State Management"
        SC[StateController]
        EC[EventController]
        PC[PermissionController]
    end
    
    subgraph "Data Layer"
        SP[SupabaseProvider]
        CP[CacheProvider]
        UP[UserProvider]
    end
    
    subgraph "Cross-cutting"
        EH[ErrorHandler]
        LH[LoggingHandler]
        MH[MetricsHandler]
    end
    
    OS --> SC
    OS --> TM
    OS --> NM
    OS --> AM
    
    SC --> EC
    SC --> PC
    
    TM --> SP
    TM --> CP
    
    NM --> UP
    
    OS --> EH
    OS --> LH
    OS --> MH
```

## Diagrama de Sequência - Retry Mechanism

```mermaid
sequenceDiagram
    participant App
    participant RetryManager
    participant OneSignalService
    participant ErrorHandler
    participant UserNotifier
    
    App->>RetryManager: initializeWithRetry()
    RetryManager->>OneSignalService: attempt 1
    OneSignalService-->>RetryManager: ❌ Network Error
    
    RetryManager->>RetryManager: wait(1s)
    RetryManager->>OneSignalService: attempt 2
    OneSignalService-->>RetryManager: ❌ Permission Denied
    
    RetryManager->>ErrorHandler: categorizeError()
    ErrorHandler-->>RetryManager: PermissionError
    
    RetryManager->>UserNotifier: showPermissionDialog()
    UserNotifier-->>App: Display dialog
    
    App->>UserNotifier: User grants permission
    UserNotifier->>RetryManager: permissionGranted
    
    RetryManager->>OneSignalService: attempt 3
    OneSignalService-->>RetryManager: ✅ Success
    RetryManager-->>App: Initialization complete
```

## Diagrama de Classes - Arquitetura Proposta

```mermaid
classDiagram
    class OneSignalService {
        -OneSignalConfig config
        -OneSignalState state
        -List~OneSignalHandler~ handlers
        +initialize() Future~bool~
        +dispose() void
        +sendNotification() Future~bool~
    }
    
    class OneSignalState {
        <<enumeration>>
        INITIALIZING
        READY
        ERROR
        LIMITED
    }
    
    class OneSignalConfig {
        +String appId
        +Duration retryDelay
        +int maxRetries
        +bool enableAnalytics
    }
    
    class OneSignalHandler {
        <<interface>>
        +handleNotification(Notification) void
        +handleError(Error) void
    }
    
    class TokenManager {
        +getPlayerId() Future~String?~
        +updateToken(String) Future~void~
        +validateToken(String) Future~bool~
    }
    
    class PermissionManager {
        +requestPermission() Future~PermissionStatus~
        +checkPermission() Future~PermissionStatus~
        +listenPermissionChanges() Stream~PermissionStatus~
    }
    
    class ErrorHandler {
        +handleInitializationError(Error) void
        +handleRuntimeError(Error) void
        +logError(Error, StackTrace) void
    }
    
    class StateNotifier {
        +state Stream~OneSignalState~
        +addListener(Function) void
        +removeListener(Function) void
    }
    
    OneSignalService --> OneSignalState
    OneSignalService --> OneSignalConfig
    OneSignalService --> OneSignalHandler
    OneSignalService --> TokenManager
    OneSignalService --> PermissionManager
    OneSignalService --> ErrorHandler
    OneSignalService --> StateNotifier
```

## Diagrama de Atividades - Processamento de Notificação

```mermaid
activityDiagram
    start
    :Notificação recebida
    :Verificar estado do app
    
    if (App em foreground?) then (sim)
      :Processar em foreground
      :Mostrar local notification
    else (não)
      :Deixar OneSignal processar
    endif
    
    :Extrair dados da notificação
    :Identificar tipo (trip/chat/update)
    
    switch (tipo)
      case trip:
        :Navegar para tela de viagem
      case chat:
        :Navegar para tela de chat
      case update:
        :Atualizar dados locais
    endswitch
    
    :Registrar analytics
    :Atualizar badge de notificações
    stop
```

## Diagrama de Implantação

```mermaid
graph TB
    subgraph "Client Device"
        subgraph "Flutter App"
            FA[Flutter App]
            OS[OneSignal Service]
            SM[State Management]
        end
        
        subgraph "Platform Layer"
            PL[Platform Channels]
            PS[iOS/Android SDK]
        end
    end
    
    subgraph "OneSignal Cloud"
        OSA[OneSignal API]
        OSD[OneSignal Dashboard]
        OSS[OneSignal SDK]
    end
    
    subgraph "Backend Services"
        SB[Supabase]
        FB[Firebase]
        AS[Analytics Service]
    end
    
    FA --> OS
    OS --> PL
    PL --> PS
    PS --> OSS
    OSS --> OSA
    
    OS --> SB
    OS --> FB
    OS --> AS
    
    OSA --> OSD
```

## Tabela de Comparação - Estado Atual vs Proposto

| Aspecto | Estado Atual | Proposto | Impacto |
|---------|--------------|----------|---------|
| **Inicialização** | Linear, sem retry | Retry com backoff | +95% confiabilidade |
| **Tratamento de Erros** | Genérico, silencioso | Contextual, visível | +90% UX |
| **Gerenciamento de Estado** | Memória apenas | Persistente + reativo | +100% consistência |
| **Comunicação** | Acoplamento direto | Event bus + DI | +80% manutenibilidade |
| **Web Support** | Limitado | Completo | +85% cobertura |
| **Performance** | 800-1200ms | 300-500ms | +60% velocidade |
| **Monitoramento** | Logs básicos | Analytics completo | +100% visibilidade |

## Métricas de Sucesso - Definição

### KPIs Técnicos
```yaml
initialization_success_rate:
  target: "> 98%"
  current: "~92%"
  
initialization_time:
  target: "< 500ms"
  current: "800-1200ms"
  
error_recovery_rate:
  target: "> 95%"
  current: "~70%"
  
permission_granted_rate:
  target: "> 85%"
  current: "unknown"
```

### Métricas de Negócio
```yaml
notification_delivery_rate:
  target: "> 99%"
  
user_engagement:
  target: "> 40% CTR"
  
retention_improvement:
  target: "> 15%"
```

---

**Documento complementar**: `onesignal_integration_analysis.md`