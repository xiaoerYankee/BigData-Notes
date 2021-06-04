#### Spark核心编程_累加器和广播变量

##### 1. 累加器

累加器用来把Executor端变量信息聚合到Driver端。在Driver程序中定义的变量，在Executor端的每个Task都会得到这个变量的一份新的副本，每个task更新这些副本的值后，传回Driver端进行merge。

###### 1. 系统累加器

```scala
// TODO 业务逻辑
val rdd: RDD[Int] = sc.makeRDD(List(1, 2, 3, 4), 2)

// Spark默认就提供了简单数据聚合的累加器
val sumAcc: LongAccumulator = sc.longAccumulator("sum")
//sc.doubleAccumulator()
//sc.collectionAccumulator()
rdd.foreach(
  num => {
    // 使用累加器
    sumAcc.add(num)
  }
)
// 获取累加器的值
println(sumAcc.value)
```

累加器常出现的问题：

- 少加：transform算子中调用累加器，如果没有action算子，不会被执行
- 多加：action调用多次，就会被计算多次

###### 2. 自定义累加器

```scala
/**
 * 自定义数据累加器：WordCount
 *  1.自定义AccumulatorV2，定义泛型
 *    IN：累加器输入的数据类型
 *    OUT：累加器返回的数据类型
 *  2.重写方法
 */
class MyAccumulator extends AccumulatorV2[String, mutable.Map[String, Long]] {
  private var wcMap = mutable.Map[String, Long]()

  // 判断是否初始状态
  override def isZero: Boolean = {
    wcMap.isEmpty
  }

  // 复制新的累加器
  override def copy(): AccumulatorV2[String, mutable.Map[String, Long]] = {
    new MyAccumulator()
  }

  // 重置累加器
  override def reset(): Unit = {
    wcMap.clear()
  }

  // 获取累加器需要计算的值
  override def add(word: String): Unit = {
    val newCnt: Long = wcMap.getOrElse(word, 0L) + 1
    wcMap.update(word, newCnt)
  }

  // 合并多个累加器
  override def merge(other: AccumulatorV2[String, mutable.Map[String, Long]]): Unit = {
    val map1: mutable.Map[String, Long] = this.wcMap
    val map2: mutable.Map[String, Long] = other.value
    map2.foreach {
      case (word, count) => {
        val newCount: Long = map1.getOrElse(word, 0L) + count
        map1.update(word, newCount)
      }
    }
  }

  // 累加器结果
  override def value: mutable.Map[String, Long] = {
    wcMap
  }
}
```

##### 2. 广播变量

广播变量用来高效分发较大的对象。向所有工作节点发送一个较大的只读值，以供一个或多个Spark操作使用。在多个并行操作中使用同一个变量，但是Spark会为每个任务分别发送。

###### 1. 基础编程

闭包数据都是以Task为单位发送的，每个任务中都包含闭包数据，这样可能会导致，一个Executor中包含多个相同的闭包数据，造成数据重复，占用内存空间。

由于Executor其实就是一个JVM，所以在启动时，会自动分配内存，可以完全把任务重的闭包数据存放在Executor的内存中，达到共享的目的。

```scala
val rdd1: RDD[(String, Int)] = sc.makeRDD(List(("a", 1), ("b", 2), ("c", 3)), 2)
val map = mutable.Map(("a", 4), ("b", 5), ("c", 6))

// 封装广播变量
val broadCast: Broadcast[mutable.Map[String, Int]] = sc.broadcast(map)

rdd1.map {
  case (word, count) => {
    val i: Int = broadCast.value.getOrElse(word, 0)
    (word, (count, i))
  }
}.collect().foreach(println)
```

