# Jun Bank Infrastructure

Jun Bank MSA의 **인프라 구성** 저장소입니다.

Docker Compose의 `extends`를 사용하여 전체 인프라를 단일 명령어로 관리합니다.

---

## 아키텍처

```
                                    ┌─────────┐
                                    │  Nginx  │
                                    │   :80   │
                                    └────┬────┘
                                         │
                          ┌──────────────┴──────────────┐
                          ▼                              ▼
                  ┌──────────────┐              ┌──────────────┐
                  │   Gateway    │              │   Gateway    │
                  │  Server 1    │              │  Server 2    │
                  │    :8080     │              │    :8089     │
                  └──────────────┘              └──────────────┘
                          │                              │
                          └──────────────┬──────────────┘
                                         │
            ┌────────────────────────────┼────────────────────────────┐
            ▼                            ▼                            ▼
    ┌──────────────┐            ┌──────────────┐            ┌──────────────┐
    │    Config    │            │    Eureka    │            │    Auth      │
    │    Server    │            │  Server 1,2  │            │    Server    │
    │    :8888     │            │ :8761,:8762  │            │    :8086     │
    └──────────────┘            └──────────────┘            └──────────────┘
                                         │
    ┌────────────────────────────────────┼────────────────────────────────────┐
    │                                    │                                    │
    ▼                                    ▼                                    ▼
┌─────────┐  ┌─────────┐  ┌─────────┐  ┌─────────┐  ┌─────────┐  ┌─────────┐  ┌─────────┐
│  User   │  │ Account │  │  Trans  │  │Transfer │  │  Card   │  │ Ledger  │  │   ...   │
│ :8087   │  │  :8081  │  │  :8082  │  │  :8083  │  │  :8084  │  │  :8085  │  │         │
└─────────┘  └─────────┘  └─────────┘  └─────────┘  └─────────┘  └─────────┘  └─────────┘
    │             │             │             │             │             │
    └─────────────┴─────────────┴─────────────┴─────────────┴─────────────┘
                                         │
         ┌───────────────────────────────┼───────────────────────────────┐
         ▼                               ▼                               ▼
 ┌──────────────┐               ┌──────────────┐               ┌──────────────┐
 │  PostgreSQL  │               │    Kafka     │               │    Zipkin    │
 │    :5432     │               │   Cluster    │               │    :9411     │
 └──────────────┘               │ :9092-9094   │               └──────────────┘
                                └──────────────┘
```

---

## 서비스 목록

### 기본 인프라

| 서비스 | 포트 | 설명 |
|--------|------|------|
| PostgreSQL | 5432 | 데이터베이스 (pgvector 포함) |
| Kafka Cluster | 9092, 9093, 9094 | 메시지 브로커 (KRaft 3대) |
| Kafka UI | 8989 | Kafka 관리 UI |
| Zipkin | 9411 | 분산 추적 |

### Spring Cloud 인프라

| 서비스 | 포트 | 설명 |
|--------|------|------|
| Eureka Server 1 | 8761 | Service Discovery (이중화) |
| Eureka Server 2 | 8762 | Service Discovery (이중화) |
| Config Server | 8888 | 중앙 설정 관리 |
| Gateway Server 1 | 8080 | API Gateway (이중화) |
| Gateway Server 2 | 8089 | API Gateway (이중화) |

### 비즈니스 서비스

| 서비스 | 포트 | 설명 | 학습 포인트 |
|--------|------|------|------------|
| User Service | 8087 | 사용자 관리 | 기본 CRUD, Kafka Producer |
| Auth Server | 8086 | 인증/인가 | JWT, Spring Security |
| Account Service | 8081 | 계좌 관리 | **동시성 제어 (낙관적/비관적 락)** |
| Transaction Service | 8082 | 입출금 | **멱등성 (Idempotency Key)** |
| Transfer Service | 8083 | 이체 | **SAGA 패턴, Outbox 패턴** |
| Card Service | 8084 | 카드/결제 | **Resilience4j** |
| Ledger Service | 8085 | 원장/감사 | **Append-only, 이벤트 소싱** |

### 모니터링 & 로깅

| 서비스 | 포트 | 설명 |
|--------|------|------|
| Elasticsearch | 9200 | 로그 저장소 |
| Logstash | 5044 | 로그 수집 |
| Kibana | 5601 | 로그 시각화 |
| Prometheus | 9090 | 메트릭 수집 |
| Grafana | 3000 | 메트릭 시각화 |
| Alertmanager | 9093 | 알림 관리 |

### 프록시

| 서비스 | 포트 | 설명 |
|--------|------|------|
| Nginx | 80, 443 | 로드밸런서, 리버스 프록시 |

---

## 디렉토리 구조

