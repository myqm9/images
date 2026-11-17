---
title: 文档首页
draft: false
template: splash
tableOfContents: false
hero:
  title: '<span class="hero-brand">Tsingyun Delivery Platform</span><span class="hero-slogan">实施交付，<br />有章可循</span>'
  tagline: 组件镜像、部署说明与运维手册，由同一套发布信息驱动。
  image:
    html: '<img src="/images/tdp-full-architecture-transparent.png" alt="TDP 的服务器、中间件、容器与监控运维拓扑示意图" width="640" height="400" />'
  actions:
    - text: 从部署前准备开始
      link: /prerequisites/
      icon: right-arrow
      variant: primary
---

<section class="home-nav" aria-labelledby="home-nav-title">
  <div class="home-nav__aside">
    <h2 id="home-nav-title">文档入口</h2>
    <p>从环境准备到组件部署，按模块进入对应手册。</p>
  </div>
  <nav class="home-nav__list" aria-label="文档入口">
    <a class="home-nav__link home-nav__link--featured" href="/middleware/">
      <span class="home-nav__name">Middleware</span>
      <span class="home-nav__desc">缓存、数据库、消息与注册中心等中间件部署与验证</span>
      <span class="home-nav__go" aria-hidden="true">→</span>
    </a>
    <a class="home-nav__link" href="/prerequisites/">
      <span class="home-nav__name">部署前准备</span>
      <span class="home-nav__desc">系统初始化、Docker、Compose、镜像仓库与网络检查</span>
      <span class="home-nav__go" aria-hidden="true">→</span>
    </a>
    <a class="home-nav__link" href="/sre/">
      <span class="home-nav__name">SRE</span>
      <span class="home-nav__desc">监控、日志、网络与 Kubernetes 运维组件交付</span>
      <span class="home-nav__go" aria-hidden="true">→</span>
    </a>
    <a class="home-nav__link" href="/middleware/">
      <span class="home-nav__name">版本交付</span>
      <span class="home-nav__desc">查看已发布组件的镜像地址、端口与部署说明</span>
      <span class="home-nav__go" aria-hidden="true">→</span>
    </a>
  </nav>
</section>

## 使用约定

- **发布元数据为唯一事实来源**：站点所呈现的镜像清单、提交标识与发布时间，均源自 CNB 流水线成功构建后产出的发布元数据，确保展示内容与交付制品一致、可追溯。
- **单一内容源，统一渲染输出**：部署与安装说明以 Markdown 为载体，经统一渲染管线生成在线文档，避免版本分叉。
- **信息安全边界**：文档正文严禁收录密码、访问令牌、私钥、生产环境 IP 及任何客户侧专属信息；示例一律采用占位符表达。
