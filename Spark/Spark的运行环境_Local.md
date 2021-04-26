#### Spark的运行环境_Local

Spark作为一个数据处理框架和计算引擎，被设计在所有常见的集群环境中运行，在国内工作中主流的环境为Yarn。

![](http://typora-image.test.upcdn.net/images/Spark运行环境.jpg)

##### 1. Local模式

所谓的Local模式，就是不需要其他任何节点资源就可以在本地执行Spark代码的环境，一般用于教学、调试、演示等。

###### 1. 启动Local环境

- 进入解压缩后的路径，执行如下命令

  ```
  bin/spark-shell
  ```

  ![](http://typora-image.test.upcdn.net/images/local.jpg)

- 启动成功后，可以输入网址进行Web UI监控页面访问

  ```
  http://虚拟机地址:4040
  ```

  ![](http://typora-image.test.upcdn.net/images/Spark-Web-UI.jpg)

###### 2. 命令行工具

- 在解压缩的目录下的data目录下，添加words.txt文件。在命令行工具中执行如下代码

  ```
  sc.textFile("data/words.txt").flatMap(_.split(" ")).map((_,1)).reduceByKey(_+_).collect
  ```

  ![](http://typora-image.test.upcdn.net/images/wordcount.jpg)

###### 3. 退出本地模式

```
:quit
```

###### 4. 提交应用

```
bin/spark-submit \
--class org.apache.spark.examples.SparkPi \
--master local[2] \ 
./examples/jars/spark-examples_2.11-2.4.6.jar \
10
```

- --class 表示要执行程序的主类
- --master local[2] 部署模式，默认为本地模式，数字表示分配的虚拟CPU核数量
- spark-examples_2.11-2.4.6.jar 运行的应用类所在的jar包
- 数字10表示程序的入口参数，用于设定当前应用的任务数量

![](http://typora-image.test.upcdn.net/images/spark-shell-pi.jpg)