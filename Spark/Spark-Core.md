### Spark-Core

#### 常见算子

##### Transformation算子

###### `parallelize`

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

Scala版本

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

![](E:\note\Spark\images\parallelize.jpg)

###### `makeRDD`

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

Scala版本

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

![](E:\note\Spark\images\makeRDD.jpg)

###### `textFile`

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

Scala版本

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

![](E:\note\Spark\images\textFile.jpg)

###### `filter`

过滤操作，对RDD中的数据按照函数进行过滤

```scala
/**
 * Return a new RDD containing only the elements that satisfy a predicate.
 */
// 返回仅包含函数的结果的RDD
def filter(f: T => Boolean): RDD[T] = withScope {
  val cleanF = sc.clean(f)
  new MapPartitionsRDD[T, T](
    this,
    (context, pid, iter) => iter.filter(cleanF),
    preservesPartitioning = true)
}
```

Scala版本

```scala
// 返回包含“hello”的那些行，只要数据是按行存储的，那么在filter是按照行返回，不需要提前对数据进行按行分隔
println("======================= filter ===========================")
val value: RDD[String] = data.filter(f => f.contains("hello"))
println(s"经过filter处理后的数据为：${value.collect.toBuffer}")
```

运行结果

![](E:\note\Spark\images\filter.jpg)

###### `map`

map的输入变换函数引用于RDD中的所有元素

```scala
/**
 * Return a new RDD by applying a function to all elements of this RDD.
 */
// 将函数应用于此RDD的所有元素来返回新的RDD
def map[U: ClassTag](f: T => U): RDD[U] = withScope {
  val cleanF = sc.clean(f)
  new MapPartitionsRDD[U, T](this, (context, pid, iter) => iter.map(cleanF))
}
```

Scala版本

```scala
// 原始数据按行每一行追加上一个“ nihao”
println("======================= map ===========================")
val value: RDD[String] = data.map(f => f + " nihao")
println(s"经过map处理后的数据为：${value.collect.toBuffer}")
```

运行结果

![](E:\note\Spark\images\map.jpg)

###### `flatMap`

对RDD中的所有元素应用该函数，返回一个新的RDD

```scala
/**
 *  Return a new RDD by first applying a function to all elements of this
 *  RDD, and then flattening the results.
 */
// 将该RDD中的所有元素应用该函数，然后将结果扁平化，返回新的RDD
def flatMap[U: ClassTag](f: T => TraversableOnce[U]): RDD[U] = withScope {
  val cleanF = sc.clean(f)
  new MapPartitionsRDD[U, T](this, (context, pid, iter) => iter.flatMap(cleanF))
}
```

Scala版本

```scala
println("======================= flatMap ===========================")
val value: RDD[String] = data.flatMap(f => f.split(" "))
println(s"经过flatMap处理后的数据为：${value.collect.toBuffer}")
```

运行结果

![](E:\note\Spark\images\flatMap.jpg)

###### `mapToPair`

将RDD转成PairRDD，在scala中map就可以实现

Scala版本

```scala
println("======================= mapToPair ===========================")
val value: RDD[(String, Int)] = data.map(f => (f, 1))
println(s"经过mapToPair处理后的数据为：${value.collect.toBuffer}")
```

运行结果

![](E:\note\Spark\images\mapToPair.jpg)

###### `flatMapToPair`

相当于先flatMap，后mapToPair，scala中没有专门的flatMapToPair

Scala版本

```scala
println("======================= flatMapToPair-1 ===========================")
val value: RDD[String] = data.flatMap(f => f.split(" "))
val result: RDD[(String, Int)] = value.map(f => (f, 1))
println(s"经过flatMapToPair处理后的数据为：${result.collect.toBuffer}")
```

运行结果

![](E:\note\Spark\images\flatMapToPair.jpg)

###### `distinct`

用于去重，生成的RDD可能有重复的元素，使用distinct方法可以去掉重复的元素，此方法会打乱元素的顺序，操作开销很大

```scala
/**
 * Return a new RDD containing the distinct elements in this RDD.
 */
// 第一种实现：需要参数numPartitions，这个类似于一个因子，如果数据集中的元素可以被numPartitions整除，则排在前面，之后排被numPartitions整除余1的，以此类推，体现局部无序，整体有序
def distinct(numPartitions: Int)(implicit ord: Ordering[T] = null): RDD[T] = withScope {
  map(x => (x, null)).reduceByKey((x, y) => x, numPartitions).map(_._1)
}

/**
 * Return a new RDD containing the distinct elements in this RDD.
 */
// 第二种实现：调用了第一种实现，参数采用了默认的参数
def distinct(): RDD[T] = withScope {
  distinct(partitions.length)
}
```

Scala版本

```scala
println("======================= distinct-1 ===========================")
// 如果没有指定numPartitions参数，则为创建数据时的分区数量
val value1: RDD[Int] = data3.distinct()
println(s"经过distinct处理后的数据为：${value1.collect.toBuffer}")

println("======================= distinct-2 ===========================")
// 局部无序，整体有序。以传入的参数numPartitions作为因子，所有的元素除以numPartitions，模为0的排在第一位，之后排模为1的，以此类推
val value2: RDD[Int] = data3.distinct(2)
println(s"经过distinct处理后的数据为：${value2.collect.toBuffer}")

// 返回结果
// (4, 2, 1, 3, 5)
// 4, 2 ==> 模为0
// 1, 3, 5 ==> 模为1
```

![](E:\note\Spark\images\distinct.jpg)

###### `union`

两个RDD进行合并，不去重

```scala
/**
 * Return the union of this RDD and another one. Any identical elements will appear multiple
 * times (use `.distinct()` to eliminate them).
 */
// 返回此RDD和另一个RDD的并集，不去重，顺序连接
def union(other: RDD[T]): RDD[T] = withScope {
  sc.union(this, other)
}
```

Scala版本

```scala
println("======================= union ===========================")
val value: RDD[Int] = data1.union(data2)
println(s"经过union处理后的数据为：${value3.collect.toBuffer}")
```

运行结果

![](E:\note\Spark\images\union.jpg)

###### `intersection`

对于两个RDD求交集，并去重，无序返回，操作开销很大

```scala
/**
 * Return the intersection of this RDD and another one. The output will not contain any duplicate
 * elements, even if the input RDDs did.
 *
 * @note This method performs a shuffle internally.
 */
// 第一种实现：一个参数，返回此RDD和另一个RDD的交集，不包含重复元素
// 最后返回也是局部无序，整体有序。分区大小采用两个RDD中分区数量较大的
def intersection(other: RDD[T]): RDD[T] = withScope {
  this.map(v => (v, null)).cogroup(other.map(v => (v, null)))
      .filter { case (_, (leftGroup, rightGroup)) => leftGroup.nonEmpty && rightGroup.nonEmpty }
      .keys
}

/**
 * Return the intersection of this RDD and another one. The output will not contain any duplicate
 * elements, even if the input RDDs did.
 *
 * @note This method performs a shuffle internally.
 *
 * @param partitioner Partitioner to use for the resulting RDD
 */
// 第二种实现：两个参数，另一个RDD和一个分区器
def intersection(
    other: RDD[T],
    partitioner: Partitioner)(implicit ord: Ordering[T] = null): RDD[T] = withScope {
  this.map(v => (v, null)).cogroup(other.map(v => (v, null)), partitioner)
      .filter { case (_, (leftGroup, rightGroup)) => leftGroup.nonEmpty && rightGroup.nonEmpty }
      .keys
}

/**
 * Return the intersection of this RDD and another one. The output will not contain any duplicate
 * elements, even if the input RDDs did.  Performs a hash partition across the cluster
 *
 * @note This method performs a shuffle internally.
 *
 * @param numPartitions How many partitions to use in the resulting RDD
 */
// 第三种实现：两个参数，第二个参数传入numPartitions，内部调用调用第二种实现，使用默认分区器HashPartitioner(numPartitions)，并且返回结果局部无序，整体有序和distinct规则一样
def intersection(other: RDD[T], numPartitions: Int): RDD[T] = withScope {
  intersection(other, new HashPartitioner(numPartitions))
}
```

Scala版本

```scala
println("======================= intersection-1 ===========================")
val value1: RDD[Int] = data1.intersection(data2)
println(s"分区数量为：${value1.getNumPartitions}")
println(s"经过intersection处理后的数据为：${value1.collect.toBuffer}")

println("======================= intersection-2 ===========================")
val value2: RDD[Int] = data1.intersection(data2, new HashPartitioner(4))
println(s"分区数量为：${value2.getNumPartitions}")
println(s"经过intersection处理后的数据为：${value2.collect.toBuffer}")

println("======================= intersection-3 ===========================")
val value3: RDD[Int] = data1.intersection(data2, 5)
println(s"分区数量为：${value3.getNumPartitions}")
println(s"经过intersection处理后的数据为：${value3.collect.toBuffer}")
```

