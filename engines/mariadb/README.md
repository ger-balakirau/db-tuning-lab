# MariaDB

Версионированные MariaDB-профили от старых совместимых веток до современных LTS.

## Версии

| Версия | Примечание |
| --- | --- |
| `5.5` | legacy baseline |
| `10.0`-`10.6` | распространенные исторические production-ветки |
| `10.11` | long-term support baseline |
| `11.4` | современный baseline |

## Проверка Одной Версии

```bash
make validate-one TARGET=engines/mariadb/versions/11.4
```

Каждая версия содержит `conf.d/00-base.cnf`, `conf.d/10-observability.cnf`, RAM-профили и Docker smoke runner.
