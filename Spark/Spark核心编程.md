#### Spark核心编程

Spark计算框架为了能够进行高并发和高吞吐的数据处理，封装了三大数据结构，用于处理不同的应用场景。三大数据结构分别是：

- RDD：弹性分布式数据集
- 累加器：分布式共享<font color='#33CCFF'>只写</font>变量
- 广播变量：分布式共享<font color='#33CCFF'>只读</font>变量

##### 1. RDD

###### 1. 什么是RDD

RDD（Resilient Distributed Dataset）叫做弹性分布式数据集，是Spark中最基本的<font color='#33CCFF'>数据处理模型</font>。代码中是一个抽象类，它代表一个弹性的、不可变、可分区、里面的原宿可并行计算的集合。

- 弹性
  - 存储的弹性：内存与磁盘的自动切换；
  - 容错的弹性：数据丢失可以自动恢复；
  - 计算的弹性：计算出错重试机制；
  - 分片的弹性：可根据需要重新分片
- 分布式：数据存储在大数据集群不同节点上
- 数据集：RDD封装了计算逻辑，并不保存数据
- 数据抽象：RDD是一个抽象类，需要子类具体实现
- 不可变：RDD封装了计算逻辑，是不可以改变的，想要改变，只能产生新的RDD，在新的RDD里面封装新的计算逻辑
- 可分区、并行计算

RDD的数据处理方式类似于IO流，也体现了<font color="#33CCFF">装饰者设计模式</font>，RDD的数据只有在调用collect方法时，才会真正的执行业务逻辑操作。之前的封装全部都是功能的扩展，并且RDD是不保存数据的，但是IO可以临时保存一部分数据。

###### 2. 核心属性

![](http://typora-image.test.upcdn.net/images/RDD核心属性.jpg)

- 分区列表

  RDD数据结构中存在分区列表，用于执行任务时并行计算，是实现分布式计算的重要属性。

  ![](http://typora-image.test.upcdn.net/images/RDD核心属性-分区.jpg)

- 分区计算函数

  Spark在计算时，是使用分区函数对每一个分区进行计算。

  ![](http://typora-image.test.upcdn.net/images/RDD核心属性-分区计算.jpg)

- RDD之间的依赖关系

  RDD是计算模型的封装，当需求中需要将多个计算模型进行组合时，就需要将多个RDD建立依赖关系。

  ![](http://typora-image.test.upcdn.net/images/RDD核心属性-依赖关系.jpg)

- 分区器（可选）

  当数据为KV类型数据时，可以通过设定分区器自定义数据的分区。

  ![](http://typora-image.test.upcdn.net/images/RDD核心属性-分区器.jpg)

- 首选位置（可选）

  计算数据时，可以根据节点的状态选择不同的节点位置进行计算，也就是说判断计算发送给那个节点的效率最优，即移动数据不如移动计算。

  ![](http://typora-image.test.upcdn.net/images/RDD核心属性-首选位置.jpg)

###### 3. 执行原理

从计算的角度来讲，数据处理过程中需要计算资源（内存&CPU）和计算模型（逻辑）。执行时，需要将计算资源和计算模型进行协调和整合。

Spark框架在执行时，先申请资源，然后将应用程序的数据处理逻辑分解成一个一个的计算任务。然后将任务分发到已经分配资源的计算节点上，按照指定的计算模型进行数据计算。最后得到结果。

RDD是Spark框架中用于数据处理的核心模型，在Yarn环境中，RDD的工作原理：

1) 启动Yarn集群环境

![](http://typora-image.test.upcdn.net/images/RDD-执行原理-启动Yarn集群环境.jpg)

2) Spark通过申请资源创建调度节点和计算节点

![](http://typora-image.test.upcdn.net/images/RDD-执行原理-Spark创建节点.jpg)

3) Spark框架根据需求将计算逻辑根据分区划分不同的任务

![](http://typora-image.test.upcdn.net/images/RDD-执行原理-Spark划分任务.jpg)

4) 调度节点将任务根据计算节点状态发送到对应的计算节点进行计算

![](http://typora-image.test.upcdn.net/images/RDD-执行原理-调度计算.jpg)

RDD在整个流程中主要用于将逻辑进行封装，并生成Task发送给Executor节点执行计算。

##### 2. 累加器

###### 1. 实现原理

累加器用来把Executor端变量信息聚合到Driver端。在Driver程序中定义的变量，在Executor端的每个Task都会得到这个变量的一份新的副本，每个Task更新这些副本的值后，传回Driver端进行merge。

##### 3. 广播变量

###### 1. 实现原理

广播变量用来高效分发较大的对象。向所有工作节点发送一个较大的只读值，以供一个或多个Spark操作使用。在多个并行操作操作中使用同一个变量，但是Spark会为每个任务分别发送。