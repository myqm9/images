#!/bin/sh

#因为fastdfs需要使用主机网络通讯，所以必须指定主机地址,主机地址在docker 运行参数中指定，FASTDFS_IPADDR: "xx.xx.xx.xx"
# 另外,/conf/storage.conf 和  /etc/fdfs/tracker.conf 中已经指明了fastdfs 的工作路径在/home/dfs/ 下；只需要做好容器的数据卷挂载即可

new_val=$FASTDFS_IPADDR
old="fastdfs.tracker.server.dddd"

sed -i "s/$old/$new_val/g" /etc/fdfs/storage.conf





# 启用参数
# - tracker : 启动tracker_server 服务
# - storage : 启动storage 服务
start_parameter=$1


function start_tracker(){
  echo "启动 tracker..."
  /usr/bin/fdfs_trackerd /etc/fdfs/tracker.conf
  # 这里我们使用 sleep 来等待一段时间，确保 trackerd 有足够的时间启动
  # 根据您的系统和配置，您可能需要调整这个等待时间
  sleep 10 
  echo "Tracker 启动完成."
}

function start_storage(){
  echo "启动 storage..."
  /usr/bin/fdfs_storaged /etc/fdfs/storage.conf
  echo "Storage 启动完成."
}

function run (){
  start_tracker
  start_storage
  tail -f  /dev/null
}

run
