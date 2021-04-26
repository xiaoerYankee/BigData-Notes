#### Hadoop集群搭建之Zeppelin安装

##### 1. 准备工作

下载Zeppelin的安装包上传到集群中的某台服务器中

##### 2. Zeppelin安装

###### 1. 安装目录规划

```
统一安装路径：/opt/apps
统一软件存放路径：/opt/software
```

###### 2. 上传压缩包

```
1. 将压缩包上传到[/opt/software]目录下，解压到[/opt/apps]目录下
2. 修改[/home/hadoop/.bash_profile]文件，增加以下内容：
	ZEPPELIN_HOME=/opt/apps/zeppelin-0.9.0
	PATH=$ZEPPELIN_HOME/bin:$PATH
	export ZEPPELIN_HOME PATH
3. 使用[source ~/.bash_profile]使其生效
```

###### 3. Zeppelin配置

配置文件目录：【/opt/apps/zeppelin-0.9.0/conf】

- zeppelin-env.sh

  需要将`zeppelin-env.sh.template`复制一份为`zeppelin-env.sh`

  ```shell
  export JAVA_HOME=/opt/apps/jdk1.8.0_162
  # zeppelin 启动的地址
  export ZEPPELIN_ADDR=slave2
  # zeppelin 启动的端口号
  export ZEPPELIN_PORT=9090
  ```

- zeppelin-site.xml(如果没有其他需求的话，可以不进行设置)

###### 4. Zeppelin启动测试

```shell
# 启动 zeppelin
[hadoop@slave2 ~]$ zeppelin-daemon.sh start
```

可以通过`http://slave2:9090`访问zeppelin启动页面

![](http://typora-image.test.upcdn.net/images/20200813213343.jpg)

```shell
# 停止 zeppelin
[hadoop@slave2 ~]$ zeppelin-daemon.sh stop
```