```
infrastructure/
├── docker-compose.yml              # 메인 (extends로 모든 서비스 통합)
├── .gitignore
├── README.md
│
├── postgres/                       # 데이터베이스
│   ├── docker-compose.yml
│   ├── config/postgresql.conf
│   └── init/01-init-databases.sh
│
├── kafka/                          # 메시지 브로커
│   └── docker-compose.yml
│
├── tracing/                        # 분산 추적
│   └── docker-compose.yml
│
├── eureka-server/                  # Service Discovery
│   ├── docker-compose.yml
│   └── .env
│
├── config-server/                  # 중앙 설정
│   ├── docker-compose.yml
│   └── .env
│
├── gateway-server/                 # API Gateway
│   ├── docker-compose.yml
│   └── .env
│
├── elk/                            # 로깅 스택
│   ├── docker-compose.yml
│   ├── logstash/
│   └── kibana/
│
├── monitoring/                     # 모니터링 스택
│   ├── docker-compose.yml
│   ├── prometheus/
│   ├── grafana/
│   └── alertmanager/
│
├── nginx/                          # 로드밸런서
│   ├── docker-compose.yml
│   └── config/
│
├── services/                       # 비즈니스 서비스
│   ├── user-service/
│   │   ├── docker-compose.yml
│   │   └── .env
│   ├── auth-server/
│   │   ├── docker-compose.yml
│   │   └── .env
│   ├── account-service/
│   │   ├── docker-compose.yml
│   │   └── .env
│   ├── transaction-service/
│   │   ├── docker-compose.yml
│   │   └── .env
│   ├── transfer-service/
│   │   ├── docker-compose.yml
│   │   └── .env
│   ├── card-service/
│   │   ├── docker-compose.yml
│   │   └── .env
│   └── ledger-service/
│       ├── docker-compose.yml
│       └── .env
│
└── data/                           # 볼륨 데이터 (.gitignore)
    ├── postgres/
    ├── kafka/
    └── ...
```

---

## 실행 방법

### 전체 실행 (단일 명령어)

```bash
cd infrastructure
docker-compose up -d
```

> `docker-compose.yml`이 `extends`로 모든 서비스를 통합하므로 한 번에 실행됩니다.

### 개별 실행

```bash
# PostgreSQL만
docker-compose up -d postgres

# Kafka 클러스터만
docker-compose up -d kafka-1 kafka-2 kafka-3

# 특정 비즈니스 서비스만
docker-compose up -d user-service

# 모니터링만
docker-compose up -d prometheus grafana alertmanager
```

### 중지

```bash
# 전체 중지
docker-compose down

# 볼륨까지 삭제 (데이터 초기화)
docker-compose down -v
```

### 로그 확인

```bash
# 전체 로그
docker-compose logs -f

# 특정 서비스 로그
docker-compose logs -f user-service
docker-compose logs -f kafka-1
```

---

## 실행 순서 (depends_on으로 자동 관리)

| 단계 | 서비스 | 의존성 |
|------|--------|--------|
| 1 | postgres, zipkin | - |
| 2 | kafka-1, kafka-2, kafka-3 | - |
| 3 | eureka-server-1, eureka-server-2 | zipkin |
| 4 | config-server | eureka |
| 5 | gateway-server-1, gateway-server-2 | config-server, kafka |
| 6 | elasticsearch, logstash, kibana | - |
| 7 | prometheus, grafana, alertmanager | - |
| 8 | nginx | gateway |
| 9 | **비즈니스 서비스** (7개) | postgres, config-server, kafka |

---

## 이미지 빌드

각 서비스 이미지는 프로젝트 루트에서 빌드합니다:

```bash
# 프로젝트 루트에서 빌드
cd jun-bank/user-service
./gradlew bootJar
docker build -t jun-bank/user-service:latest .

# 또는 전체 빌드 스크립트 (예정)
./build-all.sh
```

### Dockerfile (공통)

각 서비스 프로젝트 루트에 동일한 Dockerfile이 있습니다:

```dockerfile
FROM eclipse-temurin:21-jdk
ARG JAR_FILE=build/libs/*.jar
COPY ${JAR_FILE} app.jar

ENTRYPOINT ["java", "-jar", "app.jar"]
```

### 이미지 이름 규칙

| 서비스 | 이미지 이름 |
|--------|------------|
| Eureka Server | `jun-bank/eureka-server:latest` |
| Config Server | `jun-bank/config-server:latest` |
| Gateway Server | `jun-bank/gateway-server:latest` |
| User Service | `jun-bank/user-service:latest` |
| Auth Server | `jun-bank/auth-server:latest` |
| Account Service | `jun-bank/account-service:latest` |
| Transaction Service | `jun-bank/transaction-service:latest` |
| Transfer Service | `jun-bank/transfer-service:latest` |
| Card Service | `jun-bank/card-service:latest` |
| Ledger Service | `jun-bank/ledger-service:latest` |

---

## 환경변수 (.env)

