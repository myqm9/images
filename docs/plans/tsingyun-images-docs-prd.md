# Tsingyun Delivery Platform（TDP）文档站 PRD 与实施现状

## 1. 目标与范围

在不改变现有 CNB 镜像构建、Dockerfile 和 Harbor 推送逻辑的前提下，为 `tsingyun-images` 建设 TDP 文档站。

- 面向 Middleware 组件的镜像清单、部署说明和交付前准备。
- 网站文档为唯一交付物，构建输出为静态 HTML。
- 镜像地址由统一 JSON 驱动；组件说明由人工维护 Markdown。
- CNB 只负责镜像构建与推送，**不回写文档**。镜像清单以 `README.md` 为业务依据，经 `sync:releases` 写入 `release.json`；文档站不读取 CNB 构建结果。

已确认不做：CNB 构建结果回写文档、离线 Markdown 下载包、明暗模式。

本期明确不包含：自动发布站点、SRE 组件文档、多语言站点，以及 Docusaurus 式的**整站文档版本树**（`/v1/`、`/v2/` 前缀）。组件镜像多版本（如 InfluxDB 2.9.1 / 3.9.0）属于本期新增需求，见 4.3。

## 2. 当前目录与数据边界

```text
README.md                                    # Middleware 镜像表格的原始业务依据
VERSION.md                                   # TDP 站点当前版本与更新日志（唯一维护入口）
MAINTENANCE-RULES.md                         # TDP 维护规则（Changelog、镜像升级与文档同步等）
docs/
  plans/
    tsingyun-images-docs-prd.md              # 本 PRD
astro/
  docs/                                      # 唯一的网站 Markdown 文档源
    middleware/<component>.md                # 单版本组件页面
    middleware/<component>/<version>.md      # 多版本组件：每个版本一篇
    middleware.md                            # 汇总页说明和目录占位标记
    changelog.mdx                            # 更新日志页（内容由 VERSION.md 构建时渲染）
    prerequisites/                           # 系统初始化、Docker 与 Compose
    404.md                                   # 自定义 404 页面
    sre.md                                   # SRE 占位入口
  src/
    content/docs -> ../../docs               # Starlight 文档源软链接
    data/releases/release.json               # 组件目录、镜像与展示元数据
    plugins/replace-image-references.mjs     # 编译时变量替换、目录表格生成
    lib/version.mjs                          # 构建时读取 VERSION.md（版本号与 Changelog）
    components/                              # Header、Hero、Footer、Changelog、目录与设置组件
    styles/custom.css                        # TDP 视觉样式
  public/images/                             # 全站本地配图，禁止外链
    tdp-logo.png
    tdp-full-architecture-transparent.png
    tdp-404-ops.png
    middleware/<component>/                  # 组件部署截图
  dist/                                      # 静态构建输出
```

规则：

1. `astro/docs/` 是唯一文档源；`astro/src/content/docs` 只是软链接，不维护第二份内容。
2. `astro/src/data/releases/release.json` 是镜像地址和组件目录展示信息的唯一来源。
3. `README.md` 是镜像清单的业务依据；`release.json` 由脚本自动生成/更新。字段哪些自动变、哪些手写，见 **3.1**。命令见 **3.3**。
4. URL 以组件为一级，默认文档保持两级；仅当同一组件有多个镜像版本时，非默认版本使用第三级路径。多版本时 md 文件名必须等于 `versions[].id`，见 4.3。
5. 不记录 CNB 构建 ID、提交信息、Token、密码、私钥、服务器 IP 或客户拓扑等敏感数据。
6. 文档配图只使用 `astro/public/images/` 下的本地文件；Markdown 引用站点根路径，禁止语雀 / CDN 外链。详见 2.1。
7. **站点版本与更新日志**只维护根目录 `VERSION.md`；构建时读取，不在 Astro frontmatter 或其它页面硬编码。操作规则见根目录 `MAINTENANCE-RULES.md` 第 2 章，渲染规则见 **3.5**。

### 2.1 文档配图规范

