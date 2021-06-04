#### Hadoop集群搭建之CentOS7系统配置

##### 1. 准备工作

准备三台已经安装了CentOS7系统的虚拟机，分别是`master`，`slave1`，`slave2`。

三台虚拟机配置如下(以下配置只做参考，如果自己的电脑不允许的情况下，也可以适当的调整)：

| 主机名称 |     机器配置      | 存储容量 |  用户  |
| :------: | :---------------: | :------: | :----: |
|  master  | 4G内存，2核，2CPU |   50G    | hadoop |
|  slave1  | 1G内存，1核，1CPU |   50G    | hadoop |
|  slave2  | 1G内存，1核，1CPU |   50G    | hadoop |

##### 2. 配置`sudo`权限

三台都需要配置`hadoop`用户的`sudo`权限，否则之后使用`hadoop`用户时可能会出现的权限问题，无法解决。(三台配置方法相同)

```
1. 刚刚重启虚拟机之后，首先使用root账户登录，然后执行visudo命令
2. 进入vi编辑器之后，使用命令[:set nu]可以显示行号
3. 在第100行之后新插入一行内容[hadoop	ALL=(ALL)	ALL]
4. 之后在第111行后插入一行内容[hadoop	ALL=(ALL)	NOPASSWD: ALL]
5. 之后保存并切换到hadoop用户
```

![](http://typora-image.test.upcdn.net/images/20200809154733.jpg)

##### 3. 修改IP地址

查看自己虚拟机的`VMnet8`(也就是NAT模式)的网卡的地址，设置三台虚拟机的网络IP在同一个网段内，并且都是静态IP地址。

| 主机名称 |     IP地址     |
| :------: | :------------: |
|  master  | 192.168.21.210 |
|  slave1  | 192.168.21.211 |
|  slave2  | 192.168.21.212 |

```
1. 使用sudo权限编辑[/etc/sysconfig/network-scripts/ifcfg-ens33]文件，修改如下：
	TYPE=Ethernet
	PROXY_METHOD=none
	BROWSER_ONLY=no
	BOOTPROTO=static[修改]
	DEFROUTE=yes
	IPV4_FAILURE_FATAL=no
	IPV6INIT=yes
	IPV6_AUTOCONF=yes
	IPV6_DEFROUTE=yes
	IPV6_FAILURE_FATAL=no
	IPV6_ADDR_GEN_MODE=stable-privacy
	NAME=ens33
	UUID=4a123d67-9c45-43c9-b7fa-b26c245a5446
	DEVICE=ens33
	ONBOOT=yes[修改]
	GATEWAY=192.168.21.2[新增]
	IPADDR=192.168.21.210[新增]
	NETMASK=255.255.255.0[新增]
	DNS1=8.8.8.8[新增]
	DNS2=114.114.114.114[新增]
2. 保存后重新启动网络服务[sudo systemctl restart network]
3. 使用[ip addr]查看IP地址，是否已经修改成功
4. 使用[ping www.baidu.com]测试外网是否可以访问
```

##### 4. 添加主机名映射

```
使用sudo权限编辑[/etc/hosts]文件，修改如下：
	192.168.21.210	master
	192.168.21.211	slave1
	192.168.21.212	slave2
```

##### 5. 配置各个机器之间的免密登录

```
1. 使用[ssh-keygen -t rsa]生成各个机器的私钥和公钥(需要在三台机器上执行)
2. 使用[ssh-copy-id username@hostname]即可将本地的公钥发送到另外一台机器(需要在三台机器上执行)
	ssh-copy-id hadoop@master
	ssh-copy-id hadoop@slave1
	ssh-copy-id hadoop@slave2
3. 之后在三台机器上使用[ssh localhost]，因为第一次使用需要输入(yes/no)，防止后面产生不必要的麻烦
```

##### 6. 关闭防火墙

```
使用[systemctl stop firewalld]关闭防火墙，使用[systemctl disable firewalld]让防火墙开机不自启
```

##### 7. 安装JDK

上传JDK的压缩包，上传到[/opt/software]目录下，解压到[/opt/apps]目录下，同时记得修改[/opt]目录的归属。

```
1. 修改[/opt]目录的所属用户组和用户[sudo chown -R hadoop:hadoop /opt]
2. 解压JDK的压缩包[tar -zvxf xxxx.tar.gz -C /opt/apps]
3. 配置环境变量（这里建议修改hadoop用户的用户变量，如果出错还可以使用root账户进行修改）
4. 修改[/home/hadoop/.bash_profile]文件，添加以下内容：
	JAVA_HOME=/opt/apps/jdk1.8.0_162
	PATH=$JAVA_HOME/bin:$PATH
	export JAVA_HOME PATH
5. 执行[source ~/.bash_profile]使环境变量生效
6. 使用[java -version]测试是否生效即可
7. 使用[scp]命令将jdk发送到其他两台服务器
```