각 서비스의 `.env` 파일은 민감정보를 포함하므로 **Git에서 제외**됩니다.

### .env 파일 위치

```
infrastructure/
├── eureka-server/.env
├── config-server/.env
├── gateway-server/.env
└── services/
    ├── user-service/.env
    ├── auth-server/.env
    ├── account-service/.env
    ├── transaction-service/.env
    ├── transfer-service/.env
    ├── card-service/.env
    └── ledger-service/.env
```

### .env.example 복사

```bash
# 최초 설정 시
cp eureka-server/.env.example eureka-server/.env
cp config-server/.env.example config-server/.env
# ... 필요한 값 수정
```

---

## 접속 정보

| 서비스 | URL | 계정 |
|--------|-----|------|
| PostgreSQL | `localhost:5432` | postgres / postgres |
| Kafka UI | http://localhost:8989 | - |
| Eureka Dashboard | http://localhost:8761 | - |
| Config Server | http://localhost:8888 | - |
| Gateway (Nginx) | http://localhost | - |
| Gateway 1 (Direct) | http://localhost:8080 | - |
| Gateway 2 (Direct) | http://localhost:8089 | - |
| Kibana | http://localhost:5601 | - |
| Prometheus | http://localhost:9090 | - |
| Grafana | http://localhost:3000 | admin / admin |
| Alertmanager | http://localhost:9093 | - |
| Zipkin | http://localhost:9411 | - |

---

## 데이터베이스

### DB 목록 (자동 생성)

| Database | Username | Service |
|----------|----------|---------|
| user_db | user | User Service |
| auth_db | auth | Auth Server |
| account_db | account | Account Service |
| transaction_db | transaction | Transaction Service |
| transfer_db | transfer | Transfer Service |
| card_db | card | Card Service |
| ledger_db | ledger | Ledger Service |

### 접속 방법

```bash
# Docker 내부에서
docker exec -it jun-bank-postgres psql -U postgres

# 특정 DB 접속
docker exec -it jun-bank-postgres psql -U user -d user_db
```

---

## 이중화 구성

| 서비스 | 인스턴스 | 로드밸런싱 |
|--------|----------|------------|
| Eureka Server | eureka-server-1, eureka-server-2 | Peer-to-Peer |
| Gateway Server | gateway-server-1, gateway-server-2 | Nginx (least_conn) |
| Kafka | kafka-1, kafka-2, kafka-3 | KRaft 클러스터 |

### Kafka 클러스터 설정

| 설정 | 값 | 설명 |
|------|-----|------|
| REPLICATION_FACTOR | 3 | 모든 데이터를 3대에 복제 |
| MIN_INSYNC_REPLICAS | 2 | 최소 2대가 동기화되어야 쓰기 성공 |

**장애 시나리오:**
- 1대 장애 → 정상 동작 ✅
- 2대 장애 → 쓰기 불가 ❌ (읽기는 가능)

---

## 네트워크

모든 서비스는 `jun-bank-network` 브릿지 네트워크에서 통신합니다.

```yaml
networks:
  jun-bank-network:
    name: jun-bank-network
    driver: bridge
```

### 서비스 간 통신

```
# 서비스 이름으로 접근 (Docker DNS)
user-service → postgres:5432
user-service → kafka-1:9092
user-service → eureka-server-1:8761
user-service → config-server:8888
```

---

## 헬스체크

모든 서비스는 `/actuator/health` 엔드포인트로 헬스체크합니다.

```yaml
healthcheck:
  test: ["CMD", "wget", "-q", "--spider", "http://localhost:{PORT}/actuator/health"]
  interval: 30s
  timeout: 10s
  retries: 5
  start_period: 60s
```

### 상태 확인

```bash
# 전체 상태
docker-compose ps

# 헬스 상태만
docker ps --format "table {{.Names}}\t{{.Status}}"
```

---

## 주의사항

1. **`.env` 파일은 Git에서 제외됩니다** - 민감정보 포함
2. **`data/` 폴더는 Git에서 제외됩니다** - 볼륨 데이터
3. **운영 환경에서는 모든 비밀번호 변경 필수**
4. **메모리 설정은 서버 사양에 맞게 조정**
5. **서비스 시작 전 이미지 빌드 필요** (`jun-bank/*:latest`)

---

## 문제 해결

### 서비스가 시작되지 않을 때

```bash
# 로그 확인
docker-compose logs -f {service-name}

# 헬스체크 상태 확인
docker inspect --format='{{.State.Health.Status}}' {container-name}
```

### 네트워크 문제

```bash
# 네트워크 확인
docker network ls
docker network inspect jun-bank-network
```

### 포트 충돌

```bash
# 사용 중인 포트 확인
lsof -i :{port}
netstat -tlnp | grep {port}
```

### 볼륨 초기화

```bash
# 전체 볼륨 삭제 후 재시작
docker-compose down -v
docker-compose up -d
```