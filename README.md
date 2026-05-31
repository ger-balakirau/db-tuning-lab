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
- observability-фрагмент для slow queries/logging;
- RAM-профили `1gb`, `2gb`, `4gb`, `8gb`;
- `tools/docker-compose.yml` для локального запуска версии;
- `tools/validate.sh` для smoke-проверки контейнера.

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
```

## Быстрый старт

Проверить структуру и shell-скрипты:

```bash
make test
```

Запустить smoke-тест одной версии через Docker:

```bash
make validate-one TARGET=engines/mysql/versions/8.4
make validate-one TARGET=engines/postgresql/versions/17
```

Посмотреть все версии:

```bash
make list
```

## Как читать профили

Профили не являются универсальной production-рекомендацией. Это воспроизводимые стартовые templates, которые помогают показать:

- как меняется layout конфигов между семействами БД;
- какие параметры обычно зависят от RAM;
- где отделять base-настройки от observability и workload-specific профилей;
- как держать старые версии проверяемыми в одном репозитории.

Подробности: [docs/profiles.md](docs/profiles.md).

## Тесты и CI

CI не поднимает все 30 контейнеров, чтобы не зависеть от старых Docker image tags и не тратить много времени на pull. Вместо этого он проверяет структуру, shell-синтаксис, наличие обязательных файлов, соответствие image tag версии директории и валидность `docker compose config`.

Подробности: [docs/testing.md](docs/testing.md).

## Ограничения

- Старые Docker-теги могут быть недоступны или не запускаться на современных хостах.
- Значения в профилях демонстрационные и требуют проверки на реальном workload.
- Для production нужны отдельные проверки durability, backup/restore, replication, observability и rollback-плана.
