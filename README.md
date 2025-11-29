# Jun Bank Infrastructure

Jun Bank MSA의 **인프라 구성** 저장소입니다.

Docker Compose를 사용하여 전체 인프라를 관리합니다.

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
            │    :8080     │              │    :8081     │
            └──────────────┘              └──────────────┘
                    │                              │
                    └──────────────┬──────────────┘
                                   │
                    ┌──────────────┴──────────────┐
                    ▼                              ▼
            ┌──────────────┐              ┌──────────────┐
            │    Config    │              │    Eureka    │
            │    Server    │              │   Server 1,2 │
            │    :8888     │              │  :8761,:8762 │
            └──────────────┘              └──────────────┘
                                   │
           ┌───────────────────────┼───────────────────────┐
           ▼                       ▼                       ▼
   ┌──────────────┐       ┌──────────────┐       ┌──────────────┐
   │  PostgreSQL  │       │    Kafka     │       │    Zipkin    │
   │    :5432     │       │   Cluster    │       │    :9411     │
   └──────────────┘       └──────────────┘       └──────────────┘
```

---

## 구성 요소

| 디렉토리 | 설명 | 포트 |
|----------|------|------|
| `postgres/` | PostgreSQL + pgvector | 5432 |
| `kafka/` | Kafka 클러스터 (KRaft 3대) | 9092, 9093, 9094 |
| `tracing/` | Zipkin (분산 추적) | 9411 |
| `eureka-server/` | Eureka Server (이중화) | 8761, 8762 |
| `config-server/` | Config Server | 8888 |
| `gateway-server/` | Gateway Server (이중화) | 8080, 8081 |
| `elk/` | Elasticsearch, Logstash, Kibana | 9200, 5044, 5601 |
| `monitoring/` | Prometheus, Grafana, Alertmanager | 9090, 3000, 9093 |
| `nginx/` | Reverse Proxy, Load Balancer | 80, 443 |

---

## 실행 방법

### 전체 실행

```bash
cd infrastructure
docker-compose up -d
```

### 개별 실행

```bash
# PostgreSQL만 실행
docker-compose up -d postgres

# Kafka 클러스터만 실행
docker-compose up -d kafka-1 kafka-2 kafka-3

# 모니터링만 실행
docker-compose up -d prometheus grafana alertmanager
```

### 중지

```bash
docker-compose down

# 볼륨까지 삭제
docker-compose down -v
```

---

## 실행 순서

`depends_on`으로 자동 관리되지만, 수동 실행 시 순서:

| 단계 | 서비스 |
|------|--------|
| 1 | postgres, zipkin |
| 2 | kafka-1, kafka-2, kafka-3 |
| 3 | eureka-server-1, eureka-server-2 |
| 4 | config-server |
| 5 | gateway-server-1, gateway-server-2 |
| 6 | elasticsearch, logstash, kibana |
| 7 | prometheus, grafana, alertmanager |
| 8 | nginx |

---

## 디렉토리 구조

```
infrastructure/
├── docker-compose.yml              # extends로 전체 통합
├── README.md
│
├── postgres/
│   ├── docker-compose.yml
│   ├── config/
│   │   └── postgresql.conf         # 성능 튜닝 + pgvector
│   └── init/
│       └── 01-init-databases.sh    # DB 자동 생성
│
├── kafka/
│   └── docker-compose.yml          # KRaft 3대 + Kafka UI
│
├── tracing/
│   └── docker-compose.yml          # Zipkin
│
├── eureka-server/
│   └── docker-compose.yml          # Eureka 이중화
│
├── config-server/
│   └── docker-compose.yml          # Config Server
│
├── gateway-server/
│   └── docker-compose.yml          # Gateway 이중화
│
├── elk/
│   ├── docker-compose.yml
│   ├── logstash/
│   │   ├── config/
│   │   └── pipeline/
│   └── kibana/
│       └── config/
│
├── monitoring/
│   ├── docker-compose.yml
│   ├── prometheus/
│   │   └── config/
│   ├── grafana/
│   │   └── config/
│   └── alertmanager/
│       └── config/
│
├── nginx/
│   ├── docker-compose.yml
│   └── config/
│       ├── nginx.conf
│       └── conf.d/
│
└── data/                           # 볼륨 데이터 (.gitignore)
    ├── postgres/
    ├── kafka/
    ├── elasticsearch/
    └── ...
```

---

## 접속 정보

| 서비스 | URL | 계정 |
|--------|-----|------|
| PostgreSQL | localhost:5432 | postgres / postgres |
| Kafka UI | http://localhost:8989 | - |
| Eureka Dashboard | http://localhost:8761 | - |
| Config Server | http://localhost:8888 | - |
| Gateway | http://localhost:8080 | - |
| Kibana | http://localhost:5601 | - |
| Prometheus | http://localhost:9090 | - |
| Grafana | http://localhost:3000 | admin / admin |
| Alertmanager | http://localhost:9093 | - |
| Zipkin | http://localhost:9411 | - |

---

## 데이터베이스 목록

| DB | 사용자 | 서비스 |
|----|--------|--------|
| account_db | account | Account Service |
| transaction_db | transaction | Transaction Service |
| transfer_db | transfer | Transfer Service |
| card_db | card | Card Service |
| ledger_db | ledger | Ledger Service |
| user_db | user | User Service |
| auth_db | auth | Auth Server |

---

## 이중화 구성

| 서비스 | 인스턴스 | 로드밸런싱 |
|--------|----------|------------|
| Eureka Server | eureka-server-1, eureka-server-2 | Peer-to-Peer |
| Gateway Server | gateway-server-1, gateway-server-2 | Nginx (least_conn) |
| Kafka | kafka-1, kafka-2, kafka-3 | KRaft 클러스터 |

---

## Kafka 클러스터

| 설정 | 값 | 설명 |
|------|-----|------|
| `REPLICATION_FACTOR` | 3 | 모든 데이터를 3대에 복제 |
| `MIN_INSYNC_REPLICAS` | 2 | 최소 2대가 동기화되어야 쓰기 성공 |

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

---

## 주의사항

- `data/` 폴더는 `.gitignore`에 포함
- 운영 환경에서는 각 설정의 비밀번호 변경 필요
- 메모리 설정은 서버 사양에 맞게 조정