运行结果

![](E:\note\Spark\images\intersection.jpg)

###### `subtract`

RDD1.substract(RDD2)，返回在RDD1中出现但是不在RDD2中出现的元素

```scala
/**
 * Return an RDD with the elements from `this` that are not in `other`.
 *
 * Uses `this` partitioner/partition size, because even if `other` is huge, the resulting
 * RDD will be &lt;= us.
 */
// 第一种实现：一个参数，调用了第三种实现
// 最后返回也是局部无序，整体有序。分区大小采用两个RDD中分区数量较大的
def subtract(other: RDD[T]): RDD[T] = withScope {
  subtract(other, partitioner.getOrElse(new HashPartitioner(partitions.length)))
}

/**
 * Return an RDD with the elements from `this` that are not in `other`.
 */
// 第二种实现，调用了第三种实现，使用默认分区器HashPartitioner(numPartitions)，并且返回结果局部无序，整体有序和distinct规则一样
def subtract(other: RDD[T], numPartitions: Int): RDD[T] = withScope {
  subtract(other, new HashPartitioner(numPartitions))
}

/**
 * Return an RDD with the elements from `this` that are not in `other`.
 */
// 第三种实现，两个参数，第二个参数为分区器
def subtract(
    other: RDD[T],
    p: Partitioner)(implicit ord: Ordering[T] = null): RDD[T] = withScope {
  if (partitioner == Some(p)) {
    // Our partitioner knows how to handle T (which, since we have a partitioner, is
    // really (K, V)) so make a new Partitioner that will de-tuple our fake tuples
    val p2 = new Partitioner() {
      override def numPartitions: Int = p.numPartitions
      override def getPartition(k: Any): Int = p.getPartition(k.asInstanceOf[(Any, _)]._1)
    }
    // Unfortunately, since we're making a new p2, we'll get ShuffleDependencies
    // anyway, and when calling .keys, will not have a partitioner set, even though
    // the SubtractedRDD will, thanks to p2's de-tupled partitioning, already be
    // partitioned by the right/real keys (e.g. p).
    this.map(x => (x, null)).subtractByKey(other.map((_, null)), p2).keys
  } else {
    this.map(x => (x, null)).subtractByKey(other.map((_, null)), p).keys
  }
}
```

Scala版本

```scala
println("======================= subtract-1 ===========================")
val value1: RDD[Int] = data1.subtract(data2)
println(s"分区数量为：${value1.getNumPartitions}")
println(s"经过subtract处理后的数据为：${value1.collect.toBuffer}")

println("======================= subtract-2 ===========================")
val value2: RDD[Int] = data1.subtract(data2, new HashPartitioner(4))
println(s"分区数量为：${value2.getNumPartitions}")
println(s"经过subtract处理后的数据为：${value2.collect.toBuffer}")

println("======================= subtract-3 ===========================")
val value3: RDD[Int] = data1.subtract(data2, 5)
println(s"分区数量为：${value3.getNumPartitions}")
println(s"经过subtract处理后的数据为：${value3.collect.toBuffer}")
```

运行结果

![](E:\note\Spark\images\subtract.jpg)

###### `cartesian`

返回两个RDD的笛卡尔积，开销非常大

```scala
/**
 * Return the Cartesian product of this RDD and another one, that is, the RDD of all pairs of
 * elements (a, b) where a is in `this` and b is in `other`.
 */
// 分区数量为两个RDD之积
def cartesian[U: ClassTag](other: RDD[U]): RDD[(T, U)] = withScope {
  new CartesianRDD(sc, this, other)
}
```

Scala版本

```scala
println("======================= cartesian ===========================")
val value1: RDD[(Int, Int)] = data1.cartesian(data2)
println(s"分区数量为：${value1.getNumPartitions}")
println(s"经过cartesian处理后的数据为：${value1.collect.toBuffer}")
```

运行结果

![](E:\note\Spark\images\cartesian.jpg)

###### `sample`

采样操作，用于从样本中取出部分数据。

```scala
/**
 * Return a sampled subset of this RDD.
 *
 * @param withReplacement can elements be sampled multiple times (replaced when sampled out)
 * @param fraction expected size of the sample as a fraction of this RDD's size
 *  without replacement: probability that each element is chosen; fraction must be [0, 1]
 *  with replacement: expected number of times each element is chosen; fraction must be greater
 *  than or equal to 0
 * @param seed seed for the random number generator
 *
 * @note This is NOT guaranteed to provide exactly the fraction of the count
 * of the given [[RDD]].
 */
// 返回此RDD的采样子集
// withReplacement 是否放回
// fraction，如果withReplacement为false，则fraction表示概率，介于(0,1]
// fraction，如果withReplacement为true，则fraction表示期望的次数，大于等于0
// seed 用于指定的随机数生成器的种子，一般情况下，seed不建议指定
def sample(
    withReplacement: Boolean,
    fraction: Double,
    seed: Long = Utils.random.nextLong): RDD[T] = {
  require(fraction >= 0,
    s"Fraction must be nonnegative, but got ${fraction}")

  withScope {
    require(fraction >= 0.0, "Negative fraction value: " + fraction)
    if (withReplacement) {
      new PartitionwiseSampledRDD[T, T](this, new PoissonSampler[T](fraction), true, seed)
    } else {
      new PartitionwiseSampledRDD[T, T](this, new BernoulliSampler[T](fraction), true, seed)
    }
  }
}
```

Scala版本

```scala
println("======================= sample-1 ===========================")
val value1: RDD[Int] = data1.sample(withReplacement = false, 0.5)
println(s"分区数量为：${value1.getNumPartitions}")
println(s"经过sample抽样的结果为：${value1.collect.toBuffer}")

println("======================= sample-2 ===========================")
val data4: RDD[Int] = data1.repartition(2)
val value2: RDD[Int] = data4.sample(withReplacement = false, 0.5)
println(s"分区数量为：${value2.getNumPartitions}")
println(s"经过sample抽样的结果为：${value2.collect.toBuffer}")
```

运行结果

![](E:\note\Spark\images\sample.jpg)

###### `combineByKey`

通用函数

```scala
/**
 * Generic function to combine the elements for each key using a custom set of aggregation
 * functions. This method is here for backward compatibility. It does not provide combiner
 * classtag information to the shuffle.
 *
 * @see `combineByKeyWithClassTag`
 */
def combineByKey[C](
    createCombiner: V => C,
    mergeValue: (C, V) => C,
    mergeCombiners: (C, C) => C,
    partitioner: Partitioner,
    mapSideCombine: Boolean = true,
    serializer: Serializer = null): RDD[(K, C)] = self.withScope {
  combineByKeyWithClassTag(createCombiner, mergeValue, mergeCombiners,
    partitioner, mapSideCombine, serializer)(null)
}

/**
 * Simplified version of combineByKeyWithClassTag that hash-partitions the output RDD.
 * This method is here for backward compatibility. It does not provide combiner
 * classtag information to the shuffle.
 *
 * @see `combineByKeyWithClassTag`
 */
def combineByKey[C](
    createCombiner: V => C,
    mergeValue: (C, V) => C,
    mergeCombiners: (C, C) => C,
    numPartitions: Int): RDD[(K, C)] = self.withScope {
  combineByKeyWithClassTag(createCombiner, mergeValue, mergeCombiners, numPartitions)(null)
}

/**
 * Simplified version of combineByKeyWithClassTag that hash-partitions the resulting RDD using the
 * existing partitioner/parallelism level. This method is here for backward compatibility. It
 * does not provide combiner classtag information to the shuffle.
 *
 * @see `combineByKeyWithClassTag`
 */
// createCombiner：遍历分区中的所有元素，要么每个元素的key没遇到过，要么就是和之前的某个元素相同，如果是新元素，则会调用createCombiner()函数来创建那个key对应的累加器
// mergeValue：如果一个key在处理当前分区之前已经遇到的key，回调用mergeValue()进行合并
// mergeCombiners：每个分区是独立的，因此一个key可能有多个累加器，使用mergeCombiners()将分区之间进行合并
// 通用函数，使用一组自定义的聚合函数来组合每个键的元素
def combineByKey[C](
    createCombiner: V => C,
    mergeValue: (C, V) => C,
    mergeCombiners: (C, C) => C): RDD[(K, C)] = self.withScope {
  combineByKeyWithClassTag(createCombiner, mergeValue, mergeCombiners)(null)
}
```

Scala版本

