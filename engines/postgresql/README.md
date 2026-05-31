# PostgreSQL

Версионированные PostgreSQL-профили от `9.0` до современных major releases.

## Версии

| Версия | Примечание |
| --- | --- |
| `9.0`-`9.6` | legacy baseline |
| `10`-`13` | переходные major-версии |
| `14`-`17` | современный baseline |

## Проверка Одной Версии

```bash
make validate-one TARGET=engines/postgresql/versions/17
```

Каждая версия содержит `conf/postgresql.conf`, `conf/conf.d/00-base.conf`, `conf/conf.d/10-observability.conf`, RAM-профили и Docker smoke runner.
