#### Flink运行环境_Local

##### 1. 启动Local环境

- 进入解压缩后的路径，执行如下命令

  ```shell
  bin/start-cluster.sh
  ```

  ![](http://typora-image.test.upcdn.net/images/local-start.png)

- 启动成功后，可以输入网址进行Web UI监控页面访问

  ```
  http://虚拟机地址:8081
  ```

  ![](http://typora-image.test.upcdn.net/images/local-web.png)

##### 2. 命令行提交应用

```shell
bin/flink run \
-m hadoop01:8081 \
-d \
-c com.yankee.day01.Flink03_WordCount_UnBounded_Scala wordcount.jar
```

注意：启动之前需要先启动hadoop01上的scoket（用的jar包是快速上手中的代码）

- -m 表示JobManager所在节点
- -d 表示提交后退出客户端
- -c 全类名和jar包位置

![](http://typora-image.test.upcdn.net/images/submit-local.png)

###### 1. 在浏览器中查看执行情况

![](http://typora-image.test.upcdn.net/images/stdout-local.png)

###### 2. 在日志中查看执行结果

```shell
cat log/flink-hadoop-taskexecutor-1-hadoop01.out
```

![](http://typora-image.test.upcdn.net/images/cat-local.png)

##### 3. Web页面提交应用

![](http://typora-image.test.upcdn.net/images/web-submit.png)

![](http://typora-image.test.upcdn.net/images/web-submit-config.png)