```scala
// 定义一个样例类
case class Score(name: String, subject: String, score: Float)

println("======================= combineByKey ===========================")
val scores: List[Score] = List(Score("zhangsan", "chinese", 99), Score("zhangsan", "math", 50), Score("zhangsan", "english", 90),
  Score("lisi", "chinese", 30), Score("lisi", "math", 55), Score("lisi", "english", 60),
  Score("wangwu", "chinese", 63), Score("wangwu", "math", 65), Score("wangwu", "english", 70),
  Score("zhaoliu", "chinese", 23), Score("zhaoliu", "math", 86), Score("zhaoliu", "english", 34)
)
val scoreTuples: List[(String, Score)] = for (i <- scores) yield (i.name, i)
println("原数数据为：")
scoreTuples.foreach(println)
// 创建RDD
val score: RDD[(String, Score)] = sc.parallelize(scoreTuples, 2)
val scoreResult: RDD[(String, Float)] = score.combineByKey(
  (x: Score) => (x.score, 1),
  (acc: (Float, Int), x: Score) => (acc._1 + x.score, acc._2 + 1),
  (acc1: (Float, Int), acc2: (Float, Int)) => (acc1._1 + acc2._1, acc1._2 + acc2._2)
) map { case (key, value) => (key, value._1 / value._2) }
println("结果数据为：")
scoreResult.collect.foreach(println)
```

运行结果

![](E:\note\Spark\images\combineByKey.jpg)

###### `reduceByKey`

根据相同的key进行聚合操作

```scala
/**
 * Merge the values for each key using an associative and commutative reduce function. This will
 * also perform the merging locally on each mapper before sending results to a reducer, similarly
 * to a "combiner" in MapReduce.
 */
// 第一种实现：两个参数，一个分区器，一个函数
// 可以指定分区器用来分区
// 合并每个相同键的值，在将结果发送给reduce之前，还将在每个映射器上本地执行合并
def reduceByKey(partitioner: Partitioner, func: (V, V) => V): RDD[(K, V)] = self.withScope {
  combineByKeyWithClassTag[V]((v: V) => v, func, func, partitioner)
}

/**
 * Merge the values for each key using an associative and commutative reduce function. This will
 * also perform the merging locally on each mapper before sending results to a reducer, similarly
 * to a "combiner" in MapReduce. Output will be hash-partitioned with numPartitions partitions.
 */
// 调用第一种实现，输出的结果将使用默认分区器进行分区
def reduceByKey(func: (V, V) => V, numPartitions: Int): RDD[(K, V)] = self.withScope {
  reduceByKey(new HashPartitioner(numPartitions), func)
}

/**
 * Merge the values for each key using an associative and commutative reduce function. This will
 * also perform the merging locally on each mapper before sending results to a reducer, similarly
 * to a "combiner" in MapReduce. Output will be hash-partitioned with the existing partitioner/
 * parallelism level.
 */
// 调用了第一种实现，使用现有的并行度进行哈希分区
def reduceByKey(func: (V, V) => V): RDD[(K, V)] = self.withScope {
  reduceByKey(defaultPartitioner(self), func)
}
```

Scala版本

```scala
println("======================= reduceByKey-1 ===========================")
val value1: RDD[(String, Int)] = info1.reduceByKey(new HashPartitioner(3), (k, v) => k + v)
println(s"分区数量为：${value1.getNumPartitions}")
println(s"经过reduceByKey处理后的结果为：${value1.collect.toBuffer}")

println("======================= reduceByKey-2 ===========================")
val value2: RDD[(String, Int)] = info1.reduceByKey((k, v) => k + v, 4)
println(s"分区数量为：${value2.getNumPartitions}")
println(s"经过reduceByKey处理后的结果为：${value2.collect.toBuffer}")

println("======================= reduceByKey-3 ===========================")
val value3: RDD[(String, Int)] = info1.reduceByKey((k, v) => k + v)
println(s"分区数量为：${value3.getNumPartitions}")
println(s"经过reduceByKey处理后的结果为：${value3.collect.toBuffer}")
```

运行结果

![](E:\note\Spark\images\reduceByKey.jpg)

###### `aggregateByKey`

对pairRDD中相同的key值进行聚合，使用初始值，返回值为pairRDD

```scala
/**
 * Aggregate the values of each key, using given combine functions and a neutral "zero value".
 * This function can return a different result type, U, than the type of the values in this RDD,
 * V. Thus, we need one operation for merging a V into a U and one operation for merging two U's,
 * as in scala.TraversableOnce. The former operation is used for merging values within a
 * partition, and the latter is used for merging values between partitions. To avoid memory
 * allocation, both of these functions are allowed to modify and return their first argument
 * instead of creating a new U.
 */
// 第一种实现：2个参数列表，第一个参数列表传入一个初始值和一个分区器，第二个参数列表传入两个函数，第一个函数用于分区内聚合，第二个参数用于分区间聚合
def aggregateByKey[U: ClassTag](zeroValue: U, partitioner: Partitioner)(seqOp: (U, V) => U,
    combOp: (U, U) => U): RDD[(K, U)] = self.withScope {
  // Serialize the zero value to a byte array so that we can get a new clone of it on each key
  val zeroBuffer = SparkEnv.get.serializer.newInstance().serialize(zeroValue)
  val zeroArray = new Array[Byte](zeroBuffer.limit)
  zeroBuffer.get(zeroArray)

  lazy val cachedSerializer = SparkEnv.get.serializer.newInstance()
  val createZero = () => cachedSerializer.deserialize[U](ByteBuffer.wrap(zeroArray))

  // We will clean the combiner closure later in `combineByKey`
  val cleanedSeqOp = self.context.clean(seqOp)
  combineByKeyWithClassTag[U]((v: V) => cleanedSeqOp(createZero(), v),
    cleanedSeqOp, combOp, partitioner)
}

/**
 * Aggregate the values of each key, using given combine functions and a neutral "zero value".
 * This function can return a different result type, U, than the type of the values in this RDD,
 * V. Thus, we need one operation for merging a V into a U and one operation for merging two U's,
 * as in scala.TraversableOnce. The former operation is used for merging values within a
 * partition, and the latter is used for merging values between partitions. To avoid memory
 * allocation, both of these functions are allowed to modify and return their first argument
 * instead of creating a new U.
 */
// 第二种实现：调用第一种实现，指定分区器为HashPartitioner，需要传入一个分区个数
def aggregateByKey[U: ClassTag](zeroValue: U, numPartitions: Int)(seqOp: (U, V) => U,
    combOp: (U, U) => U): RDD[(K, U)] = self.withScope {
  aggregateByKey(zeroValue, new HashPartitioner(numPartitions))(seqOp, combOp)
}

/**
 * Aggregate the values of each key, using given combine functions and a neutral "zero value".
 * This function can return a different result type, U, than the type of the values in this RDD,
 * V. Thus, we need one operation for merging a V into a U and one operation for merging two U's,
 * as in scala.TraversableOnce. The former operation is used for merging values within a
 * partition, and the latter is used for merging values between partitions. To avoid memory
 * allocation, both of these functions are allowed to modify and return their first argument
 * instead of creating a new U.
 */
// 第三种实现：调用第一种实现，传入默认的HashPartitioner，分区个数使用并行度
def aggregateByKey[U: ClassTag](zeroValue: U)(seqOp: (U, V) => U,
    combOp: (U, U) => U): RDD[(K, U)] = self.withScope {
  aggregateByKey(zeroValue, defaultPartitioner(self))(seqOp, combOp)
}
```

Scala版本

>  ps：正常情况下应该是按照数据的顺序进行分区，可能与输出结果顺序有点不一致，但是不影响整体的结果，这只是我个人查阅资料对这个函数的理解，并没有深入查看源码，也没有深入理解传入分区器和指定分区数量的作用，如果有问题，还希望多多指正，也希望可以与大佬交流。

