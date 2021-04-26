#### DBeaver连接Phoenix

##### 1. 下载安装好DBerver之后，选择Apache Phoenix连接

![](http://typora-image.test.upcdn.net/images/DBeaver连接选项.jpg)

##### 2. 编辑Phoenix连接的设置参数

![](http://typora-image.test.upcdn.net/images/设置Phoenix连接.jpg)

驱动只需要添加`phoenix-4.15.0-HBase-1.5.jar`即可，图中`/hbase`可以在HBase的Web页面上找到。

![](http://typora-image.test.upcdn.net/images/HBase的Web页面.jpg)

需要注意的是在选择`phoenix-4.15.0-HBase-1.5.jar`之前，将HBase目录中`conf`目录下的`hbase-site.xml`压缩到jar包中，如果和我一样使用的是高可用的hadoop集群，那么还需要将`hdfs-site.xml`和`core-site.xml`也同时压缩到jar包中。

同时将Phoenix安装包下的`phoenix-core-4.15.0-HBase-1.5.jar`和`phoenix-server-4.15.0-HBase-1.5.jar`放到HBase的安装目录下的`lib`目录中。

主机位置写服务器中任意一个`Zookeeper`节点的IP地址即可。点击测试连接即可连接成功。

##### 3. 常见错误

###### 1. 测试成功后库中的表显示不出来

在驱动属性中增加以下属性：

```
phoenix.schema.isNamespaceMappingEnabled  true
phoenix.schema.mapSystemTablesToNamespace  true
```

![](http://typora-image.test.upcdn.net/images/库表显示设置.jpg)

需要注意的是，同时也要在HBase的配置文件`hbase-site.xml`中配置如下信息：

```xml
<property>
    <name>phoenix.schema.isNamespaceMappingEnabled</name>
    <value>true</value>
</property>
<property>
    <name>phoenix.schema.mapSystemTablesToNamespace</name>
    <value>true</value>
</property>
```

###### 2. 报如下错误

```java
Unexpected driver error occurred while connecting to the database
  java.lang.RuntimeException: class org.apache.hadoop.security.JniBasedUnixGroupsMappingWithFallback not org.apache.hadoop.security.GroupMappingServiceProvider
  java.lang.RuntimeException: class org.apache.hadoop.security.JniBasedUnixGroupsMappingWithFallback not org.apache.hadoop.security.GroupMappingServiceProvider
    class org.apache.hadoop.security.JniBasedUnixGroupsMappingWithFallback not org.apache.hadoop.security.GroupMappingServiceProvider
    class org.apache.hadoop.security.JniBasedUnixGroupsMappingWithFallback not org.apache.hadoop.security.GroupMappingServiceProvider

ERROR 103 (08004): Unable to establish connection.
  java.lang.reflect.InvocationTargetException
  java.lang.reflect.InvocationTargetException
    
    java.lang.reflect.InvocationTargetException
      'void sun.misc.Unsafe.putLong(java.lang.Object, int, long)'
      'void sun.misc.Unsafe.putLong(java.lang.Object, int, long)'
```

```java
org.apache.hadoop.hbase.DoNotRetryIOException: Unable to load configured region split policy 'org.apache.phoenix.schema.MetaDataSplitPolicy' for table 'SYSTEM:CATALOG' Set hbase.table.sanity.checks to false at conf or table descriptor if you want to bypass sanity checks
	at org.apache.hadoop.hbase.master.HMaster.warnOrThrowExceptionForFailure(HMaster.java:2051)
	at org.apache.hadoop.hbase.master.HMaster.sanityCheckTableDescriptor(HMaster.java:1897)
	at org.apache.hadoop.hbase.master.HMaster.createTable(HMaster.java:1799)
	at org.apache.hadoop.hbase.master.MasterRpcServices.createTable(MasterRpcServices.java:487)
	at org.apache.hadoop.hbase.protobuf.generated.MasterProtos$MasterService$2.callBlockingMethod(MasterProtos.java)
	at org.apache.hadoop.hbase.ipc.RpcServer.call(RpcServer.java:2399)
	at org.apache.hadoop.hbase.ipc.CallRunner.run(CallRunner.java:124)
	at org.apache.hadoop.hbase.ipc.RpcExecutor$Handler.run(RpcExecutor.java:311)
	at org.apache.hadoop.hbase.ipc.RpcExecutor$Handler.run(RpcExecutor.java:291)
```

报以上两种错误可以尝试修改DBeaver安装路径中的`dbeaver.ini`文件，添加自己`JDK`的路径：

```
-vm
C:\Program Files\Java\jdk1.8.0_201\bin
```

