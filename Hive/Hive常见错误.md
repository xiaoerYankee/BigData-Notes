#### Hive常见错误

##### 1. hive启动错误

整合Hbase和MapReduce时，因为导入环境变量后，导致slf4j版本不同，导致的错误

```
SLF4J: Class path contains multiple SLF4J bindings.
SLF4J: Found binding in [jar:file:/opt/apps/hbase/lib/slf4j-log4j12-1.7.5.jar!/org/slf4j/impl/StaticLoggerBinder.class]
SLF4J: Found binding in [jar:file:/opt/apps/hadoop/share/hadoop/common/lib/slf4j-log4j12-1.7.10.jar!/org/slf4j/impl/StaticLoggerBinder.class]
SLF4J: See http://www.slf4j.org/codes.html#multiple_bindings for an explanation.
SLF4J: Actual binding is of type [org.slf4j.impl.Log4jLoggerFactory]

Logging initialized using configuration in file:/opt/apps/hive/conf/hive-log4j.properties
[ERROR] Terminal initialization failed; falling back to unsupported
java.lang.IncompatibleClassChangeError: Found class jline.Terminal, but interface was expected
	at jline.TerminalFactory.create(TerminalFactory.java:101)
	at jline.TerminalFactory.get(TerminalFactory.java:158)
	at jline.console.ConsoleReader.<init>(ConsoleReader.java:229)
	at jline.console.ConsoleReader.<init>(ConsoleReader.java:221)
	at jline.console.ConsoleReader.<init>(ConsoleReader.java:209)
	at org.apache.hadoop.hive.cli.CliDriver.setupConsoleReader(CliDriver.java:787)
	at org.apache.hadoop.hive.cli.CliDriver.executeDriver(CliDriver.java:721)
	at org.apache.hadoop.hive.cli.CliDriver.run(CliDriver.java:681)
	at org.apache.hadoop.hive.cli.CliDriver.main(CliDriver.java:621)
	at sun.reflect.NativeMethodAccessorImpl.invoke0(Native Method)
	at sun.reflect.NativeMethodAccessorImpl.invoke(NativeMethodAccessorImpl.java:62)
	at sun.reflect.DelegatingMethodAccessorImpl.invoke(DelegatingMethodAccessorImpl.java:43)
	at java.lang.reflect.Method.invoke(Method.java:498)
	at org.apache.hadoop.util.RunJar.run(RunJar.java:221)
	at org.apache.hadoop.util.RunJar.main(RunJar.java:136)

Exception in thread "main" java.lang.IncompatibleClassChangeError: Found class jline.Terminal, but interface was expected
	at jline.console.ConsoleReader.<init>(ConsoleReader.java:230)
	at jline.console.ConsoleReader.<init>(ConsoleReader.java:221)
	at jline.console.ConsoleReader.<init>(ConsoleReader.java:209)
	at org.apache.hadoop.hive.cli.CliDriver.setupConsoleReader(CliDriver.java:787)
	at org.apache.hadoop.hive.cli.CliDriver.executeDriver(CliDriver.java:721)
	at org.apache.hadoop.hive.cli.CliDriver.run(CliDriver.java:681)
	at org.apache.hadoop.hive.cli.CliDriver.main(CliDriver.java:621)
	at sun.reflect.NativeMethodAccessorImpl.invoke0(Native Method)
	at sun.reflect.NativeMethodAccessorImpl.invoke(NativeMethodAccessorImpl.java:62)
	at sun.reflect.DelegatingMethodAccessorImpl.invoke(DelegatingMethodAccessorImpl.java:43)
	at java.lang.reflect.Method.invoke(Method.java:498)
	at org.apache.hadoop.util.RunJar.run(RunJar.java:221)
	at org.apache.hadoop.util.RunJar.main(RunJar.java:136)
```