配图与 `release.json` 里的 `{{ image.amd64.reference }}` **不是一回事**：后者是 Harbor 容器镜像地址，构建时由插件替换；前者是页面截图和品牌图，必须事先落到 `public/`。

目录约定：

```text
astro/public/images/
  tdp-*.png                                  # 品牌与全站插画（Logo、首页拓扑、404）
  middleware/<component>/<step>.png          # 组件部署步骤截图
  sre/<component>/<step>.png                 # SRE 接入后再用，本期不建
```

引用约定：

```md
![Nacos 登录页](/images/middleware/nacos/login.png)
```

- 路径一律以 `/images/` 开头（对应 `astro/public/images/`），不要写 `./`、`../` 或 `astro/public/...`。
- 文件名用小写英文短横线，按步骤命名，例如 `login.png`、`auth-method.png`、`object-browser.png`。
- 一个组件一个子目录，目录名与文档 slug 一致：`nacos.md` → `middleware/nacos/`。
- 先在仓库根目录创建目标目录，再写入文件，禁止在其它 cwd 下相对创建（会嵌套出错误路径，例如 `.../nacos/astro/public/images/...`）。
- 从交付手册迁图时：下载到上述目录后，Markdown 只引用本地路径，不保留 `cdn.nlark.com` 等外链。
- 不要把配图放进 `astro/docs/`；那是 Markdown 源，不是静态资源目录。
- 截图尽量不含客户真实 IP、密码、Token；手册原图若带示例地址，正文仍用 `YOUR_SERVER_IP` 等占位符说明。

当前已落地：Nacos 3 张、EMQX 9 张、MinIO 1 张；其余组件手册本身无截图。手册「系统架构」两张拓扑图不进入组件页，首页继续使用 `tdp-full-architecture-transparent.png`。

## 3. 发布元数据与渲染流程

`release.json` 当前按 README 登记全部中间件镜像。16 条 `managed` 已纳管组件、3 条 `pending` 待接入组件。同一组件的多个版本写在 `versions[]` 中，汇总表按版本分行，不标注默认版本。README 未声明哪个版本是默认；顶层 `version` / `images` 只表示详情页当前文档写到哪一条，不是清单里的官方默认。

### 3.1 README → release.json：哪些会自动变

脚本：`scripts/sync-release-json.mjs`（`npm run sync:releases`）。

解析根目录 `README.md` 里「中间件」「运维工具」两张表，写回 `astro/src/data/releases/release.json`。

| 来源 | 写入 `release.json` 的字段 | 说明 |
| --- | --- | --- |
| README「软件」列 | 组件 key、`catalog.label` | key 为小写；如 `Influxdb3-ui` → `influxdb3-ui` |
| README「版本」列 | `versions[].id`（及可选 `label`） | GeoServer 等复杂版本文案可进 `label`，id 取自镜像 tag |
| README「镜像地址」列 | `versions[].images.amd64` / `arm64` | 多地址（Apollo）拆成 `portal` / `configservice` / `adminservice`；官方镜像 AMD64/ARM64 可共用同一 tag |
| README「端口」列 | `versions[].ports`、默认版本的 `catalog.ports` | 空格分隔 |
| README「说明」列 | `versions[].note` | 空则不写 note；不要把「AMD64 / ARM64 / 官方镜像」当说明 |
| README 行序 | `versions[]` 顺序、组件在 JSON 中的出现顺序 | 与表格一致 |
| 合并逻辑 | 顶层 `images` | 等于当前默认版本的 `versions[].images` |

**同步时保留、不会被 README 覆盖的手写字段：**

| 字段 | 含义 | 维护方式 |
| --- | --- | --- |
| `catalog.status` | `managed` = 有详情页可点；`pending` = 仅汇总表展示 | 手改 JSON |
| `catalog.order` | 汇总表排序 | 已有组件保留原值；新组件追加到末尾 |
| `catalog.section` | 如 `ops`（运维工具区） | 由 README 所在表推断；已有 `ops` 会保留 |
| 顶层 `version` | 详情页默认版本 / `/middleware/<component>/` 重定向目标 | 若旧值仍存在于新的 `versions[].id` 中则保留；否则取 README 中该组件**最后一行版本** |

