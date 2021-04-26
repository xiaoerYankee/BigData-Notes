#### Spark核心编程_RDD

##### 1. RDD创建

- 从集合（内存）中创建RDD

  从集合中创建RDD，Spark主要提供了两个方法：parallelize和makeRDD

  ```scala
  val sparkConf = new SparkConf().setMaster("local[*]").setAppName(this.getClass.getSimpleName.filter(!_.equals('$')))
  val sparkContext = new SparkContext(sparkConf)
  val rdd1 = sparkContext.parallelize(List(1, 2, 3, 4))
  val rdd2 = sparkContext.makeRDD(List(1, 2, 3, 4))
  ```

  从底层代码实现来讲，makeRDD方法其实就是parallelize方法

  ```scala
  def makeRDD[T: ClassTag] (
      seq: Seq[T],
      numSlices: Int = defaultParallelism): RDD[T] = withScope {
      parallelize(seq, numSlices)
  }
  ```

- 从外部存储（文件）创建RDD

  由外部系统的数据集创建RDD包括：本地的文件系统，所有Hadoop支持的数据集

  ```scala
  val SparkConf = new SparkConf().setMaster("local[*]").setAppName(this.getClass.getSimpleName.filter(!_.equals('$')))
  val SparkContext = new SparkContext(sparkConf)
  val fileRDD: RDD[String] = sparkContext.textFile("inputPath")
  fileRDD.collect().foreach(println)
  sparkContext.stop()
  ```

- 从其他RDD创建

  主要是通过一个RDD运算完成后，再产生新的RDD

- 直接创建RDD（new）

  使用new的方式直接构造RDD，一般由Spark框架自身使用

##### 2. RDD并行度与分区

默认情况下，Spark可以将一个作业切分多个任务后，发送给Executor节点并行计算，而能够并行计算的任务数量我们称之为并行度。这个数量可以在构建RDD时指定。

```scala
val sparkConf = new SparkConf().setMaster("local[*]").setAppName(this.getClass.getSimple.filter(!_.equals('$')))
val sparkContext = new SparkContext(sparkConf)
val dataRDD: RDD[Int] = sparkContext.makeRDD(List(1, 2, 3, 4), 4)
val fileRDD: RDD[String] = sparkContext.textFile("input", 2)
fileRDD.collect().foreach(println)
sparkContext.stop()
```

