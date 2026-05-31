# MySQL

Версионированные MySQL-профили для legacy и современных веток.

## Версии

| Версия | Примечание |
| --- | --- |
| `5.5` | legacy baseline |
| `5.6` | legacy baseline |
| `5.7` | распространенная legacy production-ветка |
| `8.0` | современный baseline |
| `8.4` | актуальный LTS-style baseline |

## Проверка Одной Версии

```bash
make validate-one TARGET=engines/mysql/versions/8.4
```

Каждая версия содержит `conf.d/00-base.cnf`, `conf.d/10-observability.cnf`, RAM-профили и Docker smoke runner.
