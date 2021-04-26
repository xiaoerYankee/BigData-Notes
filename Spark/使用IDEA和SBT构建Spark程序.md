#### 使用IDEA和SBT构建Spark程序

##### 1. 打开IDEA创建一个Scala项目，选择sbt

![](http://typora-image.test.upcdn.net/images/20200517144121.jpg)

##### 2. 选择合适的sbt版本和scala版本

![](http://typora-image.test.upcdn.net/images/20200517144122.jpg)

##### 3. 创建完成之后会从远程服务器拉取一些项目的信息，可能比较慢

![](http://typora-image.test.upcdn.net/images/20200517144123.jpg)

##### 4. 完成后的项目结构如图所示

![](http://typora-image.test.upcdn.net/images/20200517144124.jpg)

##### 5. 编辑build.sbt文件，导入spark-core依赖

```properties
// 可以直接去maven的中央仓库去找，选择sbt复制即可
// https://mvnrepository.com/artifact/org.apache.spark/spark-core
libraryDependencies += "org.apache.spark" %% "spark-core" % "2.4.4"
```

导入过程需要一点时间，因为需要去远程的中央仓库去下载，导入完成后，可以在项目左侧的`External Libraries`中看到已经导入的包

![](http://typora-image.test.upcdn.net/images/20200517144125.jpg)

##### 6. 建立一个测试类，测试是否配置成功

Spark的WordCount案例

```scala
import org.apache.spark.rdd.RDD
import org.apache.spark.{SparkConf, SparkContext}

object HelloSpark {
    def main(args: Array[String]): Unit = {
        // 创建配置对象
        val conf: SparkConf = new SparkConf().setMaster("local[*]").setAppName("HelloSpark")
        // 创建上下文对象  SparkContext
        val context: SparkContext = new SparkContext(conf)
        // 从文件中读取要统计的语句
        val lines: RDD[String] = context.textFile("E:/sparkdata/text.txt")
        // 将从文件读取到的字符串进行切分
        val words: RDD[String] = lines.flatMap(_.split(" "))
        // 将单词转换成为元组
        val tuples: RDD[(String, Int)] = words.map((_, 1))
        // 将元祖进行聚合
        val sumed: RDD[(String, Int)] = tuples.reduceByKey(_ + _)
        // 对聚合后的结果进行排序
        val sorted: RDD[(String, Int)] = sumed.sortBy(_._2, false)
        // 将结果输出到文件中
        sorted.saveAsTextFile("E:/sparkdata/01")
        // 释放资源
        context.stop()
    }
}
```

如果可以运行成功，说明已经配置成功，有的人这里可能会出现运行，这是可以选择重新配置一下项目的`Scala SDK`

![](http://typora-image.test.upcdn.net/images/20200517144126.jpg)

##### 7. 将`WordCount`打包成jar包在集群上测试，并将结果保存到集群

如果在集群上运行时，需要将WordCount案例代码进行修改

```scala
import org.apache.spark.rdd.RDD
import org.apache.spark.{SparkConf, SparkContext}

object HelloSpark {
    def main(args: Array[String]): Unit = {
        // 创建配置对象
        val conf: SparkConf = new SparkConf().setAppName("WordCount")
        // 创建上下文对象  SparkContext
        val context: SparkContext = new SparkContext(conf)
        // 从文件中读取要统计的语句
        val lines: RDD[String] = context.textFile(args(0))
        // 将从文件读取到的字符串进行切分
        val words: RDD[String] = lines.flatMap(_.split(" "))
        // 将单词转换成为元组
        val tuples: RDD[(String, Int)] = words.map((_, 1))
        // 将元祖进行聚合
        val sumed: RDD[(String, Int)] = tuples.reduceByKey(_ + _)
        // 对聚合后的结果进行排序
        val sorted: RDD[(String, Int)] = sumed.sortBy(_._2, false)
        // 将结果输出到文件中
        sorted.saveAsTextFile(args(1))
        // 释放资源
        context.stop()
    }
}
```

接下来将项目进行打包

- 打开项目结构配置页面

  ![](http://typora-image.test.upcdn.net/images/20200517144127.jpg)

- 添加jar包配置

  ![](http://typora-image.test.upcdn.net/images/20200517144128.jpg)

- 如果项目中有多个项目和主类，可以选择自己要打包的项目和主类

  ![](http://typora-image.test.upcdn.net/images/20200517144129.jpg)

- 点击OK即可，然后去掉额外的lib包依赖，不要将其打包到jar文件中，只保留class编译文件及`META-INF`文件夹

  ![](http://typora-image.test.upcdn.net/images/20200517144130.jpg)

  ![](http://typora-image.test.upcdn.net/images/20200517144131.jpg)

- 编译生成jar包

  ![](http://typora-image.test.upcdn.net/images/20200517144132.jpg)

  ![](http://typora-image.test.upcdn.net/images/20200517144133.jpg)

  ![](http://typora-image.test.upcdn.net/images/20200517144134.jpg)

- 打包成功后，可以在`out`中看到jar包

  ![](http://typora-image.test.upcdn.net/images/20200517144135.jpg)

- 查看一下jar包内的项目结构

  ![](http://typora-image.test.upcdn.net/images/20200517144136.jpg)

- 将打好的jar包上传到集群，然后在集群上创建一个目录，存放`text.txt`

  ```shell
  [hadoop@master ~]$ hdfs dfs -mkdir /sparkdata
  [hadoop@master ~]$ echo "hello world hello spark" >> text.txt
  [hadoop@master ~]$ hdfs dfs -put ./text.txt /sparkdata/
  ```

- 提交作业，进行测试

  ```shell
  spark-submit \
  --class HelloSpark \
  --executor-memory 512M \
  --total-executor-cores 1 \
  /home/yangqi/sparkdata/SBTSet.jar \
  hdfs://supercluster/sparkdata/text.txt \
  hdfs://supercluster/sparkdata/out/
  ```

  我这里的集群是高可用，所以使用的supercluster，高可用集群的名称；如果不是高可用，使用主机名+端口号即可。例如：master:8020
  
  --class后面一定要添加类全名，由于我的类没有包，所以直接使用即可