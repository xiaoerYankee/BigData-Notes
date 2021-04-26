#### Hive的高级数据类型

##### 1. 数据集及建表

###### 1. 数据集

```
1	huangbo	guangzhou,xianggang,shenzhen	a1:30,a2:20,a3:100	beijing,112233,13522334455,500
2	xuzheng	xianggang	b2:50,b3:40	tianjin,223344,13644556677,600
3	wwangbaoqiang	beijing,zhejinag	c1:200	chongqinjg,334455,15622334455,20
```

###### 2. 建表语句

```shell
CREATE table cdt(
  id INT,
  name STRING,
  work_location ARRAY<STRING>,
  piaofang MAP<STRING, BIGINT>,
  address STRUCT<location:string,zipcode:int,phone:string,value:int>
)
row format delimited
fields terminated by "\t"
collection items terminated by ","
map keys terminated by ":"
lines terminated by "\n";
```

![](http://typora-image.test.upcdn.net/images/hive高级数据类型-create.jpg)

###### 3. 加载数据

```
0: jdbc:hive2://slave2:10000> load data inpath "/inputData/hiveTable/cdt/cdt" into table cdt;
```

![](http://typora-image.test.upcdn.net/images/hive高级数据类型-load.jpg)

###### 4. 查询数据

```
0: jdbc:hive2://slave2:10000> select * from cdt;
```

![](http://typora-image.test.upcdn.net/images/hive高级数据类型-select.jpg)

##### 2. Array

```
0: jdbc:hive2://slave2:10000> select work_location from cdt;
0: jdbc:hive2://slave2:10000> select work_location[0] from cdt;
0: jdbc:hive2://slave2:10000> select work_location[1] from cdt;
```

![](http://typora-image.test.upcdn.net/images/hive高级数据类型-array.jpg)

##### 3. Map

```
0: jdbc:hive2://slave2:10000> select piaofang from cdt;
0: jdbc:hive2://slave2:10000> select piaofang["a1"] from cdt;
```

![](http://typora-image.test.upcdn.net/images/hive高级数据类型-map.jpg)

##### 4. Struct

```
0: jdbc:hive2://slave2:10000> select address from cdt;
0: jdbc:hive2://slave2:10000> select address.location from cdt;
```

![](http://typora-image.test.upcdn.net/images/hive高级数据类型-struct.jpg)