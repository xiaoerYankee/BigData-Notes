#### Hadoop集群搭建之Hive安装

##### 1. 准备工作

准备好已经安装了Hadoop的集群服务器之后，需要在其中一台中安装MySQL数据库，安装可以参考[CentOS7安装MySQL5.7](https://github.com/yangqi199808/BigData-Home/blob/master/CentOS/1.CentOS7安装MySQL5.7.md)这篇文章。

下载Hive的安装包并上传至其中一台服务器中。

##### 2. Hive本地安装

###### 1. 安装目录规划

```
统一安装路径：/opt/apps
统一软件存放路径：/opt/software
```

###### 2. 上传压缩包

```
1. 将压缩包上传到[/opt/software]目录下，解压到[/opt/apps]目录下
2. 修改[/home/hadoop/.bash_profile]文件，增加以下内容：
	HIVE_HOME=/opt/apps/hive-2.3.7
	PATH=$HIVE_HOME/bin:$PATH
	export HIVE_HOME PATH
3. 使用[source ~/.bash_profile]使其生效
```

###### 3. 上传MySQL的JAR包

```
将mysql的jar包上传至/opt/apps/hive-2.3.7/lib目录下(注意和自己的mysql相匹配，如果使用mysql8，记得上传mysql8的jar包)
```

###### 4. Hive配置

配置文件目录：【/opt/apps/hive-2.3.7/conf/】

- hive-env.sh

  需要将`hive-env.sh.template`复制一份为`hive-env.sh`

  ```
  修改第48行HADOOP_HOME的路径为[/opt/apps/hadoop-2.7.7]
  修改第51行HIVE_CONF_DIR的路径为[/opt/apps/hive-2.3.7/conf]
  修改第54行HIVE_AUX_JARS_PATH的路径为[/opt/apps/hive-2.3.7/lib]
  ```

- hive-site.sh

  需要将`hive-default.xml.template`复制一份为`hive-site.xml`，并删除其配置相关内容

  ```xml
  <configuration>
      <property>
      	<name>javax.jdo.option.ConnectionURL</name>
        <value>jdbc:mysql://master:3306/hive?createDatabaseIfNotExist=true&amp;characterEncoding=latin1</value>
      </property>
      <property>
      	<name>javax.jdo.option.ConnectionDriverName</name>
          <value>com.mysql.jdbc.Driver</value>
      </property>
      <property>
      	<name>javax.jdo.option.ConnectionUserName</name>
          <value>yangqi</value>
      </property>
      <property>
      	<name>javax.jdo.option.ConnectionPassword</name>
          <value>xiaoer</value>
      </property>
  </configuration>
  ```
  

###### 5. 初始化MySQL元数据库

```shell
# 使用命令初始化MySQL元数据库
[hadoop@master ~]$ schematool -dbType mysql -initSchema
```

###### 6. 测试本地安装

``` shell
# 直接使用hive启动，hive会主动维护一个metastore服务
[hadoop@master ~]$ hive
# 之后可以测试一个最简单的命令，如果可以显示default库，说明安装成功
hive> show databases;
```

##### 3. Hive远程安装

Hive远程安装是指需要手动维护一个metastore服务或者hiveserver2服务，之后可以在任何一个客户端机器上访问该服务，连接Hive。

###### 1. Hive服务端配置

- hive-site.xml

  ```xml
  <configuration>
      <property>
      	<name>hive.metastore.warehouse.dir</name>
      	<value>/user/hive/warehouse</value>
      </property>
      <property>
      	<name>javax.jdo.option.ConnectionURL</name>
          <value>jdbc:mysql://master:3306/hive?createDatabaseIfNotExist=true&amp;characterEncoding=latin1</value>
      </property>
      <property>
      	<name>javax.jdo.option.ConnectionDriverName</name>
          <value>com.mysql.jdbc.Driver</value>
      </property>
      <property>
      	<name>javax.jdo.option.ConnectionUserName</name>
          <value>yangqi</value>
      </property>
      <property>
      	<name>javax.jdo.option.ConnectionPassword</name>
          <value>xiaoer</value>
      </property>
  </configuration>
  ```

- hive服务

  ```shell
  # 第一种：可以启动hiveserver2服务，如果启动hiveserver2服务，那么客户只能使用beeline工具连接
  # 监听状态不退出
  [hadoop@master ~]$ hiveserver2
  # 后台启动
  [hadoop@master ~]$ hive --service hiveserver2 &
  # 后台启动，日志信息送入黑洞
  [hadoop@master ~]$ hive --service hiveserver2 2>&1 >/dev/null &
  
  # 第二种：可以启动metastore服务
  [hadoop@master ~]$ hive --service metastore 2>&1 >/dev/null &
  ```

###### 2. hive客户端配置

将下载好的Hive安装包解压到[/opt/apps]目录下，并配置环境变量即可，修改hive-env.sh的相关路径即可。

如果服务端启动的是hiveserver2服务，那么客户端不需要进行过多的配置，可以使用beeline工具连接。

```shell
# 服务端启动hiveserver2服务
[hadoop@master ~]$ hive --service hiveserver2 2>&1 >/dev/null &

# 可以先看看 10000 端口是否监听
[hadoop@master ~]$ netstat -anp | grep 10000
# 客户端beeline连接
[hadoop@master ~]$ beeline
beeline> !connect jdbc:hive2://master:10000
Connecting to jdbc:hive2://slave2:10000/practice
Enter username for jdbc:hive2://slave2:10000/practice: hadoop
Enter password for jdbc:hive2://slave2:10000/practice: ******
Connected to: Apache Hive (version 2.3.7)
Driver: Hive JDBC (version 2.3.7)
Transaction isolation: TRANSACTION_REPEATABLE_READ
0: jdbc:hive2://slave2:10000/practice> 
```

使用beeline连接时需要输入用户名和密码，输入自己系统用户的用户名和密码即可，如果报错如下：

```
Error: Could not open client transport with JDBC Uri: jdbc:hive2://slave2:10000/practice: Failed to open new session: java.lang.RuntimeException: org.apache.hadoop.security.AccessControlException: Permission denied: user=anonymous, access=EXECUTE, inode="/tmp":hadoop:supergroup:drwx------
	at org.apache.hadoop.hdfs.server.namenode.FSPermissionChecker.checkTraverse(FSPermissionChecker.java:266)
	at org.apache.hadoop.hdfs.server.namenode.FSPermissionChecker.checkPermission(FSPermissionChecker.java:206)
	at org.apache.hadoop.hdfs.server.namenode.FSPermissionChecker.checkPermission(FSPermissionChecker.java:190)
	at org.apache.hadoop.hdfs.server.namenode.FSDirectory.checkPermission(FSDirectory.java:1752)
	at org.apache.hadoop.hdfs.server.namenode.FSDirStatAndListingOp.getFileInfo(FSDirStatAndListingOp.java:100)
	at org.apache.hadoop.hdfs.server.namenode.FSNamesystem.getFileInfo(FSNamesystem.java:3834)
	at org.apache.hadoop.hdfs.server.namenode.NameNodeRpcServer.getFileInfo(NameNodeRpcServer.java:1012)
	at org.apache.hadoop.hdfs.protocolPB.ClientNamenodeProtocolServerSideTranslatorPB.getFileInfo(ClientNamenodeProtocolServerSideTranslatorPB.java:855)
	at org.apache.hadoop.hdfs.protocol.proto.ClientNamenodeProtocolProtos$ClientNamenodeProtocol$2.callBlockingMethod(ClientNamenodeProtocolProtos.java)
	at org.apache.hadoop.ipc.ProtobufRpcEngine$Server$ProtoBufRpcInvoker.call(ProtobufRpcEngine.java:616)
	at org.apache.hadoop.ipc.RPC$Server.call(RPC.java:982)
	at org.apache.hadoop.ipc.Server$Handler$1.run(Server.java:2217)
	at org.apache.hadoop.ipc.Server$Handler$1.run(Server.java:2213)
	at java.security.AccessController.doPrivileged(Native Method)
	at javax.security.auth.Subject.doAs(Subject.java:422)
	at org.apache.hadoop.security.UserGroupInformation.doAs(UserGroupInformation.java:1762)
	at org.apache.hadoop.ipc.Server$Handler.run(Server.java:2211) (state=08S01,code=0)
```

由于hadoop用户访问HDFS权限不够被拒绝，可以在`core-site.xml`中增加以下配置(注意需要在三台集群中的`core-site.xml`均配置)，之后便可以使用配置的用户登录：

```xml
<!-- hadoop.proxyuser.${username}.hosts -->
<!-- hadoop.proxyuser.${username}.groups -->
<property>
	<name>hadoop.proxyuser.hadoop.hosts</name>
    <value>*</value>
</property>
<property>
	<name>hadoop.proxyuser.hadoop.groups</name>
    <value>*</value>
</property>
```

如果服务端启动的是metastore服务，需要对客户端进行配置：

- hive-site.xml

  ```xml
  <configuration>
  	<property>
      	<name>hive.metastore.uris</name>
          <value>thrift://master:9083</value>
      </property>
  </configuration>
  ```

可以在客户端直接使用hive连接远程的metastore服务，操作hive数据库。