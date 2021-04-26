#### Hive和HBase整合之后数据的存储位置

##### 1. 创建hive表

创建一张可以映射到Hbase的hive表

```sql
create table if not exists hive2hbase (
uid int,
uname string,
age int,
sex string
)
stored by 'org.apache.hadoop.hive.hbase.HBaseStorageHandler'
with serdeproperties(
"hbase.columns.mapping"=":key,base_info:name,base_info:age,base_info:sex"
)
tblproperties(
"hbase.table.name"="hive2hbase1"
);
```

插入两条数据

```sql
hive (default)> insert into hive2hbase values(1001, 'zhangsan', 23, 'female');
hive (default)> insert into hive2hbase values(1001, 'lisi', 24, null);
```

##### 2. 进入Hbase查看数据

在Hbase中列出所有的表信息，可以看到，产生了一张命名为hive2hbase的表

使用scan查看其中的数据，可以看到有一个rowkey为1001的数据

![](http://typora-image.test.upcdn.net/images/20200809160745.png)

在hbase的表hive2hbase1中插入一个rowkey为1002的两个值

```shell
hbase(main):001:0> put 'hive2hbase1', '1002', 'base_info:age', '23'
hbase(main):002:0> put 'hive2hbase1', '1002', 'base_info:name', 'zhangsan'
```

![](http://typora-image.test.upcdn.net/images/20200809160748.png)

##### 3. 在Hive中查询这个表的数据

![](http://typora-image.test.upcdn.net/images/20200809160751.png)

##### 4. 退出客户端

此时已经完成了Hive中的表可以在Hbase中查到，说明我们已经成功了

有一个问题，此时我们刚刚输入的数据是保存在哪里的呢，是在Hive中，还是在Hbase中

```
关闭hbase客户端，并停止hbase的服务（为了让数据flush到hdfs）
```

hbase的目录

![](http://typora-image.test.upcdn.net/images/20200809160754.png)

hive的目录

![](http://typora-image.test.upcdn.net/images/20200809160755.png)

通过以上的两张图可以明显的看出，数据是存储在hbase中

##### 5. 总结

经过以上验证，可以看出数据时存储在了hbase中

在hive中，查看这个表的描述信息，hive中表hive2hbase的存储目录是/user/hive/warehouse/hive2hbase

但是我们刚刚看了这个目录是空的，而且表的描述信息也是指向了这个目录，那么它是怎么获取到的hbase上的数据的呢？

![](http://typora-image.test.upcdn.net/images/20200809160800.png)

其实可以看到这个表的描述信息与普通表的描述信息稍有不同

![](http://typora-image.test.upcdn.net/images/20200809160803.png)

从图中可以看出parameters中，有一个hbase.columns.mapping的属性去映射hbase的表的相关列簇信息，再看一下mysql数据库中所维护的hive的元数据信息

![](http://typora-image.test.upcdn.net/images/20200809160808.png)

在TBLS表中我们可以看到表hive2hbase的表的id是61

![](http://typora-image.test.upcdn.net/images/20200809160812.png)

从TABLE_PARAMS这张表中可以看出，id为61的表有一个属性为hbase_table_name为hive2hbase1

```
个人觉得可能是通过这个属性和hbase中的表进行了关联，但仅仅也只是个人看法，如果有别的看法，欢迎探讨
```

