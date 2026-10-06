# Тестирование

Репозиторий проверяется двумя уровнями тестов.

## Статические Тесты

Основная команда:

```bash
make test
```

Она запускает:

- `bash -n` для общих scripts;
- `bash -n` для всех `tools/validate.sh`;
- `shellcheck`, если он установлен;
- проверку обязательных файлов каждой версии;
- проверку обязательных tuning-ключей в `1gb`, `2gb`, `4gb`, `8gb` профилях;
- проверку соответствия Docker image tag имени версии директории;
- `docker compose config` для всех compose-файлов с выбранным profile mount, если Docker Compose доступен.

Эти проверки быстрые и выполняются в CI job `structure`.

## Runtime Smoke-Тесты

Для ручной проверки конкретной версии:

```bash
make validate-one TARGET=engines/mysql/versions/8.4
make validate-one TARGET=engines/mariadb/versions/11.4 PROFILE=2gb
make validate-one TARGET=engines/postgresql/versions/17 PROFILE=4gb
```

Каждый version-local `tools/validate.sh` — тонкая обертка над общим `scripts/validate-version.sh`. Runner:

1. Валидирует имя профиля.
2. Создает отдельный Compose project для engine/version/profile.
3. Подключает base + observability + ровно один RAM-profile.
4. Ждет готовности БД.
5. Сверяет effective настройку с выбранным профилем:
   - MySQL/MariaDB: `@@innodb_buffer_pool_size`;
   - PostgreSQL: `SHOW shared_buffers`.
6. Проверяет, что slow-query threshold/logging включены.
7. Печатает ключевые runtime settings и удаляет контейнеры вместе с volume.

Для современных baseline-версий:

```bash
make validate-current PROFILE=2gb
make validate-matrix
```

В GitHub Actions отдельный job `runtime-smoke` после успешного `structure` запускает `make validate-current PROFILE=1gb`. То есть CI действительно стартует MySQL 8.4, MariaDB 11.4 и PostgreSQL 17 и проверяет, что выбранные профили применились на работающих серверах.

## Почему CI Не Поднимает Все Контейнеры

В репозитории намеренно есть очень старые версии. Некоторые Docker-теги могут быть удалены, плохо работать на новых kernel/runtime или долго скачиваться. Поэтому CI не пытается стартовать legacy-матрицу из 30 версий: статически проверяет весь репозиторий, а runtime smoke ограничивает тремя современными baseline-версиями. Для legacy runtime-тест остается целевым ручным запуском.