```scala
println("======================= aggregateByKey-1 ===========================")
def seqOp(x: Int, y: Int): Int = {
  println("seqOp:" + x + ", " + y)
  math.max(x, y)
}

def combOp(x: Int, y: Int): Int = {
  println("combOp:" + x + ", " + y)
  x + y
}
val value4: RDD[(Int, Int)] = data2.aggregateByKey(0, new HashPartitioner(4))(seqOp, combOp)
val result1: RDD[(Int, List[(Int, Int)])] = data2.mapPartitionsWithIndex((index, iter) => {
  val partitionsMap: mutable.Map[Int, List[(Int, Int)]] = mutable.Map[Int, List[(Int, Int)]]()
  var partitionsList: List[(Int, Int)] = List[(Int, Int)]()

  while (iter.hasNext) {
    partitionsList = iter.next() :: partitionsList
  }

  partitionsMap(index) = partitionsList
  partitionsMap.iterator
})
println(s"分区结果为：${result1.collect.toBuffer}")
println(s"分区数量为：${value4.getNumPartitions}")
println(s"经过aggregateByKey处理后的数据为：${value4.collect.toBuffer}")

println("======================= aggregateByKey-2 ===========================")
val value5: RDD[(Int, Int)] = data3.aggregateByKey(3, 4)(seqOp, combOp)
val result2: RDD[(Int, List[(Int, Int)])] = data3.mapPartitionsWithIndex((index, iter) => {
  val partitionsMap: mutable.Map[Int, List[(Int, Int)]] = mutable.Map[Int, List[(Int, Int)]]()
  var partitionsList: List[(Int, Int)] = List[(Int, Int)]()

  while (iter.hasNext) {
    partitionsList = iter.next() :: partitionsList
  }

  partitionsMap(index) = partitionsList
  partitionsMap.iterator
})
println(s"分区结果为：${result2.collect.toBuffer}")
println(s"分区数量为：${value5.getNumPartitions}")
println(s"经过aggregateByKey处理后的数据为：${value5.collect.toBuffer}")

////////////////////////////////////////////////////////////////////////////////
结果分析
原始数据为：(1, 2), (2, 3), (1, 3), (2, 5), (5, 6), (6, 2), (4, 1), (2, 8), (1, 1), (5, 9)
分区之后的数据：(0,List((1,2), (2,3), (1,3), (2,5), (5,6))), (1,List((6,2), (4,1), (2,8), (1,1), (5,9))
                                                      
分析：
第一个分区中第一个值为(1, 2)，1是第一次出现，默认值为3
seqOp:3, 2
第一个分区中第二个值为(2, 3)，2是第一次出现，默认值为3
seqOp:3, 3
第一个分区中第三个值为(1, 3)，1是第二次出现，上一次出现的1的value为2，应该是(2,3)，但是由于2比默认值3小，所以使用默认值3
seqOp:3, 3
第一个分区中第四个值为(2, 5)，2是第二次出现，上一次出现的2的value为3，和默认值3相等
seqOp:3, 5
第一个分区中第五个值为(5, 6)，5是第一次出现，默认值为3
seqOp:3, 6
                                                      
第二个分区中第一个值为(6, 2)，6是第一次出现，默认值为3
seqOp:3, 2
第二个分区中第二个值为(4, 1)，4是第一次出现，默认值为3
seqOp:3, 1
第二个分区中第三个值为(2, 8)，2是第一次出现，默认值为3
seqOp:3, 8
第二个分区中第四个值为(1, 1)，1是第一次出现，默认值为3
seqOp:3, 1
第二个分区中第五个值为(5, 9)，5是第一次出现，默认值为3 
seqOp:3, 9           
                                                      
因为两个分区内都有1、2、5，所以1、2、5需要进行合并
第一次进行合并：合并1时，因为第二个分区中1的value为1，比默认值3小，所以最后的合并结果为：
combOp:3, 3
第二次进行合并：合并2，最后的合并结果为：
combOp:5, 8
第三次进行合并：合并5，最后的合并结果为：
combOp:6, 9
                                                      
由于分区二内的4的value为1，小于3，所以最后使用默认值3，所以最后的结果为：
(1, 6), (2, 13), (5, 15), (6, 2), (4, 3)
////////////////////////////////////////////////////////////////////////////////

println("======================= aggregateByKey-3 ===========================")
val value6: RDD[(String, Int)] = data4.aggregateByKey(0)(seqOp, combOp)
val result3: RDD[(Int, List[(String, Int)])] = data4.mapPartitionsWithIndex((index, iter) => {
  val partitionsMap: mutable.Map[Int, List[(String, Int)]] = mutable.Map[Int, List[(String, Int)]]()
  var partitionsList: List[(String, Int)] = List[(String, Int)]()

  while (iter.hasNext) {
    partitionsList = iter.next() :: partitionsList
  }

  partitionsMap(index) = partitionsList
  partitionsMap.iterator
})
println(s"分区结果为：${result3.collect.toBuffer}")
println(s"分区数量为：${value6.getNumPartitions}")
println(s"经过aggregateByKey处理后的数据为：${value6.collect.toBuffer}")
```

运行结果

![](E:\note\Spark\images\aggregateByKey-1.jpg)

![](E:\note\Spark\images\aggregateByKey-2.jpg)

![](E:\note\Spark\images\aggregateByKey-3.jpg)

###### `foldByKey`

该函数用于RDD[K,V]根据K将V做折叠、合并处理

```scala
/**
 * Merge the values for each key using an associative function and a neutral "zero value" which
 * may be added to the result an arbitrary number of times, and must not change the result
 * (e.g., Nil for list concatenation, 0 for addition, or 1 for multiplication.).
 */
// 第一种实现：两个参数列表：共三个参数，默认的zeroValue值，分区器和关联函数
// 使用关联函数和zeroValue合并每个键的值，该zeroValue可以多次添加到结果中
// 如果关联函数的作用是进行累加，那么在相同分区内出现的相同key的值会先进行累加，之后在将zeroValue添加到结果中，对于乘法来说，初始化zeroValue为0时，所有的结果都为0
def foldByKey(
    zeroValue: V,
    partitioner: Partitioner)(func: (V, V) => V): RDD[(K, V)] = self.withScope {
  // Serialize the zero value to a byte array so that we can get a new clone of it on each key
  val zeroBuffer = SparkEnv.get.serializer.newInstance().serialize(zeroValue)
  val zeroArray = new Array[Byte](zeroBuffer.limit)
  zeroBuffer.get(zeroArray)

  // When deserializing, use a lazy val to create just one instance of the serializer per task
  lazy val cachedSerializer = SparkEnv.get.serializer.newInstance()
  val createZero = () => cachedSerializer.deserialize[V](ByteBuffer.wrap(zeroArray))

  val cleanedFunc = self.context.clean(func)
  combineByKeyWithClassTag[V]((v: V) => cleanedFunc(createZero(), v),
    cleanedFunc, cleanedFunc, partitioner)
}

/**
 * Merge the values for each key using an associative function and a neutral "zero value" which
 * may be added to the result an arbitrary number of times, and must not change the result
 * (e.g., Nil for list concatenation, 0 for addition, or 1 for multiplication.).
 */
// 调用第一种实现：分区器使用默认的分区器，需要传入一个分区数量
def foldByKey(zeroValue: V, numPartitions: Int)(func: (V, V) => V): RDD[(K, V)] = self.withScope {
  foldByKey(zeroValue, new HashPartitioner(numPartitions))(func)
}

/**
 * Merge the values for each key using an associative function and a neutral "zero value" which
 * may be added to the result an arbitrary number of times, and must not change the result
 * (e.g., Nil for list concatenation, 0 for addition, or 1 for multiplication.).
 */
// 调用第一种实现，分区器使用默认的分区器，分区数量使用并行度
def foldByKey(zeroValue: V)(func: (V, V) => V): RDD[(K, V)] = self.withScope {
  foldByKey(zeroValue, defaultPartitioner(self))(func)
}
```

Scala版本

