1、创建目录
mkdir -p /home/application/Database/mysql/{data,etc,init}

2、上传并修改配置文件
vim /home/application/Database/mysql/etc/my.cnf


3、上传sql初始化文件到/home/application/Database/mysql/init  目录下 ，注意 需要渲染SQL！！！


4、运行
docker run -d \
  --name mysql \
  -v /home/application/Database/mysql/data:/var/lib/mysql \
  -v /home/application/Database/mysql/etc:/etc/mysql/conf.d \
  -v /home/application/Database/mysql/init:/docker-entrypoint-initdb.d \
  -e MYSQL_ROOT_PASSWORD='xxxx' \
  -e TZ='Asia/Shanghai' \
  -p 3306:3306 \
  --restart=always \
  dockerhub.qingcloud.com/tsingyun_database/mysql:5.7.44 \
  --default-authentication-plugin=mysql_native_password \
  --explicit_defaults_for_timestamp=true \
  --character_set_server=utf8 \
  --collation-server=utf8_general_ci \
  --log-error=/var/lib/mysql/mysql_error.log
