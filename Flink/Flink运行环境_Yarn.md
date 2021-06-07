#### Flink运行环境_Yarn

独立部署（Standalone）模式是由Flink框架本身提供计算资源，无需其他框架提供资源。这种方式降低了和其他第三方资源框架的耦合性，独立性非常强。但是由于Flink主要是计算框架，而不是资源调度框架，所以本身资源调度并不是它的强项。

把Flink应用提交给Yarn的ResourceManager，Yarn的ResourceManager会申请容器从Yarn的NodeManager上面，Flink会创建JobManager和TaskManager在这些容器上面，Flink会根据运行在JobManager上的job的需要的slot数量动态分配TaskManager资源。

##### 1. 解压缩文件

将flink-1.12.2.tgz文件上传到集群并解压缩，放置在指定位置。

##### 2. 配置环境变量

```shell
export HADOOP_CLASSPATH=`hadoop classpath`
```

##### 3. 修改配置文件

如果需要每一个taskManager有更多的slot可用，需要修改flink-conf.yaml文件

```
taskmanager.numberOfTaskSlots: 3
```

##### 4. 启动hdfs和yarn集群

```
sbin/start-dfs.sh
sbin/start-yarn.sh
```

##### 5. 提交作业

```
bin/flink run \
-m yarn-cluster \
-yqu flink-xiaoer \
-d \
-c com.yankee.day01.Flink03_WordCount_UnBounded_Java wordcount.jar
```

- -m：yarn提交模式
- -yqu：表示yarn的执行队列
- -d：提交作业后关闭客户端
- -c：作业的主类以及jar包

![](http://typora-image.test.upcdn.net/images/yarn-cluster-submit.png)

##### 6. Yarn Web页面

![](http://typora-image.test.upcdn.net/images/yarn-cluster-web.png)

##### 7. Flink on Yarn的三种部署模式

Flink提供了yarn上运行的三种模式，分别为Session-Cluster，Application Mode和Per-Job-Cluster模式。

###### 1. Session-Cluster

Session-Cluster模式需要先启动Flink集群，向yarn申请资源，资源申请到以后，永远保持不变。以后提交任务都向这里提交，这个Flink集群会常驻在yarn集群中，除非手工停止。

向Flink集群提交Job的时候，如果资源被用完了，则新的Job不能正常提交。

缺点：如果提交的作业中有长时间执行的大作业，占用了该Flink集群的所有的资源，则后续无法继续提交新的Job。

Session-Cluster适合那些需要频繁提交的多个小Job，并且执行时间都不长。

```
bin/flink run \
-t yarn-session \
-Dyarn.application.id=application_xxx_yy \
-Dyarn.application.queue=flink-xiaoer \
-d \
-c com.yankee.day01.Flink03_WordCount_UnBounded_Java wordcount.jar
```

- -t：yarn运行模式，可以指定yarn-session，也可以不指定，自动提交到yarn-session
- -Dyarn.application.id：指定yarn-session，和-t同时出现
- -Dyarn.application.queue：指定作业运行的yarn的队列
- -d：提交作业后退出客户端
- -c：指定作业运行的主类和jar包

###### 2. Per-Job-Cluster

一个Job会对应一个Flink集群，每提交一个作业会根据自身的情况，都会单独向yarn申请资源，直到作业执行完成，一个作业的失败并不会影响下一个作业的正常提交和执行。独享Dispatcher和ResourceManager，按需接受资源申请，适合大规模长时间运行的作业。

每次提交作业都会创建一个新的Flink集群，任务之间互相独立，互不影响，方便管理。在任务执行完成之后创建的集群也会消失。

```
bin/flink run \
-t yarn-per-job \
-Dyarn.application.queue=flink-xiaoer \
-d \
-c com.yankee.day01.Flink03_WordCount_UnBounded_Java wordcount.jar
```

```
bin/flink run \
-m yarn-cluster \
-yqu flink-xiaoer \
-d \
-c com.yankee.day01.Flink03_WordCount_UnBounded_Java wordcount.jar
```

###### 3. Application Mode

Application Mode会在Yarn上启动集群，应用jar包的main函数将会在JobManager上执行，只要应用程序执行结束，Flink集群会马上被关闭，也可以手动停止集群。

```
bin/flink run-application \
-t yarn-application \
-Dyarn.application.queue=flink-xiaoer \
-d \
-c com.yankee.day01.Flink03_WordCount_UnBounded_Java wordcount.jar
```

###### 4. Per-Job-Cluster和Application Mode的区别

```
Per-Job-Cluster模式的main方法在客户端执行，Application Mode中的main方法在JobManager中执行，也就是说Application Mode模式将main方法提交到了集群执行。通过在JobManager中执行程序的main方法，Application模式可以节省很多提交应用所需的资源。
```

##### 8. Yarn模式高可用

Yarn模式的高可用和Standalone的高可用原理不一样。Standalone模式中，同时启动多个JobManager，一个为leader，其他的是standby，当leader挂了，其他的一个才会成为leader。yarn的高可用是同时只启动一个JobManager，当这个JobManager挂了之后，yarn会再次启动一个，其实是利用yarn的重试次数来实现的高可用。

###### 1. 修改yarn-site.xml配置文件

```xml
<property>
    <name>yarn.resourcemanager.am.max-attempts</name>
    <value>4</value>
</property>
```

###### 2. 修改flink-conf.yaml配置文件

```
# 这个配置要小于等于yarn-site中的配置
yarn.application-attempts: 3

high-availability: zookeeper
high-availability.storageDir: hdfs://supercluster/flink/yarn/ha/
high-availability.zookeeper.quorum: hadoop01:2181,hadoop02:2181,hadoop03:2181
high-availability.zookeeper.path.root: /flink-yarn
high-availability.cluster-id: /flink-yanr-ha
```

