#### Hadoop集群搭建之HBase安装

##### 1. 准备工作

准备好已经安装了Hadoop的集群服务器之后，下载HBase的安装包并上传至其中一台服务器中。

##### 2. HBase独立模式安装

###### 1. 安装目录规划

```
统一安装路径：/opt/apps
统一软件存放路径：/opt/software
```

###### 2. 上传压缩包

```
1. 将压缩包上传到[/opt/software]目录下，解压到[/opt/apps]目录下
2. 修改[/home/hadoop/.bash_profile]文件，增加以下内容：
	HBASE_HOME=/opt/apps/hbase-1.5.0
	PATH=$HBASE_HOME/bin:$PATH
	export HBASE_HOME PATH
3. 使用[source ~/.bash_profile]使其生效
```

###### 3. HBase配置

配置文件目录：【/opt/apps/hbase-1.5.0/conf/】

- hbase-env.sh

  ```
  修改第26行JAVA_HOME的路径为[/opt/apps/jdk1.8.0_162]
  修改第128行HBASE_MANAGES_ZK=true
  ```

- hbase-site.xml

  ```xml
  <configuration>
      <property>
          <name>hbase.rootdir</name>
          <value>file:///opt/apps/hbase-1.5.0/data</value>
      </property>
      <property>
          <name>hbase.zookeeper.property.dataDir</name>
          <value>/opt/apps/hbase-1.5.0/zookeeper</value>
      </property>
  </configuration>
  ```

###### 5. 启动HBase守护进程

```shell
# 启动HBase
[hadoop@master ~]$ start-hbase.sh
```

###### 6. 测试本地安装

``` shell
# 连接HBase
[hadoop@master ~]$ hbase shell
```

##### 3. HBase伪分布式安装

HBase配置：配置文件目录：【/opt/apps/hbase-1.5.0/conf/】

- hbase-env.sh

  ```
  修改第26行JAVA_HOME的路径为[/opt/apps/jdk1.8.0_162]
  修改第128行HBASE_MANAGES_ZK=false
  ```

- hbase-site.xml

  ```xml
  <configuration>
      <property>
           <name>hbase.rootdir</name>
           <value>hdfs://supercluster/hbase</value>
      </property>
      <property>
              <name>hbase.zookeeper.quorum</name>
              <value>master:2181,slave1:2181,slave2:2181</value>
      </property>
      <property>
           <name>hbase.cluster.distributed</name>
           <value>true</value>
      </property>
      <property>
          <name>hbase.unsafe.stream.capability.enforce</name>
          <value>true</value>
      </property>
  </configuration>
  ```
  
- 启动HBase服务

  ```shell
  # 首先启动zookeeper服务
  [hadoop@master ~]$ zkServer.sh start
  [hadoop@slave1 ~]$ zkServer.sh start
  [hadoop@slave2 ~]$ zkServer.sh start
  
  # 启动HMaster进程(可以同时启动backup-master
  # 2 3 5 是偏移量，启动在不同的端口
  [hadoop@master ~]$ local-master-backup.sh start 2 3 5
  # 停止HMaster
  [hadoop@master ~]$ local-master-backup.sh stop 2 3 5
  
  # 启动RegionServer
  [hadoop@master ~]$ local-regionservers.sh start 2 3 5
  # 停止RegionServer
  [hadoop@master ~]$ local-regionservers.sh stop 2 3 5
  ```

##### 4. HBase全分布式安装

###### 1. HBase进程规划

| 主机名称 |     IP地址     |  用户  |             HBase             |   Zookeeper    |
| :------: | :------------: | :----: | :---------------------------: | :------------: |
|  master  | 192.168.21.210 | hadoop |    HMaster，HRegionServer     | QuorumPeerMain |
|  slave1  | 192.168.21.211 | hadoop | Backer HMaster，HRegionServer | QuorumPeerMain |
|  slave2  | 192.168.21.212 | hadoop |         HRegionServer         | QuorumPeerMain |

###### 2. HBase配置

配置文件目录：【/opt/apps/hbase-1.5.0/conf/】

- hbase-env.sh

  ```
  修改第26行JAVA_HOME的路径为[/opt/apps/jdk1.8.0_162]
  修改第128行HBASE_MANAGES_ZK=false
  ```

- hbase-site.xml

  ```xml
  <configuration>
      <property>
          <name>hbase.rootdir</name>
          <value>hdfs://supercluster/hbase</value>
      </property>
      <property>
          <name>hbase.cluster.distributed</name>
          <value>true</value>
      </property>
      <property>
          <name>hbase.unsafe.stream.capability.enforce</name>
          <value>true</value>
      </property>
      <property>
          <name>hbase.zookeeper.quorum</name>
          <value>master:2181,slave1:2181,slave2:2181</value>
      </property>
      <property>
          <name>hbase.zookeeper.property.dataDir</name>
          <value>/opt/apps/zookeeper-3.6.1/hbase</value>
      </property>
  </configuration>
  ```

- 配置regionserver的节点信息

  ```shell
  [hadoop@master ~]$ vi /opt/apps/hbase-1.5.0/conf/regionservers
  # 添加如下内容
  master
  slave1
  slave2
  ```

- 配置backup-hmaster，需要创建backup-masters文件

  ```shell
  [hadoop@master ~]$ echo "slave1" >> /opt/apps/hbase-1.5.0/conf/backup-masters
  ```

- 将HBase安装包发送至其他节点，并配置环境变量

  ```shell
  [hadoop@master ~]$ scp /opt/apps/hbase-1.5.0/ slave1:/opt/apps/
  [hadoop@master ~]$ scp /opt/apps/hbase-1.5.0/ slave2:/opt/apps/
  ```

###### 3. 启动集群并测试

```shell
[hadoop@master ~]$ start-hbase.sh
```

###### 4. 查看WebUI页面

```
http://ip:16010
```

##### 5. 其它问题

###### 1. Hadoop是HA的情况

```
将Hadoop目录下的hdfs-site.xml和core-site.xml复制到HBase目录的conf目录下，重新启动
```

###### 2. JDK版本大于1.7

```
如果使用的JDK版本大于1.7，可以将hbase-env.sh中的第36和37行注释掉
```

