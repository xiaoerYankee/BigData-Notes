#### Flink-SQL-Clinet案例

##### 1. kafka-to-kafka

###### 1. 语法

```sql
CREATE TABLE user_info (
	user_id BIGINT,
	user_name STRING,
	sex STRING,
	age BIGINT
) WITH (
    'connector' = 'kafka',
    'topic' = 'sql_user_info',
    'properties.bootstrap.servers' = 'hadoop01:9092,hadoop02:9092,hadoop03:9092',
    'properties.group.id' = 'user_info',
    'scan.startup.mode' = 'earliest-offset',
    'format' = 'json'
);

CREATE TABLE user_info_sink (
	user_id BIGINT,
	user_name STRING,
	sex STRING,
	age BIGINT
) WITH (
    'connector' = 'kafka',
    'topic' = 'sql_user_info_sink',
    'properties.bootstrap.servers' = 'hadoop01:9092,hadoop02:9092,hadoop03:9092',
    'scan.startup.mode' = 'earliest-offset',
    'format' = 'json'
);

INSERT INTO user_info_sink
SELECT 
user_id,
user_name,
sex,
age
FROM user_info;
```

###### 2. 数据格式

```json
{"user_id": 1,"user_name": "zhangsan","sex": "female","age": 10}
{"user_id": "002","user_name": "zhangsan","sex": "female","age": 22}
```

##### 2. kafka-to-kafka（多表关联insert）

###### 1. 语法

```sql
CREATE TABLE user_base_info (
	user_id BIGINT,
	user_name STRING,
	sex STRING,
	age BIGINT
) WITH (
    'connector' = 'kafka',
    'topic' = 'flink_user_base_info',
    'properties.bootstrap.servers' = 'hadoop01:9092,hadoop02:9092,hadoop03:9092',
    'properties.group.id' = 'user_info',
    'scan.startup.mode' = 'earliest-offset',
    'format' = 'json'
);

CREATE TABLE user_job_info (
	user_id BIGINT,
	user_job STRING,
	salary DECIMAL
) WITH (
    'connector' = 'kafka',
    'topic' = 'flink_user_job_info',
    'properties.bootstrap.servers' = 'hadoop01:9092,hadoop02:9092,hadoop03:9092',
    'properties.group.id' = 'user_info',
    'scan.startup.mode' = 'earliest-offset',
    'format' = 'json'
);

CREATE TABLE user_all_info_kafka (
	user_id BIGINT,
	user_name STRING,
	sex STRING,
	age BIGINT,
	user_job STRING,
	salary DECIMAL
) WITH (
    'connector' = 'kafka',
    'topic' = 'flink_user_info',
    'properties.bootstrap.servers' = 'hadoop01:9092,hadoop02:9092,hadoop03:9092',
    'scan.startup.mode' = 'earliest-offset',
    'format' = 'json'
);

INSERT INTO user_all_info_kafka
SELECT
a.user_id,
a.user_name,
a.sex,
a.age,
b.user_job,
b.salary
FROM user_base_info a
JOIN user_job_info b ON a.user_id = b.user_id;
```

###### 2. 数据格式

```json
# flink_user_base_info
{"user_id": 1, "user_name": "zhangsan", "sex": "male", "age": 12}

# flink_user_job_info
{"user_id": 1, "user_job": "程序猿", "salary": 128.3}
```

##### 3. kafka-to-kafka（多表关联upsert）

###### 1. 语法

```sql
CREATE TABLE user_base_info (
	user_id BIGINT,
	user_name STRING,
	sex STRING,
	age BIGINT
) WITH (
    'connector' = 'kafka',
    'topic' = 'flink_user_base_info',
    'properties.bootstrap.servers' = 'hadoop01:9092,hadoop02:9092,hadoop03:9092',
    'properties.group.id' = 'user_info',
    'scan.startup.mode' = 'earliest-offset',
    'format' = 'json'
);

CREATE TABLE user_job_info (
	user_id BIGINT,
	user_job STRING,
	salary DECIMAL
) WITH (
    'connector' = 'kafka',
    'topic' = 'flink_user_job_info',
    'properties.bootstrap.servers' = 'hadoop01:9092,hadoop02:9092,hadoop03:9092',
    'properties.group.id' = 'user_info',
    'scan.startup.mode' = 'earliest-offset',
    'format' = 'json'
);

CREATE TABLE user_all_info_kafka (
	user_id BIGINT,
	user_name STRING,
	sex STRING,
	age BIGINT,
	user_job STRING,
	salary DECIMAL,
	PRIMARY KEY (user_id) NOT ENFORCED
) WITH (
    'connector' = 'upsert-kafka',
    'topic' = 'flink_user_info',
    'properties.bootstrap.servers' = 'hadoop01:9092,hadoop02:9092,hadoop03:9092',
    'key.format' = 'json',
    'value.format' = 'json'
);

INSERT INTO user_all_info_kafka
SELECT
a.user_id,
a.user_name,
a.sex,
a.age,
b.user_job,
b.salary
FROM user_base_info a
LEFT JOIN user_job_info b
ON a.user_id = b.user_id;
```

###### 2. 数据格式

```json
# flink_user_base_info
{"user_id": 1, "user_name": "zhangsan", "sex": "male", "age": 12}

# flink_user_job_info
{"user_id": 1, "user_job": "程序猿", "salary": 128.3}
```

###### 3. 注意事项

```
1.更新的宽表必须设定主键约束，并且connector类型为upsert-kafka
2.必须指定宽表中的value.format和key.format，可选（avro、json、csv）
```

