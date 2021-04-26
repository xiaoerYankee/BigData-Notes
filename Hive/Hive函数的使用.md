#### Hive函数的使用

##### 1. Hive函数相关的操作

```
-- 查看所有的函数
0: jdbc:hive2://slave2:10000> show functions;

-- 查看函数的详细信息
0: jdbc:hive2://slave2:10000> desc function substr;

-- 显示函数的扩展信息
0: jdbc:hive2://slave2:10000> desc function extended substr;
```

![](http://typora-image.test.upcdn.net/images/hive高级数据类型-functions.jpg)

##### 2. Hive自定义函数

```
UDF(User-Defined Function)：作用于单个数据行，产生一个数据行作为输出（数学函数，字符串函数）
UDAF(User-Defined Aggregation Function)：接收多个输入数据行，并产生一个输出数据行（count，max）
UDTF(User-Defined Table Function)：接收一行输入，输出多行（explode）
```