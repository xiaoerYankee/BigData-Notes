#### Hive的服务及其常见客户端

Hive的shell环境只是`hive`命令提供的其中一项服务。可以在使用是使用`hive --service`选项指明我们需要哪一种服务。可以使用`hive --service help`获取可用服务列表。

- `cli`：Hive的命令行接口（shell 环境）。这是默认的服务。
- `hiveserver2`：让Hive以提供 Thrift 服务的服务器形式运行，允许用不同语言编写的客户端进行访问。`hiveserver2`在支持认证和多用户并发方面比原始的`hiveserver`有很大改进。使用 Thrift、JDBC 和 ODBC 连接器的客户端需要运行`hiveserver2`服务器来和 Hive 进行通信。通过设置`hive.server2.thrift.port`配置属性来指明服务器所监听的端口号（默认为10000）。
- `beeline`：以嵌入方式工作的 Hive 命令行接口（类似于常规的 CLI），或者使用 JDBC 连接到一个 HiveServer2 进程。
- `hwi`：Hive 的 Web 接口。在没有安装任何客户端软件的情况下，这个简单的 Web 接口可以代替 CLI，另外，Hue 是一个功能更加全面的 Hadoop Web 接口，其中包括运行 Hive 查询和浏览 Hive metastore 的应用程序。
- `jar`：与`hadoop jar`等价。这是运行类路径中同时包含 Hadoop 和 Hive 类 Java 应用程序的简便方法。
- `metastore`：默认情况下，`metastore`和 Hive 服务运行在同一个进程里。使用这个服务，可以让`metastore`作为一个简单的（远程）进程运行。通过设置`METASTORE_PORT`环境变量（或者使用`-p`命令行选项）可以指定服务器监听的端口号（默认是9083）。