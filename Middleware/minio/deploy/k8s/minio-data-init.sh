mc alias set minio http://tsingyun-minio-svc:9000 tsingyun 'xxxxxx'
mc admin user add minio LCfz7gXVnNjvjEDq2qez jj6r9Hu2gtueIQFSV35FzKcvGtK1G61d9ieNmKDg
mc admin policy attach minio readwrite --user LCfz7gXVnNjvjEDq2qez