特例（解析器已处理）：

- MySQL：一行里 `5.7.44 8.0.38` + 两个官方镜像 → 拆成两条 `versions[]`
- Nacos：README 版本里的空格（如 `2. 5.3`）以镜像 tag 为准纠成 `2.5.3`
- EMQX 4.9：可无 ARM64 行
- 运维工具表：写入 `catalog.section: "ops"`

同步成功后还会改 `astro/docs/middleware.md` 中的占位注释为 `<!-- middleware-catalog bust=<hash> -->`，迫使 Starlight 重编汇总页（避免只改 JSON 时开发服仍显示旧表）。

### 3.2 文档里的模板变量（构建时替换，不是手写死地址）

插件：`astro/src/plugins/replace-image-references.mjs`。编译 Markdown 时读**当前这篇**对应的 `release.json` 条目并替换。

| 变量 | 含义 |
| --- | --- |
| `{{ image.amd64.reference }}` / `{{ image.arm64.reference }}` | 当前页绑定版本的单镜像地址（也可用 `images.*`） |
| `{{ images.amd64.portal.reference }}` 等 | Apollo 等多服务组件 |
| `{{ release.version }}` / `{{ version }}` | 当前页绑定的版本 id |
| `{{ release.ports }}` / `{{ ports }}` | 当前页端口（空格拼接） |
| `{{ version.3_9_0.image.amd64.reference }}` | 按版本 id 引用；id 里 `.` / `-` 写成 `_` |

汇总页不写死表格：`astro/docs/middleware.md` 里放占位注释，插件展开为完整 HTML 表（组件 / 版本 / 镜像 / 端口 / 说明）。匹配规则允许带或不带 `bust=`：

```html
<!-- middleware-catalog -->
<!-- middleware-catalog bust=c6c7532b5629 -->
```

多版本组件在详情页可继续用当前文档变量，也可按版本 id 引用：

```md
{{ version.3_9_0.image.amd64.reference }}
{{ version.2_9_1.image.amd64.reference }}
{{ version.5_8_9.image.amd64.reference }}
{{ version.4_9.image.amd64.reference }}
{{ version.2_3_0.image.amd64.portal.reference }}
```

单镜像组件：

```md
{{ image.amd64.reference }}
{{ image.arm64.reference }}
```

Apollo：

```md
{{ images.amd64.portal.reference }}
{{ images.arm64.configservice.reference }}
```

汇总页表格从 `versions[]` 按版本分行。已纳管且存在对应文档的版本号应能跳到该版本页面。详情页版本切换见 4.3。

### 3.3 命令与自动化脚本

```text
README.md
        ↓  sync:releases（dev 启动/监听、build 前都会跑）
release.json
        ↓
Astro / Starlight 编译 Markdown
        ↓
replace-image-references.mjs
  ├─ 替换 {{ image.* }} / {{ version.* }} 等
  └─ 将 middleware-catalog 占位展开为汇总表
        ↓
astro/dist/ 静态 HTML
```

| 命令 | 脚本 | 作用 |
| --- | --- | --- |
| `npm run sync:releases` | `scripts/sync-release-json.mjs` | 按 README 写 `release.json`，并更新汇总页 `bust=` |
| `npm run check:releases` | 同上 `--check` | 只对比是否漂移，**不写文件**；不一致退出码 1 |
| `npm run dev` | `scripts/dev-with-sync.mjs` | 先 sync；再启动 Astro；监听 README（目录 watch + 轮询）自动 sync；监听 `release.json` 刷新汇总页 |
| `npm run build` | sync → `clean-astro-cache.mjs` → `astro build` → `verify-dist-catalog.mjs` | 打包前同步并清 `astro/.astro`，产物校验汇总表已生成且含最新说明 |
| `npm run preview` | Astro preview | 只预览已有 `astro/dist/`，不同步、不打包 |

根目录 `package.json` 里用 `"//命令名"` 键写了同样说明（JSON 不能写真正注释）。

