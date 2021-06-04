#### Spark的运行架构

##### 1. 运行架构

Spark框架的核心是一个计算引擎，整天来说，它使用了标准的master-slave的结构。图形中的Driver表示master，负责管理整个集群中的作业任务调度。图形中的Executor则是salve，负责实际执行任务。

![](http://typora-image.test.upcdn.net/images/Spark的运行架构.jpg)

##### 2. 核心组件

###### 1. Driver

Spark驱动器节点，用于执行Spark任务中的main方法，负责实际代码的执行工作。Driver在Spark作业执行时主要负责：

- 将用户程序转化为作业（job）
- 在Executor之间调度任务（task）
- 根据Executor的执行情况
- 通过UI展示查询运行情况

###### 2. Executor

Spark Executor是集群中工作节点（Worker）中的一个JVM进程，负责在Spark作业中运行具体任务（Task），任务彼此之间相互独立。Spark应用启动时，Executor节点被同时启动，并且伴随着整个Spark应用的生命周期而存在。如果有Executor节点发生了故障或崩溃，Spark应用也可以继续执行，会将出错节点上的任务调度到其他Executor节点上继续运行。Executor有两个核心功能：

- 负责运行组成Spark应用的任务，并将结果返回给驱动器进程
- 它们通过自身的块管理器（Block Manager）为用户程序中要求缓存的RDD提供内存式存储。RDD是直接缓存在Executor进程内的，因此任务可以在运行时充分利用缓存数据加速运算

###### 3. Master & Worker

Spark集群的独立部署环境中，不需要依赖其他的资源调度框架，自身就实现了资源调度的功能，所以环境中还有其他两个核心组件：Master和Worker，这里的Master是一个进程，主要负责资源的调度和分配，并进行集群的监控等职责，类似于Yarn环境中的ResourceManager，而Worker也是进程，一个Worker运行在集群中的一台服务器上，由Master分配资源对数据进行并行的处理和计算，类似于Yarn环境中的NodeManager。

###### 4. ApplicationMaster

Hadoop用户向YARN集群提交应用程序时，提交程序中应该包含ApplicationMaster，用于向资源调度器申请执行任务的资源容器Container，运行用户自己的程序任务job，监控整个任务的执行，跟踪整个任务的状态，处理任务失败等异常情况。也就是说ResourceManager（资源）和Driver（计算）之间的解耦靠的就是ApplicationMaster。

##### 3. 核心概念

###### 1. Executor和Core

Spark Executor是集群中运行在工作节点（Worker）中的一个JVM进程，是整个集群中的专门用于计算的节点。在提交应用中，可以提供参数指定计算节点的个数，以及对应的资源。这里的资源一般指的是工作节点Executor的内存大小和使用的虚拟CPU核（Core）数量。

应用程序相关启动参数如下：

|       名称        |                说明                |
| :---------------: | :--------------------------------: |
|  --num-executors  |         配置Executor的数量         |
| --executor-memory |     配置每个Executor的内存大小     |
| --executor-cores  | 配置每个Executor的虚拟CPU core数量 |

###### 2. 并行度（Parallelism）

在分布式计算框架中一般都是多个任务同时执行，由于任务分布在不同的计算节点进行计算，所以能够真正的实现多任务并行执行。我们将整个集群并行执行任务的数量称之为并行度。一个作业的并行度的多少取决于框架的默认配置，应用程序也可以在运行过程中动态修改。

###### 3. 有向无环图（DAG）

![](http://typora-image.test.upcdn.net/images/DAG有向无环图.jpg)

这里所谓的有向无环图，并不是真正意义上的图形，而是由Spark程序直接映射成的数据流的高级抽象模型。简单理解就是将整个程序计算的执行过程用图形表示出来，这样更直观，更便于理解，可以用于表示程序的拓扑结构。但是以Spark为代表的第三代计算引擎，主要特点是支持Job内的DAG，以及实时计算。

DAG（Directed Acyclic Graph）有向无环图是由点和线组成的拓扑图形，该图形具有方向，不会闭环。

##### 4. 提交流程

所谓的提交流程，其实就是我们开发人员根据需求写的应用程序通过Spark客户端提交给Spark运行环境执行计算的流程。在不同的部署环境中，这个提交过程基本相同，但是又有细微的区别。

![](http://typora-image.test.upcdn.net/images/Spark-Yarn提交流程.jpg)

Spark应用程序提交到Yarn环境中执行的时候，一般会有两种部署执行的方式：Client和Cluster。

两种模式主要的区别在于：Driver程序的运行节点位置。

###### 1. Yarn Client模式

Client模式将用于监控和调度的Driver模块在客户端执行，而不是在Yarn中，所以一般用于测试。

- Driver在任务提交的本地机器上运行
- Driver启动后会和ResourceManager通讯申请启动ApplicationMaster
- ResourceManager分配container，在合适的NodeManager上启动ApplicationMaster，负责向ResourceManager申请Executor内存
- ResouceManager接到ApplicationMaster的资源申请后会分配container，然后ApplicationMaster在资源分配指定的NodeManager上启动Executor进程
- Executor进程启动后会向Driver反向注册，Executor全部注册完成后Driver开始执行main函数
- 之后执行到action算子时，触发一个Job，并根据宽依赖开始划分stage，每个stage生成对应的TaskSet，之后将task分发到各个Executor上执行

###### 2. Yarn Cluster模式

Cluster模式将用于监控和调度的Driver模块启动在Yarn集群资源中执行，一般应用于实际生产环境。

- 在Yarn Cluster模式下，任务提交后会和ResourceManager通讯申请启动ApplicationMaster
- 随后ResourceManager分配container，在合适的NodeManager上启动ApplicationMaster，此时的ApplicationMaster就是Driver
- Driver启动后向ResourceManager申请Executor内存，ResourceManager接到ApplicationMaster的资源申请后会分配container，然后在合适的NodeManager上启动Executor进程
- Executor进程启动后会向Driver反向注册，Executor全部完成注册后Driver开始执行main函数
- 之后执行到action算子时，触发一个Job，并根据宽依赖开始划分stage，每个stage生成对应的TaskSet，之后将task分发到各个Executor上执行