- 读取内存数据时，数据可以按照并行度的设定进行数据的分区操作，数据分区规则的Spark核心源码如下：

  ![](http://typora-image.test.upcdn.net/images/paration.jpg)

- 读取文件数据时，数据是按照Hadoop文件读取的规则进行切片分区，而切片规则和数据读取的规则有些差异，具体Spark核心源码如下：

  ![](http://typora-image.test.upcdn.net/images/paration-text.jpg)

##### 3. RDD转换算子

RDD根据数据处理方式的不同将算子整体上分为Value类型、双Value类型和Key-Value类型。

###### 1. Value类型

- map

  ```
  - 函数签名
    def map[U: ClassTag](f: T => U): RDD[U]
  - 函数说明
    将处理的数据逐条进行映射转换，这里的转换可以是类型的转换，也可以是值的转换。
  ```

- mapPartitions

  ```
  - 函数签名
    def mapPartitions[U: ClassTag](f: Iterator[T] => Itertor[U], preservesPartitionint: Boolean = false): RDD[U]
  - 函数说明
    将待处理的数据以分区为单位发送到计算节点进行处理，这里的处理是指可以进行任意的处理，哪怕是过滤数据。
  ```

<font color="#33CCFF">map和mapPartitions的区别？</font>

```
- 数据处理角度
  map算子在分区内一个数据一个数据的执行，类似于串行操作。而mapPartitions算子是以分区为单位进行批处理操作。

- 功能的角度
  map算子主要目的是将数据源中的数据进行转换和改变。但不会减少或增多数据。mapPartitions算子需要传递一个迭代器，返回一个迭代器，没有要求的元素的个数保持不变，所以可以增加或减少数据。

- 性能的角度
  map算子因为类似于串行操作，所以性能比较低，而是mapPartitions算子类似于批处理，所以性能高。但是mapPartitions算子会长时间的占用内存，那么这样会导致内存可能不够用，出现内存溢出的错误。所以在内存有限的情况下，不推荐使用。
```

- mapPartitionsWithIndex

  ```
  - 函数签名
    def mapPartitionsWithIndex[U: ClassTag](f: (Int, Itertor[T]) => Itertor[U], preservesPartitions: Boolean = false): RDD[U]
  - 函数说明
    将待处理的数据以分区为单位发送到计算节点进行处理，这里的处理是值可以进行任意的处理，哪怕是过滤数据，在处理同时可以获取当前分区索引。
  ```

- flatMap

  ```
  - 函数签名
    def flatMap[U: ClassTag](f: T => TraversableOnce[U]): RDD[U]
  - 函数说明
    将处理的数据进行扁平化后在进行映射处理，所以算子也称之为扁平映射。
  ```

- glom

  ```
  - 函数签名
    def glom(): RDD[Array[T]]
  - 函数说明
    将同一个分区的数据直接转换为相同类型的内存数组进行处理，分区不变。
  ```

- groupBy

  ```
  - 函数签名
    def groupBy[K](f: T => K)(implicit kt: ClassTag[K]): RDD[(K, Iterable[T])]
  - 函数说明
    将数据根据指定的规则进行分组，分区默认不变，但是数据会被打乱重新组合，我们将这样的操作称之为shuffle。极限情况下，数据可能被分在同一个分区中。
    一个组的数据在一个分区中，但是并不是说一个分区中只有一个组。
  ```

- filter

  ```
  - 函数签名
    def filter(f: T => Boolean): RDD[T]
  - 函数说明
    将数据根据指定的规则进行筛选过滤，符合规则的数据保留，不符合规则的数据丢弃。当数据进行筛选后，分区不变，但是分区内的数据可能不均衡，生产环境下，可能会出现数据倾斜。
  ```

- sample

  ```
  - 函数签名
    def sample(withReplacement: Boolean,
    	fraction: Double,
    	seed: Long = Utils.random.nextLong): RDD[T]
  - 函数说明
    根据指定的规则从数据集中抽取数据。
  ```

- distinct

  ```
  - 函数签名
    def distinct()(implicit ord: Ordering[T] = null): RDD[T]
    def distinct()(numPartitions: Int)(implicit ord: Ordering[T] = null): RDD[T]
  - 函数说明
    将数据集中重复的数据去重。
  ```

- coalesce

  ```
  - 函数签名
    def coalesce(numPartitions: Int, shuffle: Boolean = false,
    	partitionCoalescer: Option[PartitionCoalescer] = Option.empty)(implicit ord: Ordering[T] = null): RDD[T]
  - 函数说明
    根据数据量缩减分区，用于大数据集过滤后，提高小数据集的执行效率。当spark程序中，存在过多的小任务的时候，可以通过coalesce方法，收缩合并分区，减少分区的个数，减少任务调度成本。
  ```

- repartition

  ```
  - 函数签名
    def repartition(numPartitions: Int)(implicit ord: Ordering[T] = null): RDD[T]
  - 函数说明
    该操作内部其实执行的是coalesce操作，参数shuffle的默认值为true。无论将分区数多的RDD转换为分区数少的RDD，还是将分区数少的RDD转换为分区数多的RDD，repartition操作都可以完成，因为无论如果都会经shuffle过程。
  ```

- sortBy

  ```
  - 函数签名
    def sortBy[K](f: (T) => K,
    	ascending: Boolean = true,
    	numPartitions: Int = thie.partitions.length)(implicit ord: Ordering[K], ctag: ClassTag[K]): RDD[T]
  - 函数说明
    该操作作用域排序数据。在排序之前，可以将数据通过f函数进行处理，之后按照f函数处理的结果排序，默认为升序排列。排序后新产生的RDD的分区数与原RDD的分区数一致。中间存在shuffle的过程。
  ```

###### 2. 双Value类型

- intersection

  ```
  - 函数签名
    def intersection(other: RDD[T]): RDD[T]
  - 函数说明
    对源RDD和参数RDD求交集后返回一个新的RDD，要求两个RDD的数据类型要相同。
  ```

- union

  ```
  - 函数签名
    def union(other: RDD[T]): RDD[T]
  - 函数说明
    对源RDD和参数RDD求并集后返回一个新的RDD，要求两个RDD的数据类型要相同。
  ```

- subtract

  ```
  - 函数签名
    def subtract(other: RDD[T]): RDD[T]
  - 函数说明
    以一个RDD为主，去除两个RDD中重复元素，将其他元素保留下来，求差集。要求两个RDD的数据类型要相同。
  ```

- zip

  ```
  - 函数签名
    def zip[U: ClassTag](other: RDD[U]): RDD[(T, U)]
  - 函数说明
    将两个RDD中的元素，以键值对的形式进行合并。其中，键值对中的Key为第1个RDD中的元素，Value为第2个RDD中的相同位置的元素。要求两个RDD的分区数量并且分区中的元素个数也要相同。
  ```

###### 3. Key-Value类型

- partitionBy

  ```
  - 函数签名
    def partitionBy(partitioner: Partitioner): RDD[(K, V)]
  - 函数说明
    将数据按照指定Partitioner重新进行分区。Spark默认的分区器是HashPartitioner。Spark共有两个已经实现的分区器，分别是HashPartitioner和RangePartitioner，RangePartitioner主要用于排序时的分区器。如果重分区的分区器和当前RDD的分区器一样（分区器一样，分区数量一样），此时Spark并不会进行任何操作。
  ```

- reduceByKey

  ```
  - 函数签名
    def reduceByKey(func: (V, V) => V): RDD[(K, V)]
    def reduceByKey(func: (V, V) => V, numPartitions: Int): RDD[(K, V)]
  - 函数说明
    可以将数据按照相同的Key对Value进行聚合。Spark的聚合也是两两聚合，并且如果某个Key只存在一个值，是不参与运算的。会将数据打乱重组，存在shuffle操作。reduceByKey的分区内和分区间的计算规则是相同的。
  ```

- groupByKey

  ```
  - 函数签名
    def groupByKey(): RDD[(K, Iterable[V])]
    def groupByKey(numPartitions: Int): RDD[(K, Iterable[V])]
    def groupByKey(partitioner: Partitioner): RDD[(K, Iterable[V])]
  - 函数说明
    将分区的数据直接转换为相同类型的内存数组进行后续处理。会将数据打乱重组，存在shuffle操作。
  ```

<font color="#33CCFF">Spark中的操作必须落盘处理，不能在内存中等待。</font>

<font color="#33CCFF">reduceByKey与groupByKey的最主要区别在于：reduceByKey会在分区内对数据进行预聚合（combine），预聚合后会减少进行shuffle操作时与磁盘的IO操作，提高性能。</font>

```
- 从shuffle的角度：reduceByKey和groupByKey都存在shuffle的操作，但是reduceByKey可以在shuffle前对分区内相同Key的数据进行预聚合（combine）功能，这样会减少落盘的数据量，而groupByKey只是进行分组，不存在数据量减少的问题，reduceByKey性能比较高。
- 从功能的角度：reduceByKey其实包含分组和聚合的功能。groupByKey只能分组，不能聚合，所以在分组聚合的场合下，推荐使用reduceByKey，如果仅仅是分组而不需要聚合，那么还是只能使用groupByKey。
```

- aggregateByKey

  ```
  - 函数签名
    def aggregateByKey[U: ClassTag](zeroValue: U)(seqOp: (U, V) => U, combOp: (U, V) => U): RDD[(K, U)]
  - 函数说明
    将数据根据不同的规则进行分区内计算和分区间计算。参数列表中第一个是初始值，因为比较是两两间进行比较，第一个（K,V）进入时没有比较的对象，所以需要一个初始值。最终的返回数据结果应该和zeroValue的类型一致。
  ```

- foldByKey

  ```
  - 函数签名
    def foldByKey(zeroValue: V)(func: (V, V) => V): RDD[(K, V)]
  - 函数说明
    当分区内计算规则和分区间计算规则相同时，aggregateByKey可以简化为foldByKey。
  ```

- combineByKey

  ```
  - 函数签名
    def combineByKey[C](createCombiner: V => C,
    	mergeValue: (C, V) => C,
    	mergeCombiners: (C, C) => C): RDD[(K, C)]
  - 函数说明
    最通用的对Key-Value型的RDD进行聚集操作的聚集函数（aggregation function）。类似于aggregate()，combineByKey()允许用户返回值的类型与输入的不一致。
  ```

<font color="#33CCFF">reduceByKey、foldByKey、aggregateByKey、combineByKey的区别？</font>

```
reduceByKey：相同Key的第一个数据不进行任何计算，分区内和分区间计算规则相同。
foldByKey：相同Key的第一个数据和初始值进行分区内计算，分区内和分区间计算规则相同。
aggregateByKey：相同Key的第一个数据和初始化进行分区内计算，分区内和分区间计算规则可以不相同。
combineByKey：当计算时，发现数据结构不满足时，可以让第一个数据转换结构。分区内和分区间计算规则不相同。
```

```
三个参数：
      1.相同Key的第一条数据进行的处理函数
      2.表示分区内的处理函数
      3.表示分区间的处理函数

reduceByKey:
	combineByKeyWithClassTag[V]((v: V) => v, func, func, partitioner)

foldByKey:
	combineByKeyWithClassTag[V]((v: V) => cleanedFunc(createZero(), v), cleanedFunc, cleanedFunc, partitioner)

aggregateByKey:
	combineByKeyWithClassTag[U]((v: V) => cleanedSeqOp(createZero(), v), cleanedSeqOp, combOp, partitioner)

combineByKey:
	combineByKeyWithClassTag(createCombiner, mergeValue, mergeCombiners, partitioner, mapSideCombine, serializer)(null)
```

- sortByKey

  ```
  - 函数签名
    def sortByKey(ascending: Boolean = true, numPartitions: Int = self.partitions.length)
  - 函数说明
    在一个(K,V)的RDD上调用，K必须实现Ordered接口（特质），返回一个按照Key进行排序的。
  ```

- join

  ```
  - 函数签名
    def join[W](other: RDD[(K, W)]): RDD[(K, (V, W))]
  - 函数说明
    在类型为(K,V)的(K,W)的RDD上调用，返回一个相同Key对应的所有元素连接在一起的(K,(V,W))的RDD。两个不同数据源的数据，相同的Key的Value会连接在一起，形成元组；两个数据源的数据Key没有匹配上，那么数据不会出现在结果中；两个数据源的数据Key存在多个相同时，会依次匹配，可能会出现笛卡尔乘积，数据量会几何性增长，会导致性能降低。
  ```

- leftOuterJoin

  ```
  - 函数签名
    def leftOuterJoin[W](other: RDD[(K, W)]): RDD[(K, (V, Option[W]))]
  - 函数说明
    类似于SQL语句的左外连接。
  ```

- cogroup

  ```
  - 函数签名
    def cogroup[W](other: RDD[(K, W)]): RDD[(K, (Iterable[V], Iterable[W]))]
  - 函数说明
    在类型为(K,V)和(K,W)的RDD调用，返回一个(K,Iterable<V>,Iterable<W>))类型的RDD。
  ```

##### 4. RDD行动算子

- reduce

  ```
  - 函数签名
    def reduce(f: (T, T) => T): T
  - 函数说明
    聚集RDD中的所有元素，先聚合分区内数据，在聚合分区间数据。
  ```

- collect

  ```
  - 函数签名
    def collect(): Array[T]
  - 函数说明
    在驱动程序中，以数组Array的形式返回数据集的所有元素。会按照数据分区的顺序采集到Driver端的内存中，形成数组。
  ```

- count

  ```
  - 函数签名
    def count(): Long
  - 函数说明
    返回RDD中元素的个数。
  ```

- first

  ```
  - 函数签名
    def first(): T
  - 函数说明
    返回RDD中的第一个元素。
  ```

- take

  ```
  - 函数签名
    def take(num: Int): Array[T]
  - 函数说明
    返回一个由RDD的前n个元素组成的数组。
  ```

- takeOrdered

  ```
  - 函数签名
    def takeOrdered(num: Int)(implicit ord: Ordering[T]): Array[T]
  - 函数说明
    返回该RDD排序后的前n个元素组成的数据。
  ```

- aggregate

  ```
  - 函数签名
    def aggregate[U: ClassTag](zeroValue: U)(seqOp: (U, T) => U, combOp: (U, U) => U): U
  - 函数说明
    分区的数据通过初始值和分区内的数据进行聚合，然后再和初始值进行分区间的数据聚合。
  ```

- fold

  ```
  - 函数签名
    def fold(zeroValue: T)(op: (T, T) => T): T
  - 函数说明
    折叠操作，aggregate的简化操作。也就是说分区内和分区间的计算规则保持一致。
  ```

- countByKey

  ```
  - 函数签名
    def countByKey(): Map[K, Long]
  - 函数说明
    统计每种Key的个数。
  ```

- save相关的算子

  ```
  - 函数签名
    def saveAsTextFile(path: String): Unit
    def saveAsObjectFile(path: String): Unit
    def saveAsSequenceFile(path: String,
    	codec: Option[Class[_ <: CompressionCodec]] = None): Unit
  - 函数说明
    将数据保存到不同格式的文件中。
  ```

- foreach

  ```
  - 函数签名
    def foreach(f: T => Unit): Unit = withScope {
    	val cleanF = sc.clean(f)
    	sc.runJob(this, (iter: Itertor[T]) => iter.foreach(cleanF))
    }
  - 函数说明
    分布式遍历RDD中的每一个元素，调用指定函数。
  ```


##### 5. RDD序列化

###### 1. 闭包检查

从计算的角度，算子以外的代码都是在Driver端执行，算子里面的代码都是在Executor端执行。由于在Scala的函数式编程中，经常会出现算子内使用算子外的数据，这样就形成了闭包的效果，如果使用的算子外的数据无法序列化，就意味着无法传值给Executor端执行，就会发生错误，所以需要在执行任务计算前，检测闭包内的对象是否可以进行序列化，这个操作叫做闭包检测。

###### 2. 序列化方法和属性

算子以外的代码都是在Driver端执行，算子里面的代码都是在Executor端执行。所以对于类中的构造函数，其实在调用时省略了this，也就是经过了类的实例化，所以类要实现特质Serializable。

```scala
package com.yankee.spark.core.rdd.serial

import org.apache.spark.rdd.RDD
import org.apache.spark.{SparkConf, SparkContext}

/**
 * @author Yankee
 * @date 2021/3/15 21:35
 */
object Spark01_RDD_Serial {
  def main(args: Array[String]): Unit = {
    System.setProperty("HADOOP_USER_NAME", "hadoop")

    // TODO 创建环境
    val conf: SparkConf = new SparkConf().setMaster("local[*]").setAppName(this.getClass.getSimpleName.filter(!_.equals('$')))
    val sc: SparkContext = new SparkContext(conf)

    // TODO 业务逻辑
    val rdd: RDD[String] = sc.makeRDD(Array("hello world", "hello spark", "hello hive", "zookeeper"))

    val search: Search = new Search("h")

    // 需要闭包检测
    //search.getMatch1(rdd).collect().foreach(println)
    // 需要闭包检测
    //search.getMatch2(rdd).collect().foreach(println)
    // 不需要闭包检测
    search.getMatch3(rdd).collect().foreach(println)

    // TODO 关闭环境
    sc.stop()
  }

  // 类的构造参数其实是类的属性，构造参数需要进行闭包检测，其实就等同于类进行闭包检测
  class Search(query: String) /*extends Serializable*/ {
    def isMatch(s: String): Boolean = {
      s.contains(query)
    }

    // 函数序列化案例
    def getMatch1(rdd: RDD[String]): RDD[String] = {
      rdd.filter(isMatch)
    }

    // 属性序列化案例
    def getMatch2(rdd: RDD[String]): RDD[String] = {
      rdd.filter(x => x.contains(query))
    }

    // 这样可以不需要闭包检测
    def getMatch3(rdd: RDD[String]): RDD[String] = {
      val s: String = query
      rdd.filter(x => x.contains(s))
    }
  }
}
```

###### 3. Kryo序列化框架

Java的序列化能够序列化任何的类。但是比较重（字节多），序列化后，对象的提交也比较大。在大数据领域，如果字节较多会直接影响其在网络中的传输速度，所以Spark出于性能的考虑，Spark2.0开始支持另外一种Kryo序列化机制。Kryo速度是Serializable的10倍。当RDD在shuffle数据时，简单数据类型、数组和字符串类型已经在Spark内部使用kryo来序列化。

```scala
package com.yankee.spark.core.rdd.serial

import org.apache.spark.rdd.RDD
import org.apache.spark.{SparkConf, SparkContext}

/**
 * @author Yankee
 * @date 2021/3/15 22:06
 */
object Spark02_RDD_Kryo {
  def main(args: Array[String]): Unit = {
    System.setProperty("HADOOP_USER_NAME", "hadoop")

    // TODO 创建环境
    val conf: SparkConf = new SparkConf().setMaster("local[*]").setAppName(this.getClass.getSimpleName.filter(!_.equals('$')))
      .set("spark.serializer", "org.apache.spark.serializer.KryoSerializer")
      .registerKryoClasses(Array(classOf[Search]))
    val sc: SparkContext = new SparkContext(conf)

    // TODO 业务逻辑
    val rdd: RDD[String] = sc.makeRDD(Array("hello spark", "hello scala", "zookeeper"))
    val search: Search = Search("hello")
    search.getMatch(rdd).collect().foreach(println)

    // TODO 关闭环境
    sc.stop()
  }

  case class Search(query: String) {
    def isMatch(s: String): Boolean = {
      s.contains(query)
    }

    def getMatch(rdd: RDD[String]): RDD[String] = {
      rdd.filter(isMatch)
    }

    def getMatch2(rdd: RDD[String]): RDD[String] = {
      rdd.filter(x => x.contains(query))
    }
  }
}
```

##### 6. RDD依赖关系

###### 1. RDD血缘关系

RDD只支持粗粒度转换，即在大量记录上执行的单个操作。将创建RDD的一系列Lineage（血统）记录下来，以便恢复丢失的分区。RDD的Lineage会记录RDD的元数据信息和转换行为，当该RDD的部分分区数据丢失时，它可以根据这些信息来重新运算和恢复丢失的数据分区。

```scala
val lines: RDD[String] = sc.textFile("data/words.txt")
println(lines.toDebugString)
println("=====================================")
val flatMapRDD: RDD[String] = lines.flatMap(_.split(" "))
println(flatMapRDD.toDebugString)
println("=====================================")
val mapRDD: RDD[(String, Int)] = flatMapRDD.map((_, 1))
println(mapRDD.toDebugString)
println("=====================================")
val reduceRDD: RDD[(String, Int)] = mapRDD.reduceByKey(_ + _)
println(reduceRDD.toDebugString)
println("=====================================")
reduceRDD.collect().foreach(println)
```

```shell
# 其中(2)表示为分区个数
(2) data/words.txt MapPartitionsRDD[1] at textFile at Spark01_RDD_Depend.scala:19 []
 |  data/words.txt HadoopRDD[0] at textFile at Spark01_RDD_Depend.scala:19 []
=====================================
(2) MapPartitionsRDD[2] at flatMap at Spark01_RDD_Depend.scala:23 []
 |  data/words.txt MapPartitionsRDD[1] at textFile at Spark01_RDD_Depend.scala:19 []
 |  data/words.txt HadoopRDD[0] at textFile at Spark01_RDD_Depend.scala:19 []
=====================================
(2) MapPartitionsRDD[3] at map at Spark01_RDD_Depend.scala:26 []
 |  MapPartitionsRDD[2] at flatMap at Spark01_RDD_Depend.scala:23 []
 |  data/words.txt MapPartitionsRDD[1] at textFile at Spark01_RDD_Depend.scala:19 []
 |  data/words.txt HadoopRDD[0] at textFile at Spark01_RDD_Depend.scala:19 []
=====================================
(2) ShuffledRDD[4] at reduceByKey at Spark01_RDD_Depend.scala:29 []
 +-(2) MapPartitionsRDD[3] at map at Spark01_RDD_Depend.scala:26 []
    |  MapPartitionsRDD[2] at flatMap at Spark01_RDD_Depend.scala:23 []
    |  data/words.txt MapPartitionsRDD[1] at textFile at Spark01_RDD_Depend.scala:19 []
    |  data/words.txt HadoopRDD[0] at textFile at Spark01_RDD_Depend.scala:19 []
```

###### 2. RDD依赖关系

这里所谓的依赖关系，其实就是两个相邻RDD之间的关系。

```scala
val lines: RDD[String] = sc.textFile("data/words.txt")
println(lines.dependencies)
println("=====================================")
val flatMapRDD: RDD[String] = lines.flatMap(_.split(" "))
println(flatMapRDD.dependencies)
println("=====================================")
val mapRDD: RDD[(String, Int)] = flatMapRDD.map((_, 1))
println(mapRDD.dependencies)
println("=====================================")
val reduceRDD: RDD[(String, Int)] = mapRDD.reduceByKey(_ + _)
println(reduceRDD.dependencies)
println("=====================================")
reduceRDD.collect().foreach(println)
```

###### 3. RDD窄依赖

窄依赖表示每一个父（上游）RDD的Partition最多被子（下游）RDD的一个Partition使用，窄依赖我们形象的比喻为独生子女。

```scala
class OneToOneDependency[T](rdd: RDD[T]) extends NarrowDependency[T](rdd)
```

###### 4. RDD宽依赖

宽依赖表示同一个父（上游）RDD的Partition被多个子（下游）RDD的Partition依赖，会引起Shuffle，宽依赖我们形象的比喻为多生。

```scala
class ShuffleDependency[K: ClassTag, V: ClassTag, C: ClassTag](
    @transient private val _rdd: RDD[_ <: Product2[K, V]],
    val partitioner: Partitioner,
    val serializer: Serializer = SparkEnv.get.serializer,
    val keyOrdering: Option[Ordering[K]] = None,
    val aggregator: Option[Aggregator[K, V, C]] = None,
    val mapSideCombine: Boolean = false,
    val shuffleWriterProcessor: ShuffleWriteProcessor = new ShuffleWriteProcessor)
  extends Dependency[Product2[K, V]]
```

###### 5. RDD阶段划分

DAG（Directed Acyclic Graph）有向无环图是由点和线组成的拓扑图形，该图形具有方向，不会闭环。

![](http://typora-image.test.upcdn.net/images/DAG有向无环图.jpg)

###### 6. RDD阶段划分源码

```scala
private[scheduler] def handleJobSubmitted(jobId: Int,
    finalRDD: RDD[_],
    func: (TaskContext, Iterator[_]) => _,
    partitions: Array[Int],
    callSite: CallSite,
    listener: JobListener,
    properties: Properties): Unit = {
  var finalStage: ResultStage = null
  try {
    // New stage creation may throw an exception if, for example, jobs are run on a
    // HadoopRDD whose underlying HDFS files have been deleted.
    finalStage = createResultStage(finalRDD, func, partitions, jobId, callSite)
  } catch {
    case e: BarrierJobSlotsNumberCheckFailed =>
      // If jobId doesn't exist in the map, Scala coverts its value null to 0: Int automatically.
      val numCheckFailures = barrierJobIdToNumTasksCheckFailures.compute(jobId,
        (_: Int, value: Int) => value + 1)

      logWarning(s"Barrier stage in job $jobId requires ${e.requiredConcurrentTasks} slots, " +
        s"but only ${e.maxConcurrentTasks} are available. " +
        s"Will retry up to ${maxFailureNumTasksCheck - numCheckFailures + 1} more times")

      if (numCheckFailures <= maxFailureNumTasksCheck) {
        messageScheduler.schedule(
          new Runnable {
            override def run(): Unit = eventProcessLoop.post(JobSubmitted(jobId, finalRDD, func,
              partitions, callSite, listener, properties))
          },
          timeIntervalNumTasksCheck,
          TimeUnit.SECONDS
        )
        return
      } else {
        // Job failed, clear internal data.
        barrierJobIdToNumTasksCheckFailures.remove(jobId)
        listener.jobFailed(e)
        return
      }

    case e: Exception =>
      logWarning("Creating new stage failed due to exception - job: " + jobId, e)
      listener.jobFailed(e)
      return
  }
  // Job submitted, clear internal data.
  barrierJobIdToNumTasksCheckFailures.remove(jobId)

  val job = new ActiveJob(jobId, finalStage, callSite, listener, properties)
  clearCacheLocs()
  logInfo("Got job %s (%s) with %d output partitions".format(
    job.jobId, callSite.shortForm, partitions.length))
  logInfo("Final stage: " + finalStage + " (" + finalStage.name + ")")
  logInfo("Parents of final stage: " + finalStage.parents)
  logInfo("Missing parents: " + getMissingParentStages(finalStage))

  val jobSubmissionTime = clock.getTimeMillis()
  jobIdToActiveJob(jobId) = job
  activeJobs += job
  finalStage.setActiveJob(job)
  val stageIds = jobIdToStageIds(jobId).toArray
  val stageInfos = stageIds.flatMap(id => stageIdToStage.get(id).map(_.latestInfo))
  listenerBus.post(
    SparkListenerJobStart(job.jobId, jobSubmissionTime, stageInfos, properties))
  submitStage(finalStage)
}

/**
 * Create a ResultStage associated with the provided jobId.
 */
private def createResultStage(
    rdd: RDD[_],
    func: (TaskContext, Iterator[_]) => _,
    partitions: Array[Int],
    jobId: Int,
    callSite: CallSite): ResultStage = {
  checkBarrierStageWithDynamicAllocation(rdd)
  checkBarrierStageWithNumSlots(rdd)
  checkBarrierStageWithRDDChainPattern(rdd, partitions.toSet.size)
  val parents = getOrCreateParentStages(rdd, jobId)
  val id = nextStageId.getAndIncrement()
  val stage = new ResultStage(id, rdd, func, partitions, parents, jobId, callSite)
  stageIdToStage(id) = stage
  updateJobIdStageIdMaps(jobId, stage)
  stage
}

/**
 * Returns shuffle dependencies that are immediate parents of the given RDD.
 *
 * This function will not return more distant ancestors.  For example, if C has a shuffle
 * dependency on B which has a shuffle dependency on A:
 *
 * A <-- B <-- C
 *
 * calling this function with rdd C will only return the B <-- C dependency.
 *
 * This function is scheduler-visible for the purpose of unit testing.
 */
private[scheduler] def getShuffleDependencies(
    rdd: RDD[_]): HashSet[ShuffleDependency[_, _, _]] = {
  val parents = new HashSet[ShuffleDependency[_, _, _]]
  val visited = new HashSet[RDD[_]]
  val waitingForVisit = new ListBuffer[RDD[_]]
  waitingForVisit += rdd
  while (waitingForVisit.nonEmpty) {
    val toVisit = waitingForVisit.remove(0)
    if (!visited(toVisit)) {
      visited += toVisit
      toVisit.dependencies.foreach {
        case shuffleDep: ShuffleDependency[_, _, _] =>
          parents += shuffleDep
        case dependency =>
          waitingForVisit.prepend(dependency.rdd)
      }
    }
  }
  parents
}
```

###### 7. RDD任务划分

RDD任务切分中间分为：Application、Job、Stage和Task

- Application：初始化一个SparkContext即生成一个Application
- Job：一个Action算子就会生成一个Job
- Stage：Stage等于宽依赖（ShuffleDependency）的个数加1
- Task：一个Stage阶段中，最后一个RDD的分区个数就是Task的个数

```shell
# 都是1->n的关系
Application -> Job -> Stage -> Task
```

###### 8. RDD任务划分源码

```scala
private[scheduler] def handleJobSubmitted(jobId: Int,
    finalRDD: RDD[_],
    func: (TaskContext, Iterator[_]) => _,
    partitions: Array[Int],
    callSite: CallSite,
    listener: JobListener,
    properties: Properties): Unit = {
  var finalStage: ResultStage = null
  try {
    // New stage creation may throw an exception if, for example, jobs are run on a
    // HadoopRDD whose underlying HDFS files have been deleted.
    finalStage = createResultStage(finalRDD, func, partitions, jobId, callSite)
  } catch {
    case e: BarrierJobSlotsNumberCheckFailed =>
      // If jobId doesn't exist in the map, Scala coverts its value null to 0: Int automatically.
      val numCheckFailures = barrierJobIdToNumTasksCheckFailures.compute(jobId,
        (_: Int, value: Int) => value + 1)

      logWarning(s"Barrier stage in job $jobId requires ${e.requiredConcurrentTasks} slots, " +
        s"but only ${e.maxConcurrentTasks} are available. " +
        s"Will retry up to ${maxFailureNumTasksCheck - numCheckFailures + 1} more times")

      if (numCheckFailures <= maxFailureNumTasksCheck) {
        messageScheduler.schedule(
          new Runnable {
            override def run(): Unit = eventProcessLoop.post(JobSubmitted(jobId, finalRDD, func,
              partitions, callSite, listener, properties))
          },
          timeIntervalNumTasksCheck,
          TimeUnit.SECONDS
        )
        return
      } else {
        // Job failed, clear internal data.
        barrierJobIdToNumTasksCheckFailures.remove(jobId)
        listener.jobFailed(e)
        return
      }

    case e: Exception =>
      logWarning("Creating new stage failed due to exception - job: " + jobId, e)
      listener.jobFailed(e)
      return
  }
  // Job submitted, clear internal data.
  barrierJobIdToNumTasksCheckFailures.remove(jobId)

  val job = new ActiveJob(jobId, finalStage, callSite, listener, properties)
  clearCacheLocs()
  logInfo("Got job %s (%s) with %d output partitions".format(
    job.jobId, callSite.shortForm, partitions.length))
  logInfo("Final stage: " + finalStage + " (" + finalStage.name + ")")
  logInfo("Parents of final stage: " + finalStage.parents)
  logInfo("Missing parents: " + getMissingParentStages(finalStage))

  val jobSubmissionTime = clock.getTimeMillis()
  jobIdToActiveJob(jobId) = job
  activeJobs += job
  finalStage.setActiveJob(job)
  val stageIds = jobIdToStageIds(jobId).toArray
  val stageInfos = stageIds.flatMap(id => stageIdToStage.get(id).map(_.latestInfo))
  listenerBus.post(
    SparkListenerJobStart(job.jobId, jobSubmissionTime, stageInfos, properties))
  submitStage(finalStage)
}

/** Submits stage, but first recursively submits any missing parents. */
private def submitStage(stage: Stage): Unit = {
  val jobId = activeJobForStage(stage)
  if (jobId.isDefined) {
    logDebug(s"submitStage($stage (name=${stage.name};" +
      s"jobs=${stage.jobIds.toSeq.sorted.mkString(",")}))")
    if (!waitingStages(stage) && !runningStages(stage) && !failedStages(stage)) {
      val missing = getMissingParentStages(stage).sortBy(_.id)
      logDebug("missing: " + missing)
      if (missing.isEmpty) {
        logInfo("Submitting " + stage + " (" + stage.rdd + "), which has no missing parents")
        submitMissingTasks(stage, jobId.get)
      } else {
        for (parent <- missing) {
          submitStage(parent)
        }
        waitingStages += stage
      }
    }
  } else {
    abortStage(stage, "No active job for stage " + stage.id, None)
  }
}

val tasks: Seq[Task[_]] = try {
  val serializedTaskMetrics = closureSerializer.serialize(stage.latestInfo.taskMetrics).array()
  stage match {
    case stage: ShuffleMapStage =>
      stage.pendingPartitions.clear()
      partitionsToCompute.map { id =>
        val locs = taskIdToLocations(id)
        val part = partitions(id)
        stage.pendingPartitions += id
        new ShuffleMapTask(stage.id, stage.latestInfo.attemptNumber,
          taskBinary, part, locs, properties, serializedTaskMetrics, Option(jobId),
          Option(sc.applicationId), sc.applicationAttemptId, stage.rdd.isBarrier())
      }

    case stage: ResultStage =>
      partitionsToCompute.map { id =>
        val p: Int = stage.partitions(id)
        val part = partitions(p)
        val locs = taskIdToLocations(id)
        new ResultTask(stage.id, stage.latestInfo.attemptNumber,
          taskBinary, part, locs, id, properties, serializedTaskMetrics,
          Option(jobId), Option(sc.applicationId), sc.applicationAttemptId,
          stage.rdd.isBarrier())
      }
  }
} catch {
  case NonFatal(e) =>
    abortStage(stage, s"Task creation failed: $e\n${Utils.exceptionString(e)}", Some(e))
    runningStages -= stage
    return
}

/**
 * Returns the sequence of partition ids that are missing (i.e. needs to be computed).
 *
 * This can only be called when there is an active job.
 */
override def findMissingPartitions(): Seq[Int] = {
  val job = activeJob.get
  (0 until job.numPartitions).filter(id => !job.finished(id))
}
```

##### 7. RDD的持久化

###### 1. RDD Cache缓存

RDD通过Cache或者Persist方法将前面的计算结果缓存，默认情况下会把数据以缓存在JVM的堆内存中。但是并不是这两个方法被调用时立即缓存，而是触发后面的action算子时，该RDD将会被缓存在计算节点的内存中，并供后面重用。

```scala
// cache操作会增加血缘关系，不改变原有的血缘关系
println(mapRDD.toDebugString)

// 数据缓存
mapRDD.cache()

// 可以更改存储级别，存储到磁盘中时，当执行成功后会删除
mapRDD.persist(StorageLevel.DISK_ONLY)
```

存储级别

```scala
/**
 * Various [[org.apache.spark.storage.StorageLevel]] defined and utility functions for creating
 * new storage levels.
 */
object StorageLevel {
  val NONE = new StorageLevel(false, false, false, false)
  val DISK_ONLY = new StorageLevel(true, false, false, false)
  val DISK_ONLY_2 = new StorageLevel(true, false, false, false, 2)
  val MEMORY_ONLY = new StorageLevel(false, true, false, true)
  val MEMORY_ONLY_2 = new StorageLevel(false, true, false, true, 2)
  val MEMORY_ONLY_SER = new StorageLevel(false, true, false, false)
  val MEMORY_ONLY_SER_2 = new StorageLevel(false, true, false, false, 2)
  val MEMORY_AND_DISK = new StorageLevel(true, true, false, true)
  val MEMORY_AND_DISK_2 = new StorageLevel(true, true, false, true, 2)
  val MEMORY_AND_DISK_SER = new StorageLevel(true, true, false, false)
  val MEMORY_AND_DISK_SER_2 = new StorageLevel(true, true, false, false, 2)
  val OFF_HEAP = new StorageLevel(true, true, true, false, 1)

  /**
   * :: DeveloperApi ::
   * Return the StorageLevel object with the specified name.
   */
  @DeveloperApi
  def fromString(s: String): StorageLevel = s match {
    case "NONE" => NONE
    case "DISK_ONLY" => DISK_ONLY
    case "DISK_ONLY_2" => DISK_ONLY_2
    case "MEMORY_ONLY" => MEMORY_ONLY
    case "MEMORY_ONLY_2" => MEMORY_ONLY_2
    case "MEMORY_ONLY_SER" => MEMORY_ONLY_SER
    case "MEMORY_ONLY_SER_2" => MEMORY_ONLY_SER_2
    case "MEMORY_AND_DISK" => MEMORY_AND_DISK
    case "MEMORY_AND_DISK_2" => MEMORY_AND_DISK_2
    case "MEMORY_AND_DISK_SER" => MEMORY_AND_DISK_SER
    case "MEMORY_AND_DISK_SER_2" => MEMORY_AND_DISK_SER_2
    case "OFF_HEAP" => OFF_HEAP
    ......
```

缓存有可能丢失，或者存储于内存的数据由于内存不足而被删除，RDD的缓存容错机制保证了及时缓存丢失也能保证计算的正确执行。通过基于RDD的一系列转换，丢失的数据会被重算，由于RDD的各个Partition是相对独立的，因此只需要计算丢失的部分即可，并不需要重算全部Partition。

Spark会自动对一些Shuffle操作的中间数据做持久化操作。这样做的目的是为了当一个节点Shuffle失败了避免重新计算整个输入。但是，在实际使用的时候，如果想重用数据，仍然建议调用persist或cache。

###### 2. RDD CheckPoint检查点

所谓的检查点其实就是通过将RDD中间结果写入磁盘，由于血缘依赖过长会造成容错成本过高，所以在中间阶段设置检查点，如果检查点之后的节点出现了问题，可以冲检查点开始重做血缘，减少了开销。对RDD进行checkpoint操作并不会马上被执行，必须执行action操作才能触发。

```scala
sc.setCheckpointDir("checkpoint")
// TODO 业务逻辑
val list: List[String] = List("hello scala", "hello spark")
val rdd: RDD[String] = sc.makeRDD(list, 2)
val flatMapRDD: RDD[String] = rdd.flatMap(_.split(" "))
val mapRDD: RDD[(String, Int)] = flatMapRDD.map(word => {
  println("@@@@@@@@@@@@@")
  (word, 1)
})
// 增加缓存，避免再重新跑一个Job做checkpoint
mapRDD.cache()
// 数据检查点：针对mapRDD做检查点计算
mapRDD.checkpoint()

val reduceRDD: RDD[(String, Int)] = mapRDD.reduceByKey(_ + _)
val groupRDD: RDD[(String, Iterable[Int])] = mapRDD.groupByKey()
reduceRDD.collect().foreach(println)
```

###### 3. 缓存和检查点区别

- Cache缓存只是将数据保存起来，不切断血缘依赖，但是会在血缘关系中添加新的依赖，一旦出现问题可以从头读取数据。CheckPoint检查点切断血缘依赖，重新建立新的血缘关系。
- Cache缓存的数据通过存储在磁盘、内存等地方，可靠性低。CheckPoint的数据通常存储在HDFS等容错、高可用的文件系统，可靠性高。
- 建议对checkpoint()的RDD使用Cache缓存，这样checkpoint的job只需从Cache缓存中读取数据即可，否则需要再从头计算一次RDD。

##### 8. RDD分区器

Spark目前支持Hash分区和Range分区，和用户自定义分区。Hash分区为当前的默认分区。分区器直接决定了RDD中分区的个数、RDD中每条数据经过Shuffle后进入哪个分区，进而决定了Reduce的个数。

- 只有Key-Value类型的RDD才有分区器，非Key-Value类型的RDD分区的值是None
- 每个RDD的分区ID范围：0~（numPartitions-1），决定这个值是属于那个分区的

###### 1. Hash分区器

对于给定的Key，计算其hashCode并除以分区个数取余。

```scala
class HashPartitioner(partitions: Int) extends Partitioner {
  require(partitions >= 0, s"Number of partitions ($partitions) cannot be negative.")

  def numPartitions: Int = partitions

  def getPartition(key: Any): Int = key match {
    case null => 0
    case _ => Utils.nonNegativeMod(key.hashCode, numPartitions)
  }

  override def equals(other: Any): Boolean = other match {
    case h: HashPartitioner =>
      h.numPartitions == numPartitions
    case _ =>
      false
  }

  override def hashCode: Int = numPartitions
}
```

###### 2. Range分区器

将一定范围内的数据映射到一个分区中，尽量保证每个分区数据均匀，而且分区间有序。

```scala
class RangePartitioner[K : Ordering : ClassTag, V](
    partitions: Int,
    rdd: RDD[_ <: Product2[K, V]],
    private var ascending: Boolean = true,
    val samplePointsPerPartitionHint: Int = 20)
  extends Partitioner {

  // A constructor declared in order to maintain backward compatibility for Java, when we add the
  // 4th constructor parameter samplePointsPerPartitionHint. See SPARK-22160.
  // This is added to make sure from a bytecode point of view, there is still a 3-arg ctor.
  def this(partitions: Int, rdd: RDD[_ <: Product2[K, V]], ascending: Boolean) = {
    this(partitions, rdd, ascending, samplePointsPerPartitionHint = 20)
  }

  // We allow partitions = 0, which happens when sorting an empty RDD under the default settings.
  require(partitions >= 0, s"Number of partitions cannot be negative but found $partitions.")
  require(samplePointsPerPartitionHint > 0,
    s"Sample points per partition must be greater than 0 but found $samplePointsPerPartitionHint")

  private var ordering = implicitly[Ordering[K]]

  // An array of upper bounds for the first (partitions - 1) partitions
  private var rangeBounds: Array[K] = {
    if (partitions <= 1) {
      Array.empty
    } else {
      // This is the sample size we need to have roughly balanced output partitions, capped at 1M.
      // Cast to double to avoid overflowing ints or longs
      val sampleSize = math.min(samplePointsPerPartitionHint.toDouble * partitions, 1e6)
      // Assume the input partitions are roughly balanced and over-sample a little bit.
      val sampleSizePerPartition = math.ceil(3.0 * sampleSize / rdd.partitions.length).toInt
      val (numItems, sketched) = RangePartitioner.sketch(rdd.map(_._1), sampleSizePerPartition)
      if (numItems == 0L) {
        Array.empty
      } else {
        // If a partition contains much more than the average number of items, we re-sample from it
        // to ensure that enough items are collected from that partition.
        val fraction = math.min(sampleSize / math.max(numItems, 1L), 1.0)
        val candidates = ArrayBuffer.empty[(K, Float)]
        val imbalancedPartitions = mutable.Set.empty[Int]
        sketched.foreach { case (idx, n, sample) =>
          if (fraction * n > sampleSizePerPartition) {
            imbalancedPartitions += idx
          } else {
            // The weight is 1 over the sampling probability.
            val weight = (n.toDouble / sample.length).toFloat
            for (key <- sample) {
              candidates += ((key, weight))
            }
          }
        }
        if (imbalancedPartitions.nonEmpty) {
          // Re-sample imbalanced partitions with the desired sampling probability.
          val imbalanced = new PartitionPruningRDD(rdd.map(_._1), imbalancedPartitions.contains)
          val seed = byteswap32(-rdd.id - 1)
          val reSampled = imbalanced.sample(withReplacement = false, fraction, seed).collect()
          val weight = (1.0 / fraction).toFloat
          candidates ++= reSampled.map(x => (x, weight))
        }
        RangePartitioner.determineBounds(candidates, math.min(partitions, candidates.size))
      }
    }
  }

  def numPartitions: Int = rangeBounds.length + 1

  private var binarySearch: ((Array[K], K) => Int) = CollectionsUtils.makeBinarySearch[K]

  def getPartition(key: Any): Int = {
    val k = key.asInstanceOf[K]
    var partition = 0
    if (rangeBounds.length <= 128) {
      // If we have less than 128 partitions naive search
      while (partition < rangeBounds.length && ordering.gt(k, rangeBounds(partition))) {
        partition += 1
      }
    } else {
      // Determine which binary search method to use only once.
      partition = binarySearch(rangeBounds, k)
      // binarySearch either returns the match location or -[insertion point]-1
      if (partition < 0) {
        partition = -partition-1
      }
      if (partition > rangeBounds.length) {
        partition = rangeBounds.length
      }
    }
    if (ascending) {
      partition
    } else {
      rangeBounds.length - partition
    }
  }

  override def equals(other: Any): Boolean = other match {
    case r: RangePartitioner[_, _] =>
      r.rangeBounds.sameElements(rangeBounds) && r.ascending == ascending
    case _ =>
      false
  }

  override def hashCode(): Int = {
    val prime = 31
    var result = 1
    var i = 0
    while (i < rangeBounds.length) {
      result = prime * result + rangeBounds(i).hashCode
      i += 1
    }
    result = prime * result + ascending.hashCode
    result
  }

  @throws(classOf[IOException])
  private def writeObject(out: ObjectOutputStream): Unit = Utils.tryOrIOException {
    val sfactory = SparkEnv.get.serializer
    sfactory match {
      case js: JavaSerializer => out.defaultWriteObject()
      case _ =>
        out.writeBoolean(ascending)
        out.writeObject(ordering)
        out.writeObject(binarySearch)

        val ser = sfactory.newInstance()
        Utils.serializeViaNestedStream(out, ser) { stream =>
          stream.writeObject(scala.reflect.classTag[Array[K]])
          stream.writeObject(rangeBounds)
        }
    }
  }

  @throws(classOf[IOException])
  private def readObject(in: ObjectInputStream): Unit = Utils.tryOrIOException {
    val sfactory = SparkEnv.get.serializer
    sfactory match {
      case js: JavaSerializer => in.defaultReadObject()
      case _ =>
        ascending = in.readBoolean()
        ordering = in.readObject().asInstanceOf[Ordering[K]]
        binarySearch = in.readObject().asInstanceOf[(Array[K], K) => Int]

        val ser = sfactory.newInstance()
        Utils.deserializeViaNestedStream(in, ser) { ds =>
          implicit val classTag = ds.readObject[ClassTag[Array[K]]]()
          rangeBounds = ds.readObject[Array[K]]()
        }
    }
  }
}
```

###### 3. 自定义分区器

```scala
/**
 * 自定义分区器
 */
class MyPartitioner extends Partitioner {
  // 分区数量
  override def numPartitions: Int = 3

  // 根据数据的Key值返回数据的分区索引（从0开始）
  override def getPartition(key: Any): Int = {
    //if (key == "NBA") {
    //  0
    //} else if (key == "CBA") {
    //  1
    //} else {
    //  2
    //}
    key match {
      case "NBA" => 0
      case "CBA" => 1
      case _ => 2
    }
  }
}
```

##### 9. RDD文件读取与保存

Spark的数据读取及数据保存可以从两个维度来作区分：文件格式以及文件系统。

文件格式分为：text文件、csv文件、sequence文件以及Object文件；

文件系统分为：本地文件系统、HDFS、HBASE以及数据库。

###### 1. text文件

```scala
// 保存成text文件
rdd.saveAsTextFile("output1")
// 读取text文件
rdd.textFile("output1")
```

###### 2. object对象文件

对象文件是将对象序列化后保存的文件，采用Java的序列化机制。可以通过objectFile[T: ClassTag]\(path)函数接收一个路径，读取对象文件，返回对应的RDD，也可以通过调用saveAsObjectFile()实现对象文件的输出。因为是序列化所以要指定类型。

```scala
// 保存成object文件
rdd.saveAsObjectFile("output2")
// 读取object文件
sc.objectFile[(String, Int)]("output2")
```

###### 3. sequence文件

Sequence文件是Hadoop用来存储二进制形式的key-value对而设计的一种平面文件（Flat File）。在SparkContext中，可以调用sequenceFile[keyClass, valueClass]\(path)。

```scala
// 保存成sequence文件
rdd.saveAsSequenceFile("output3")
// 读取sequence文件
sc.sequenceFile[String, Int]("output3")
```

