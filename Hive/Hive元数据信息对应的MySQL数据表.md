#### Hive元数据信息对应的MySQL数据表

Hive的元数据一般选择放在关系型数据库中，自带的数据库是Derby，我将Hive的元数据信息存放在MySQL数据库中，对应的hive数据库中，共57张表。

![](http://typora-image.test.upcdn.net/images/20200902222450.jpg)

##### 1. Hive版本信息

元数据表`VERSION`中存储的是Hive的元数据版本，如果该表出现问题，根本进入不了Hive-Cli。

- VERSION表结构：

  |  元数据表字段   |      说明       |          示例数据          |
  | :-------------: | :-------------: | :------------------------: |
  |     VER_ID      |    ID(主键)     |             1              |
  | SCHEMA_VERSION  | Hive-Schema版本 |           2.3.0            |
  | VERSION_COMMENT |    版本说明     | Hive release version 2.3.0 |

  ![](http://typora-image.test.upcdn.net/images/20200902223837.jpg)

##### 2. Hive数据库相关的元数据表

与Hive数据库相关的元数据表有3个，分别是`DBS`、`DATABASE_PARAMS`和`DB_PRIVS`这3张表。`DBS`存储的是Hive数据库的基本信息，`DATABASE_PARAMS`存储的是数据库的相关参数，`DB_PRIVS`存储的是数据库的授权信息，通过GRANT授权后将存储在这里表中(不常用)。

- DBS表结构：

  |  元数据表字段   |       说明       |                    示例数据                     |
  | :-------------: | :--------------: | :---------------------------------------------: |
  |      DB_ID      |     数据库ID     |                       51                        |
  |      DESC       |    数据库描述    |                                                 |
  | DB_LOCATION_URI |  数据库HDFS路径  | hdfs://supercluster/user/hive/warehouse/test.db |
  |      NAME       |    数据库名称    |                      test                       |
  |   OWNER_NAME    |   数据库所有者   |                     hadoop                      |
  |   OWNER_TYPE    | 数据库所有者类型 |                      USER                       |
  
  ![](http://typora-image.test.upcdn.net/images/20200903204549.jpg)
  
- DATABASE_PARAMS表结构：

  | 元数据表字段 |   说明   |  示例数据  |
  | :----------: | :------: | :--------: |
  |    DB_ID     | 数据库ID |     51     |
  |  PARAM_KEY   |  参数名  |    date    |
  | PARAM_VALUE  |  参数值  | 2020-09-02 |
  
  ![](http://typora-image.test.upcdn.net/images/20200903204708.jpg)
  
- DB_PRIVS表结构(不常用)：

  |  元数据表字段  |      说明      |  示例数据  |
  | :------------: | :------------: | :--------: |
  |  DB_GRANT_ID   |     授权ID     |     1      |
  |  CREATE_TIME   |    授权时间    | 1599136358 |
  |     DB_ID      |    数据库ID    |     51     |
  |  GRANT_OPTION  |    授权选项    |     0      |
  |    GRANTOR     |    授权用户    |   hadoop   |
  |  GRANTOR_TYPE  |  授权用户类型  |    USER    |
  | PRINCIPAL_NAME |   被授权用户   |   hadoop   |
  | PRINCIPAL_TYPE | 被授权用户类型 |    USER    |
  |    DB_PRIV     |   数据库权限   |   SELECT   |

  ![](http://typora-image.test.upcdn.net/images/20200903215439.jpg)

##### 3. Hive表和视图相关的元数据表

与Hive数据表和视图相关的元数据表有3个，分别是`TBLS`、`TABLE_PARAMS`和`TBL_PRIVS`这3张表。`TBLS`存储的是Hive数据表、视图和索引表的基本信息，`TABLE_PARAMS`存储的是数据表和视图的属性信息，`TABLE_PRIVS`存储的是数据表和视图的授权信息。

- TBLS表结构：

  |元数据表字段|说明|示例数据|
  | :----------------: | :---------------: | :-------------------: |
  |TBL_ID|数据表ID|18|
  |CREATE_TIME|创建时间|1599139279|
  |DB_ID|数据库ID|51|
  |LAST_ACCESS_TIME|上次访问时间|0|
  |OWNER|所有者|hadoop|
  |RETENTION|保留字段|0|
  |SD_ID|序列化配置信息|18|
  |TBL_NAME|表名|studentview|
  |TBL_TYPE|表类型|VIRTUAL_VIEW|
  |VIEW_EXPANDED_TEXT|视图的详细HQL语句|SELECT \`id\` AS \`id\`, \`name\` AS \`name\`, \`sex\` AS \`sex\` FROM (select \`student\`.\`id\`, \`student\`.\`name\`, \`student\`.\`sex\` from \`test\`.\`student\`) \`test.studentView\`|
  |VIEW_ORIGINAL_TEXT|视图的原始HQL语句|select * from test.student|
  |IS_REWRITE_ENABLED||0|
  
  ![](http://typora-image.test.upcdn.net/images/20200903212149.jpg)
  
- TABLE_PARAMS表结构：

  | 元数据表字段 |   说明   |       示例数据        |
  | :----------: | :------: | :-------------------: |
  |    TBL_ID    | 数据表ID |          18           |
  |  PARAM_KEY   |  属性名  | transient_lastDdlTime |
  | PARAM_VALUE  |  属性值  |      1599139279       |

  ![](http://typora-image.test.upcdn.net/images/20200903213546.jpg)

- TBL_PRIVS表结构：

  |  元数据表字段  |      说明      |  示例数据  |
  | :------------: | :------------: | :--------: |
  |  TBL_GRANT_ID  |     授权ID     |     61     |
  |  CREATE_TIME   |    授权时间    | 1599139279 |
  |  GRANT_OPTION  |    授权选项    |     1      |
  |    GRANTOR     |    授权用户    |   hadoop   |
  |  GRANTOR_TYPE  |  授权用户类型  |    USER    |
  | PRINCIPAL_NAME |   被授权用户   |   hadoop   |
  | PRINCIPAL_TYPE | 被授权用户类型 |    USER    |
  |    TBL_PRIV    |   数据表权限   |   UPDATE   |
  |     TBL_ID     |    数据表ID    |     18     |

  ![](http://typora-image.test.upcdn.net/images/20200903213738.jpg)

##### 4. Hive文件存储信息相关的元数据表

由于HDFS的文件格式很多，建Hive表的同时也可以指定各种文件格式，Hive在将SQL解析成MapReduce程序时，需要知道去哪里可以查询到这些信息，这些信息就保存在`SDS`、`SD_PARAMS`、`SERDES`和`SERDE_PARAMS`这4张表中。`SDS`存储的是文件存储的基本信息，如输入格式、输出格式、是否压缩等，`SD_PARAMS`存储的是hive存储的相关属性，在创建表时使用，`SERDES`存储的是序列化使用的类信息，`SERDE_PARAMS`存储的是序列化的一些属性和格式信息，比如行、分隔符等。

- SDS表结构：

  |       元数据表字段        |       说明       |                          示例数据                          |
  | :-----------------------: | :--------------: | :--------------------------------------------------------: |
  |           SD_ID           |    存储信息ID    |                             2                              |
  |           CD_ID           |    字段信息ID    |                             2                              |
  |       INPUT_FORMAT        |   文件输入格式   |          org.apache.hadoop.mapred.TextInputFormat          |
  |       IS_COMPRESSED       |     是否压缩     |                             0                              |
  | IS_STOREDASSUBDIRECTORIES | 是否以子目录存储 |                             0                              |
  |         LOCATION          |     HDFS路径     |  hdfs://supercluster/user/hive/warehouse/test.db/student   |
  |        NUM_BUCKETS        |     分桶数量     |                             -1                             |
  |       OUTPUT_FORMAT       |   文件输出格式   | org.apache.hadoop.hive.ql.io.HiveIgnoreKeyTextOutputFormat |
  |         SERDE_ID          |    序列化类ID    |                             17                             |

  ![](http://typora-image.test.upcdn.net/images/20200904194214.jpg)

- SD_PARAMS表结构：

  | 元数据表字段 |    说明    | 示例数据 |
  | :----------: | :--------: | :------: |
  |    SD_ID     | 存储信息ID |          |
  |  PARAM_KEY   |   属性名   |          |
  | PARAM_VALUE  |   属性值   |          |

- SERDES表结构：

  | 元数据表字段 |      说明      |                      示例数据                      |
  | :----------: | :------------: | :------------------------------------------------: |
  |   SERDE_ID   | 序列化类配置ID |                         17                         |
  |     NAME     |  序列化类别名  |                                                    |
  |     SLIB     |    序列化类    | org.apache.hadoop.hive.serde2.lazy.LazySimpleSerDe |

  ![](http://typora-image.test.upcdn.net/images/20200904200728.jpg)

- SERDE_PARAMS表结构：

  | 元数据表字段 |      说明      |  示例数据   |
  | :----------: | :------------: | :---------: |
  |   SERDE_ID   | 序列化类配置ID |     17      |
  |  PARAM_KEY   |     属性名     | field.delim |
  | PARAM_VALUE  |     属性值     |             |

  ![](http://typora-image.test.upcdn.net/images/20200904203822.jpg)

##### 5. Hive表字段相关的元数据表

元数据表COLUMNS_V2主要存储的是Hive数据表中字段的相关信息。

- COLUMNS_V2表结构：

  | 元数据表字段  |    说明    | 示例数据 |
  | :-----------: | :--------: | :------: |
  |     CD_ID     | 字段信息ID |    17    |
  |    COMMENT    |  字段注释  |          |
  |  COLUMN_NAME  |   字段名   |    id    |
  |   TYPE_NAME   |  字段类型  |   int    |
  | INTEGER_INDEX |  字段顺序  |    0     |

  ![](http://typora-image.test.upcdn.net/images/20200904204258.jpg)

##### 6. Hive表分区相关的元数据表

和Hive表分区相关的元数据表主要有`PARTITIONS`、`PARTITION_KEYS`、`PARTITION_KEY_VALS`和`PARTITION_PARAMS`这4张表。`PARTITIONS`表存储的是Hive表分区的基本信息，`PARTITION_KEYS`表存储的是Hive分区表的分区字段的信息，`PARTITION_KEY_VALS`表存储的是Hive表分区的字段值，`PARTITION_PARAMS`表存储的是Hive分区的属性信息。

- PARTITIONS表结构：

  |   元数据表字段   |       说明       |   示例数据    |
  | :--------------: | :--------------: | :-----------: |
  |     PART_ID      |      分区ID      |       1       |
  |   CREATE_TIME    |   分区创建时间   |  1599224944   |
  | LAST_ACCESS_TIME | 最后一次访问时间 |       0       |
  |    PART_NAME     |      分区名      | dt=2020-09-03 |
  |      SD_ID       |    分区存储ID    |      21       |
  |      TBL_ID      |     数据表ID     |      19       |

  ![](http://typora-image.test.upcdn.net/images/20200904211355.jpg)

- PARTITION_KEYS表结构：

  | 元数据表字段 |     说明     | 示例数据 |
  | :----------: | :----------: | :------: |
  |    TBL_ID    |   数据表ID   |    19    |
  | PKEY_COMMENT | 分区字段注释 |          |
  |  PKEY_NAME   | 分区字段名称 |    dt    |
  |  PKEY_TYPE   | 分区字段类型 |  string  |
  | INTEGER_IDX  | 分区字段顺序 |    0     |

  ![](http://typora-image.test.upcdn.net/images/20200904211654.jpg)

- PARTITION_KEY_VALS表结构：

  | 元数据表字段 |     说明     |  示例数据  |
  | :----------: | :----------: | :--------: |
  |   PART_ID    |    分区ID    |     1      |
  | PART_KEY_VAL |  分区字段值  | 2020-09-03 |
  | INTEGER_IDX  | 分区字段顺序 |     0      |

  ![](http://typora-image.test.upcdn.net/images/20200904212542.jpg)

- PARTITION_PARAMS表结构：

  | 元数据表字段 |    说明    | 示例数据 |
  | :----------: | :--------: | :------: |
  |   PART_ID    |   分区ID   |    1     |
  |  PARAM_KEY   | 分区属性名 | numFiles |
  | PARAM_VALUE  | 分区属性值 |    1     |

  ![](http://typora-image.test.upcdn.net/images/20200904213541.jpg)

##### 7. 其他不常用的元数据表

- IDXS：索引表；
- INDEX_PARAMS：索引参数/属性表；
- TAB_COL_STATS：表字段的统计信息表。使用ANALYZE语句对标字段分析后记录在这里；
- TAB_COL_PRIVS：表字段的授权信息表；
- PART_PRIVS：分区授权信息表；
- PART_COL_STATS：分区字段的统计信息表；
- PART_COL_PRIVS：分区字段的权限信息表；
- FUNCS：用户注册的函数信息表；
- FUNCS_RU：用户注册函数的资源信息表。