# Cреда для ETL-разработки в экосистеме Hadoop
`Red Hat 8.5` `Hadoop 2.10.1 ` `Spark 2.4.8` `Hive 2.3.9` `Airflow 1.10.12` <br>
`Docker` `Docker Compose` `OpenShift` `Kubernetes`

- Минимальные требования по памяти в режиме простоя - 2Gb RAM
- Требования для средней нагрузки для работы локально - 5Gb RAM
- Для работы на OpenShift - от 8Gb RAM
- По CPU утилизируются практически все выдаваемые ресурсы в режиме под нагрузкой.

**Локальные директории:** <br>
`/dags` - для DAG-скриптов под Airflow<br>
`/spark` - для PySpark-скриптов<br>
`/sql` - для HQL-скриптов

Среда состоит из двух контейнеров
- **hadoop** - все указанные выше инструменты экосистемы Hadoop 
- **postgres** - PostgreSQL 9.6, БД под metastore для Airflow и Hive

Пароль от PostgreSQL меняется в следующих местах:
- `/docker-compose.yml` - значение параметра `POSTGRES_PASSWORD`
- `/airflow.cfg` - значение параметра `sql_alchemy_conn`
- `/hive-site.xml` - значение параметра `javax.jdo.option.ConnectionPassword`
- `/openshift/pg-deployment.yaml`  - значение параметра `POSTGRES_PASSWORD`

## Локальное развертывание

```bash
docker-compose up -d
```

Вариант с принудительной пересборкой
```bash
docker-compose build --no-cache
docker-compose up -d
```

Локальные директории  `/dags` `/spark` и `/sql` будут синхронизированы
с соответствующими директориями в контейнере `~/airflow/dags` `~/share/spark` и `~/share/sql`.

Веб-интерфейс **Airflow** будет доступен по адресу http://localhost:8080.

Подключиться к Hive можно через DBeaver: `jdbc:hive2://localhost:10000` 
или через консоль самого контейнера командой `hive`.

Статические Variables для Airflow можно положить в файл `/airflow_variables.dev.json` - 
он запекается в образе и применяется при запуске контейнера.

## Развертывание в OpenShift / Kubernetes
Пример манифестов для развертывания двух отдельных контейнеров среды 
находятся в директории `/openshift`

### Сборка docker-образа
```bash
# аргумент USER_UID, к сожалению, узнаем постфактум - из манифеста POD`а, после его первого запуска, найдя значение `runAsUser` 
docker build . -t chernyakzv/hadoop-rhel8:1.02 --target openshift-env --build-arg USER_UID="1002710000"

# вариант с принудительной пересборкой
docker build . -t chernyakzv/hadoop-rhel8:1.02 --target openshift-env --build-arg USER_UID="1002710000" --no-cache
```
