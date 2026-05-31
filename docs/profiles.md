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

Для MySQL/MariaDB главный демонстрационный параметр — `innodb_buffer_pool_size`. Для PostgreSQL профили держат commented examples вокруг `shared_buffers`, потому что старые версии и разные workload часто требуют более осторожного включения.

## Как применять

1. Выбрать engine и major/minor версию.
2. Начать с base + observability.
3. Подключить один RAM profile.
4. Запустить `tools/validate.sh`.
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
