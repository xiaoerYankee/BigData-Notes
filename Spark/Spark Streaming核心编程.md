#### Spark Streaming核心编程

##### 1. DStream入门

###### 1. WordCount实例

```scala
import org.apache.spark.SparkConf
import org.apache.spark.streaming.dstream.{DStream, ReceiverInputDStream}
import org.apache.spark.streaming.{Seconds, StreamingContext}

/**
 * @author Yankee
 * @date 2021/4/4 18:19
 */
object SparkStreaming01_WordCount {
  def main(args: Array[String]): Unit = {
    System.setProperty("HAOOP_USER_NAME", "hadoop")

    // TODO 创建环境
    // StreamingContext创建时，需要传递两个参数
    //  第一个参数表示环境配置
    val conf: SparkConf = new SparkConf().setMaster("local[*]").setAppName(this.getClass.getSimpleName.filter(!_.equals('$')))
    //  第二个参数表示批量处理的周期（采集周期）
    val ssc: StreamingContext = new StreamingContext(conf, Seconds(3))

    // TODO 逻辑处理
    // 获取端口数据
    val lines: ReceiverInputDStream[String] = ssc.socketTextStream("master", 9999)
    val result: DStream[(String, Int)] = lines.flatMap(_.split(" ")).map((_, 1)).reduceByKey(_ + _)
    result.print()

    // TODO 关闭环境
    // 由于SparkStreaming采集器是长期执行的任务，所以不能直接关闭
    // 如果main方法执行完毕，应用程序也会自动结束，所以不能让main执行完毕
    // ssc.stop()
    // 1.启动采集器
    ssc.start()
    // 2.等待采集器的关闭
    ssc.awaitTermination()
  }
}
```

###### 2. WordCount解析

Discretized Stream是Spark Streaming的基础抽象，代表持续性额数据流和经过各种Spark原语操作后的结果数据流。在内部实现上，DStream是一系列连续的RDD来表示。每个RDD含有一段时间间隔内的数据。

