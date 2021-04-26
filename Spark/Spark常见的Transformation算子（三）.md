#### Spark常见的Transformation算子（三）

##### `初始化数据`

```scala
println("======================= 原始数据 ===========================")
val data1: RDD[Int] = sc.parallelize(1 to 10, 3)
println(s"原始数据为：${data1.collect.toBuffer}")
val data2: RDD[Int] = sc.parallelize(5 to 15, 2)
println(s"原始数据为：${data2.collect.toBuffer}")
val data3: RDD[Int] = sc.parallelize(List(1, 2, 3, 4, 5, 5, 4, 3, 2, 1))
println(s"原数数据为：${data3.collect.toBuffer}")
```

结果

![](http://typora-image.test.upcdn.net/images/third_data.jpg)

##### `distinct`

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

###### Scala版本

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

运行结果

![](http://typora-image.test.upcdn.net/images/distinct.jpg)

##### `union`

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

###### Scala版本

```scala
println("======================= union ===========================")
val value: RDD[Int] = data1.union(data2)
println(s"经过union处理后的数据为：${value3.collect.toBuffer}")
```

运行结果

![](http://typora-image.test.upcdn.net/images/union.jpg)

##### `intersection`

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

###### Scala版本

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

![](http://typora-image.test.upcdn.net/images/intersection.jpg)

##### `subtract`

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

###### Scala版本

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

![](http://typora-image.test.upcdn.net/images/subtract.jpg)

##### `cartesian`

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

###### Scala版本

```scala
println("======================= cartesian ===========================")
val value1: RDD[(Int, Int)] = data1.cartesian(data2)
println(s"分区数量为：${value1.getNumPartitions}")
println(s"经过cartesian处理后的数据为：${value1.collect.toBuffer}")
```

运行结果

![](http://typora-image.test.upcdn.net/images/cartesian.jpg)

##### `sample`

采样操作，用于从样本中取出部分数据

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

###### Scala版本

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

![](http://typora-image.test.upcdn.net/images/sample.jpg)