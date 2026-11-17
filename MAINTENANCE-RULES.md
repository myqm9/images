# TDP 维护规则

本文件记录 `tsingyun-images` 仓库的日常维护规则：改哪些文件、按什么格式、注意什么边界。

- 产品需求与架构见 [`docs/plans/tsingyun-images-docs-prd.md`](./docs/plans/tsingyun-images-docs-prd.md)。
- 本文面向发版与文档维护人员，按场景分章；新增规则时追加章节，不要拆成多个零散说明文件。

典型发版顺序：**先完成镜像升级与文档同步（第 1 章）**，再更新站点版本与 Changelog（第 2 章）。

## 目录

1. [升级镜像版本并同步站点文档](#1-升级镜像版本并同步站点文档)（主体待补充；[1.1](#11-详情页镜像地址已知边界) 已记边界）
2. [更新站点版本与 Changelog](#2-更新站点版本与-changelog)
3. [文档站布局自适应](#3-文档站布局自适应)

---

## 1. 升级镜像版本并同步站点文档

> **状态：待补充**  
> 本章将说明：升级某个 Middleware 镜像后，如何改 `README.md`、同步 `release.json`、更新 `astro/docs/` 中的部署文档，以及何时改 `catalog.status`、多版本组件如何增删版本页。

暂按 PRD 查阅以下章节，具体操作步骤后续写入本章：

| 主题 | PRD 章节 |
| --- | --- |
| README → release.json 字段与 sync 规则 | [3.1](./docs/plans/tsingyun-images-docs-prd.md#31-readme--releasejson哪些会自动变) |
| 命令：`sync:releases` / `dev` / `build` | [3.3](./docs/plans/tsingyun-images-docs-prd.md#33-命令与自动化脚本) |
| 多版本组件文档命名与路由 | [4.3](./docs/plans/tsingyun-images-docs-prd.md#43-组件镜像多版本) |
| 文档配图规范 | [2.1](./docs/plans/tsingyun-images-docs-prd.md#21-文档配图规范) |

**预期维护链路（草案，待细化）：**

```text
升级镜像 / 改端口 / 改说明
        ↓
README.md（业务依据）
        ↓  npm run sync:releases（dev/build 会自动跑）
release.json
        ↓
astro/docs/middleware/…（部署说明，人工维护）
        ↓  Astro 构建
站点汇总表 + 详情页镜像变量
        ↓
VERSION.md（第 2 章：记录本次 TDP 发布版本与 Changelog）
```

补充本章时，请写明：检查清单、常见组件差异（Apollo 多镜像、MySQL 多版本等），以及镜像变更应如何在 `VERSION.md` Changelog 中表述（例如 `构建(redis): …`）。

### 1.1 详情页镜像地址（已知边界）

详情页编译时由 `astro/src/plugins/replace-image-references.mjs` 处理两类替换：

1. `{{ image.amd64.reference }}` / `{{ image.arm64.reference }}` → 绑定**当前这篇**对应版本的镜像。
2. 正文里写死的 `harbor.tsingyun.net/...` 地址 → 仅当该地址出现在**本组件** `release.json` 历史镜像列表中时，才改写成当前版本（用于文档里旧 tag 跟着发版走）。

**同仓库不同 tag 不要被误改**：例如 InfluxDB 3 页上的 `influxdb:influxdb3-ui-1.6.3` 与 `influxdb:3.9.0` 仓库名同为 `influxdb`，但 UI 镜像属于另一条 catalog（`influxdb3-ui`）。二次替换**不会**、也**不应**把 UI tag 改成当前 InfluxDB 版本。附带组件镜像（如 `kafka-map`、`influxdb3-ui`、Nginx 代理）在详情页用完整 Harbor 地址硬编码即可；仓库名不同的（如 `kafka-map`）本来就不会撞车。

从交付手册迁文档时：密码、Token、真实 IP 换成占位符；手册截图按 PRD [2.1](./docs/plans/tsingyun-images-docs-prd.md#21-文档配图规范) 落到 `astro/public/images/`，禁止语雀外链。

---

## 2. 更新站点版本与 Changelog

### 2.1 适用范围

TDP 文档站的**当前版本号**与**更新日志**，唯一维护文件：根目录 [`VERSION.md`](./VERSION.md)。

构建时由 `astro/src/lib/version.mjs` 读取并渲染到：

- 首页 Hero 区版本展示（链接到 `/changelog/`）
- 更新日志页 `/changelog/`

发版时**无需**改 `astro/docs/index.md`、Hero 组件或其它页面的硬编码版本。

**建议在完成 [第 1 章](#1-升级镜像版本并同步站点文档) 镜像与文档更新后再改本章**，使 Changelog 能完整反映本次交付内容。

### 2.2 操作步骤

1. 打开根目录 `VERSION.md`。
2. 将 `latest_version` 改为本次发布的版本号。
3. 在 `# Changelog` 下追加一条新记录（日期 + 版本号 + 变更列表）。
4. 保存后重新构建或刷新开发服务器（`npm run dev` / `npm run build`）。
5. 打开首页与 `/changelog/`，确认版本号、条目数量、最近更新日期正确。

### 2.3 文件格式

**当前版本（必填）**

```markdown
# 版本
latest_version=v2.1.2
```

- 字段名固定为 `latest_version`。
- 等号两侧可不加空格。
- 版本号建议统一带 `v` 前缀，例如 `v2.1.2`。
- 该值即站点「当前版本」，并与 Changelog 里标记为「当前」的那条记录对应（大小写不敏感）。

**变更记录（每条一次发布）**

```markdown
# Changelog
> 2026-08-20 v2.1.2
``` bash
1、简要说明第一条变更
2、简要说明第二条变更
```
```

引用行格式：

```text
> YYYY-MM-DD <版本号>
```

- 日期格式：`YYYY-MM-DD`。
- 版本号紧跟日期，中间一个空格。
- 同一天多次发布时，**每条发布单独写一个引用行 + 代码块**，不要合并。

变更列表：

- 紧跟引用行之后，使用 Markdown 围栏代码块（语言标记 `bash` 或留空均可）。
- 每行一条变更，推荐 `1、……` 或 `1. ……`。
- 空行忽略；只有序号、没有正文的行会被自动过滤。

**完整示例**

```markdown
# 版本
latest_version=v2.1.2


# Changelog
> 2026-08-20 v2.1.2
``` bash
1、升级 Redis 至 8.10.1
2、补充 Nacos 部署说明
```

> 2026-08-18 v2.1.0
``` bash
1、增加 Astro 在线文档功能
```
```

### 2.4 页面展示规则

| 位置 | 数据来源 | 说明 |
| --- | --- | --- |
| 首页「版本」 | `latest_version` | 点击跳转到 `/changelog/` |
| 更新日志顶部「当前版本」 | `latest_version` | 与首页一致 |
| 「已记录批次」 | Changelog 条目数 | 每个 `> 日期 版本` 块计 1 条 |
| 「最近更新」 | 最新一条记录的日期 | 按日期倒序；同日期按文件顺序靠后的优先 |
| 时间线列表 | 全部 Changelog 块 | 新 → 旧；与 `latest_version` 匹配者显示「当前」 |

### 2.5 注意事项

**必须遵守**

1. **只改 `VERSION.md`**：不要把版本号或变更说明写进 Astro 页面 frontmatter。
2. **`latest_version` 与最新 Changelog 一致**：顶部当前版本应与最近一次发布的版本号相同。
3. **每条发布独立成块**：一次发布 = 一行 `> 日期 版本` + 一个代码块。
4. **变更说明写人话**：一句话说清「做了什么」。
5. **构建后自检**：改完务必看首页和 `/changelog/`。

**格式常见错误**

| 错误写法 | 后果 |
| --- | --- |
| 使用旧字段 `tsingyun_images_version=` | 当前版本读不到 |
| 引用行只有日期、没有版本号 | 该条 Changelog 无法解析 |
| 代码块前缺少引用行 | 内容不会出现在站点 |
| 引用行与代码块之间插入其它内容 | 可能导致解析失败 |
| 变更条目留空（如 `7、` 后无文字） | 空条目被自动忽略 |

**安全规范**

不要在 `VERSION.md` 中记录：密码、令牌、私钥、真实服务器 IP、客户专属信息、CNB 构建 ID。

### 2.6 与镜像清单的边界

| 文件 | 用途 |
| --- | --- |
| `VERSION.md` | TDP 文档站 / 交付平台的版本与更新说明 |
| `README.md` | Middleware 镜像清单业务依据 → `release.json` |

- 升级中间件镜像：改 `README.md` 并同步文档（见 [第 1 章](#1-升级镜像版本并同步站点文档)）。
- 发布文档站版本：改 `VERSION.md`（本章）。

不要在 `VERSION.md` 里维护 Harbor 镜像地址；改 README 也不会自动更新 Changelog。

### 2.7 相关代码

| 路径 | 作用 |
| --- | --- |
| `VERSION.md` | 维护入口 |
| `astro/src/lib/version.mjs` | 解析 `VERSION.md` |
| `astro/src/components/Changelog.astro` | 渲染更新日志页 |
| `astro/src/components/Hero.astro` | 首页版本展示与链接 |
| `astro/docs/changelog.mdx` | 更新日志页面壳 |

修改 `VERSION.md` 结构时，须同步更新 `version.mjs` 与本章说明。

---

## 3. 文档站布局自适应

改 Astro / Starlight 页面样式时，按本章执行。参考实现：更新日志页 `/changelog/`（`Changelog.astro` + `custom.css` 中 `.changelog-*`）。

### 3.1 原则

1. **不要用写死像素撑整页布局**（如 `width: 1200px`）。宽度用相对单位，并设上限。
2. **窄屏优先改结构，不只改数字**：不够放就换行、单列、隐藏次要栏，而不是全部等比缩小。
3. **媒体查询按视口断点；内容区挤兑用流体布局**（`flex-wrap` / `minmax(0, 1fr)` / `min()`），因为侧栏 + TOC 存在时，内容宽度远小于视口宽度。
4. **表格等宽内容**：外层 `overflow-x: auto`，保留可读的 `min-width`，不要强行压进一屏。

### 3.2 必用写法

| 场景 | 写法 | 示例 |
| --- | --- | --- |
| 正文最大宽度 | `min(理想宽度, 剩余视口)` | `min(56rem, calc(100vw - var(--sl-sidebar-width) - 2.5rem))` |
| 字体 / 间距随屏缩放 | `clamp(最小, 优选, 最大)` | `font-size: clamp(2rem, 4.2vw + 1rem, 4rem)` |
| 两栏在窄内容区自动叠 | `flex` + `flex-wrap` + `flex: 1 1 <min>` | 更新日志 intro：文案 `1 1 18rem`，统计区 `width: max-content` |
| 子项防撑破 | `min-width: 0` + `overflow-wrap` | Flex/Grid 子项与长文本 |
| 图片 | `max-width: 100%; height: auto` | Hero、文档截图 |
| 无用的右侧 TOC | frontmatter `tableOfContents: false` | 更新日志、纯组件页 |
| 嵌入 MDX 的自定义块 | 根节点加 `not-content` | 避免 Starlight 给相邻块加 `margin-top` 导致错位 |

**推荐模式（头部信息区）**

```css
.block {
  display: flex;
  flex-wrap: wrap;
  gap: clamp(1.25rem, 3vw, 2.5rem);
  align-items: end;
}
.block__copy { flex: 1 1 18rem; min-width: 0; }
.block__aside { flex: 0 1 auto; width: max-content; max-width: 100%; }
```

宽屏并排，内容区不够时自动换行，不依赖「视口刚好等于内容宽」的媒体查询。

**统计 / 指标卡**

- 每个 item 含 label + value；外层 `display: flex; align-items: flex-start`，保证多列顶对齐。
- 嵌入 `sl-markdown-content` 时，根节点必须带 **`not-content`**（见 3.3），否则 Starlight 会对相邻块级子元素加 `margin-top`，表现为「第一列高、后面列被顶下去」。
- `dt` / `dd` / 自定义 `div` 的默认 margin 要清零（Starlight `markdown.css` 会对 `dt + dd` 等加间距）。
- 极窄屏（如 `max-width: 30rem`）改为单列，或每行左右 label/value。

**汇总表（`/middleware/` catalog）**

- 外层 `.catalog-table-wrap` 已 `overflow-x: auto`，表 `min-width` 保底可读。
- **组件列**不要写死过窄宽度 + `white-space: nowrap`：长名（如 `vmware_exporter`）会溢出盖住「版本」列。应给足宽度，并允许 `overflow-wrap` / 换行。
- 中间件与运维工具是**同一套** `renderRows`，仅按 `catalog.section === 'ops'` 分表；`pending` 组件名不可点，不是两套逻辑。

### 3.3 与 Starlight 布局的配合

本站 CSS 变量（`astro/src/styles/custom.css`）：

| 变量 | 用途 |
| --- | --- |
| `--sl-sidebar-width` | 左侧栏 |
| `--tdp-toc-width` | 右侧本页导航 |
| `--sl-content-width` | 正文内容区宽度 |

规则：

1. **有侧栏 + 有 TOC**：正文宽度用 `min(90rem, calc(100vw - 侧栏 - TOC - 边距))`，吃满两栏之间剩余空间，避免笔记本屏挤爆、超宽屏中间留白。正文须**贴左侧栏**（`--sl-content-margin-inline: 0`），禁止 `auto 0`——会把正文顶向右侧 TOC，侧栏与正文之间出现大块空白。
2. **有侧栏、无 TOC**（或页面关闭 TOC）：正文可放宽，吃满侧栏右侧剩余宽度。
3. **页面自带大标题**（如 `catalog-intro` / `changelog-intro`）：视觉隐藏 Starlight `.tdp-page-title`，但保留 `#_top` 锚点，不要出现两个可见 H1。自定义 intro / 统计等块加 **`not-content`**，避免被 `starlight.content` 的相邻元素间距规则打乱对齐。
4. **详情页保留 TOC**：部署/组件详情等有二级标题的页面不要关 `tableOfContents`；几乎无二级标题的汇总页（首页、Changelog）可关。
5. **断点约定**（与现有 CSS 对齐，新增时优先复用）：

| 断点 | 用途 |
| --- | --- |
| `~30rem` | 极窄：统计卡单列等 |
| `~50–52rem` | 手机 / 小平板：多列改单列 |
| `64rem` | 启用右侧 TOC 固定栏（本站早于 Starlight 默认） |
| `78rem` | 超宽：Hero 等大屏排版 |

### 3.4 新做 / 改版页面检查清单

1. 用 DevTools 设备模式检查：**1280、1440、1920** 宽度（必要时再加 1024）。
2. 确认无整页横向滚动条（表格区域内部横滑除外）。
3. 侧栏 + TOC + 正文三栏同时出现时，正文仍可读、不重叠。
4. 长镜像地址、长中文句、版本号等可换行，不被 `nowrap` 撑破。
5. 图片不溢出内容区。
6. 若本页几乎无二级标题，关闭 `tableOfContents`，把宽度留给正文。

### 3.5 禁止事项

| 禁止 | 原因 |
| --- | --- |
| 整页 / 主栏写死 `width: NNpx` | 换分辨率立刻乱版 |
| 仅用 JS 按 `window.innerWidth` 改布局 | 与 CSS 流体布局重复且难维护 |
| 统计数字、日期强制 `white-space: nowrap` 且父级过窄 | 窄内容区溢出；统计区用 `max-width: 100%` 兜底 |
| 为「塞进一屏」把宽表格字体缩到不可读 | 应横滑，不牺牲可读性 |
| 忽略 Flex/Grid 子项 `min-width: 0` | 常见莫名横向溢出原因 |
| 汇总表组件列 `nowrap` + 过窄 `width` | 长组件名溢出叠到下一列 |
| 自定义组件不加 `not-content` 又横排多列 | Starlight 给第 2 列起加 `margin-top`，列不对齐 |

### 3.6 相关路径

| 路径 | 作用 |
| --- | --- |
| `astro/src/styles/custom.css` | 站点自适应与版式主样式 |
| `astro/src/components/Changelog.astro` | 自适应参考实现（流体 intro + 统计卡 + 时间线；`not-content`） |
| `astro/docs/changelog.mdx` | 关闭 TOC 等页面壳配置 |
| `astro/src/plugins/replace-image-references.mjs` | 详情页变量 / Harbor 二次替换；汇总表渲染 |
| `.cursor/rules/astro-responsive-layout.mdc` | 供 Cursor 在改 Astro 样式时自动套用本章 |

修改全局断点或 `--sl-*` 宽度策略时，须同步更新本章与 Cursor 规则。