![](http://typora-image.test.upcdn.net/images/DStream-RDD.jpg)

对数据的操作也是按照RDD为单位来进行的

![](http://typora-image.test.upcdn.net/images/DStream-RDD-Line.jpg)

计算过程由Spark Engine来完成

![](http://typora-image.test.upcdn.net/images/DStream-SparkEngine.jpg)

##### 2. DStream创建

###### 1. RDD队列

可以通过使用`ssc.queueStream(queueOfRDDs)`来创建DStream，每一个推送到这个队列中的RDD，都会作为一个DStream处理。

```scala
import org.apache.spark.SparkConf
import org.apache.spark.rdd.RDD
import org.apache.spark.streaming.dstream.{DStream, InputDStream}
import org.apache.spark.streaming.{Seconds, StreamingContext}

import scala.collection.mutable

/**
 * @author Yankee
 * @date 2021/4/5 11:46
 */
object SparkStreaming01_Queue {
  def main(args: Array[String]): Unit = {
    System.setProperty("HADOOP_USER_NAME", "hadoop")

    // TODO 创建环境
    val conf: SparkConf = new SparkConf().setMaster("local[*]").setAppName(this.getClass.getSimpleName.filter(!_.equals('$')))
    val ssc: StreamingContext = new StreamingContext(conf, Seconds(3))

    // TODO 业务逻辑
    val rddQueue: mutable.Queue[RDD[Int]] = new mutable.Queue[RDD[Int]]()
    // 创建QueueInputDStream
    val inputStream: InputDStream[Int] = ssc.queueStream(rddQueue, oneAtATime = false)
    // 处理队列中的RDD数据
    val mappedStream: DStream[(Int, Int)] = inputStream.map((_, 1))
    val reducedStream: DStream[(Int, Int)] = mappedStream.reduceByKey(_ + _)
    // 打印结果
    reducedStream.print()

    // TODO 启动任务
    ssc.start()

    for (i <- 1 to 5) {
      rddQueue += ssc.sparkContext.makeRDD(1 to 300, 10)
      Thread.sleep(2000)
    }

    ssc.awaitTermination()
  }
}
```

###### 2. 自定义数据源

需要继承Receiver，并实现onStart、onStop方法来自定义数据源采集。

```scala
import org.apache.spark.SparkConf
import org.apache.spark.storage.StorageLevel
import org.apache.spark.streaming.dstream.ReceiverInputDStream
import org.apache.spark.streaming.receiver.Receiver
import org.apache.spark.streaming.{Seconds, StreamingContext}

import scala.util.Random

/**
 * @author Yankee
 * @date 2021/4/5 11:46
 */
object SparkStreaming02_DIY {
  def main(args: Array[String]): Unit = {
    System.setProperty("HADOOP_USER_NAME", "hadoop")

    // TODO 创建环境
    val conf: SparkConf = new SparkConf().setMaster("local[*]").setAppName(this.getClass.getSimpleName.filter(!_.equals('$')))
    val ssc: StreamingContext = new StreamingContext(conf, Seconds(3))

    // TODO 业务逻辑
    val messageDS: ReceiverInputDStream[String] = ssc.receiverStream(new MyReceiver)
    messageDS.print()

    // TODO 启动任务
    ssc.start()
    ssc.awaitTermination()
  }

  /**
   * 自定义数据采集器
   *  1.继承Receiver，定义泛型
   *  2.重写两个方法：onStart、onStop
   */
  class MyReceiver extends Receiver[String](StorageLevel.MEMORY_ONLY) {
    private var flag: Boolean = true

    override def onStart(): Unit = {
      new Thread(new Runnable {
        override def run(): Unit = {
          while (flag) {
            val message: String = "采集的数据为：" + new Random().nextInt(10).toString
            store(message)
            Thread.sleep(500)
          }
        }
      }).start()
    }

    override def onStop(): Unit = {
      flag = false
    }
  }
}
```

###### 3. Kafka数据源

```scala
import org.apache.kafka.clients.consumer.{ConsumerConfig, ConsumerRecord}
import org.apache.spark.SparkConf
import org.apache.spark.streaming.dstream.InputDStream
import org.apache.spark.streaming.kafka010.{ConsumerStrategies, KafkaUtils, LocationStrategies}
import org.apache.spark.streaming.{Seconds, StreamingContext}

/**
 * @author Yankee
 * @date 2021/4/7 20:08
 */
object SparkStreaming03_Kafka {
  def main(args: Array[String]): Unit = {
    System.setProperty("HADOOP_USER_NAME", "hadoop")

    // TODO 创建环境
    val conf: SparkConf = new SparkConf().setMaster("local[*]").setAppName(this.getClass.getSimpleName.filter(!_.equals('$')))
    val ssc: StreamingContext = new StreamingContext(conf, Seconds(3))

    // TODO 业务逻辑
    val kafkaPara: Map[String, Object] = Map[String, Object](
      ConsumerConfig.BOOTSTRAP_SERVERS_CONFIG -> "master:9092,slave1:9092,slave2:9092",
      ConsumerConfig.GROUP_ID_CONFIG -> "yankee",
      "key.deserializer" -> "org.apache.kafka.common.serialization.StringDeserializer",
      "value.deserializer" -> "org.apache.kafka.common.serialization.StringDeserializer"
    )

    val kafkaDataDS: InputDStream[ConsumerRecord[String, String]] = KafkaUtils.createDirectStream[String, String](
      ssc,
      LocationStrategies.PreferConsistent,
      ConsumerStrategies.Subscribe[String, String](Set("yankee"), kafkaPara)
    )

    kafkaDataDS.map(_.value()).print()

    // TODO 关闭环境
    ssc.start()
    ssc.awaitTermination()
  }
}
```

##### 3. DStream转换

DStream上的操作与RDD的类似，分为Transformatios（转换）和Output Operations（输出）两种，此外转换操作中还有一些比较特殊的原语，如：updateStateByKey()、transform()以及各种window()相关的原语。

###### 1. 无状态转化操作

无状态转化操作就是把简单的RDD转化操作应用到每个批次上，也就是转化DStream中的每一个RDD。部分无状态转化操作如下。注意：针对键值对的DStream转化操作（比如reduceByKey）要添加`import StreamingContext._`才可以在Scala中使用。

![](http://typora-image.test.upcdn.net/images/SparkStreaming%E6%97%A0%E7%8A%B6%E6%80%81%E5%8E%9F%E8%AF%AD.png)

需要记住的是，尽管这些函数看起来像是作用在整个流上一样，但事实上每个DStream在内部都是由许多的RDD（批次）组成，且无状态转化操作是分别应用到每个RDD上的。

- Transform