维护约定：

1. 改镜像 / 版本 / 端口 / 说明 → 改 `README.md`，然后 `dev` 自动同步，或手动 `sync:releases` / `build`。
2. 组件详情页写好后 → 把对应条目的 `catalog.status` 改成 `managed`。
3. 改默认文档版本 → 改该组件顶层 `version`，并保证存在 `astro/docs/middleware/<component>/<version>.md`（或单文件页）。
4. 不要只改 `release.json` 里 README 会覆盖的字段后长期不改 README，否则下次 sync 会被冲掉；`check:releases` 可查漂移。

初次安装与常用命令：

```bash
npm --prefix astro install
npm run dev       # http://localhost:4321/
npm run build     # 输出 astro/dist/
npm run preview
```

### 3.4 每条 release 记录字段说明

- `version`：详情页当前文档对应的版本，`{{ release.version }}` 使用此值；
- `images.amd64` / `images.arm64`：上述版本的镜像引用，详情页 `{{ image.amd64.reference }}` 使用此值；
- `versions[]`：完整版本清单，顺序与 README 一致，供汇总表分行和详情页版本切换器；
- `versions[].id`、`ports`、`note`、`images`、可选 `label`：单个版本的镜像与说明；
- `catalog.label`、`order`、`ports`、`status`、可选 `section`：汇总页展示信息。

### 3.5 站点版本与更新日志（VERSION.md）

与 **3.1 README → release.json**（镜像清单）分离：TDP 文档站自身的发布版本与变更说明，**唯一数据源**为仓库根目录 `VERSION.md`。维护规则见根目录 [`MAINTENANCE-RULES.md`](../../MAINTENANCE-RULES.md) 第 2 章。

#### 职责边界

| 文件 | 驱动内容 | 典型变更 |
| --- | --- | --- |
| `README.md` | Middleware 镜像、`release.json`、汇总表 | 升级 Redis、新增组件镜像 |
| `VERSION.md` | 首页版本号、`/changelog/` 更新日志 | 文档站功能发布、交付说明更新 |

CNB 构建结果**不回写** `VERSION.md`；发版人员按 `MAINTENANCE-RULES.md` 第 2 章手工维护。

#### 文件格式

```markdown
# 版本
latest_version=v2.1.1

# Changelog
> 2026-08-19 v2.1.1
``` bash
1、变更说明
```
```

- **当前版本**：`latest_version=<版本号>`，等号两侧可不加空格。
- **每条发布**：一行引用 `> YYYY-MM-DD <版本号>`，紧跟一个 fenced 代码块；代码块内每行一条变更（推荐 `1、……`）。
- 同一天多次发布：**每条独立一块**，不合并。
- 空变更行（仅序号无正文）解析时忽略。

#### 构建时渲染

解析器：`astro/src/lib/version.mjs`（`loadVersionInfo()`）。

| 消费位置 | 展示内容 |
| --- | --- |
| `Hero.astro` | 首页「版本」；链接至 `/changelog/` |
| `Changelog.astro` | 更新日志页：当前版本 / 已记录批次 / 最近更新 + 时间线 |
| `astro/docs/changelog.mdx` | 页面壳，import `Changelog` 组件 |

排序：按日期倒序；同日期按文件中出现顺序，靠后的视为较新。与 `latest_version` 匹配（大小写不敏感）的条目标记「当前」。

#### 维护约定

1. 发版只改 `VERSION.md`；**禁止**在 `index.md` frontmatter 或其它页面硬编码版本。
2. `latest_version` 必须与最近一次发布的 Changelog 版本一致。
3. 修改 `VERSION.md` 结构时，须同步改 `version.mjs` 与 `MAINTENANCE-RULES.md` 第 2 章。
4. Changelog 正文遵守 **2** 节安全规范：不写密码、Token、真实 IP、客户专属信息。

#### 侧边栏与路由

- 路径：`/changelog/`
- 侧边栏：「开始使用 → 更新日志」
- 首页 Hero 版本号点击跳转至该页

