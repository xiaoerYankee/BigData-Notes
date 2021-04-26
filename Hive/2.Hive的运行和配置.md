#### Hive的运行和配置

##### 1. 配置Hive

`Hive`用`XML`配置文件进行设置。配置文件为`hive-site.xml`，它在`Hive`的`conf`目录下。通过这个文件，可以设置每次运行`Hive`时希望`Hive`使用的选项。该目录下还包括`hive-default.xml`(其中记录`Hive`使用的选项及其默认值)。

传递`--config`选项参数给`hive`命令，可以通过这种方式重新定义`Hive`查找`hive-site.xml`文件的目录：

```shell
[hadoop@master ~]$ hive --config /opt/apps/hive-2.3.6/conf
```

这个选项指定的是包含配置文件的目录，而不是配置文件`hive-site.xml`本身。这对于有(对应于多个集群的)多个站点文件时很有用，可以方便地在这些站点文件之间进行切换。还有一种方法就是可以通过设置`HIVE_CONF_DIR`环境变量来指定配置文件目录，效果相同。

`Hive`还允许向`hive`命令传递`-hiveconf`选项来为单个会话(per-session)设置属性。可以使用下面的命令设定在会话中使用一个(伪分布)集群：

```shell
[hadoop@master ~]$ hive -hiveconf fs.defaultFS=hdfs://localhost \
-hiveconf mapreduce.framework.name=yarn \
-hiveconf yarn.resourcemanager.address=localhost:8032
```

`Hive`还允许在一个会话中`SET`命令更改设置。这个方便于为某个特定的查询修改`Hive`的设置非常有用。

```shell
hive> set hive.enforce.bucketing=true;
```

也可以使用只带属性名的`SET`命令查看任何属性的当前值：

```shell
hive> set hive.enforce.bucketing;
hive.enforce.bucketing=true
```

- `hive`配置优先级

  ```
  (1) Hive SET 命令
  (2) 命令行 -hiveconf 选项
  (3) hive-site.xml 和 Hadoop 站点文件(core-site.xml、hdfs-site.xml、mapred-site.xml、yarn-site.xml)
  (4) Hive 的默认值和 Hadoop 默认文件(core-default.xml、hdfs-default.xml、mapred-default.xml、yarn-default.xml)
  ```

##### 2. 执行引擎

`Hive`的原始设计是使用`MapReduce`作为执行引擎(目前仍然是默认的执行引擎)。目前，`Hive`的执行引擎还包括`Apache Tez`，另外`Hive`对`Spark`引擎也支持。`Tez`和`Spark`都是通用有向无环图(`DAG`)引擎，它们比`MapReduce`更加灵活，性能也更优越。

具体使用哪种引擎由属性`hive.execution.engine`来控制，其默认值为`mr`，如果需要切换执行引擎，只需要修改`hive.execution.engine`属性的值即可。

```shell
hive> set hive.execution.engine=tez;
hive> set hive.execution.engine=spark;
```

##### 3. 日志记录

`Hive`日志可以通过配置文件`cong/hive-log4j.properties`进行日志级别和其它日志的相关设置。还有一种可以在会话中通过`-hiveconf`选项指定日志输出的位置：

```shell
[hadoop@master ~]$ hive -hiveconf hive.log.dir='/tmp/${user.name}'
# 将日志打印到控制台，日志级别为 DEBUG
[hadoop@master ~]$ hive -hiveconf hive.root.logger=DEBUG,console
```

