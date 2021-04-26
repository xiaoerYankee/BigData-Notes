#### CentOS7安装MySQL5.7

##### 1. 配置yum源

在 https://dev.mysql.com/downloads/repo/yum/ 找到yum源的安装包

![](http://typora-image.test.upcdn.net/images/20200809154415.png)

点击Download，右边复制链接地址

![](http://typora-image.test.upcdn.net/images/20200809154457.png)

可以使用wget或者curl下载

##### 2. 安装yum源

```shell
# 下载
[yangqi@xiaoer ~]$ wget https://dev.mysql.com/get/mysql57-community-release-el7-11.noarch.rpm
# 安装mysql的yum源
[yangqi@xiaoer ~]$ sudo yum install mysql57-community-release-el7-11.noarch.rpm
```

检查是否安装成功

```shell
[yangqi@xiaoer ~]$ yum repolist enabled | grep "mysql.*-community.*"
```

![](http://typora-image.test.upcdn.net/images/20200809155023.png)

##### 3. 安装MySQL

使用yum install命令安装

```shell
[yangqi@xiaoer ~]$ sudo yum install -y mysql-community-server
```

注意：最好在网络环境好的地方下进行，不然会很慢

##### 4. 启动MySQL服务

因为只有启动了MySQL服务，才会产生/var/log/mysqld.log文件，初始root密码在这个文件目录下。启动mysql服务（在CentOS7下，启动和关闭服务的命令是systemctl start|stop）

```shell
[yangqi@xiaoer ~]$ sudo systemctl start mysqld
```

> 查看mysql服务的启动状态，如下图显示则表示已经开启

```shell
[yangqi@xiaoer ~]$ systemctl status mysqld
```

![](http://typora-image.test.upcdn.net/images/20200809155020.png)

##### 5. 查看mysql的初始密码

```shell
# 如果没有找到密码，也有可能是初始密码为空，直接登录即可
[yangqi@xiaoer ~]$ sudo cat /var/log/mysqld.log | grep password
```

![](http://typora-image.test.upcdn.net/images/20200809155017.png)

##### 6. 登录mysql，修改密码

登录mysql

```shell
[yangqi@xiaoer ~]$ mysql -uroot -poggwtYaws4?6
```

修改密码

```mysql
mysql> alter user 'root'@'localhost' identified by 'xiaoer';
```

```mysql
# 方法二
mysql> set password for root@localhost = password('xiaoer');
```

一般会提示有一个错误，这是因为mysql5.6.6之后增加了密码强度验证插件validate_password，相关参数的设置比较严格。先解决密码强度的验证问题，因为只是自己测试，只想使用简单的密码。但是在修改参数配置之前，需要先重置密码（大小写和特殊字符都要有）

```mysql
step1：修改mysql密码
mysql> alter user 'root'@'localhost' identified by 'ijifjWfs21@#$';

step2：查看mysql全局配置参数
mysql> select @@validate_password_policy;
mysql> show variables like 'validate_password%';
```

![](http://typora-image.test.upcdn.net/images/20200809155014.png)

```mysql
参数：
	# 插件用于验证用户名
	validate_password_check_user_name
	
	# 插件用于验证密码强度的字典文件路径
	validate_password_dictionary_file

	# 密码最小长度，参数默认为8，它有最小值的限制，最小值为：validate_password_number_count + validate_password_special_char_count + (2 * validate_password_mixed_case_count)
	validate_password_length

	# 密码至少要包含的小写字母个数和大写字母个数
	validate_password_mixed_case_count

	# 密码至少要包含的数字个数
	validate_password_number_count

	# 密码强度检查等级，0/LOW、1/MEDIUM、2/STRONG。默认是1
	# 0 or LOW		Length
	# 1 or MEDIUM   Length; numeric, lowercase/uppercase, and special characters
	# 2 or STRONG   Length; numeric, lowercase/uppercase, and special characters; dictionary file
	validate_password_policy

	# 密码至少要包含的特殊字符数
	validate_password_special_char_count
```

修改mysql参数配置（根据自己密码的习惯进行自定义配置）

```mysql
mysql> set global validate_password_policy=0;
mysql> set global validate_password_mixed_case_count=0;
mysql> set global validate_password_number_count=0;
mysql> set global validate_password_special_char_count=0;
mysql> set global validate_password_length=6;
mysql> show variables like 'validate_password%';
```

![](http://typora-image.test.upcdn.net/images/20200809155009.png)

现在可以修改密码了

```shell
mysql> alter user 'root'@'localhost' identified by 'abcdef';
```

将mysql服务设置为开机自启

```shell
[yangqi@xiaoer ~]$ systemctl enable mysqld
```

