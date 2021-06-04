#### Hadoop集群搭建之全分布式集群搭建

##### 1. 准备工作

准备三台已经安装了CentOS7系统的虚拟机，并进行了相关设置。

系统配置可以参考[Hadoop集群搭建之CentOS7系统配置](https://github.com/yangqi199808/BigData-Home/blob/master/Hadoop/1.Hadoop集群搭建之CentOS7系统配置.md)这篇文章。

##### 2. 集群规划

| 主机名称 |     IP地址     |  用户  |            HDFS             |             YARN             |
| :------: | :------------: | :----: | :-------------------------: | :--------------------------: |
|  master  | 192.168.21.210 | hadoop |     NameNode，DataNode      | ResourceManager，NodeManager |
|  slave1  | 192.168.21.211 | hadoop | DataNode，SecondaryNameNode |         NodeManager          |
|  slave2  | 192.168.21.212 | hadoop |          DataNode           |         NodeManager          |

##### 3. Hadoop安装

###### 1. 安装目录规划

```
统一安装路径：/opt/apps
统一软件存放路径：/opt/software
```

###### 2. 上传压缩包

```
1. 将压缩包上传到[/opt/software]目录下，解压到[/opt/apps]目录下
2. 修改[/home/hadoop/.bash_profile]文件，增加以下内容：
	HADOOP_HOME=/opt/apps/hadoop-2.7.7
	PATH=$HADOOP_HOME/bin:$HADOOP_HOME/sbin:$PATH
	export HADOOP_HOME PATH
3. 使用[source ~/.bash_profile使其生效
```

###### 3. 集群配置

配置文件目录：【/opt/apps/hadoop-2.7.7/etc/hadoop/】

- hadoop-env.sh

  ```
  修改第25行JAVA_HOME的路径为[/opt/apps/jdk1.8.0_162]
  ```

- yarn-env.sh

  ```
  修改第23行JAVA_HOME的路径为[/opt/apps/jdk1.8.0_162]（记得取消注释）
  ```

- core-site.xml

  ```xml
  <configuration>
      <property>
          <name>hadoop.tmp.dir</name>
          <value>/opt/apps/hadoop-2.7.7/tmp</value>
      </property>
      <property>
          <name>fs.defaultFS</name>
          <value>hdfs://master:8020</value>
      </property>
  </configuration>
  ```

- hdfs-site.xml

  ```xml
  <configuration>
      <property>
          <name>dfs.replication</name>
          <value>3</value>
      </property>
      <property>
          <name>dfs.blocksize</name>
          <value>134217728</value>
      </property>
      <property>
          <name>dfs.namenode.secondary.http-address</name>
          <value>slave1:50090</value>
      </property>
      <property>
          <name>dfs.namenode.name.dir</name>
          <value>/opt/apps/hadoop-2.7.7/tmp/namenode</value>
      </property>
      <property>
        	<name>dfs.datanode.data.dir</name>
        	<value>/opt/apps/hadoop-2.7.7/tmp/datanode</value>
      </property>
  </configuration>
  ```

- mapred-site.xml

  需要将`mapred-site.xml.template`复制一份为`mapred-site.xml`

  ```xml
  <configuration>
      <property>
          <name>mapreduce.framework.name</name>
          <value>yarn</value>
      </property>
      <property>
          <name>mapreduce.jobhistory.address</name>
          <value>master:10020</value>
      </property>
      <property>
          <name>mapreduce.jobhistory.weapp.address</name>
          <value>master:19888</value>
      </property>
  </configuration>
  ```

- yarn-site.xml

  ```xml
  <configuration>
      <property>
          <name>yarn.resourcemanager.hostname</name>
      	<value>master</value>
      </property>
      <property>
          <name>yarn.nodemanager.aux-services</name>
          <value>mapreduce_shuffle</value>
      </property>
      <property>
          <name>yarn.log-aggregation-enable</name>
          <value>true</value>
      </property>
      <property>
  		<name>yarn.log.server.url</name>
      	<value>http://master:19888/jobhistory/logs</value>
  	</property>
  </configuration>
  ```

- slaves

  ```
  master
  slave1
  slave2
  ```


使用[scp -r /opt/appshadoop-2.7.7 username@hostname:/opt/apps]命令将hadoop发送到三台服务器中

##### 4. Hadoop集群测试

###### 1. 集群格式化

使用[hadoop namenode -format]命令对集群进行格式化，格式化后会产生集群ID，块池ID等相关信息。

![](http://typora-image.test.upcdn.net/images/20200809154838.jpg)

###### 2. 启动集群

```
官方建议使用[start-dfs.sh]和[start-yarn.sh]分别启动hdfs和yarn集群，当然也可以使用[start-all.sh]启动集群
```

###### 3. 集群测试

```
1. 访问[192.168.21.210:50070]查看HDFS集群WebUI
2. 访问[192.168.21.210:8088]查看YARN集群WebUI
```

##### 5. Hadoop高可用集群

###### 1. 集群规划

| 主机名称 |     IP地址     |  用户  |              HDFS               |             YARN             |       ZK       |          ZKFC           |
| :------: | :------------: | :----: | :-----------------------------: | :--------------------------: | :------------: | :---------------------: |
|  master  | 192.168.21.210 | hadoop | NameNode，DataNode，JournalNode | ResourceManager，NodeManager | QuorumPeerMain | DFSZKFailoverController |
|  slave1  | 192.168.21.211 | hadoop | Namenode，DataNode，JournalNode | ResourceManager，NodeManager | QuorumPeerMain | DFSZKFailoverController |
|  slave2  | 192.168.21.212 | hadoop |      DataNode，JournalNode      |         NodeManager          | QuorumPeerMain |                         |

###### 2. Zookeeper安装

由于安装高可用集群需要Zookeeper的支持，所以我们先要安装Zookeeper集群

+ 上传压缩包并配置环境变量

  ```
  ZOOKEEPER_HOME=/opt/apps/zookeeper-3.6.1
  PATH=$ZOOKEEPER_HOME/bin:$PATH
  export ZOOKEEPER_HOME PATH
  ```

+ 修改zookeeper相关配置文件

  + zoo.cfg

    由于[conf]目录下只有[zoo_sample.cfg]，所以需要复制一份重命名为[zoo.cfg]

    ```properties
    # The number of milliseconds of each tick
    tickTime=2000
    # The number of ticks that the initial
    # synchronization phase can take
    initLimit=10
    # The number of ticks that can pass between
    # sending a request and getting an acknowledgement
    syncLimit=5
    # the directory where the snapshot is stored.
    # do not use /tmp for storage, /tmp here is just
    # example sakes.
    dataDir=/opt/apps/zookeeper-3.6.1/data
    # the port at which the clients will connect
    clientPort=2181
    # the maximum number of client connections.
    # increase this if you need to handle more clients
    #maxClientCnxns=60
    #
    # Be sure to read the maintenance section of the
    # administrator guide before turning on autopurge.
    #
    # http://zookeeper.apache.org/doc/current/zookeeperAdmin.html#sc_maintenance
    #
    # The number of snapshots to retain in dataDir
    #autopurge.snapRetainCount=3
    # Purge task interval in hours
    # Set to "0" to disable auto purge feature
    #autopurge.purgeInterval=1
    
    ## Metrics Providers
    #
    # https://prometheus.io Metrics Exporter
    #metricsProvider.className=org.apache.zookeeper.metrics.prometheus.PrometheusMetricsProvider
    #metricsProvider.httpPort=7000
    #metricsProvider.exportJvmInfo=true
    
    server.1=master:2888:3888
    server.2=slave1:2888:3888
    server.3=slave2:2888:3888
    ```

  + myid

    新建一个目录[data]，在data中新建一个文件[myid]，写上刚才IP地址所对应的[server.id]中的[id]值。（192.168.21.210填写1，其余的自行修改）

    ```
    1
    ```

+ 分发到三台服务器，并修改[myid]内容

+ 使用命令[zkServer.sh start]启动三台服务器中的zookeeper，如果出现进程名为[QuorumPeerMain]的进程表示zookeeper启动成功

###### 3. HA集群配置

配置文件目录：【/opt/apps/hadoop-2.7.7/etc/hadoop/】

- hadoop-env.sh

  ```
  修改第25行JAVA_HOME的路径为[/opt/apps/jdk1.8.0_162]
  ```

- yarn-env.sh

  ```
  修改第23行JAVA_HOME的路径为[/opt/apps/jdk1.8.0_162]（记得取消注释）
  ```


+ core-site.xml

  ```xml
  <configuration>
      <property>
          <name>hadoop.tmp.dir</name>
          <value>/opt/apps/hadoop-2.7.7/tmp</value>
      </property>
      <property>
          <name>fs.defaultFS</name>
          <value>hdfs://supercluster</value>
      </property>
      <property>
          <name>ha.zookeeper.quorum</name>
          <value>master:2181,slave1:2181,slave2:2181</value>
      </property>
  </configuration>
  ```

+ hdfs-site.xml

  ```xml
  <configuration>
      <property>
          <name>dfs.replication</name>
          <value>3</value>
      </property>
      <property>
          <name>dfs.blocksize</name>
          <value>134217728</value>
      </property>
      <property>
          <name>dfs.nameservices</name>
          <value>supercluster</value>
      </property>
      <property>
          <name>dfs.ha.namenodes.supercluster</name>
          <value>nn1,nn2</value>
      </property>
      <property>
          <name>dfs.namenode.rpc-address.supercluster.nn1</name>
          <value>master:8020</value>
      </property>
      <property>
          <name>dfs.namenode.rpc-address.supercluster.nn2</name>
          <value>slave1:8020</value>
      </property>
      <property>
          <name>dfs.namenode.http-address.supercluster.nn1</name>
          <value>master:50070</value>
      </property>
      <property>
          <name>dfs.namenode.http-address.supercluster.nn2</name>
          <value>slave1:50070</value>
      </property>
      <property>
          <name>dfs.namenode.shared.edits.dir</name>
          <value>qjournal://master:8485;slave1:8485;slave2:8485/supercluster</value>
      </property>
      <property>
          <name>dfs.journalnode.edits.dir</name>
          <value>/opt/apps/hadoop-2.7.7/tmp/journaldata</value>
      </property>
      <property>
          <name>dfs.namenode.name.dir</name>
          <value>/opt/apps/hadoop-2.7.7/tmp/namenode</value>
      </property>
      <property>
        	<name>dfs.datanode.data.dir</name>
        	<value>/opt/apps/hadoop-2.7.7/tmp/datanode</value>
      </property>
      <property>
          <name>dfs.ha.automatic-failover.enabled</name>
          <value>true</value>
      </property>
      <property>
          <name>dfs.client.failover.proxy.provider.supercluster</name>
          <value>org.apache.hadoop.hdfs.server.namenode.ha.ConfiguredFailoverProxyProvider</value>
      </property>
      <property>
          <name>dfs.ha.fencing.methods</name>
          <value>sshfence</value>
      </property>
      <property>
          <name>dfs.ha.fencing.ssh.private-key-files</name>
          <value>/home/hadoop/.ssh/id_rsa</value>
      </property>
      <property>
          <name>dfs.ha.fencing.ssh.connect-timeout</name>
          <value>30000</value>
      </property>
  </configuration>
  ```
  
+ mapred-site.xml

  ```xml
  <configuration>
      <property>
          <name>mapreduce.framework.name</name>
          <value>yarn</value>
      </property>
      <property>
          <name>mapreduce.jobhistory.address</name>
          <value>master:10020</value>
      </property>
      <property>
          <name>mapreduce.jobhistory.weapp.address</name>
          <value>master:19888</value>
      </property>
  </configuration>
  ```

+ yarn-site.xml

  ```xml
  <configuration>
      <property>
          <name>yarn.resourcemanager.ha.enabled</name>
      	<value>true</value>
      </property>
      <property>
          <name>yarn.resourcemanager.cluster-id</name>
          <value>yarncluster</value>
      </property>
      <property>
          <name>yarn.resourcemanager.ha.rm-ids</name>
          <value>rm1,rm2</value>
      </property>
      <property>
          <name>yarn.resourcemanager.hostname.rm1</name>
          <value>master</value>
      </property>
      <property>
          <name>yarn.resourcemanager.hostname.rm2</name>
          <value>slave1</value>
      </property>
      <property>
          <name>yarn.resourcemanager.zk-address</name>
          <value>master:2181,slave1:2181,slave2:2181</value>
      </property>
      <property>
          <name>yarn.nodemanager.aux-services</name>
          <value>mapreduce_shuffle</value>
      </property>
      <property>
          <name>yarn.log-aggregation-enable</name>
          <value>true</value>
      </property>
      <property>
  		<name>yarn.log.server.url</name>
      	<value>http://master:19888/jobhistory/logs</value>
  	</property>
  </configuration>
  ```

###### 4. 启动HA集群

+ 首先停止原有集群，启动[journalnode]（三台都要启动）

  ```shell
  [hadoop@master ~]$ hadoop-daemon.sh start journalnode
  [hadoop@slave1 ~]$ hadoop-daemon.sh start journalnode
  [hadoop@slave2 ~]$ hadoop-daemon.sh start journalnode
  ```

+ 启动原有节点上的[namenode]

  ```shell
  [hadoop@master ~]$ hadoop-daemon.sh start namenode
  ```

+ 在新的[namenode]上拉取集群镜像文件

  ```shell
  [hadoop@slave1 ~]$ hdfs namenode -bootstrapStandby
  ```

+ 停止原有集群的[namenode]，同步数据到[journalnode]

  ```shell
  [hadoop@master ~]$ hadoop-daemon.sh stop namenode
  [hadoop@master ~]$ hdfs namenode -initializeSharedEdits
  ```

+ 格式化ZKFC集群

  ```shell
  [hadoop@master ~]$ hdfs zkfc -formatZK
  ```

+ 启动HA集群

  ```shell
  [hadoop@master ~]$ start-dfs.sh
  [hadoop@master ~]$ start-yarn.sh
  ```

+ 手动启动[slave1]上的[resourcemanager]

  ```shell
  [hadoop@slave1 ~]$ yarn-daemon.sh start resourcemanager
  ```

###### 5. 测试HA集群自动容灾

直接[kill]掉为[active]的[namenode]，如果状态为[standby]的[namenode]切换为[active]，说明自动容灾成功

##### 6. Yarn历史服务器

【yarn】历史服务器配置属性：

- mapred-site.xml

  ```xml
  <property>
      <name>mapreduce.jobhistory.address</name>
      <value>master:10020</value>
  </property>
  <property>
      <name>mapreduce.jobhistory.weapp.address</name>
      <value>master:19888</value>
  </property>
  ```

- yarn-site.xml

  ```xml
  <property>
      <name>yarn.log-aggregation-enable</name>
      <value>true</value>
  </property>
  <property>
  	<name>yarn.log.server.url</name>
      <value>http://master:19888/jobhistory/logs</value>
  </property>
  ```

上述配置都已经配合了【yarn】历史服务器的相关配置，如果需要启动可以使用：

```shell
[hadoop@master ~]$ mr-jobhistory-daemon.sh start historyserver
```

