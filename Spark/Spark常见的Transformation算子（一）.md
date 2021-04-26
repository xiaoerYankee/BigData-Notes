#### Spark常见的Transformation算子（一）

##### `parallelize`

将一个存在的集合，转换成一个RDD

```scala
/** Distribute a local Scala collection to form an RDD.
 *
 * @note Parallelize acts lazily. If `seq` is a mutable collection and is altered after the call
 * to parallelize and before the first action on the RDD, the resultant RDD will reflect the
 * modified collection. Pass a copy of the argument to avoid this.
 * @note avoid using `parallelize(Seq())` to create an empty `RDD`. Consider `emptyRDD` for an
 * RDD with no partitions, or `parallelize(Seq[T]())` for an RDD of `T` with empty partitions.
 * @param seq Scala collection to distribute
 * @param numSlices number of partitions to divide the collection into
 * @return RDD representing distributed collection
 */
// 可以指定分区数量，如果不指定，使用默认的分区数量为主机核心数
def parallelize[T: ClassTag](
    seq: Seq[T],
    numSlices: Int = defaultParallelism): RDD[T] = withScope {
  assertNotStopped()
  new ParallelCollectionRDD[T](this, seq, numSlices, Map[Int, Seq[String]]())
}
```

###### Scala版本

```scala
println("======================= parallelize-1 ===========================")
val data: RDD[Int] = sc.parallelize(1 to 10)
println(s"分区数量为：${data.getNumPartitions}")
println(s"原始数据为：${data.collect.toBuffer}")

println("======================= parallelize-2 ===========================")
val message: RDD[String] = sc.parallelize(List("hello world", "hello spark", "hello scala"), 2)
println(s"分区数量为：${message.getNumPartitions}")
println(s"原始数据为：${message.collect.toBuffer}")
```

运行结果

![](http://typora-image.test.upcdn.net/images/parallelize.jpg)

##### `makeRDD`

将一个存在的集合，转换成一个RDD

```scala
/** Distribute a local Scala collection to form an RDD.
 *
 * This method is identical to `parallelize`.
 * @param seq Scala collection to distribute
 * @param numSlices number of partitions to divide the collection into
 * @return RDD representing distributed collection
 */
// 第一种 makeRDD 实现，底层调用了 parallelize 函数
def makeRDD[T: ClassTag](
    seq: Seq[T],
    numSlices: Int = defaultParallelism): RDD[T] = withScope {
  parallelize(seq, numSlices)
}

/**
 * Distribute a local Scala collection to form an RDD, with one or more
 * location preferences (hostnames of Spark nodes) for each object.
 * Create a new partition for each collection item.
 * @param seq list of tuples of data and location preferences (hostnames of Spark nodes)
 * @return RDD representing data partitioned according to location preferences
 */
// 第二种 makeRDD 实现，可以为数据提供位置信息，但是不可以指定分区的数量，而是固定为seq参数的size大小
def makeRDD[T: ClassTag](seq: Seq[(T, Seq[String])]): RDD[T] = withScope {
  assertNotStopped()
  val indexToPrefs = seq.zipWithIndex.map(t => (t._2, t._1._2)).toMap
  new ParallelCollectionRDD[T](this, seq.map(_._1), math.max(seq.size, 1), indexToPrefs)
}
```

###### Scala版本

```scala
println("======================= makeRDD-1 ===========================")
val data: RDD[Int] = sc.makeRDD(1 to 10)
println(s"分区数量为：${data.getNumPartitions}")
println(s"原始数据为：${data.collect.toBuffer}")

println("======================= makeRDD-2 ===========================")
val message: RDD[String] = sc.makeRDD(List("hello world", "hello spark", "hello scala"), 2)
println(s"分区数量为：${message.getNumPartitions}")
println(s"原始数据为：${message.collect.toBuffer}")

println("======================= makeRDD-3 ===========================")
val info: RDD[Int] = sc.makeRDD(List((1, List("aa", "bb")), (2, List("cc", "dd")), (3, List("ee", "ff"))))
println(s"分区数量为：${info.getNumPartitions}")
println(s"原始数据为：${info.collect.toBuffer}")
println(s"第一分区的数据为：${info.preferredLocations(info.partitions(0))}")
```

运行结果

![](http://typora-image.test.upcdn.net/images/makeRDD.jpg)

##### `textFile`

从外部读取数据来创建RDD

```scala
/**
 * Read a text file from HDFS, a local file system (available on all nodes), or any
 * Hadoop-supported file system URI, and return it as an RDD of Strings.
 * @param path path to the text file on a supported file system
 * @param minPartitions suggested minimum number of partitions for the resulting RDD
 * @return RDD of lines of the text file
 */
// 两个参数，其中一个有默认值，最小的默认分区数量为：2
def textFile(
    path: String,
    minPartitions: Int = defaultMinPartitions): RDD[String] = withScope {
  assertNotStopped()
  hadoopFile(path, classOf[TextInputFormat], classOf[LongWritable], classOf[Text],
    minPartitions).map(pair => pair._2.toString).setName(path)
}
```

###### Scala版本

```scala
println("======================= textFile-1 ===========================")
val data: RDD[String] = sc.textFile("src/main/data/textFile.txt")
println(s"分区数量为：${data.getNumPartitions}")
println(s"原始数据为：${data.collect.toBuffer}")

println("======================= textFile-2 ===========================")
val message: RDD[String] = sc.textFile("src/main/data/textFile.txt", 3)
println(s"分区数量为：${message.getNumPartitions}")
println(s"原始数据为：${message.collect.toBuffer}")
```

运行结果

![](http://typora-image.test.upcdn.net/images/textFile.jpg)