## 4. 页面设计与交互

### 4.1 已实现

- 品牌为 **Tsingyun Delivery Platform（TDP）**，左上角仅展示 Logo。
- 站点只支持**明亮模式**；默认清华紫，可在右上角选择紫藤色、深海蓝、松石绿及柔和/聚光背景效果。
- 默认宽屏，未提供布局宽度切换；首页不显示搜索，内容页在 Logo 右侧提供紧凑搜索入口。
- 顶部导航静止时与背景融合，滚动后显示分隔线和半透明背景。
- 全站固定页脚：`Copyright © 2026 Powered by 清云智通`。
- 首页 Hero 展示“实施交付，有章可循”和透明运维拓扑图；Hero 区展示当前版本（来自 `VERSION.md`），点击跳转更新日志。
- 更新日志页 `/changelog/`：由 `VERSION.md` 构建时渲染；顶部展示当前版本、已记录批次、最近更新；下方为按日期倒序的变更时间线。
- 自定义 404 页面含运维插画、返回首页和 Middleware 入口。
- 右侧“本页导航”由当前文章标题自动生成；其上方提供“分享此页面”按钮，点击后复制当前页链接并显示“链接已复制”。
- Middleware 汇总页由 `release.json` 动态生成，展示组件、版本、AMD64/ARM64 镜像、端口、说明和文档入口。
- 已纳管组件名称可跳转到部署页面；镜像地址可点击复制，并显示成功或失败提示。
- 左侧 Middleware 一级菜单点击进入汇总页，箭头仍用于展开或收起文章列表。

### 4.2 当前内容范围

- 已纳管 Middleware：Apollo、ClickHouse、EMQX、FastDFS、GeoServer、InfluxDB、Kafka、LibreOffice、MinIO、MySQL、Nacos、Nginx、OpenJDK、PostGIS、PostgreSQL、Redis。
- 待接入：InfluxDB 3 UI、Kafka Map、MongoDB；仅在汇总页展示，不提供独立详情页。Kafka Map 可在 Kafka 页作为可选管理台出现。
- 多版本详情页：InfluxDB（2.9.1 / 3.9.0）、EMQX（4.9 / 5.8.9）、MySQL（5.7.44 / 8.0.38）。
- 部署前准备：系统初始化配置、Docker 与 Compose 两篇文档已接入。
- SRE：保留目录入口，尚未接入任何 SRE 组件详情页。

### 4.3 组件镜像多版本

这不是整站文档版本（不是「TDP 文档 v1 / v2」），而是**同一个组件下多条镜像发布线**。交付手册把它们写成并列小节（如 `Docker容器化部署V2.1.1.md` 的 7.1 InfluxDB 2.9.1 与 7.2 InfluxDB 3.9.0）。两者的端口、compose、目录和验证步骤都不同，不能写在同一篇文章里用锚点或 Tab 切换。

#### 路由

| 页面 | URL | 说明 |
| --- | --- | --- |
| 左侧目录、旧链接 | `/middleware/<component>/` | 多版本组件 302 到默认版本；单版本组件就是文档本身。 |
| 多版本中的每一篇 | `/middleware/<component>/<version-id>/` | `version-id` 与 `versions[].id` 一致，默认版本也走这条路径。 |
| 单版本组件 | 只有 `/middleware/<component>/` | 不生成第三级路径，标题旁不出现切换器。 |

不采用：

- 整站前缀 `/v2/middleware/influxdb/`（版本是组件级的，不是站点级的）。
- 查询参数 `?v=2.9.1`（静态站分享、目录链接和构建产物都不干净）。
- 单页内把 2.x / 3.x 全文叠在一起再客户端隐藏（InfluxDB 2 与 3、EMQX 4 与 5 是两套部署，不是同一篇的变体）。

默认版本由 `release.json` 的 `version` 决定，不另做「官方推荐」标记。当前默认：InfluxDB `3.9.0`，EMQX `5.8.9`，MySQL `8.0.38`。切换默认版本时改 JSON，并把 `<component>/<version>.md` 作为默认正文；`/middleware/<component>/` 的重定向目标随之变化。

