#创建数据库
CREATE DATABASE nacos CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;


#创建nacos用户/密码；需要指定mysql_native_password密码插件
create user nacos@'%' IDENTIFIED WITH 'mysql_native_password' BY 'xxxx';
grant all on nacos.* to nacos@'%';


#创建业务JDBC用户/密码
create user tsingyun@'%' IDENTIFIED by 'xxxx';
grant all on *.* to tsingyun@'%';