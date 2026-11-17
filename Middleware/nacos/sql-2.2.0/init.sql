#创建数据库
CREATE DATABASE nacos CHARACTER SET utf8 COLLATE utf8_general_ci;


#创建nacos用户/密码
create user nacos@'%' IDENTIFIED by 'xxx';
grant all on nacos.* to nacos@'%';


#创建业务JDBC用户/密码
create user tsingyun@'%' IDENTIFIED by 'xxx';
grant all on *.* to tsingyun@'%';