```scala
println("======================= foldByKey-1 ===========================")
val value7: RDD[(Int, Int)] = data2.foldByKey(0, new HashPartitioner(4))(_ + _)
val result4: RDD[(Int, List[(Int, Int)])] = data2.mapPartitionsWithIndex((index, iter) => {
  val partitionsMap: mutable.Map[Int, List[(Int, Int)]] = mutable.Map[Int, List[(Int, Int)]]()
  var partitionsList: List[(Int, Int)] = List[(Int, Int)]()

  while (iter.hasNext) {
    partitionsList = iter.next() :: partitionsList
  }

  partitionsMap(index) = partitionsList
  partitionsMap.iterator
})
println(s"原始数据为：${data2.collect.toBuffer}")
println(s"分区结果为：${result4.collect.toBuffer}")
println(s"分区数量为：${value7.getNumPartitions}")
println(s"经过aggregateByKey处理后的数据为：${value7.collect.toBuffer}")

println("======================= foldByKey-2 ===========================")
val data5: RDD[(Int, Int)] = data3.repartition(4)
val value8: RDD[(Int, Int)] = data5.foldByKey(2, 4)(_ + _)
val result5: RDD[(Int, List[(Int, Int)])] = data5.mapPartitionsWithIndex((index, iter) => {
  val partitionsMap: mutable.Map[Int, List[(Int, Int)]] = mutable.Map[Int, List[(Int, Int)]]()
  var partitionsList: List[(Int, Int)] = List[(Int, Int)]()

  while (iter.hasNext) {
    partitionsList = iter.next() :: partitionsList
  }

  partitionsMap(index) = partitionsList
  partitionsMap.iterator
})
println(s"原始数据为：${data5.collect.toBuffer}")
println(s"分区结果为：${result5.collect.toBuffer}")
println(s"分区数量为：${value8.getNumPartitions}")
println(s"经过aggregateByKey处理后的数据为：${value8.collect.toBuffer}")

////////////////////////////////////////////////////////////////////////////////
结果分析
原始数据为：(2,3), (1,1), (1,4), (6,2), (5,9), (2,5), (4,1), (1,2), (5,6), (2,8)
分区结果为：(0,List((1,1), (2,3))), (1,List((5,9), (6,2), (1,4))), (2,List((4,1), (2,5))), (3,List((2,8), (5,6), (1,2)))

分析：
zeroValue的默认值为2
对于第一个分区：
1和2是单独的key，则最后的结果为：
(1, 1+2), (2, 3+2)
对于第二个分区：
1、5、6是单独的key，则最后的结果为：
(5, 9+2), (6, 2+2), (1, 4+2)
对于第三个分区：
2和4是单独的key，则最后的结果为：
(2, 5+2), (4, 1+2)
对于第四个分区：
1、2、5是单独的key，则最后的结果为：
(1, 2+2), (2, 8+2), (5, 6+2)

所以最后的结果为：
(1, 13), (2, 22), (4, 3), (5, 19), (6, 4)
////////////////////////////////////////////////////////////////////////////////

println("======================= foldByKey-3 ===========================")
val value9: RDD[(String, Int)] = data4.foldByKey(0)(_ * _)
val result6: RDD[(Int, List[(String, Int)])] = data4.mapPartitionsWithIndex((index, iter) => {
  val partitionsMap: mutable.Map[Int, List[(String, Int)]] = mutable.Map[Int, List[(String, Int)]]()
  var partitionsList: List[(String, Int)] = List[(String, Int)]()

  while (iter.hasNext) {
    partitionsList = iter.next() :: partitionsList
  }

  partitionsMap(index) = partitionsList
  partitionsMap.iterator
})
println(s"原始数据为：${data4.collect.toBuffer}")
println(s"分区结果为：${result6.collect.toBuffer}")
println(s"分区数量为：${value9.getNumPartitions}")
println(s"经过aggregateByKey处理后的数据为：${value9.collect.toBuffer}")

val value10: RDD[(String, Int)] = data4.foldByKey(1)(_ * _)
val result7: RDD[(Int, List[(String, Int)])] = data4.mapPartitionsWithIndex((index, iter) => {
  val partitionsMap: mutable.Map[Int, List[(String, Int)]] = mutable.Map[Int, List[(String, Int)]]()
  var partitionsList: List[(String, Int)] = List[(String, Int)]()

  while (iter.hasNext) {
    partitionsList = iter.next() :: partitionsList
  }

  partitionsMap(index) = partitionsList
  partitionsMap.iterator
})
println(s"原始数据为：${data4.collect.toBuffer}")
println(s"分区结果为：${result7.collect.toBuffer}")
println(s"分区数量为：${value10.getNumPartitions}")
println(s"经过aggregateByKey处理后的数据为：${value10.collect.toBuffer}")
```

运行结果

![](E:\note\Spark\images\foldByKey.jpg)

###### `sortByKey`

根据 key 值来进行排序，ascending 升序，默认为 true，即升序

```scala
/**
 * Sort the RDD by key, so that each partition contains a sorted range of the elements. Calling
 * `collect` or `save` on the resulting RDD will return or output an ordered list of records
 * (in the `save` case, they will be written to multiple `part-X` files in the filesystem, in
 * order of the keys).
 */
// TODO: this currently doesn't work on P other than Tuple2!
// 通过key对RDD进行排序，输出顺序是按照key的顺序，目前不适用于Tuple2
def sortByKey(ascending: Boolean = true, numPartitions: Int = self.partitions.length)
    : RDD[(K, V)] = self.withScope
{
  val part = new RangePartitioner(numPartitions, self, ascending)
  new ShuffledRDD[K, V, V](self, part)
    .setKeyOrdering(if (ascending) ordering else ordering.reverse)
}
```

Scala版本

```scala
println("======================= sortByKey ===========================")
val value11: RDD[(Int, Int)] = data2.sortByKey()
println(s"分区数量为：${value11.getNumPartitions}")
println(s"经过sortByKey处理后的结果为：${value11.collect.toBuffer}")

val data6: RDD[(Int, Int)] = data2.repartition(4)
val value12: RDD[(Int, Int)] = data6.sortByKey()
println(s"分区数量为：${value12.getNumPartitions}")
println(s"经过sortByKey处理后的结果为：${value12.collect.toBuffer}")
```

运行结果

![](E:\note\Spark\images\sortByKey.jpg)

##### Action算子

#### Partitioner分区器

---

##### HashPartitioner（默认的分区器）

&emsp;&emsp;HashPartitioner分区原理是对于给定的key，计算其hashCode，并除以分区的个数取余，如果余数小于0，则余数+分区的个数，最后返回的值就是这个key所属的分区ID，当key为null值是返回0。源码在`org.apache.spark`包下，实现如下：

