#### Zeppelin集成Hive

##### 1. 准备工作

已经安装了Hive的机器以及安装了zeppelin的机器。

##### 2. Hive操作

修改hive-site.xml配置文件：

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
    <property>
    	<name>hive.server2.transport.mode</name>
    	<value>binary</value>
    </property>
    <property>
  	<name>hive.server2.thrift.port</name>
  	<value>10000</value>
    </property>
</configuration>
```

```shell
# 启动hiveserver2服务，并查看是否监听了10000端口
[hadoop@slave2 ~]$ hive --service hiveserver2 2>&1 >/dev/null &
# 查看是否监听 10000 端口
[hadoop@slave2 ~]$ netstat -anp | grep 10000
```

![](http://typora-image.test.upcdn.net/images/20200814194216.jpg)

##### 3. Zeppelin操作

```shell
# 启动 zeppelin 服务
[hadoop@slave2 ~]$ zeppelin-daemon.sh start
# 访问 web 页面
http://slave2:9090
```

打开解释器配置页面：

![](http://typora-image.test.upcdn.net/images/20200814194454.jpg)

一般情况下，没有`hive`的解释器，`jdbc`默认的是`postgresql`，可以直接新增一个`hive`的解释器：

![](http://typora-image.test.upcdn.net/images/20200814194650.jpg)

```
Interpreter Name：hive
Interpreter group：jdbc
```

修改配置为以下内容：

![](http://typora-image.test.upcdn.net/images/20200814194834.jpg)

```xml
user和password就写自己系统的用户名和密码，前提是配置了对HDFS的访问权限，即在core-site.xml中增加内容：
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

底下的Artifact配置按照自己的路径去填写
hive-jdbc-2.3.7-standalone.jar在hive目录的jdbc目录下
hadoop-common-2.7.7.jar在hadoop的lib目录下
```

##### 4. 测试zeppelin操作hive

新建NoteBook，通过zeppelin访问Hive：

![](http://typora-image.test.upcdn.net/images/20200814195305.jpg)

通过notebook写hive的查询语句，访问hiveserver2服务，连接hive：
![](http://typora-image.test.upcdn.net/images/20200814195423.jpg)

```
%hive：表示使用hive的interpreter
右上角可以切换hive的notebook的显示模式
```

