#### Spark常见的Transformation算子（四）

##### `原始数据`

```scala
println("======================= 原始数据 ===========================")
val data1: RDD[String] = sc.parallelize(List("hello", "world", "spark", "hello", "spark", "hello", "scala"), 2)
println(s"原始数据为：${data1.collect.toBuffer}")
val info1: RDD[(String, Int)] = data1.map((_, 1))
println(s"map处理过后的数据：${info1.collect.toBuffer}")
val data2: RDD[(Int, Int)] = sc.parallelize(List((1, 2), (2, 3), (1, 3), (2, 5), (3, 6), (6, 2), (4, 1), (3, 8), (5, 1), (5, 9)), 2)
println(s"原始数据为：${data2.collect.toBuffer}")
val data3: RDD[(Int, Int)] = sc.parallelize(List((1, 2), (2, 3), (1, 3), (2, 5), (5, 6), (6, 2), (4, 1), (2, 8), (1, 1), (5, 9)), 2)
println(s"原始数据为：${data3.collect.toBuffer}")
val data4: RDD[(String, Int)] = sc.parallelize(List(("aa", 2), ("cc", 3), ("aa", 3), ("bb", 5), ("aa", 6), ("cc", 2), ("dd", 1), ("aa", 8), ("bb", 1), ("cc", 9)), 2)
println(s"原始数据为：${data4.collect.toBuffer}")
```

结果

![](http://typora-image.test.upcdn.net/images/four_data.jpg)

##### `combineByKey`

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

###### Scala版本

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

![](http://typora-image.test.upcdn.net/images/combineByKey.jpg)

##### `reduceByKey`

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

###### Scala版本

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

![](http://typora-image.test.upcdn.net/images/reduceByKey.jpg)

##### `aggregateByKey`

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

###### Scala版本

ps：正常情况下应该是按照数据的顺序进行分区，可能与输出结果顺序有点不一致，但是不影响整体的结果，这这是我个人查询资料对这个函数的理解，并没有深入查询源码，也没有深入理解传入分区器和指定分区数量的作用，如果有问题，还希望多多指正，也希望可以与大佬交流。

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

![](http://typora-image.test.upcdn.net/images/aggregateByKey-1.jpg)

![](http://typora-image.test.upcdn.net/images/aggregateByKey-2.jpg)

![](http://typora-image.test.upcdn.net/images/aggregateByKey-3.jpg)

##### `foldByKey`

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

###### Scala版本

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

![](http://typora-image.test.upcdn.net/images/foldByKey.jpg)

##### `sortByKey`

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

###### Scala版本

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

![](http://typora-image.test.upcdn.net/images/sortByKey.jpg)