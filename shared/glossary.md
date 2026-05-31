# Глоссарий

| Термин | Значение |
| --- | --- |
| OLTP | Нагрузка с большим числом коротких транзакционных чтений/записей. |
| Working set | Подмножество данных/индексов, которое активно использует workload. |
| Buffer pool | Область памяти InnoDB для кеширования данных и индексов. |
| Shared buffers | Область памяти PostgreSQL для кеширования страниц БД. |
| WAL | Write-ahead log: журнал PostgreSQL для durability и replication. |
| Binlog | Бинарный журнал MySQL/MariaDB для replication и point-in-time recovery. |
| Checkpoint | Сброс dirty pages, чтобы recovery мог стартовать с известной точки. |
| Vacuum | Очистка PostgreSQL от dead tuples и обновление visibility metadata. |
| Durability | Гарантия, что подтвержденные записи переживут crash/restart согласно настройкам. |
| RPO | Recovery Point Objective: допустимое окно потери данных. |
| RTO | Recovery Time Objective: допустимая длительность восстановления. |
| Replication lag | Задержка между записью на primary и replay/apply на replica. |
| Slow query | Запрос, который превысил настроенный порог latency. |
| Saturation | Ресурс полностью занят, и запросы начинают вставать в очередь. |
