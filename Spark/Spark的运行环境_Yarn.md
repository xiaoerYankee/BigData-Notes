#### Spark的运行环境_Yarn

独立部署（Standalone）模式由Spark自身提供计算资源，无需其它框架提供资源。这种方式降低了和其它第三方资源框架的耦合性，独立性非常强。但是由于Spark本身是计算框架，所以本身提供的资源调度并不是它的强项。

##### 1. 解压缩文件

将spark-2.4.6.tgz文件上传到CentOS并解压缩，放置在指定位置。

##### 2. 修改配置文件

- 修改hadoop配置文件/opt/app/hadoop-2.7.7/etc/hadoop/yarn-site.xml，并分发

  ```xml
   <!-- 是否启动一个线程检查每个任务正使用的物理内存量，如果任务超出分配值，则直接将其杀掉，默认是true -->
  <property>
      <name>yarn.nodemanager.pmem-check-enabled</name>
      <value>false</value>
  </property>
  <!-- 是否启动一个线程检查每个任务正使用的虚拟内存量，如果任务超出分配值，则直接将其杀掉，默认是true -->
  <property>
      <name>yarn.nodemanager.vmem-check-enabled</name>
      <value>false</value>
  </property>
  ```

- 修改conf/spark-env.sh，添加JAVA_HOME和YARN_CONF_DIR配置

  ```
  export JAVA_HOME=/opt/apps/jdk1.8.0_162
  YARN_CONF_DIR=/opt/apps/hadoop-2.7.7/etc/hadoop
  ```

##### 3. 启动HDFS以及YARN集群

```
sbin/start-dfs.sh
sbin/start-yarn.sh
```

##### 4. 提交应用

```
bin/spark-submit \
--class org.apache.spark.examples.SparkPi \
--master yarn \
--deploy-mode cluster \
./examples/jars/spark-examples_2.11-2.4.6.jar \
10
```

![](http://typora-image.test.upcdn.net/images/yarn-submit.jpg)

查看http://master:8088页面，点击History，查看历史页面

![](http://typora-image.test.upcdn.net/images/yarn-history.jpg)

##### 5. 配置历史服务器

- 修改spark-defaults.conf.template文件名为spark-defaults.conf

  ```
  mv spark-defaults.conf.template spark-defaults.conf
  ```

- 修改spark-defalult.conf文件，配置日志存储路径

  ```
  spark.eventLog.enabled	true
  spark.eventLog.dir		hdfs://master:8020/history
  ```

  注意：需要启动hadoop集群，HDFS上的directory目录需要提前存在

  ```
  sbin/start-dfs.sh
  hadoop fs -mkdir /history
  ```

- 修改spark-env.sh文件，添加日志配置

  ```
  export SPARK_HISTORY_OPTS="-Dspark.history.ui.port=18080 -Dspark.history.fs.logDirectory=hdfs://master:8020/history -Dspark.history.retainedApplication=30"
  ```

  - 参数1含义：WEB UI访问的端口号18080
  - 参数2含义：指定历史服务器日志存储路径
  - 参数3含义：指定保存Application历史记录的个数，如果超过这个值，旧的应用程序信息将被删除，这个是内存中的应用数，而不是页面上显示的应用数。

- 修改spark-defaults.conf

  ```
  spark.yarn.historyServer.address=master:18080
  spark.history.ui.port=18080
  ```

- 分发配置文件

  ```
  scp conf slave1:/opt/apps/spark-2.4.6/
  scp conf slave2:/opt/apps/spark-2.4.6/
  ```

- 重新启动集群和历史服务

  ```
  sbin/start-all.sh
  sbin/start-history-server.sh
  ```

- 重新执行任务

  ```
  bin/spark-submit \
  --class org.apache.spark.examples.SparkPi \
  --master yarn \
  --deploy-mode client \
  ./examples/jars/spark-examples_2.11-2.4.6.jar \
  10
  ```

  ![](http://typora-image.test.upcdn.net/images/yarn-client.jpg)

- 查看历史服务：http://master:18080

  ![](http://typora-image.test.upcdn.net/images/yarn-history-spark.jpg)

##### 6. Yarn Client和Yarn Cluster

这两种模式本质的区别在于AM（Application Master）进程的区别。

- Cluster：Cluster模式下，Spark Driver运行在AM中，负责向Yarn(RM)申请资源，并监督Application的运行情况。当Client提交作业后，就会关闭Client，作业会继续在Yarn上运行，这也是Cluster模式不适合交互类型作业的原因。
- Client：AM不仅仅向Yarn(RM)申请资源，之后Client会和请求的Container通信来完成任务的调度，即Client不能被关闭。

一般情况下，先在Client模式下调通任务，之后提交到Cluster上进行运行。