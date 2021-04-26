#### Hadoop-HA集群启动脚本

##### 1. 添加函数到环境变量中

```sh
# 判断一个进程是否存在的函数
processExist() {
    isExist=$(ps -ef | grep -w $1 | grep -v grep | wc -l)
    if [ ${isExist} -ne 0 ] && [ $2 -eq 0 ];then
        echo "[${HOSTNAME}_${time}] 进程 $1 已经存在，不需要重新启动"
    elif [ ${isExist} -eq 0 ] && [ $2 -eq 0 ];then
        echo "[${HOSTNAME}_${time}] 进程 $1 尚未启动，请启动"
    elif [ ${isExist} -eq 0 ] && [ $2 -eq 1 ];then
        echo "[${HOSTNAME}_${time}] 进程 $1 启动失败，请手动重启"
    elif [ ${isExist} -ne 0 ] && [ $2 -eq 1 ];then
        echo "[${HOSTNAME}_${time}] 进程 $1 启动成功"
    fi
    return ${isExist}
}
```

##### 2. Hadoop-HA启动脚本

```sh
#!/bin/bash
######################################################
#
#   脚本作用：启动 hadoop HA 集群及其相关组件
#   脚本参数：参数为空时：启动 zookeeper，dfs集群
#            可用参数：all-启动所有服务
#					yarn resourcemanager jobhistoryserver metastore hbase zeppelin presto
#
######################################################

echo "欢迎使用 hadoop-HA启动脚本"
echo "脚本参数：all-启动所有服务"
echo "脚本参数：yarn resourcemanager jobhistoryserver metastore hbase zeppelin presto"
echo "请根据自己的需要启动相应的服务"

# 执行日期
date=$(date "+%Y%m%d")
time=$(date "+%Y-%m-%d %H:%M:%S")

# 配置时间同步保证集群工作在同一时间
echo "[${HOSTNAME}_${time}] 正在同步集群服务器时间，请稍等......"
ssh -T hadoop@master "sudo ntpdate -u time.pool.aliyun.com"
ssh -T hadoop@slave1 "sudo ntpdate -u time.pool.aliyun.com"
ssh -T hadoop@slave2 "sudo ntpdate -u time.pool.aliyun.com"
echo "[${HOSTNAME}_${time}] 集群服务器时间同步完成"

# 启动 zookeeper 集群
# 启动 master 上的 zookeeper 服务
echo "[${HOSTNAME}_${time}] 正在启动 zookeeper 集群，请稍等......"
ssh -T hadoop@master >/home/hadoop/log/hadoop_start_${date}.log 2>&1 << eeooff
    if processExist QuorumPeerMain 0 ;then
        echo "进程 QuorumPeerMain 正在启动，请稍等......"
        /opt/apps/zookeeper-3.6.1/bin/zkServer.sh start
        processExist QuorumPeerMain 1
    fi
    exit
eeooff
# 启动 slave1 上的 zookeeper 服务
ssh -T hadoop@slave1 >>/home/hadoop/log/hadoop_start_${date}.log 2>&1 << eeooff
    if processExist QuorumPeerMain 0 ;then
        echo "进程 QuorumPeerMain 正在启动，请稍等......"
        /opt/apps/zookeeper-3.6.1/bin/zkServer.sh start
        processExist QuorumPeerMain 1
    fi
    exit
eeooff
# 启动 slave2 上的 zookeeper 服务
ssh -T hadoop@slave2 >>/home/hadoop/log/hadoop_start_${date}.log 2>&1 << eeooff
    if processExist QuorumPeerMain 0 ;then
        echo "进程 QuorumPeerMain 正在启动，请稍等......"
        /opt/apps/zookeeper-3.6.1/bin/zkServer.sh start
        processExist QuorumPeerMain 1
    fi
    exit
eeooff
echo "[${HOSTNAME}_${time}] zookeeper 集群启动完成"

# 启动 hadoop 集群
echo "[${HOSTNAME}_${time}] 正在启动 hdfs 集群，请稍等......"
ssh -T hadoop@master >>/home/hadoop/log/hadoop_start_${date}.log 2>&1 << eeooff
    /opt/apps/hadoop-2.7.7/sbin/start-dfs.sh
    exit
eeooff
echo "[${HOSTNAME}_${time}] hdfs 集群启动完成"

# 脚本参数
if [ $# -ne 0 ] && [ $1 == 'all' ];then
    PARAMS=(yarn resourcemanager jobhistoryserver metastore hiveserver2 hbase zeppelin presto)
else
    PARAMS=$@
fi

# 以下操作均在参数列表中进行
for arg in ${PARAMS[@]}
do
    # 启动 yarn
    if [ ${arg} == 'yarn' ];then
        echo "[${HOSTNAME}_${time}] 正在启动 yarn 集群，请稍等......"
        ssh -T hadoop@master >>/home/hadoop/log/hadoop_start_${date}.log 2>&1 << eeooff
            /opt/apps/hadoop-2.7.7/sbin/start-yarn.sh
            exit
eeooff
        echo "[${HOSTNAME}_${time}] yarn 集群启动完成"
    fi

    # 启动 resourcemanager HA
    if [ ${arg} == 'resourcemanager' ];then
        echo "[${HOSTNAME}_${time}] 正在启动 resourcemanager 服务，请稍等......"
        ssh -T hadoop@slave1 >>/home/hadoop/log/hadoop_start_${date}.log 2>&1 << eeooff
            if processExist ResourceManager 0 ;then
                echo "进程 ResourceManager 正在启动，请稍等......"
                /opt/apps/hadoop-2.7.7/sbin/yarn-daemon.sh start resourcemanager
                processExist ResourceManager 1
            fi
            exit
eeooff
        echo "[${HOSTNAME}_${time}] resourcemanager 服务启动完成"
    fi

    # 启动 jobhistoryserver
    if [ ${arg} == 'jobhistoryserver' ];then
        echo "[${HOSTNAME}_${time}] 正在启动 jobhistoryserver 服务，请稍等......"
        ssh -T hadoop@master >>/home/hadoop/log/hadoop_start_${date}.log 2>&1 << eeooff
            if processExist JobHistoryServer 0 ;then
                echo "进程 JobHistoryServer 正在启动，请稍等......"
                /opt/apps/hadoop-2.7.7/sbin/mr-jobhistory-daemon.sh start historyserver
                processExist JobHistoryServer 1
            fi
            exit
eeooff
        echo "[${HOSTNAME}_${time}] jobhistoryserver 服务启动完成"
    fi

    # 启动 hive metastore 服务
    if [ ${arg} == 'metastore' ];then
        echo "[${HOSTNAME}_${time}] 正在启动 hive metastore 服务，请稍等......"
        ssh -T hadoop@master >>/home/hadoop/log/hadoop_start_${date}.log 2>&1 << eeooff
            if processExist metastore 0 ;then
                echo "进程 metastore 正在启动，请稍等......"
                /opt/apps/hive-2.3.7/bin/hive --service metastore >/dev/null 2>&1 &
                processExist metastore 1
            fi
            exit
eeooff
        echo "[${HOSTNAME}_${time}] hive metastore 服务启动完成"
    fi

    # 启动 HBase 集群
    if [ ${arg} == 'hbase' ];then
        echo "[${HOSTNAME}_${time}] 正在启动 hbase 集群，请稍等......"
        ssh -T hadoop@master >>/home/hadoop/log/hadoop_start_${date}.log 2>&1 << eeooff
            /opt/apps/hbase-1.5.0/bin/start-hbase.sh
            exit
eeooff
        echo "[${HOSTNAME}_${time}] hbase 集群启动完成"
    fi

    # 启动 zeppelin 服务
    if [ ${arg} == 'zeppelin' ];then
        echo "[${HOSTNAME}_${time}] 正在启动 zeppelin 服务，请稍等......"
        ssh -T hadoop@slave2 >>/home/hadoop/log/hadoop_start_${date}.log 2>&1 << eeooff
            if processExist ZeppelinServer 0 ;then
                echo "进程 ZeppelinServer 正在启动，请稍等......"
                /opt/apps/zeppelin-0.9.0/bin/zeppelin-daemon.sh start
                processExist ZeppelinServer 1
            fi
            exit
eeooff
        echo "[${HOSTNAME}_${time}] zeepelin 服务启动完成"
    fi

    # 启动 presto 服务
    if [ ${arg} == 'presto' ];then
        echo "[${HOSTNAME}_${time}] 正在启动 presto 集群，请稍等......"
        ssh -T hadoop@slave1 >>/home/hadoop/log/hadoop_start_${date}.log 2>&1 << eeooff
            if processExist PrestoServer 0 ;then
                echo "进程 PrestoServer 正在启动，请稍等......"
                /opt/apps/presto-server/bin/launcher start
                processExist PrestoServer 1
            fi
            exit
eeooff

        ssh -T hadoop@master >>/home/hadoop/log/hadoop_start_${date}.log 2>&1 << eeooff
            if processExist PrestoServer 0 ;then
                echo "进程 PrestoServer 正在启动，请稍等......"
                /opt/apps/presto-server/bin/launcher start
                processExist PrestoServer 1
            fi
            exit
eeooff

        ssh -T hadoop@slave2 >>/home/hadoop/log/hadoop_start_${date}.log 2>&1 << eeooff
            if processExist PrestoServer 0 ;then
                echo "进程 PrestoServer 正在启动，请稍等......"
                /opt/apps/presto-server/bin/launcher start
                processExist PrestoServer 1
            fi
            exit
eeooff
        echo "[${HOSTNAME}_${time}] presto 集群启动完成"
    fi
done
echo "hadoop-HA启动脚本执行完成"
```