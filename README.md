# db-tuning-lab

Портфолио-лаборатория с версионированными профилями настройки MySQL, MariaDB и PostgreSQL. Репозиторий показывает подход к сопровождению баз данных разных поколений: от старых production-like версий до современных LTS/актуальных релизов.

## Что внутри

| Движок | Версии | Структура конфигов |
| --- | --- | --- |
| MySQL | `5.5`, `5.6`, `5.7`, `8.0`, `8.4` | `conf.d/*.cnf`, `conf.d/profiles/*.cnf` |
| MariaDB | `5.5`, `10.0`-`10.6`, `10.11`, `11.4` | `conf.d/*.cnf`, `conf.d/profiles/*.cnf` |
| PostgreSQL | `9.0`-`9.6`, `10`-`17` | `postgresql.conf`, `conf.d/*.conf`, `conf.d/profiles/*.conf` |

Каждая версия содержит:

- базовый конфиг с безопасными стартовыми настройками;
- observability-фрагмент для slow queries, checkpoints/lock waits и temp-file pressure;
- активные RAM-профили `1gb`, `2gb`, `4gb`, `8gb` с несколькими связанными параметрами;
- `tools/docker-compose.yml` для локального запуска версии;
- `tools/validate.sh` для smoke-проверки контейнера и фактически примененного профиля.

## Структура

```text
engines/
  mysql/versions/<ver>/
  mariadb/versions/<ver>/
  postgresql/versions/<ver>/
shared/
  formulas.md
  glossary.md
docs/
  profiles.md
  testing.md
scripts/
  test-structure.sh
  validate-version.sh
```

## Быстрый старт

Проверить структуру и shell-скрипты:

```bash
make test
```

Запустить smoke-тест одной версии через Docker. По умолчанию используется профиль `1gb`:

```bash
make validate-one TARGET=engines/mysql/versions/8.4
make validate-one TARGET=engines/postgresql/versions/17 PROFILE=4gb
```

Проверить современные baseline-версии MySQL, MariaDB и PostgreSQL:

```bash
make validate-current PROFILE=2gb
```

Прогнать все четыре RAM-профиля на актуальной тройке:

```bash
make validate-matrix
```

Smoke-runner использует отдельное Docker Compose project name для каждой комбинации engine/version/profile, поднимает БД с выбранным профилем и проверяет effective `innodb_buffer_pool_size` или `shared_buffers`. Это ловит ситуацию, когда файл выглядит убедительно, но сервер его вообще не прочитал.

Посмотреть все версии:

```bash
make list
```

## Как читать профили

Профили не являются универсальной production-рекомендацией. Это воспроизводимые стартовые templates, которые помогают показать:

- как меняется layout конфигов между семействами БД;
- какие global/cache/per-operation параметры обычно зависят от RAM и concurrency;
- где отделять base-настройки от observability и workload-specific профилей;
- как проверять, что выбранный профиль действительно применился;
- как держать legacy и современные версии в одном воспроизводимом layout.

Подробности: [docs/profiles.md](docs/profiles.md).

## Тесты и CI

CI не поднимает все 30 контейнеров, чтобы не зависеть от старых Docker image tags и не тратить много времени на pull. Статический job проверяет структуру, shell-синтаксис/ShellCheck, обязательные tuning-ключи, соответствие image tag версии директории и `docker compose config`. Отдельный runtime-smoke job реально поднимает современные baseline-версии MySQL 8.4, MariaDB 11.4 и PostgreSQL 17 с профилем `1gb` и проверяет effective настройки.

Подробности: [docs/testing.md](docs/testing.md).

## Ограничения

- Старые Docker-теги могут быть недоступны или не запускаться на современных хостах.
- Значения в профилях являются стартовыми эвристиками и требуют проверки на реальном workload, concurrency и latency storage.
- Для production нужны отдельные проверки durability, backup/restore, replication, observability и rollback-плана.
