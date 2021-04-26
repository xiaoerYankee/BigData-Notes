#### SparkSQL概述

##### 1. SparkSQL是什么

SparkSQL是Spark用于结构化数据（structured data）处理的Spark模块。

##### 2. SparkSQL的发展

- 数据兼容方面：SparkSQL不但兼容Hive，还可以从RDD、parquet文件、JSON文件中获取数据，未来版甚至支持获取RDBMS数据以及cassandra等NOSQL数据
- 性能优化方面：出来才去In-Memory Columnar Storage、byte-code generation等优化技术外、将会引进Cost Model对查询进行动态评估、获取最佳物理计划等等
- 组件扩展方面：无论是SQL的语法解析器、分析器还是优化器都可以重新定义，进行扩展

最终Spark也因此发展出了两个分支：SparkSQL和Hive on Spark。

其中SparkSQL作为Spark生态的一员继续发展，而不再受限于Hive，只是兼容HIve；而Hive on Spark是一个Hive的发展计划，该计划将Spark作为Hive的底层引擎之一，也就是说，Hive不再受限于一个引擎，可以采用Map-Reduce、Tez、Spark等引擎。

SparkSQL为了简化RDD的开发，提高开发效率，提供了2个编程抽象，类似于Spark Core中的RDD：DataFrame和DataSet。

##### 3. SparkSQL特点

###### 1. 易整合

无缝的整合了SQL查询和Spark编程。

###### 2. 统一的数据访问

使用相同的方式连接不同的数据源。

###### 3. 兼容Hive

在已有仓库上直接运行SQL或者HiveSQL。

###### 4. 标准数据连接

通过JDBC或者ODBC来连接。

##### 4. DataFrame

DataFrame是一种以RDD为基础的分布式数据集，类似于传统数据库中的二维表格。DataFrame与RDD的主要区别在于，前者带有schema元信息，即DataFrame所表示的二维表数据集的每一列都带有名称和类型。这使得Spark SQL得以洞察更多的数据信息，从而对藏于DataFrame背后的数据源以及作用于DataFrame之上的变换进行了针对性的优化，最终达到大幅提升运行时效率的目标。由于RDD无从得知锁存数据元素的具体内部结构，Spark Core只能在stage层面进行简单、通用的流水线优化。

同时，DataFrame也支持嵌套数据类型（struct、array和map）。从API易用性的角度上看，DataFrame API提供的是一套高层的关系操作，比函数式的RDD API要更加友好。

DataFrame是为数据提供了Schema的视图，可以直接当做数据库中的一张表来对待。DataFrame也是懒执行的，但性能上比RDD要高，主要原因：优化的执行计划，即查询计划通过Spark catalyst optimiser进行优化。

逻辑查询计划优化就是一个利用基于关系代数的等价变换，将高成本的操作替换为低成本操作的过程。

##### 5. DataSet

DataSet是分布式数据集合。DataSet是Spark 1.6中添加的一个新抽象，是DataFrame的一个扩展。它提供了RDD的优化（强类型，使用强大的lambda函数的能力）以及SparkSQL优化执行引擎的优化。DataSet也可以使用功能性的转换（操作map，flatMap，filter等等）。

- DataSet是DataFrame API的一个扩展，是SparkSQL最新的数据抽象
- 用户友好的API风格，既具有类型安全检查也具有DataFrame的查询优化特性
- 用样例类来对DataSet中定义数据的结构信息，样例类中每个属性的名称直接映射到DataSet中的字段名称
- DataSet是强类型的
- DataFrame是DataSet的特例，DataFrame=DataSet[Row]，所以可以通过as方法将DataFrame转换为DataSet。Row是一个类型，所有的表结构信息都用Row来表示，获取数据时需要指定顺序