```scala
class HashPartitioner(partitions: Int) extends Partitioner {
  require(partitions >= 0, s"Number of partitions ($partitions) cannot be negative.")

  def numPartitions: Int = partitions

  def getPartition(key: Any): Int = key match {
    case null => 0
    // 要求非负数的取模值，如果为负数，那么 mod + numPartitions 来转为正数
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

##### RangePartitioner

&emsp;&emsp;HashPartitioner分区的实现可能会导致每个分区中的数据量分布不均匀，极端情况下会导致某些分区拥有RDD的所有数据。而RangePartitioner分区器则尽量保证每个分区中数据量的均匀，而且分区和分区之间是有序的，也就是说一个分区中的元素肯定都比另一个分区中的元素小或者大；但是分区内的元素是不能保证顺序的。简单地说就是将一定范围内的数据映射到一个分区内。

&emsp;&emsp;sortByKey底层使用的数据分区器就是RangePartitioner分区器，该分区器的实现方式主要是通过两个步骤来实现的，第一步：先从整个RDD中抽取样本数据，将样本数据排序，计算出每个分区的最大key值，形成一个Array[key]类型的数组变量rangeBounds；第二步：判断key在rangeBounds中所处的范围，给出该key值在下一个RDD中的分区id下标。<font color=#00CCCC>该分区器要求RDD中的key类型必须是可排序的。</font>

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

  // 获取RDD中key类型数据的排序器
  private var ordering = implicitly[Ordering[K]]

  // An array of upper bounds for the first (partitions - 1) partitions
  private var rangeBounds: Array[K] = {
    if (partitions <= 1) {
      // 如果给定的分区数是一个的情况下，直接返回一个空的集合，表示数据不进行分区
      Array.empty
    } else {
      // This is the sample size we need to have roughly balanced output partitions, capped at 1M.
      // Cast to double to avoid overflowing ints or longs
      // 给定总的数据抽样大小，最多1M的数据量（10^6），最少20倍的RDD分区数量，也就是每个RDD分区至少抽取20条数据
      val sampleSize = math.min(samplePointsPerPartitionHint.toDouble * partitions, 1e6)
      // Assume the input partitions are roughly balanced and over-sample a little bit.
      // 计算每个分区抽样的数据量大小，假设输入数据每个分区分布的比较均匀
      // 对于超大数据集（分区数量超过5万的）乘以3会让数据稍微增大一点，对于分区数低于5万的数据集，每个分区抽取数据量为60条也不算多
      val sampleSizePerPartition = math.ceil(3.0 * sampleSize / rdd.partitions.length).toInt
      // 从RDD中抽取数据，返回值：（总RDD数据量，Array[分区id, 当前分区的数据量, 当前分区抽取的数据]）
      val (numItems, sketched) = RangePartitioner.sketch(rdd.map(_._1), sampleSizePerPartition)
      if (numItems == 0L) {
        // 如果总的数据量为0（RDD为空），那么直接返回一个空的数组
        Array.empty
      } else {
        // If a partition contains much more than the average number of items, we re-sample from it
        // to ensure that enough items are collected from that partition.
        // 计算总样本数量和总记录数的占比，占比最大为1.0
        val fraction = math.min(sampleSize / math.max(numItems, 1L), 1.0)
        // 保存样本数据的集合buffer
        val candidates = ArrayBuffer.empty[(K, Float)]
        // 保存数据分布不均衡的分区id（数据量超过fraction比率的分区）
        val imbalancedPartitions = mutable.Set.empty[Int]
        // 计算抽取出来的样本数据
        sketched.foreach { case (idx, n, sample) =>
          if (fraction * n > sampleSizePerPartition) {
            // 如果fraction乘以当前分区中的数据量大于之前计算的每个分区的抽样数据大小，那么表示当前分区抽取的数据太少了，该分区数据分布不均衡，需要重新抽取
            imbalancedPartitions += idx
          } else {
            // 当前分区不属于数据分布不均衡的分区，计算占比权重，并添加到candidates集合中
            // The weight is 1 over the sampling probability.
            val weight = (n.toDouble / sample.length).toFloat
            for (key <- sample) {
              candidates += ((key, weight))
            }
          }
        }
        // 对数据分布不均衡的RDD分区，重新进行数据抽样
        if (imbalancedPartitions.nonEmpty) {
          // Re-sample imbalanced partitions with the desired sampling probability.
          // 获取数据分布不均衡的RDD分区，并构成RDD
          val imbalanced = new PartitionPruningRDD(rdd.map(_._1), imbalancedPartitions.contains)
          // 随机种子
          val seed = byteswap32(-rdd.id - 1)
          // 利用RDD的sample抽样函数API进行数据抽样
          val reSampled = imbalanced.sample(withReplacement = false, fraction, seed).collect()
          val weight = (1.0 / fraction).toFloat
          candidates ++= reSampled.map(x => (x, weight))
        }
        // 将最终的抽样数据计算出rangeBounds
        RangePartitioner.determineBounds(candidates, math.min(partitions, candidates.size))
      }
    }
  }

  // 下一个RDD的分区数量是rangeBounds数组中元素数量+1个
  def numPartitions: Int = rangeBounds.length + 1

  // 二分查找器，内部使用Java中的Arrays提供的二分查找方法
  private var binarySearch: ((Array[K], K) => Int) = CollectionsUtils.makeBinarySearch[K]

  // 根据RDD的key值返回对应的分区id，从0开始
  def getPartition(key: Any): Int = {
    // 强制转换key类型为RDD中原本的数据类型
    val k = key.asInstanceOf[K]
    var partition = 0
    if (rangeBounds.length <= 128) {
      // If we have less than 128 partitions naive search
      // 如果分区数据小于等于128个，那么直接本地循环寻找当前k所属的分区下标
      while (partition < rangeBounds.length && ordering.gt(k, rangeBounds(partition))) {
        partition += 1
      }
    } else {
      // Determine which binary search method to use only once.
      // 如果分区数量大于128个，那么使用二分查找方法寻找对应k所属的下标
      // 但是如果k在rangeBounds中没有出现，实质上返回的是一个负数（范围）或者是一个超过rangeBounds大小的数（最后一个分区，比所有的数据都大）
      partition = binarySearch(rangeBounds, k)
      // binarySearch either returns the match location or -[insertion point]-1
      if (partition < 0) {
        partition = -partition-1
      }
      if (partition > rangeBounds.length) {
        partition = rangeBounds.length
      }
    }
    // 根据数据排序是升序还是降序进行数据的排列，默认为升序
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

将一定范围内的数映射到某一个分区内，在实现中，分界（rangeBounds）算法用到了[水塘抽样算法](https://blog.csdn.net/weixin_43495317/article/details/103943957)。RangePartitioner的重点在于构建rangeBounds数组对象，主要步骤是：

-  如果分区数量小于2或者RDD中不存在数据的情况下，直接返回一个空的数组，不需要计算range的边界；如果分区数量大于1的情况下，而且RDD中有数据的情况下，才需要计算数组对象
-  计算总体的数据抽样大小sampleSize，计算规则是：至少每个分区抽取20个数据或者最多1M的数据量
-  根据sampleSize和分区数量计算每个分区的数据抽样样本数量sampleSizePartition
-  调用RangePartitioner的sketch函数进行数据抽样，计算出每个分区的样本
-  计算样本的整体占比以及数据量过多的数据分区，防止数据倾斜
-  对于数据量比较多的RDD分区调用RDD的sample函数API重新进行数据获取
-  将最终的样本数据通过RangePartitioner的determineBounds函数进行数据排序分配，计算出rangeBounds

&emsp;&emsp;RangePartitioner的sketch函数的作用是对RDD中的数据按照需要的样本数据量进行数据抽取，主要调用SamplingUtils类的reservoirSampleAndCount方法对每个分区进行数据抽取，抽取后计算出整体所有分区的数据量大小；reserviorSampleAndCount方法的抽取方式是先从迭代器中获取样本数量个数据（顺序获取），然后对剩余的数据进行判断，替换之前的样本数据，最终达到数据抽样的效果。RangePartitioner的determineBounds函数的作用是根据样本数据记忆权重大小确定数据边界。

RangePartitioner的determineBounds函数的作用是根据样本数据记忆权重大小确定数据边界，源代码如下：

```scala
/**
   * Determines the bounds for range partitioning from candidates with weights indicating how many
   * items each represents. Usually this is 1 over the probability used to sample this candidate.
   *
   * @param candidates unordered candidates with weights
   * @param partitions number of partitions
   * @return selected bounds
   */
  def determineBounds[K : Ordering : ClassTag](
      candidates: ArrayBuffer[(K, Float)],
      partitions: Int): Array[K] = {
    val ordering = implicitly[Ordering[K]]
    // 按照数据进行排序，默认升序排序
    val ordered = candidates.sortBy(_._1)
    // 获取总的样本数据大小
    val numCandidates = ordered.size
    // 计算总的权重大小
    val sumWeights = ordered.map(_._2.toDouble).sum
    // 计算步长
    val step = sumWeights / partitions
    var cumWeight = 0.0
    var target = step
    val bounds = ArrayBuffer.empty[K]
    var i = 0
    var j = 0
    var previousBound = Option.empty[K]
    while ((i < numCandidates) && (j < partitions - 1)) {
      // 获取排序后的第i个数据及权重
      val (key, weight) = ordered(i)
      // 累计权重
      cumWeight += weight
      if (cumWeight >= target) {
        // Skip duplicate values.
        // 权重已经达到一个步长的范围，计算出一个分区id的值
        if (previousBound.isEmpty || ordering.gt(key, previousBound.get)) {// 上一个边界值为空，或者当前边界值key数据大于上一个边界的值，那么当前key有效，进行计算
          // 添加当前key到边界集合中
          bounds += key
          // 累计target步长界限
          target += step
          // 分区数量加1
          j += 1
          // 上一个边界的值重置为当前边界的值
          previousBound = Some(key)
        }
      }
      i += 1
    }
    // 返回结果
    bounds.toArray
  }
```



##### 自定义分区器

自定义分区器是需要继承`org.apache.spark.Partitioner`类并实现以下三个方法：

-  numPartitioner: Int：返回创建出来的分区数
-  getPartition(key: Any): Int：返回给定键的分区编号（0到numPartitions - 1）
-  equals()：Java判断相等性的标准方法。这个方法的实现非常重要，Spark需要用这个方法来检查你的分区器是否和其他分区器实例相同，这样Spark才可以判断两个RDD的分区方式是否相同

自定义分区器案例（CustomPartitioner）：

```scala
// CustomPartitioner
import org.apache.spark.Partitioner

/**
 * @author xiaoer
 * @date 2020/1/11 19:06
 *
 * @param numPartition 分区数量
 */
class CustomPartitioner(numPartition: Int) extends Partitioner{
    // 返回分区的总数
    override def numPartitions: Int = numPartition

    // 根据传入的 key 返回分区的索引
    override def getPartition(key: Any): Int = {
        key.toString.toInt % numPartition
    }
}

// CustomPartitionerDemo
import com.yangqi.util.SparkUtil
import org.apache.spark.SparkContext
import org.apache.spark.rdd.RDD

/**
 * @author xiaoer
 * @date 2020/1/11 19:13
 */
object CustomPartitionerDemo {
    def main(args: Array[String]): Unit = {
        val sc: SparkContext = SparkUtil.getSparkContext()
        println("=================== 原始数据 =====================")
        // zipWithIndex 该函数将 RDD 中的元素和这个元素在 RDD 中的 ID（索引号）组合成键值对
        val data: RDD[(Int, Long)] = sc.parallelize(0 to 10, 1).zipWithIndex()
        println(data.collect().toBuffer)

        println("=================== 分区和数据组合成 Map =====================")
        val func: (Int, Iterator[(Int, Long)]) => Iterator[String] = (index: Int, iter: Iterator[(Int, Long)]) => {
            iter.map(x => "[partID:" + index + ", value:" + x + "]")
        }
        val array: Array[String] = data.mapPartitionsWithIndex(func).collect()
        for (i <- array) {
            println(i)
        }

        println("=================== 自定义5个分区和数据组合成 Map =====================")
        val rdd1: RDD[(Int, Long)] = data.partitionBy(new CustomPartitioner(5))
        val array1: Array[String] = rdd1.mapPartitionsWithIndex(func).collect()
        for (i <- array1) {
            println(i)
        }
    }
}
```

自定义分区器案例（SubjectPartitioner）：

```scala
// SubjectPartitioner
import org.apache.spark.Partitioner

import scala.collection.mutable

/**
 * @author xiaoer
 * @date 2020/1/11 19:31
 *
 * @param subjects 学科数组
 */
class SubjectPartitioner(subjects: Array[String]) extends Partitioner {
    // 创建一个 map 集合用来存储到分区号和学科
    val subject: mutable.HashMap[String, Int] = new mutable.HashMap[String, Int]()
    // 定义一个计数器，用来生成自定义分区号
    var i = 0
    for (s <- subjects) {
        // 存储学科和分区
        subject += (s -> i)
        // 分区自增
        i += 1
    }

