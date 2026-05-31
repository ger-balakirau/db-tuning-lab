# Тестирование

Репозиторий проверяется двумя уровнями тестов.

## Статические Тесты

Основная команда:

```bash
make test
```

Она запускает:

- `bash -n` для `scripts/test-structure.sh`;
- `bash -n` для всех `tools/validate.sh`;
- проверку обязательных файлов каждой версии;
- проверку `1gb`, `2gb`, `4gb`, `8gb` профилей;
- проверку соответствия Docker image tag имени версии;
- `docker compose config` для всех compose-файлов, если Docker Compose доступен.

Эти проверки быстрые и подходят для CI.

## Runtime Smoke-Тесты

Для ручной проверки конкретной версии:

```bash
make validate-one TARGET=engines/mysql/versions/8.4
make validate-one TARGET=engines/mariadb/versions/11.4
make validate-one TARGET=engines/postgresql/versions/17
```

`validate.sh` поднимает контейнер, ждет healthcheck-ready состояние, выполняет простой SQL-запрос версии и затем удаляет контейнеры/volumes.

## Почему CI Не Поднимает Все Контейнеры

В репозитории намеренно есть очень старые версии. Некоторые Docker-теги могут быть удалены, плохо работать на новых kernel/runtime или долго скачиваться. Поэтому CI отвечает за целостность структуры и compose-конфигов, а runtime smoke остается целевой ручной проверкой.
