#### Flink常见的面试题

##### 1. Flink-On-Yarn的两种架构

**问题：Flink-On-Yarn常见的提交模式有哪些，分别有什么优缺点？**

**解答：**

flink在yarn模式下运行，有两种任务提交模式，资源消耗各不相同。

###### 1. yarn-session

yarn-session这种方式需要先启动集群，然后在提交作业，接着会向yarn申请一块空间后，资源永远保持不变。如果资源满了，下一个就任务就无法提交，只能等到yarn中其中一个作业完成后，释放了资源，那下一个作业才会正常提交，这种方式资源被限制在session中，不能超过，比较适合特定的运行环境或测试环境。

###### 2. flink run

flink run直接在yarn上提交任务运行Flink作业，这种方式的好处是一个任务会对应一个job，即每提交一个作业会根据自身的情况，向yarn中申请资源，直到作业执行完成，并不会影响下一个作业的正常运行，除非是yarn上面没有任何资源的情况下。一般生产环境是采用此方式运行。这种方式需要保证集群资源足够。

##### 2. 压测和监控

**问题：怎么做压力测试和监控？**

**解答：**

- 产生的数据流的速度如果过快，而下游的算子消费不过来的话，会产生背压。背压的监控可以使用Flink Web UI来可视化监控Metrics，一旦报警就能知道。一般情况下可能由于sink这个操作符没有优化好，做一下优化就可以了。
- 设置watermark的最大延迟时间这个参数，如果设置的过大，可能会造成内存的压力。可以设置最大延迟时间小一些，然后把迟到的元素发送到测输出流中，晚一点更新结果。
- 还有就是滑动窗口的长度如果过大，而滑动距离很短的话，Flink的性能也会下降的厉害。可以通过分片的方法，将每个元素只存入一个“重叠窗口”，这样就可以减少窗口处理中状态的写入。

##### 3. Flink背压

**问题：Flink是通过什么机制实现的背压机制？**

**解答：**

Flink在运行时主要由operators和streams两大构件组成。每个operator会消费中间状态的流，并在流上进行转换，然后生成新的流。对于Flink的网络机制一种形象的类比是，Flink使用了高效有界的分布式阻塞队列，就像Java通过的阻塞队列（BlockingQueue）一样。使用BlockingQueue的话，一个较慢的接受者会降低发送者的发送速率，因为一旦队列满了（有界队列）发送者会被阻塞。

在Flink中，这些分布式阻塞队列就是这些逻辑流，而队列容量通过缓冲池（LocalBufferPool）实现的。每个被生产和消费的流都会被分配一个缓冲池。缓冲池管理者一组缓冲（Buffer），缓冲在被消费后可以被回收循环利用。

##### 4. 为什么用Flink

**问题：为什么使用Flink替代Spark？**

**解答：**

使用Flink主要考虑的是Flink的低延迟、高吞吐量和对流式数据应用场景更好的支持。另外，Flink可以很好的处理乱序数据，而且可以保证exactly-once的状态一致性。

##### 5. Checkpoint的存储

**问题：Flink的checkpoint存在哪里？**

**解答：**

Flink的checkpoint可以存储在内存，文件系统。

##### 6. exactly-once的保证

**问题：如果下级存储不支持事务，Flink是如果保证exactly-once的？**

**解答：**

端到端的exactly-once对sink的要求比较高，具体的实现主要有幂等写入和事务性写入两种方式。幂等写入的场景依赖于业务逻辑，更常见的是用事务性写入。而事务性写入又有预写日志（WAL）和两阶段提交（2PC）两种方式。

如果外部系统不支持事务，那么可以使用预写日志的方式，把结果数据当成状态保存，然后在收到checkpoint完成的通知时，一次性写入sink系统。

##### 7. 状态机制

**问题：Flink的状态机制是什么？**

**解答：**

Flink内置的很多算子，包括源Source，数据存储Sink都是有状态的。在Flink中，状态始终与特定算子相关联。Flink会以checkpoint的形式对各个任务的状态进行快照，用于保存故障恢复时的状态一致性。Flink通过状态后端来管理状态和checkpoint的存储，状态后端可以有不同的配置选择。

##### 8. 海量key去重

**问题：怎么去重？**

**解答：**

使用类似于Scala的set数据结构或者redis的set显然是不行的，因为可能有上亿个key，内存放不下。所以可以考虑使用布隆过滤器（Bloom Filter）来去重。

##### 9. 数据倾斜

**问题：使用KeyBy算子时，某一个Key的数据量过大，导致数据倾斜，怎么处理？**

**解答：**

可以先将key进行散列，将key转换为key-随机数，保证数据散列，对打散后的数据进行聚合统计，这时我们会得到的数据是原始的key加上随机数的统计结果。将散列的key去除拼接的随机数，这时我们会得到原始的key，进行二次keyby进行结果统计。

##### 10. checkpoint与Spark的比较

**问题：Flink的checkpoint机制对比spark有什么不同和优势？**

**解答：**

spark streaming的checkpoint仅仅是针对driver的故障恢复做了数据和元数据的checkpoint。而flink的checkpoint机制要复杂很多，它采用的是轻量级的分布式快照，实现了每个算子的快照，及流动中的数据的快照。

##### 11. watermark机制

**问题：详细解释一下Flink的watermark机制？**

**解答：**

Watermark的本质是Flink中衡量EventTime进展的一个机制，主要用来处理乱序的数据。

##### 12. exactly-once如何实现

**问题：Flink中的exactly-once语义如何实现的，状态如何存储的？**

**解答：**

Flink依靠checkpoint机制来实现exactly-once语义，如果要实现端到端的exactly-once，还需要外部source和sink满足一定的条件。状态的存储通过状态后端来管理，Flink中可以配置不同的状态后端。

##### 13. CEP

**问题：Flink CEP编程中当状态没有到达的时候会将数据保存到哪里？**

**解答：**

在流式处理中，CEP当然是要支持EventTime的，那么相对应的也要支持数据的迟到现象，也就是说watermark的处理逻辑。CEP对未匹配成功的事件序列的处理，和迟到数据是类似的。在Flink CEP的处理逻辑中，状态没有满足和迟到的数据，都会存储在一个Map数据结构中，也就是说，如果我们限定判断事件序列的时长为5分钟，那么内存中就会存储5分钟的数据，这也是对内存的极大损伤之一。

##### 14. 三种时间语义

**问题：Flink的三种时间语义是什么？应用场景是什么？**

**解答：**

- Event Time：这是实际应用最常见的时间语义。
- Processing Time：没有事件时间的情况下，或者对实时要求超高的情况下。
- Ingestion Time：存在多个Source Operator的情况下，每个Source Operator可以使用自己本地系统始终指派Ingestion Time后。后续基于时间相关的各种操作，都会使用数据记录中的Ingestion Time。

##### 15. 数据高峰的处理

**问题：Flink程序在面对数据高峰期时如何处理？**

**解答：**

使用大容量的Kafka把数据先放到消息队列里面作为数据源，再使用Flink进行消费，不过这样会影响一点实时性。

