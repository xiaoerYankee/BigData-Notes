#### Flink运行环境_Standalone

只使用Flink自身节点运行的集群模式，也就是我们所谓的（Standalone）模式，也叫做独立集群模式。

##### 1. Flink独立集群部署

###### 1. 解压缩文件

将flink-1.12.2文件上传到指定目录并解压。

###### 2. 修改配置文件

- 进入解压缩的路径的conf目录，修改flink-conf.yaml

  ```
  jobmanager.rpc.address: hadoop01
  ```

- 修改works文件，添加work节点

  ```
  hadoop01
  hadoop02
  hadoop03
  ```

- 将flink分发到集群的每台机器中

  ```
  scp flink-1.12.2 hadoop02:/opt/apps/
  scp flink-1.12.2 hadoop03:/opt/apps/
  ```

###### 3. 启动集群

- 启动集群

  ```
  bin/start-cluster.sh
  ```

- 查看Web UI界面

  ![](http://typora-image.test.upcdn.net/images/standalone-web.png)

##### 2. Flink独立高可用集群部署

###### 1. 解压缩文件

将flink-1.12.2文件上传到指定目录并解压。

###### 2. 修改配置文件

- 进入解压缩的路径的conf目录，修改flink-conf.yaml

  ```
  jobmanager.rpc.address: hadoop01
  # 每个task可用的slot
  taskmanager.numberOfTaskSlots: 3
  
  high-availability: zookeeper
  high-availability.storageDir: hdfs://supercluster/flink/standalone/ha/
  high-availability.zookeeper.quorum: hadoop01:2181,hadoop02:2181,hadoop03:2181
  high-availability.zookeeper.path.root: /flink-standalone
  high-availability.cluster-id: /flink-standalone-ha
  ```

- 修改works文件，添加work节点

  ```
  hadoop01
  hadoop02
  hadoop03
  ```

- 修改masters文件，添加高可用

  ```
  hadoop01:8081
  hadoop02:8082
  ```

- 将flink分发到集群的每台机器中

  ```
  scp flink-1.12.2 hadoop02:/opt/apps/
  scp flink-1.12.2 hadoop03:/opt/apps/
  ```

- 修改每台机器的环境变量

  ```
  export HADOOP_CLASSPATH=`hadoop classpath`
  ```

###### 3. 启动集群

- 启动zookeeper和HDFS集群

- 启动Flink集群

  ```
  bin/start-cluster.sh
  ```

- 使用zkCli查看谁是leader·

  ```
  get /flink-standalone/flink-standalone-ha/leader/rest_server_lock
  ```

  ![](http://typora-image.test.upcdn.net/images/standalone-hbleader.png)

- 查看Web UI界面

  从Web UI上无法区分谁是leader，都可以提交作业。

  ![](http://typora-image.test.upcdn.net/images/standalone-web.png)

##### 3. 提交作业

```
bin/flink run \
-d \
-m hadoop02:8081 \
-c com.yankee.day01.Flink03_WordCount_UnBounded_Java wordcount.jar
```

![](http://typora-image.test.upcdn.net/images/standalone-submit.png)

##### 4. Web UI查看作业

![](http://typora-image.test.upcdn.net/images/standalone-webui.png)