#!/bin/bash
# 开启kafka集群
ssh yangqi@xiaoer > /dev/null 2>&1 << eeooff
cd /opt/apps/kafka_2.11-2.3.1
nohup ./bin/kafka-server-start.sh ./config/server.properties >/dev/null 2>&1 &
exit
eeooff
echo xiaoer:kafka done!

ssh yangqi@yangqi1 > /dev/null 2>&1 << eeooff
cd /opt/apps/kafka_2.11-2.3.1
nohup ./bin/kafka-server-start.sh ./config/server.properties >/dev/null 2>&1 &
exit
eeooff
echo yangqi1:kafka done!

ssh yangqi@yangqi2 > /dev/null 2>&1 << eeooff
cd /opt/apps/kafka_2.11-2.3.1
nohup ./bin/kafka-server-start.sh ./config/server.properties >/dev/null 2>&1 &
exit
eeooff
echo yangqi2:kafka done!