![](http://typora-image.test.upcdn.net/images/Snipaste_2019-11-27_19-04-24.png)

![](http://typora-image.test.upcdn.net/images/Snipaste_2019-11-27_19-07-39.png)

解决方法：在使用API将Hbase和MapReduce整合在一起时，需要导入Hbase的相关jar包到Hadoop的目录下，或者使用下面的方法进行临时设置
`export HADOOP_CLASSPATH=$HADOOP_CLASSPATH:/opt/apps/hbase/lib/*`

设置完成之后，Hive启动如果产生上述错误，则说明是由于slf4j的版本不同导致的错误
可以将`/opt/apps/hbase/lib和/opt/apps/hadoop/share/hadoop/common/lib`两个目录下的slf4j的版本统一一下，都是用同一个版本的就可以了

##### 2. hive-1.2.1升级hive-2.3.6

```shell
Exception in thread "main" java.lang.NoSuchMethodError: com.ibm.icu.impl.ICUBinary.getRequiredData(Ljava/lang/String;)Ljava/nio/ByteBuffer;
        at com.ibm.icu.charset.UConverterAlias.haveAliasData(UConverterAlias.java:131)
        at com.ibm.icu.charset.UConverterAlias.getCanonicalName(UConverterAlias.java:525)
        at com.ibm.icu.charset.CharsetProviderICU.getICUCanonicalName(CharsetProviderICU.java:126)
        at com.ibm.icu.charset.CharsetProviderICU.charsetForName(CharsetProviderICU.java:62)
        at java.nio.charset.Charset$2.run(Charset.java:412)
        at java.nio.charset.Charset$2.run(Charset.java:407)
        at java.security.AccessController.doPrivileged(Native Method)
        at java.nio.charset.Charset.lookupViaProviders(Charset.java:406)
        at java.nio.charset.Charset.lookup2(Charset.java:477)
        at java.nio.charset.Charset.lookup(Charset.java:464)
        at java.nio.charset.Charset.forName(Charset.java:528)
        at com.sun.org.apache.xml.internal.serializer.Encodings$EncodingInfos.findCharsetNameFor(Encodings.java:386)
        at com.sun.org.apache.xml.internal.serializer.Encodings$EncodingInfos.findCharsetNameFor(Encodings.java:422)
        at com.sun.org.apache.xml.internal.serializer.Encodings$EncodingInfos.loadEncodingInfo(Encodings.java:450)
        at com.sun.org.apache.xml.internal.serializer.Encodings$EncodingInfos.<init>(Encodings.java:308)
        at com.sun.org.apache.xml.internal.serializer.Encodings$EncodingInfos.<init>(Encodings.java:296)
        at com.sun.org.apache.xml.internal.serializer.Encodings.<clinit>(Encodings.java:564)
        at com.sun.org.apache.xml.internal.serializer.ToStream.<init>(ToStream.java:134)
        at com.sun.org.apache.xml.internal.serializer.ToXMLStream.<init>(ToXMLStream.java:67)
        at com.sun.org.apache.xml.internal.serializer.ToUnknownStream.<init>(ToUnknownStream.java:143)
        at com.sun.org.apache.xalan.internal.xsltc.runtime.output.TransletOutputHandlerFactory.getSerializationHandler(TransletOutputHandlerFactory.java:159)
        at com.sun.org.apache.xalan.internal.xsltc.trax.TransformerImpl.getOutputHandler(TransformerImpl.java:438)
        at com.sun.org.apache.xalan.internal.xsltc.trax.TransformerImpl.transform(TransformerImpl.java:328)
        at org.apache.hadoop.conf.Configuration.writeXml(Configuration.java:2707)
        at org.apache.hadoop.conf.Configuration.writeXml(Configuration.java:2686)
        at org.apache.hadoop.hive.conf.HiveConf.getConfVarInputStream(HiveConf.java:3628)
        at org.apache.hadoop.hive.conf.HiveConf.initialize(HiveConf.java:4051)
        at org.apache.hadoop.hive.conf.HiveConf.<init>(HiveConf.java:4003)
        at org.apache.hadoop.hive.common.LogUtils.initHiveLog4jCommon(LogUtils.java:81)
        at org.apache.hadoop.hive.common.LogUtils.initHiveLog4j(LogUtils.java:65)
        at org.apache.hadoop.hive.cli.CliDriver.run(CliDriver.java:702)
        at org.apache.hadoop.hive.cli.CliDriver.main(CliDriver.java:686)
        at sun.reflect.NativeMethodAccessorImpl.invoke0(Native Method)
        at sun.reflect.NativeMethodAccessorImpl.invoke(NativeMethodAccessorImpl.java:62)
        at sun.reflect.DelegatingMethodAccessorImpl.invoke(DelegatingMethodAccessorImpl.java:43)
        at java.lang.reflect.Method.invoke(Method.java:498)
        at org.apache.hadoop.util.RunJar.run(RunJar.java:221)
        at org.apache.hadoop.util.RunJar.main(RunJar.java:136)
```

解决方法：删除`hbase/lib`目录下的phoenix的相关jar包，一般是两个，我的分别是`phoenix-4.13.1-HBase-1.2-client.jar`和` phoenix-core-4.13.1-HBase-1.2.jar` 

##### 3. Hive初始化MySQL数据库时报错

```
Exception in thread "main" java.lang.NoSuchMethodError: com.google.common.base.Preconditions.checkArgument(ZLjava/lang/String;Ljava/lang/Object;)V
        at org.apache.hadoop.conf.Configuration.set(Configuration.java:1357)
        at org.apache.hadoop.conf.Configuration.set(Configuration.java:1338)
        at org.apache.hadoop.mapred.JobConf.setJar(JobConf.java:536)
        at org.apache.hadoop.mapred.JobConf.setJarByClass(JobConf.java:554)
        at org.apache.hadoop.mapred.JobConf.<init>(JobConf.java:448)
        at org.apache.hadoop.hive.conf.HiveConf.initialize(HiveConf.java:4045)
        at org.apache.hadoop.hive.conf.HiveConf.<init>(HiveConf.java:4008)
        at org.apache.hive.beeline.HiveSchemaTool.<init>(HiveSchemaTool.java:82)
        at org.apache.hive.beeline.HiveSchemaTool.main(HiveSchemaTool.java:1117)
        at sun.reflect.NativeMethodAccessorImpl.invoke0(Native Method)
        at sun.reflect.NativeMethodAccessorImpl.invoke(NativeMethodAccessorImpl.java:62)
        at sun.reflect.DelegatingMethodAccessorImpl.invoke(DelegatingMethodAccessorImpl.java:43)
        at java.lang.reflect.Method.invoke(Method.java:498)
        at org.apache.hadoop.util.RunJar.run(RunJar.java:323)
        at org.apache.hadoop.util.RunJar.main(RunJar.java:236)
```

解决方法：由于hadoop内的guava和hive中的guava版本不一致造成的，可以将hive中低版本中的guava删除，将hadoop的share/hadoop/common/lib中guava复制到hive的lib目录下即可



##### 错误一：

```
FAILED: SemanticException Cartesian products are disabled for safety reasons. If you know what you are doing, please sethive.strict.checks.cartesian.product to false and that hive.mapred.mode is not set to 'strict' to proceed. Note that if you may get errors or incorrect results if you make a mistake while using some of the unsafe features.
```

解决办法：

```xml
<!-- 方法一：设置 hive.strict.checks.cartesian.product 值为 false，默认值为 true -->
<property>
	<name>hive.strict.checks.cartesian.product</name>
    <value>false</value>
</property>

<!-- 方法二：设置 hive.mapred.mode 值为 nostrict -->
<property>
	<name>hive.mapred.mode</name>
    <value>nostrict</value>
</property>
```



