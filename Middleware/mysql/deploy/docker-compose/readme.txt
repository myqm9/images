1、创建目录
mkdir -p /home/application/Database/mysql/{data,etc,init}

2、上传并修改配置文件
vim /home/application/Database/mysql/etc/my.cnf


3、上传sql初始化文件到/home/application/Database/mysql/init  目录下 ，注意 需要渲染SQL！！！
create-user.sql
tsingyun-apollo-2.1.0.sql
tsingyun-baseline-init.sql

4、运行
docker-compose up -d
