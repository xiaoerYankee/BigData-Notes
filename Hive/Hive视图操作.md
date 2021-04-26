#### Hive视图操作

##### 1. 视图

```
Hive中的视图只有逻辑视图，没有物化视图；视图只能查询，不能load/insert/update/delete数据；视图在创建的时候，只是保存了一份元数据，存放在元数据表TBLS中，只有当查询视图时，才开始执行那些视图对应的子查询
```

##### 2. 创建视图

```
0: jdbc:hive2://slave2:10000> create view view_cdt as select * from cdt;
```

![](http://typora-image.test.upcdn.net/images/hive高级数据类型-create-view.jpg)

##### 3. 视图的查看语句

```
0: jdbc:hive2://slave2:10000> show views;
0: jdbc:hive2://slave2:10000> desc view_cdt;
```

![](http://typora-image.test.upcdn.net/images/hive高级数据类型-view-show.jpg)

##### 4. Hive视图的使用

```
0: jdbc:hive2://slave2:10000> select * from view_cdt;
```

![](http://typora-image.test.upcdn.net/images/hive高级数据类型-view-select.jpg)

##### 5. Hive视图的删除语句

```
0: jdbc:hive2://slave2:10000> drop view view_cdt;
```

![](http://typora-image.test.upcdn.net/images/hive高级数据类型-view-drop.jpg)