非法版本路径（如 `/middleware/influxdb/9.9.9/`）走现有 404。

#### 文档源与命名对应

多版本组件的 **Markdown 文件名必须与 `release.json` 一一对应**，否则版本下拉、镜像变量和路由都会对不上。

| 项 | 规则 | 示例（EMQX） |
| --- | --- | --- |
| 组件目录名 | 等于 `release.json` 的组件 key | `astro/docs/middleware/emqx/` |
| 版本文档文件名 | `<versions[].id>.md`，与 id **完全一致**（含点号） | `4.9.md`、`5.8.9.md` |
| 默认版本 | 顶层 `version` 必须是某个 `versions[].id`，且存在同名 md | `"version": "5.8.9"` → `5.8.9.md` |
| URL | `/middleware/<component>/<versions[].id>/` | `/middleware/emqx/4.9/` |
| 单版本组件 | 仍可用 `middleware/<component>.md`，不建版本子目录 | `nacos.md` |

对应关系：

```text
release.json                         文档文件
─────────────────────────────────    ────────────────────────────────
"emqx": {                            astro/docs/middleware/emqx/
  "version": "5.8.9",         ←→       5.8.9.md   （默认页）
  "versions": [
    { "id": "4.9", ... },     ←→       4.9.md
    { "id": "5.8.9", ... }    ←→       5.8.9.md
  ]
}
```

禁止：

- 文件名与 `versions[].id` 不一致（例如 json 是 `4.9`，文件却叫 `4.3.md`）。
- 只改 md / 只改 json 一侧而不改另一侧。
- 同一组件同时保留 `emqx.md` 与 `emqx/` 目录。

文件名对不上时的表现：版本下拉可能缺项；`{{ image.* }}` 绑不到当前版本；汇总表版本链接 404。

目录示例：

```text
astro/docs/middleware/influxdb/3.9.0.md     # 默认版本，URL /middleware/influxdb/3.9.0/
astro/docs/middleware/influxdb/2.9.1.md     # URL /middleware/influxdb/2.9.1/
astro/docs/middleware/emqx/5.8.9.md         # 默认版本，URL /middleware/emqx/5.8.9/
astro/docs/middleware/emqx/4.9.md           # URL /middleware/emqx/4.9/
astro/docs/middleware/mysql/8.0.38.md       # 默认版本，URL /middleware/mysql/8.0.38/
astro/docs/middleware/mysql/5.7.44.md       # URL /middleware/mysql/5.7.44/
astro/docs/middleware/nacos.md              # 单版本写法仍可用
```

`/middleware/influxdb/` 重定向到当前默认版本，旧链接不断。不要同时保留 `influxdb.md` 和 `influxdb/` 目录。

规则：

1. 每个版本一篇完整 Markdown，结构与现有组件页一致：发布信息、前提、目录、compose、启动、验证。
2. 非默认版本 frontmatter 必须 `sidebar.hidden: true`。默认版本页作为目录里的「InfluxDB」入口（`sidebar.order` 与原来一致）。构建时把只含一篇可见文档的目录组拍平，避免左侧出现 `influxdb > InfluxDB` 两层。
3. 页面 `title` 仍是组件名（InfluxDB），版本号只出现在切换器里。正文不要再写一级标题 `# InfluxDB {{ release.version }}`，避免标题重复三次。
4. 正文继续使用 `{{ image.amd64.reference }}` / `{{ release.version }}`。替换插件按文件路径解析组件和版本，把这些变量绑到**当前这篇**对应的 `versions[]` 条目。Harbor 镜像地址的二次替换只允许使用当前版本的 `images`，禁止用全站清单按镜像名覆盖——否则 `influxdb` 会和 `influxdb3-ui` 撞名。文件名里的点必须保留在 URL 中，`docsLoader` 使用自定义 `generateId`。
5. 版本文档仍只放 `astro/docs/`。不要把正文放到 `astro/src/data/docs/`（那里不是 Starlight 文档源）。
6. 从交付手册迁入旧版本时，密码、Token、真实 IP 换成占位符，与现有文档规范一致。手册 7.1 中的 `DOCKER_INFLUXDB_INIT_PASSWORD`、`DOCKER_INFLUXDB_INIT_ADMIN_TOKEN` 不得原文进入站点。

