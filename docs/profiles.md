# Конфигурационные Профили

Профиль в этом репозитории — это маленький, версионируемый фрагмент конфигурации под типовой размер RAM. Он не заменяет нагрузочное тестирование, но задает понятную стартовую точку для разговора о tuning.

## Слои конфигурации

| Слой | Назначение |
| --- | --- |
| `00-base` | минимальные безопасные настройки, которые подходят большинству sandbox/dev запусков |
| `10-observability` | slow query logging, log duration и другие настройки видимости |
| `profiles/<ram>` | параметры, которые обычно масштабируются от доступной памяти |

Такой layout позволяет менять workload-specific профиль, не смешивая его с базовой эксплуатационной гигиеной.

## RAM-Профили

В репозитории есть четыре профиля:

| Профиль | Ожидаемый тип хоста |
| --- | --- |
| `1gb` | маленький VPS, dev/staging, минимальный запас памяти |
| `2gb` | типовой single-service VPS |
| `4gb` | небольшой production-like сервер или несколько сервисов рядом |
| `8gb` | выделенный DB-heavy узел малого проекта |

### MySQL / MariaDB

Профиль связывает несколько параметров, а не только размер buffer pool:

| Профиль | Buffer pool | Log buffer | Tmp/heap table | Thread cache | Table cache |
| --- | ---: | ---: | ---: | ---: | ---: |
| `1gb` | 256M | 16M | 16M | 16 | 512 |
| `2gb` | 768M | 32M | 32M | 32 | 1024 |
| `4gb` | 2G | 64M | 64M | 64 | 2048 |
| `8gb` | 5G | 64M | 64M | 100 | 4096 |

`tmp_table_size` и `max_heap_table_size` особенно важно оценивать вместе с concurrency: эти лимиты могут одновременно проявляться у нескольких соединений.

### PostgreSQL

PostgreSQL-профили активны и задают несколько memory-related GUC:

| Профиль | shared_buffers | effective_cache_size | work_mem | maintenance_work_mem |
| --- | ---: | ---: | ---: | ---: |
| `1gb` | 256MB | 640MB | 4MB | 64MB |
| `2gb` | 512MB | 1280MB | 8MB | 128MB |
| `4gb` | 1GB | 2560MB | 12MB | 256MB |
| `8gb` | 2GB | 5GB | 16MB | 512MB |

`work_mem` не является «памятью на соединение»: один запрос может одновременно использовать несколько sort/hash operations. Поэтому эти числа специально консервативные и должны проверяться на реальном плане запросов и concurrency.

## Как применять

1. Выбрать engine и major/minor версию.
2. Начать с base + observability.
3. Выбрать ровно один RAM profile через `PROFILE=1gb|2gb|4gb|8gb`.
4. Запустить `make validate-one TARGET=... PROFILE=...`.
5. Проверить реальные метрики: cache hit ratio, slow queries, checkpoint/write pressure, replication lag, disk latency.
6. Менять профиль только после измерений.

## Production-Чеклист

Перед использованием вне lab обязательно проверить:

- backup и restore на тестовом стенде;
- replica/bootstrap сценарий;
- лимиты подключений и file descriptors;
- disk IOPS/latency;
- durability-настройки под RPO/RTO;
- alerting по saturation и error rate;
- rollback к предыдущему конфигу.
