# Формулы И Эвристики

Ниже не production-рецепты, а стартовые эвристики для lab-профилей. Реальные значения должны подтверждаться метриками и нагрузочным тестом.

## Входные Параметры

- `RAM`: память, доступная процессу БД.
- `dedicated`: БД одна на узле или делит память с приложениями.
- `max_connections`: ожидаемый предел одновременных подключений.
- `working_set`: объем активно читаемых/записываемых данных.
- `write_rate`: скорость записи, WAL/binlog pressure, replication needs.
- `durability`: требования к потере данных и latency.

## MySQL / MariaDB

Типовая отправная точка для `innodb_buffer_pool_size`:

| Тип хоста | Стартовое значение |
| --- | --- |
| co-located app + DB | `25%`-`50%` RAM |
| mostly dedicated DB | `50%`-`70%` RAM |
| very small VPS | оставить запас OS/page cache и PHP/app процессам |

Дополнительно проверять:

- `max_connections * per_connection_buffers`;
- redo/binlog write pressure;
- slow queries и missing indexes;
- temporary tables on disk;
- replication lag.

## PostgreSQL

Типовая отправная точка:

| Параметр | Стартовое значение |
| --- | --- |
| `shared_buffers` | `25%` RAM для dedicated DB, ниже для co-located |
| `effective_cache_size` | оценка OS cache + shared buffers |
| `work_mem` | считать от concurrency, а не от RAM напрямую |
| `maintenance_work_mem` | выше для vacuum/index maintenance, но с лимитом |

Дополнительно проверять:

- checkpoint frequency and write spikes;
- autovacuum activity;
- cache hit ratio;
- temp files;
- lock waits;
- WAL volume and archive pressure.

## Практическое Правило

Любая формула должна проходить три вопроса:

1. Что произойдет при пиковом concurrency?
2. Что случится при failover/restart/warmup?
3. Как быстро можно откатить конфиг?