    // 获取分区数
    override def numPartitions: Int = subjects.size

    // 获取分区号（如果传入 key 不存在，默认将数据存储到 0 分区）
    override def getPartition(key: Any): Int = subject.getOrElse(key.toString, 0)
}

// SubjectPartitionerDemo
import java.net.URL

import com.yangqi.util.SparkUtil
import org.apache.spark.SparkContext
import org.apache.spark.rdd.RDD

/**
 * @author xiaoer
 * @date 2020/1/11 19:51
 */
object SubjectPartitionerDemo {
    def main(args: Array[String]): Unit = {
        // 获取上下文对象
        val sc: SparkContext = SparkUtil.getSparkContext()
        val tuples: RDD[(String, Int)] = sc.textFile("src/main/data/project.txt").map(line => {
            val fields: Array[String] = line.split("\t")
            for (i <- fields) {
                println(i)
            }
            // 取出 url
            val url: String = fields(1)
            (url, 1)
        })
        // 将相同的 url 进行聚合，得到了各个学科的访问量
        val sumed: RDD[(String, Int)] = tuples.reduceByKey(_ + _).cache()
        // 从 url 中取出学科的字段，数据组成：学科，url，统计数量
        val subjectAndUC: RDD[(String, (String, Int))] = sumed.map(tup => {
            // 用户 url
            val url: String = tup._1
            // 统计的访问量
            val count: Int = tup._2
            // 学科
            val subject: String = new URL(url).getHost
            (subject, (url, count))
        })
        // 将所有学科取出来
        val subjects: Array[String] = subjectAndUC.keys.distinct.collect
        // 创建自定义分区器对象
        val partitioner: SubjectPartitioner = new SubjectPartitioner(subjects)
        // 分区
        val partitioned: RDD[(String, (String, Int))] = subjectAndUC.partitionBy(partitioner)
        // 取 top3
        val result: RDD[(String, (String, Int))] = partitioned.mapPartitions(it => {
            val list: List[(String, (String, Int))] = it.toList
            val sorted: List[(String, (String, Int))] = list.sortBy(_._2._2).reverse
            val top3: List[(String, (String, Int))] = sorted.take(3)
            // 因为方法的返回值需要一个 iterator
            top3.iterator
        })
        // 存储数据
        result.saveAsTextFile("src/main/data/out/")
        // 释放资源
        sc.stop()
    }
}
```

#### Accumulator累加器

---

&emsp;&emsp;累加器用来对信息进行聚合，通常在向Spark传递函数时，比如使用map()函数或者用filter()传条件时，可以使用驱动器程序中定义的变量，但是集群中运行的每个任务都会得到这些变量的一份新的副本，更新这些副本的值也不会影响驱动器中的对应变量。如果我们想实现所有分片处理时更新共享变量的功能，那么累加器可以实现我们想要的效果。

&emsp;&emsp;累加器是懒执行，需要行动触发。

##### 默认累加器

Spark提供了一个默认的累加器，只能用于求和没有任何用处，而且已经过时了。

```scala
import com.yangqi.util.SparkUtil
import org.apache.spark.{Accumulator, SparkContext}
import org.apache.spark.rdd.RDD

/**
 * @author xiaoer
 * @date 2020/1/12 11:57
 */
object AccumulatorDemo {
  def main(args: Array[String]): Unit = {
    // 获取上下文配置对象
    val sc: SparkContext = SparkUtil.getSparkContext()
    println("==================== 原始数据 =======================")
    val data: RDD[Int] = sc.parallelize(List(1, 2, 3, 4, 5, 6, 7, 8, 9, 10), 2)
    println(data.collect().toBuffer)
    println(s"分区的长度为：${data.partitions.length}")

    // 测试默认的累加器
    testAccumulator(data, sc)

    // 释放资源
    sc.stop()
  }

  /**
   * 测试默认的累加器
   *
   * @param data 测试数据
   * @param sc 上下文对象
   */
  def testAccumulator(data: RDD[Int], sc: SparkContext): Unit = {
    println("==================== 不使用累加器 =======================")
    var sum: Int = 0
    data.foreach(num => {
      sum += num
    })
    println(s"累计总和为：${sum}")

    println("==================== 使用累加器 =======================")
    var summed: Accumulator[Int] = sc.accumulator(0)
    data.foreach(num => {
      summed += num
    })
    println(s"累计总和为：${summed.value}")
  }
}
```

##### 自定义累加器

数值类型累加器，已经被定义好了，可以直接使用

```scala
import com.yangqi.util.SparkUtil
import org.apache.spark.SparkContext
import org.apache.spark.rdd.RDD
import org.apache.spark.util.{DoubleAccumulator, LongAccumulator}

/**
 * @author xiaoer
 * @date 2020/1/12 12:45
 */
object AccumulatorV2Demo {
  def main(args: Array[String]): Unit = {
    // 获取上下文对象
    val sc: SparkContext = SparkUtil.getSparkContext()
    // 原始数据
    println("======================= 原始数据 ======================")
    val data1: RDD[Int] = sc.parallelize(List(1, 2, 3, 4, 5, 6, 7, 8, 9, 10), 2)
    println(s"data1：${data1.collect.toBuffer}")
    val data2: RDD[Double] = sc.parallelize(List(1.1, 2.2, 3.3, 4.4, 5.5, 6.6, 7.7, 8.8, 9.9, 10.10), 2)
    println(s"data2：${data2.collect.toBuffer}")
    // 创建并注册一个 long accumulator，从“0”开始，用“add”累加
    def longAccumulator(name: String): LongAccumulator = {
      val longAcc: LongAccumulator = new LongAccumulator
      sc.register(longAcc, name)
      longAcc
    }

    println("======================= 累加器测试 data1 ======================")
    val acc1: LongAccumulator = longAccumulator("longAccumulator")
    data1.foreach(x => acc1.add(x))
    println(s"累加总和为：${acc1.value}")

    // 创建并注册一个 double accumulator，从“0”开始，用“add”累加
    def doubleAccumulator(name: String): DoubleAccumulator = {
      val doubleAcc: DoubleAccumulator = new DoubleAccumulator
      sc.register(doubleAcc, name)
      doubleAcc
    }

    println("======================= 累加器测试 data2 ======================")
    val acc2: DoubleAccumulator = doubleAccumulator("'doubleAccumulator")
    data2.foreach(x => acc2.add(x))
    println(s"累加总和为：${acc2.value}")

    // 释放资源
    sc.stop()
  }
}
```

自定义类型累加器，需要继承`org.apache.spark.util.AccumulatorV2`

```scala
import org.apache.spark.util.AccumulatorV2

import scala.collection.mutable

/**
 * @author xiaoer
 * @date 2020/1/12 13:40
 */
class WordCountAccumulator extends AccumulatorV2[String, mutable.HashMap[String, Int]] {
  // 创建一个输入值的变量
  private val result: mutable.HashMap[String, Int] = new mutable.HashMap[String, Int]()

  // 检测方法：是否为空
  override def isZero: Boolean = {
    result.isEmpty
  }

  // 拷贝一个新的累加器
  override def copy(): AccumulatorV2[String, mutable.HashMap[String, Int]] = {
    // 创建当前自定义累加器对象
    val wordCountAccumulator: WordCountAccumulator = new WordCountAccumulator
    // 将原有的累加器数据拷贝到新的累加器数据里面
    result.synchronized {
      wordCountAccumulator.result ++= result
    }
    wordCountAccumulator
  }

  // 重置累加器
  override def reset(): Unit = {
    result.clear()
  }

  // 每一个分区中用来添加数据的方法：小区域SUM
  override def add(v: String): Unit = {
    result.get(v) match {
      case None => result += ((v, 1))
      case Some(a) => result += ((v, a + 1))
    }
  }

  // 合并每一个分区的输出：总 SUM
  override def merge(other: AccumulatorV2[String, mutable.HashMap[String, Int]]): Unit = {
    other match {
      case o: AccumulatorV2[String, mutable.HashMap[String, Int]] => {
        for ((k, v) <- o.value) {
          result.get(k) match {
            case None => result += ((k, v))
            case Some(a) => result += ((k, a + v))
          }
        }
      }
    }
  }

