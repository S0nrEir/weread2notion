# WeRead2Notion 本地使用文档

本文基于 NotionHub 的 WeRead2Notion 说明页整理，并结合当前仓库代码适配为本地使用版本。

- 原始说明页: https://www.notionhub.app/docs/weread2notion.html
- 整理时间: 2026-06-24

## 项目说明

这个项目会把微信读书中的书籍信息、划线和想法同步到 Notion。当前版本使用微信读书 `Gateway API Key` 和 Notion Token，不再依赖微信读书 Cookie。

需要特别注意：

- 脚本在发现某本书的笔记有更新时，会删除该书之前生成的 Notion 页面后再重建。
- 不要在同步生成的书籍页面里直接写自己的长期笔记，否则后续同步时可能被覆盖。

## 准备 3 个值

本地运行至少需要下面 3 项：

| 名称 | 作用 | 必填 |
| --- | --- | --- |
| `WEREAD_API_KEY` | 读取微信读书数据 | 是 |
| `NOTION_TOKEN` | 调用 Notion API 写入数据 | 是 |
| `NOTION_DATA_SOURCE_ID` / `NOTION_PAGE` / `NOTION_DATABASE_ID` | 指定同步目标 | 三选一 |

说明：

- 线上原文主要使用 `NOTION_PAGE`。
- 当前仓库代码同时支持 `NOTION_DATA_SOURCE_ID`、`NOTION_PAGE`、`NOTION_DATABASE_ID`，优先级也是这个顺序。
- 如果你是本地直接跑仓库代码，优先推荐使用 `NOTION_DATA_SOURCE_ID`。

## 获取 Notion 授权信息

原始说明页提供了一套现成模板和授权流程。最稳妥的做法是先按原文复制模板，再拿到授权结果中的 `NOTION_TOKEN` 和 `NOTION_PAGE`。

原文里的授权入口是：

```text
https://api.notion.com/v1/oauth/authorize?client_id=801fd03a-a44f-41af-9a17-feb048b4bbdd&response_type=code&owner=user&redirect_uri=https%3A%2F%2Fnotion-auth.malinkang.com%2Fweread2notion-oauth-callback
```

流程简述：

1. 打开上面的授权链接。
2. 选择开发者提供的 WeRead2Notion 模板。
3. 授权完成后，保存返回页中的 `NOTION_TOKEN` 和 `NOTION_PAGE`。

补充说明：

- 从仓库代码看，脚本会动态读取 Notion data source 的属性，不强制所有字段都存在。
- 但如果你偏离原模板，至少要保证必填字段完整，最好先在测试库里验证一次。

## 获取微信读书 API Key

按原始说明页的流程：

1. 打开 `https://weread.qq.com/r/weread-skills`
2. 使用你的微信读书账号登录。
3. 创建并复制 Key。
4. 这个值就是 `WEREAD_API_KEY`。

安全提醒：

- 这个 Key 可以读取你的微信读书数据，不要提交到公开仓库。
- 不要把它直接写进脚本源码，放进 `.env` 或系统环境变量即可。

## 本地安装

如果你已经 clone 了这个仓库，直接在仓库根目录执行：

```powershell
python -m venv .venv
.\.venv\Scripts\Activate.ps1
python -m pip install -e .
```

如果你只想安装发布版本，原始说明页给出的方式是：

```bash
pip install "git+https://github.com/malinkang/weread2notion.git@v1"
```

但对于当前仓库，优先推荐 `pip install -e .`，这样你改代码后可以直接生效。

## 本地配置

在仓库根目录创建 `.env`：

```env
WEREAD_API_KEY=你的微信读书 API Key
NOTION_TOKEN=你的 Notion Token
NOTION_DATA_SOURCE_ID=你的 Notion Data Source ID

# 如果你没有 data source ID，也可以改用下面其中一项
# NOTION_PAGE=你的 Notion 页面或数据库链接
# NOTION_DATABASE_ID=你的 Notion Database ID
```

说明：

- 脚本启动时会自动读取 `.env`。
- 值前后如果有多余空格或换行，代码会先做清理。
- `NOTION_TOKEN` 必须是 `secret_` 或 `ntn_` 开头的值。

## 运行方式

激活虚拟环境后执行：

