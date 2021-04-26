#### Spark常见的Transformation算子（二）

##### `初始化数据`

```scala
println("======================= 原始数据 ===========================")
val data: RDD[String] = sc.textFile("src/main/data/test.txt")
println(s"原始数据为：${data.collect.toBuffer}")
```

##### `filter`

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

###### Scala版本

```scala
// 返回包含“hello”的那些行，只要数据是按行存储的，那么在filter是按照行返回，不需要提前对数据进行按行分隔
println("======================= filter ===========================")
val value: RDD[String] = data.filter(f => f.contains("hello"))
println(s"经过filter处理后的数据为：${value.collect.toBuffer}")
```

运行结果

![](http://typora-image.test.upcdn.net/images/filter.jpg)

##### `map`

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

###### Scala版本

```scala
// 原始数据按行每一行追加上一个“ nihao”
println("======================= map ===========================")
val value: RDD[String] = data.map(f => f + " nihao")
println(s"经过map处理后的数据为：${value.collect.toBuffer}")
```

运行结果

![](http://typora-image.test.upcdn.net/images/map.jpg)

##### `flatMap`

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

###### Scala版本

```scala
println("======================= flatMap ===========================")
val value: RDD[String] = data.flatMap(f => f.split(" "))
println(s"经过flatMap处理后的数据为：${value.collect.toBuffer}")
```

运行结果

![](http://typora-image.test.upcdn.net/images/flatMap.jpg)

##### `mapToPair`

将RDD转成PairRDD，在scala中map就可以实现

###### Scala版本

```scala
println("======================= mapToPair ===========================")
val value: RDD[(String, Int)] = data.map(f => (f, 1))
println(s"经过mapToPair处理后的数据为：${value.collect.toBuffer}")
```

运行结果

![](http://typora-image.test.upcdn.net/images/mapToPair.jpg)

##### `flatMapToPair`

相当于先flatMap，后mapToPair，scala中没有专门的flatMapToPair

###### Scala版本

```scala
println("======================= flatMapToPair-1 ===========================")
val value: RDD[String] = data.flatMap(f => f.split(" "))
val result: RDD[(String, Int)] = value.map(f => (f, 1))
println(s"经过flatMapToPair处理后的数据为：${result.collect.toBuffer}")
```

运行结果

![](http://typora-image.test.upcdn.net/images/flatMapToPair.jpg)