  // 输出值
  override def value: mutable.HashMap[String, Int] = {
    result
  }
}
```

#### Broadcast广播变量

---

&emsp;&emsp;广播变量用来高效分发较大的对象。向所有的工作节点发送一个较大的只读值，以供一个或者多个Spark操作使用。广播变量的好处就是不是每个task是一份变量副本，而是每个节点的executor一份副本。

&emsp;&emsp;task在运行的时候，想要使用广播变量中的数据时，此时首先会先从自己本地的executor对应的BlockManager中尝试获取变量副本，如果本地没有，那么就从Driver远程拉取变量副本，并保存在本地的BlockManager中，此后这个executor节点上的task都会直接使用本地的BlockManager中的副本。executor除了从driver上拉取，也可能从其他executor节点的BlockManager上拉取变量副本。（BlockManager：负责管理某个executor对应的内存和磁盘上的数据）

```scala
import com.yangqi.util.SparkUtil
import org.apache.spark.SparkContext
import org.apache.spark.broadcast.Broadcast
import org.apache.spark.rdd.RDD

/**
 * 这是 scala 程序启动的另一种方法，但是官方不建议用。可能会出现空指针异常
 *
 * @author xiaoer
 * @date 2020/1/12 15:43
 */
object BroadcastDemo extends App {
  // 获取上下文对象
  val sc: SparkContext = SparkUtil.getSparkContext()
  // 创建一个用于共享的数据
  val list: List[String] = List("hello")
  // 将 list 封装成广播变量
  val broadList: Broadcast[List[String]] = sc.broadcast(list)
  // 算子部分在 executor 执行
  val data: RDD[String] = sc.parallelize(List("hello"), 1)
  val filterStr: RDD[String] = data.filter(broadList.value.contains(_))
  filterStr.foreach(println)
}
```

&emsp;&emsp;注意：<font color=#00cccc>任何可序列化的类型都可以被封装成一个广播变量，但是RDD不能被封装成广播变量，因为RDD是不存储数据的，可以将RDD的结果封装成广播变量。广播变量只能在driver端定义，不能在executor端定义。</font>

#### 文件的输入与输出

---

##### 文本文件

`textFile`：对文本文件进行读取，如果传入的是一个目录，那么目录下所有的文件都将被读取。

`saveAsTextFile`：对文本文件进行输出，传入的值会被当做一个目录，在该目录下生成多个文件。

```scala
import com.yangqi.util.SparkUtil
import org.apache.spark.SparkContext
import org.apache.spark.rdd.RDD

/**
 * @author xiaoer
 * @date 2020/1/12 16:28
 */
object TextFileDemo {
  def main(args: Array[String]): Unit = {
    // 获取上下文对象
    val sc: SparkContext = SparkUtil.getSparkContext()
    // 获取文本文件输入路径
    val data: RDD[String] = sc.textFile("src/main/data/test.txt")
    println(s"文本文件的内容为：${data.collect.toBuffer}")
    // 将数据写入到文本文件中
    data.saveAsTextFile("src/main/data/out")
    // 释放资源
    sc.stop()
  }
}
```

##### JSON文件

JSON文件中的每一行就是一个记录，可以通过Spark将JSON文件当做文本文件来读取，然后利用相关的JSON库对每一条数据进行解析。

```scala
import com.alibaba.fastjson.{JSON, JSONObject}
import com.yangqi.util.SparkUtil
import org.apache.spark.SparkContext
import org.apache.spark.rdd.RDD

import scala.collection.mutable

/**
 * @author xiaoer
 * @date 2020/1/12 16:33
 */
object JsonDemo {
  def main(args: Array[String]): Unit = {
    // 获取上下文对象
    val sc: SparkContext = SparkUtil.getSparkContext()
    // 获取json数据
    val data: RDD[String] = sc.textFile("src/main/data/info.json")
    // 将数据按行切分
    val infos: RDD[String] = data.flatMap(_.split("\\n"))
    // 将数据用 fastjson 进行解析
    val result: RDD[(AnyRef, AnyRef, AnyRef)] = infos.map(info => {
      val infoObject: JSONObject = JSON.parseObject(info)
      (infoObject.get("name"), infoObject.get("age"), infoObject.get("sex"))
    })
    println("===================== 读取到的数据 =====================")
    result.foreach(println)

    // 将读取到的数据进行编码存储成 json
    var datas: mutable.HashMap[String, String] = new mutable.HashMap[String, String]()
    val results: RDD[mutable.HashMap[String, String]] = result.map(info => {
      val map: mutable.HashMap[String, String] = new mutable.HashMap[String, String]()
      map.put("name", info._1.toString)
      map.put("age", info._2.toString)
      map.put("sex", info._3.toString)
      datas ++= map
    })
    println("=====================读取到的数据=====================")
    results.foreach(println)
    results.saveAsTextFile("src/main/data/out")

    // 释放资源
    sc.stop()
  }
}
```

##### CSV文件

读取CSV数据和读取JSON数据相似，都需要先把这个文件当做普通文本文件来读取，然后通过讲每一行进行解析实现对CSV的读取

```scala
import com.yangqi.util.SparkUtil
import org.apache.spark.SparkContext
import org.apache.spark.rdd.RDD

/**
 * @author xiaoer
 * @date 2020/1/12 18:24
 */
object CSVDemo {
  def main(args: Array[String]): Unit = {
    // 获取上下文对象
    val sc: SparkContext = SparkUtil.getSparkContext()
    // 读取文件，默认以“,”分隔
    val data: RDD[String] = sc.textFile("src/main/data/test.csv")
    // 查看数据
    data.foreach(println)
  }
}
```

##### SequenceFile文件

SequenceFile文件是Hadoop用来存储二进制形式的key-value对而设计的，sequenceFile读取文件是需要指定文件中的数据类型（泛型）

`saveAsSequenceFile`：存储文件数据，可以直接调用该方法保存PairRDD，要求键和值都能够自动转换为Writable类型

```scala
import com.yangqi.util.SparkUtil
import org.apache.spark.SparkContext
import org.apache.spark.rdd.RDD

/**
 * @author xiaoer
 * @date 2020/1/12 18:17
 */
object SequenceFileDemo {
  def main(args: Array[String]): Unit = {
    // 获取上下文对象
    val sc: SparkContext = SparkUtil.getSparkContext()
    // 数据输入
    val data: RDD[(Int, String)] = sc.parallelize(List((2, "bb"), (3, "cc"), (4, "dd"), (5, "ee")))
    println("================= 原始数据 ==================")
    data.foreach(println)

    // 使用 sequenceFile 文件格式保存文件
    println("================= 保存的数据 ==================")
    data.saveAsSequenceFile("src/main/data/out")
    val sdata: RDD[(Int, String)] = sc.sequenceFile[Int, String]("src/main/data/out/")
    sdata.foreach(println)
  }
}
```

##### JDBCRDD

Spark提供了一个RDD来处理对JDBC的连接，这个RDD只能进行查询而且是范围查询，不能进行增删改查。

```scala
import java.sql.{Connection, Date}

import com.yangqi.util.{SparkJDBCUtil, SparkUtil}
import org.apache.spark.SparkContext
import org.apache.spark.rdd.JdbcRDD

/**
 * @author xiaoer
 * @date 2020/1/11 16:18
 */
object QueeryDemo {
  def main(args: Array[String]): Unit = {
    // 获取上下文对象
    val sc: SparkContext = SparkUtil.getSparkContext()
    // 获取连接对象
    val conn: () => Connection = SparkJDBCUtil.getConnection("jdbc.properties")
    // SQL 语句
    val sql: String = "select * from emp where empno > ? and empno < ?"
    val jdbcRDD: JdbcRDD[(Int, String, String, Int, Date, Int, Int, Int)] = new JdbcRDD(sc, conn, sql, 7521, 7838, 1, res => {
      val empno: Int = res.getInt("empno")
      val ename: String = res.getString("ename")
      val job: String = res.getString("job")
      val mgr: Int = res.getInt("mgr")
      val hiredate: Date = res.getDate("hiredate")
      val sal: Int = res.getInt("sal")
      val comm: Int = res.getInt("comm")
      val deptno: Int = res.getInt("deptno")
      (empno, ename, job, mgr, hiredate, sal, comm, deptno)
    })
    println(jdbcRDD.collect.toBuffer)
  }
}
```

工具类

```scala
import java.io.InputStream
import java.sql.{Connection, DriverManager}
import java.util.Properties

/**
 * Spark 数据库操作的相关工具
 *
 * @author xiaoer
 * @date 2020/1/11 16:05
 */
object SparkJDBCUtil {
  /**
   * 获取 JDBC 连接
   *
   * @param properties 配置文件名称
   * @return JDBC 连接对象
   */
  def getConnection(properties: String): () => Connection = {
    val is: InputStream = SparkJDBCUtil.getClass.getClassLoader.getResourceAsStream(properties)
    val prop: Properties = new Properties()
    // 加载配置文件
    prop.load(is)
    () => {
      // 加载驱动类
      Class.forName(prop.getProperty("driver"))
      // 获取连接对象
      DriverManager.getConnection(prop.getProperty("url"), prop.getProperty("username"), prop.getProperty("password"))
    }
  }
}
```

