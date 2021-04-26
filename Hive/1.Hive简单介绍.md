#### Hive简单介绍

##### 1. Hive是什么？

Hive是一个构建在Hadoop上的数据仓库框架，是应`Facebook`每天产生的海量新兴社会网络数据进行管理和（机器）学习的需求而产生和发展的。Hive可以将结构化的数据映射成为一张二维表，并提供了HQL（Hive SQL）进行查询和分析的功能，它的底层数据存储在HDFS中，可以实现大规模数据集的存储及处理。Hive的本质是将SQL语句转换为MapReduce任务执行的，但后期版本也推出了可以将Hive的执行引擎换成Spark或者Tez，提供HQL的好处就是为了使得使用Hive更加简单，可以方便不熟悉MapReduce的人员快速上手Hive，适用于进行离线的、海量的数据计算。

##### 2. Hive的shell环境

###### 1. 交互式shell 

安装完成Hive之后，Hive提供的shell环境可以通过进入类似MySQL的客户端进行操作，命令必须以分号结束。

```shell
hive> show tables;
```

###### 2. 非交互式shell

也可以使用非交互式模式使用Hive的shell环境，使用`-f`选项可以运行指定文件中的命令。

```shell
[hadoop@master ~]$ hive -f script.sql
```

如果是较短的脚本，也可以使用`-e`命令在行内嵌入命令，此时不需要分号。

```shell
[hadoop@master ~]$ hive -e 'select * from tableName'
```

###### 3. 选项`-S`

对于交互式或者非交互式的shell模式，Hive都会将操作运行时的信息打印输出到标准错误输出（standard error），可以使用`-S`选项强制不显示这些信息，只显示查询结果：

```shell
[hadoop@master ~]$ hive -S -e 'select * from tableName'
```

##### 3. Hive的简单示例

###### 1. 创建一张表

```sql
create table tableName (id int, name string, age int)-- 声明创建一个tableName表，表中有三列
row foramt delimited-- 声明数据文件的每一行数据使用换行符分隔
fields terminated by '\t';-- 声明数据文件的每一行是由制表符分隔的文本
```

###### 2. 加载数据文件

```sql
load data local inpath '/home/hadoop/tableData/person.txt'
overwrite into table tableName;
```

正常情况下，一个HDFS的表目录下可以有多个数据文件，使用`local`关键字代表从服务器本地上传文件到HDFS上的表目录下，使用`overwrite`关键字可以将表目录下的数据文件全部删除，如果不使用此关键字就只是简单的将该数据文件放到HDFS上的表目录中，如果有重名的文件则覆盖。