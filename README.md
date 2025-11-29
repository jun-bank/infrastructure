# Jun Bank Infrastructure

Jun Bank MSA 인프라 구성을 위한 Docker Compose 파일 모음입니다.

---

## 구성 요소

| 디렉토리 | 설명 | 포트 |
|----------|------|------|
| `postgres/` | PostgreSQL + pgvector | 5432 |
| `kafka/` | Kafka 클러스터 (KRaft 3대) | 9092, 9093, 9094 |
| `elk/` | Elasticsearch, Logstash, Kibana | 9200, 5044, 5601 |
| `monitoring/` | Prometheus, Grafana, Alertmanager | 9090, 3000, 9093 |
| `tracing/` | Zipkin (분산 추적) | 9411 |
| `nginx/` | Reverse Proxy | 80, 443 |

---

## 실행 방법

### 전체 실행

```bash
docker-compose up -d
```

### 개별 실행

```bash
# PostgreSQL
docker-compose -f postgres/docker-compose.yml up -d

# Kafka
docker-compose -f kafka/docker-compose.yml up -d

# ELK
docker-compose -f elk/docker-compose.yml up -d

# Monitoring
docker-compose -f monitoring/docker-compose.yml up -d

# Tracing
docker-compose -f tracing/docker-compose.yml up -d

# Nginx
docker-compose -f nginx/docker-compose.yml up -d
```

### 종료

```bash
docker-compose down

# 볼륨까지 삭제
docker-compose down -v
```

---

## 디렉토리 구조

```
infrastructure/
├── docker-compose.yml              # 전체 통합 실행
├── .gitignore
├── README.md
│
├── postgres/
│   ├── docker-compose.yml          # PostgreSQL + pgvector
│   ├── config/
│   │   └── postgresql.conf         # 성능 튜닝 설정
│   └── init/
│       └── 01-init-databases.sh    # DB 초기화 스크립트
│
├── kafka/
│   └── docker-compose.yml          # KRaft 3대 클러스터 + Kafka UI
│
├── elk/
│   ├── docker-compose.yml
│   ├── logstash/
│   │   ├── config/
│   │   │   └── logstash.yml
│   │   └── pipeline/
│   │       └── logstash.conf
│   └── kibana/
│       └── config/
│           └── kibana.yml
│
├── monitoring/
│   ├── docker-compose.yml
│   ├── prometheus/
│   │   └── config/
│   │       ├── prometheus.yml
│   │       └── alert-rules.yml
│   ├── grafana/
│   │   ├── config/
│   │   │   ├── datasources.yml
│   │   │   └── dashboards.yml
│   │   └── dashboards/
│   │       └── .gitkeep
│   └── alertmanager/
│       └── config/
│           └── alertmanager.yml
│
├── tracing/
│   └── docker-compose.yml          # Zipkin
│
├── nginx/
│   ├── docker-compose.yml
│   └── config/
│       ├── nginx.conf
│       └── conf.d/
│           └── default.conf
│
└── data/                           # .gitignore 제외 (볼륨 데이터)
    ├── kafka/
    │   ├── kafka-1/
    │   ├── kafka-2/
    │   └── kafka-3/
    ├── elasticsearch/
    ├── prometheus/
    ├── grafana/
    ├── alertmanager/
    └── nginx/
        └── logs/
```

---

## 네트워크

모든 서비스는 `jun-bank-network` 브릿지 네트워크를 공유합니다.

---

## Kafka 클러스터 장애 대응

| 설정 | 값 | 설명 |
|------|-----|------|
| `REPLICATION_FACTOR` | 3 | 모든 데이터를 3대에 복제 |
| `MIN_INSYNC_REPLICAS` | 2 | 최소 2대가 동기화되어야 쓰기 성공 |

**장애 시나리오:**
- 1대 장애 → 정상 동작 ✅ (2대 동기화 유지)
- 2대 장애 → 쓰기 불가 ❌ (읽기는 가능)

---

## 이중화 구성

| 서비스 | 인스턴스 | 로드밸런싱 |
|--------|----------|------------|
| API Gateway | gateway-1, gateway-2 | Nginx (least_conn) |
| Eureka Server | eureka-1, eureka-2 | Nginx (least_conn) |
| Kafka | kafka-1, kafka-2, kafka-3 | KRaft 클러스터 |

**Nginx 로드밸런싱 설정:**
- `least_conn`: 최소 연결 수 기반 분배
- `max_fails=3`: 3회 실패 시 비정상 판정
- `fail_timeout=30s`: 30초 후 재시도
- `proxy_next_upstream`: 장애 시 다음 서버로 자동 전환

---

## 접속 정보

| 서비스 | URL | 계정 |
|--------|-----|------|
| PostgreSQL | localhost:5432 | postgres / postgres |
| Kafka UI | http://localhost:8989 | - |
| Kibana | http://localhost:5601 | - |
| Prometheus | http://localhost:9090 | - |
| Grafana | http://localhost:3000 | admin / admin |
| Alertmanager | http://localhost:9093 | - |
| Zipkin | http://localhost:9411 | - |

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