已落地：InfluxDB、EMQX、MySQL。

| 组件 | 默认页 | 其它版本 |
| --- | --- | --- |
| InfluxDB | 3.9.0 → `/middleware/influxdb/3.9.0/`，`/middleware/influxdb/` 重定向到此 | 2.9.1，来源手册 7.1 |
| EMQX | 5.8.9 → `/middleware/emqx/5.8.9/`，`/middleware/emqx/` 重定向到此 | 4.9，来源手册 13 |
| MySQL | 8.0.38 → `/middleware/mysql/8.0.38/`，`/middleware/mysql/` 重定向到此 | 5.7.44，来源手册 5.1 |

InfluxDB 3 UI（`influxdb3-ui`）是另一条组件，不进入 InfluxDB 的版本下拉。InfluxDB 3.9.0 端口为 `8181`，2.9.1 为 `8086`。

#### 切换器 UI

位置：覆盖 Starlight `PageTitle`，在主标题右侧、右侧「本页导航」左侧的内容区页眉，即截图红框处。不要放进左侧目录，也不要替代右侧 TOC。

行为：

- 仅当该组件 `versions.length > 1` **且**至少两个版本都有详情页时渲染。
- 控件是原生 `<select>`（或同视觉的自定义列表），选项文案为 `versions[].id`；若有 `note`，可作选项的辅助说明或 `title`。
- 当前页对应项为选中态。变更后跳转到该版本 URL（整页导航，不是客户端抽换正文）。
- 窄屏下去到标题下方，避免挤压「InfluxDB」标题。
- 单版本组件：页面与现在完全相同，没有空下拉。

汇总页：组件名仍指向 `/middleware/<component>/`（多版本会重定向到默认版本）；已纳管版本号改为链接，指向该版本的文档 URL。

#### 实现时要动的代码

| 位置 | 作用 |
| --- | --- |
| `astro/src/components/PageTitle.astro` | 标题 + 版本选择器 |
| `astro/src/lib/middleware-versions.mjs` | 解析组件/版本、判断文档是否存在、生成 URL |
| `astro/src/plugins/replace-image-references.mjs` | 按路径绑定当前版本镜像；汇总表版本号加链接 |
| `astro/src/styles/custom.css` | 标题行与选择器样式 |
| `astro/docs/middleware/influxdb/3.9.0.md` | 默认版本正文 |
| `astro/docs/middleware/influxdb/2.9.1.md` | 2.9.1 正文 |
| `astro/src/starlight-route-data.mjs` | 拍平单子项目录组，并高亮当前组件 |

验收时多出来的静态页：`/middleware/influxdb/3.9.0/`、`/middleware/influxdb/2.9.1/`、`/middleware/emqx/5.8.9/`、`/middleware/emqx/4.9/`、`/middleware/mysql/8.0.38/`、`/middleware/mysql/5.7.44/`；对应 `/middleware/<component>/` 重定向到默认版本。左侧目录每个组件仍只有一条。

## 5. 实施状态与偏移清单

