---
title: 部署前准备
draft: false
description: 在拉取和部署组件镜像前完成基础环境检查。
---

# 部署前准备

部署前准备为所有 Middleware 与 SRE 组件提供一致的运行基线。请先完成系统初始化和 Docker 环境确认，再进入具体组件页面。

<div class="portal-grid">
  <a class="portal-card" href="/prerequisites/system-initialization/"><strong>系统初始化配置</strong><span>时区、时间同步、资源限制、磁盘与基础工具。</span></a>
  <a class="portal-card" href="/prerequisites/docker/"><strong>Docker 与 Compose</strong><span>运行时安装、镜像仓库连通性与基础验证。</span></a>
</div>

## 最小检查清单

1. 确认目标主机的 CPU 架构、磁盘容量和内存满足组件要求。
2. 确认与 Harbor、NTP/DNS 和所需服务端口的网络连通性。
3. 以最小权限账号执行部署，并准备持久化数据目录与备份策略。