```powershell
weread2notion sync
```

也可以直接调用可执行文件：

```powershell
.\.venv\Scripts\weread2notion.exe sync
```

兼容旧入口：

```powershell
python scripts\weread.py
```

## Notion 属性要求

结合原始说明页和当前代码，目标 Notion data source 至少要满足下面几点：

- 必须有一个 `Title` 类型的标题属性。
- 必须保留 `BookId`。
- 必须保留 `Sort`。

建议的属性类型如下：

| 属性名 | 建议类型 | 说明 |
| --- | --- | --- |
| `BookId` | Rich text | 用于识别同一本书 |
| `Sort` | Number | 用于增量同步 |
| `链接` | URL | 微信读书网页链接 |
| `作者` | Rich text | 作者 |
| `ISBN` | Rich text | ISBN |
| `评分` | Number | 书籍评分 |
| `分类` | Multi-select | 书籍分类 |
| `状态` | Status 或 Select | `在读` / `读完` |
| `阅读进度` | Number | 建议在 Notion 中显示为 Percent |
| `阅读时长` | Rich text | 文本格式时长 |
| `时间` | Date | 读完时间 |

补充：

- 可选属性缺失时，脚本会自动跳过，不会因此中断。
- `状态` 不要求固定成单一类型，`Status` 和 `Select` 都能写。

## 运行结果和同步行为

脚本会按微信读书笔记列表拉取书籍，再把每本书写入 Notion。

从当前实现看：

- 增量同步依赖 `Sort` 字段。
- 同一本书重新同步前，会先按 `BookId` 找到旧页面并删除。
- 没有划线、没有想法、也没有进入笔记列表的书，可能不会出现在同步结果里。

## 常见问题

### 1. 提示缺少 `NOTION_PAGE` / `NOTION_DATA_SOURCE_ID`

检查 `.env` 或系统环境变量是否真的生效。

建议排查：

- 文件名是不是 `.env`
- 变量名有没有拼错
- 值里有没有多余引号
- 是否至少提供了 `NOTION_DATA_SOURCE_ID`、`NOTION_PAGE`、`NOTION_DATABASE_ID` 其中之一

### 2. 提示缺少 `BookId` 或 `Sort`

说明你的目标 Notion data source 缺了必填字段。补上这两个属性后再运行。

### 3. 有些字段没有写入

这通常是因为目标库里没有对应字段，或者字段类型不匹配。常见受影响的字段包括：

- `链接`
- `分类`
- `评分`
- `阅读进度`
- `时间`

### 4. 为什么有些书没有同步

开源版主要围绕笔记列表做同步。没有划线、没有想法、也不在笔记列表里的书，通常不会被同步出来。

### 5. 本地运行成功，但 GitHub Actions 定时没按北京时间触发

仓库里的示例 workflow 使用的是：

```yaml
schedule:
  - cron: "0 0 * * *"
```

这表示 `UTC 00:00`，对应北京时间 `08:00`。GitHub Actions 的定时任务本身可能会有几分钟延迟。

## 可选：改为 GitHub Actions 运行

如果你不想长期在本地手动执行，这个仓库已经带了 workflow 文件 [weread.yml](../.github/workflows/weread.yml)。

按当前仓库配置，你需要在 GitHub 仓库 Secrets 中设置：

- `WEREAD_API_KEY`
- `NOTION_TOKEN`
- `NOTION_PAGE` 或 `NOTION_DATABASE_ID` 或 `NOTION_DATA_SOURCE_ID`

然后在 GitHub 的 `Actions -> weread sync` 中手动运行一次，确认配置无误。

## 使用建议

- 优先先跑到一个测试用 Notion 数据库，确认字段映射正确再切正式库。
- 不要把个人笔记写在脚本生成的页面里，单独建页面更安全。
- 如果你已经 Fork 过旧版仓库，确认旧的 Cookie 相关 Secret 已经废弃，改用 `WEREAD_API_KEY`。

## 参考来源

- NotionHub 原始说明页: https://www.notionhub.app/docs/weread2notion.html
- 本仓库 CLI 实现: [src/weread2notion/cli.py](../src/weread2notion/cli.py)
- GitHub Action 定时配置: [weread.yml](../.github/workflows/weread.yml)