| 需求 / 项目 | 当前状态 | 结论或后续动作 |
| --- | --- | --- |
| Astro + Starlight 静态站 | 已完成 | 根目录可执行 `npm run dev`、`npm run build`。 |
| 两级 Middleware 路由 | 已完成，待扩展 | 默认文档仍为 `/middleware/<component>/`；多版本组件的非默认版本改为三级路径，见 4.3。 |
| 详情页版本切换 | 已完成 | InfluxDB 2.9.1 / 3.9.0、EMQX 4.9 / 5.8.9、MySQL 5.7.44 / 8.0.38 已接入。 |
| JSON 统一镜像地址 | 已完成 | 详情页变量和汇总表格均读取 `release.json`。 |
| 汇总页动态生成 | 已完成 | `middleware.md` 只保留说明与占位标记。 |
| 镜像复制交互 | 已完成 | 支持点击和键盘操作，提供提示。 |
| 前置部署文档 | 已完成 | 系统初始化、Docker 与 Compose 内容已依据交付手册补齐。 |
| 首页、页脚、404、目录导航 | 已完成 | 已按当前 TDP 视觉与交互实现。 |
| 明暗模式 | 已明确取消 | PRD 旧版“支持明暗主题”已纠正为只支持明亮模式。 |
| 下载 Markdown | 已明确取消 | 不生成、也不展示下载入口。 |
| CNB 构建结果回写文档 | 已确认不做 | CNB 只构建并推送镜像。清单以 README 为准，经 sync 写入 `release.json`（见 3.1）。 |
| README 自动解析为 JSON | 已完成 | `scripts/sync-release-json.mjs`；自动字段与手写字段见 3.1；`dev`/`build` 会自动 sync；见 3.3。 |
| 汇总页缓存刷新 | 已完成 | sync 后写入 `middleware-catalog bust=<hash>`；build 前清 `astro/.astro` 并用 `verify-dist-catalog.mjs` 校验。 |
| 站点版本与更新日志 | 已完成 | 根目录 `VERSION.md` + `MAINTENANCE-RULES.md`；`version.mjs` 构建时读取；首页版本链至 `/changelog/`。 |
| 镜像升级与文档同步规则 | 待补充 | 见 `MAINTENANCE-RULES.md` 第 2 章（草案已留，细则待写）。 |
| SRE 组件接入 | 未开始 | 当前只有入口页；`astro/docs/sre.md` 内仍有旧 `site/docs/` 路径文案，接入 SRE 前应一并更正。 |
| 静态站发布 | 未开始 | 只完成 `astro/dist/` 本地构建，发布位置和 CNB 发布流程尚未确定。 |
| 构建产物忽略规则 | 待修复 | `.gitignore` 仍指向旧 `site/` 路径，尚未忽略 `astro/node_modules/`、`astro/.astro/`、`astro/dist/`；提交代码前必须修正。 |
| 文档配图本地化 | 已完成规范 | 配图只放 `astro/public/images/`，Markdown 用 `/images/...`；禁止语雀外链。Nacos / EMQX / MinIO 截图已按此落地。 |
| Sitemap | 待配置 | 未设置公开站点地址，构建会跳过 sitemap；确定发布地址后补 `site` 配置。 |

## 6. 验收标准

```bash
npm run build
```

构建成功后应生成：16 个 Middleware 默认详情页、InfluxDB / EMQX / MySQL 非默认版本页、1 个动态 Middleware 汇总页、2 个部署前准备页面、更新日志页、SRE 入口和自定义 404 页面。

- 修改根目录 `VERSION.md` 后 rebuild：首页版本号与 `/changelog/` 内容一致；`latest_version` 与标记「当前」的条目匹配。
- `/middleware/influxdb/` 重定向到 3.9.0；标题旁可切到 2.9.1。两个版本的镜像地址必须是 `influxdb:3.9.0` / `influxdb:2.9.1`，不得写成 `influxdb3-ui`。
- `/middleware/emqx/` 重定向到 5.8.9，可切到 4.9；`/middleware/mysql/` 重定向到 8.0.38，可切到 5.7.44。
- 版本文档文件名必须等于对应 `versions[].id`（见 4.3）；单版本组件没有版本选择器；左侧目录仍是每个组件一条，不出现版本子项。
- 页面中的镜像地址与当前版本在 `release.json` 中的条目一致；汇总表里已有文档的版本号能进入对应页面。
- `npm run build` 须先 sync、清缓存，且 `verify-dist-catalog` 通过（汇总表已渲染，占位注释不残留，ClickHouse 等说明与 JSON 一致）。
- Nacos / EMQX / MinIO 配图来自 `astro/public/images/middleware/`，页面不出现语雀或其它外链图片；不生成 Markdown 下载文件，不读取、也不回写任何 CNB 构建结果。
