---
title: Hugo + Github 搭建你的个人Blog（最新Stack-V4主题）
description: 简单方便的Stack-V4主题Blog搭建
slug: Tools
date: 2026-03-06 00:00:00+0000
image: cover.png
categories:
    - 教程
    - Hugo
tags:
    - MacOS
weight: 1       # You can add weight to some posts to override the default sorting (date descending)
draft: false
---

偶然看到别人Blog的搭建，刚好最近不想发社交媒体，就想着搭建个人博客偶尔在里面随便写写，记录些自己想看的东西。因为Hugo的更新，Stack这个主题也更新到4.0版本，网上很少有针对这个主题最新版本的搭建教程，刚好分享我自己的搭建过程，希望对你有帮助

**Stack** 是目前 Hugo 生态里**最漂亮、最具设计感**的卡片式博客主题。它的最新版本 **v4** 进行了底层架构的大换血：全面拥抱了 **Hugo Modules（官方模块化）** 和 **TOML 多文件配置**，这使得它比以前用 Git Submodule 安装要优雅和稳定得多。

针对**Stack v4**作者的建议，我们可以不用普通的 `hugo new site` 来从零搭了（因为它的配置项非常丰富，从零手写容易漏掉）。官方强烈推荐使用它的 **Starter（启动模板）**。

### 第一步：安装核心环境（Hugo 扩展版 + Go 语言）

Stack 主题由于使用了 SCSS 预处理器，**必须**使用 Hugo 的扩展版（Extended version）；同时 v4 启用了 Hugo Modules，这就要求你的 Mac 上必须装有 **Go 语言环境**。

打开 Mac 终端，运行：
```bash
brew install hugo go
```
*(注：Mac 的 Homebrew 默认安装的就是 Hugo 扩展版，一步到位)*

安装完验证一下：
```bash
hugo version  # 只要输出里带 "+extended" 字样就完美
go version    # 确认 Go 已安装
```

---

### 第二步：拉取 Stack v4 官方极速模板

我们直接把作者配置好的 v4 启动模板拉取下来，以此为基础修改。

找一个你存放代码的目录，依次执行以下命令：

**1. 克隆模板并进入目录**
```bash
git clone https://github.com/CaiJimmy/hugo-theme-stack-starter.git my-stack-blog
cd my-stack-blog
```

**2. 斩断原作者的 Git 历史，变成你自己的项目**
```bash
rm -rf .git
git init
```

**3. 强行更新到 v4 的“最新版本”**
虽然模板自带了 v4，但我们可以用 Go 模块命令让它拉取最新的 v4 更新（比如最新的修复和特性）：
```bash
hugo mod get -u github.com/CaiJimmy/hugo-theme-stack/v4
hugo mod tidy
```
*(运行这个命令时，Go 会自动去云端下载主题的最新源码并缓存在本地，你的项目目录里再也不用看到乱七八糟的主题源码文件了，极其清爽！)*

---

### 第三步：用 VS Code 进行极客化配置

在终端输入以下命令，用 VS Code 打开你的博客项目：
```bash
code .
```

Stack v4 最优雅的地方在于，它把庞杂的配置分散到了 config/_default/ 文件夹下。在 VS Code 左侧的目录树中找到这个文件夹，我们要改三个核心文件：

**1. 基础信息配置：`config.toml`**
打开 config/_default/config.toml：
* 将 baseURL 改成你的 GitHub Pages 地址（例如："https://你的用户名.github.io/"，注意最后有个斜杠）。
* 将 title 改成你博客的名字（比如 "我的Blog"）。
* languageCode 如果是中文，可以确认是 "zh-cn"。

**2. 个性化参数配置：`params.toml`**
打开 config/_default/params.toml，这是 Stack 主题的灵魂所在，往下找：
* **[sidebar.avatar]**：把 local = true 保持不变，src = "img/avatar.png"。你可以把自己的头像重命名为 avatar.png，然后放到项目根目录的 assets/img/ 文件夹里（如果没有这个文件夹就建一个）。
* **[sidebar]**：修改 emoji 和 subtitle（侧边栏的个性签名）。
* 里面还有很多强大的开关，比如 darkmode（暗黑模式）、article.readingTime（阅读时间）等，全都可以根据你的喜好开启（设为 `true`）。

**3. 菜单配置：`menu.toml`**
这是左侧导航栏的配置。你可以看到 [main] 下面有 Home、Archives、Search 等，可以把 name 字段改成中文（如“首页”、“归档”、“搜索”）。

---

### 第四步：写下你的第一篇卡片文章

Stack 主题非常适合使用 **Page Bundles（页面包）** 来写文章，这样一篇文章和它的配图可以放在同一个文件夹里，非常整洁。

在 VS Code 终端运行：
```bash
hugo new content/post/my-first-post/index.md
```
你会看到 content/post/my-first-post/ 下多了一个 `index.md`。打开它，完善头部的 Front Matter：
```yaml
---
title: "我的第一篇 Stack 博客"
description: "这是我用 Mac 和 VS Code 搭建的全新博客体验"
date: 2026-03-13
image: "cover.jpg" # 如果你想给这张卡片加个好看的封面图，把图片和 index.md 放在一起，并命名为 cover.jpg
draft: true # 记得预览没问题后，改为 false 才能正式发布！
---

你好，Stack v4！这是正文内容...
```

**本地极速预览体验**：
在终端运行：
```bash
hugo server -D
```
打开浏览器访问 `http://localhost:1313`。伴随着极其丝滑的动画和惊艳的卡片式 UI，你的个人博客就完成了，你在 VS Code 保存 markdown 的瞬间，浏览器依然是毫秒级刷新。

---

### 第五步：自动化部署到 GitHub Pages（终极工作流）

原作者的 starter 模板其实已经自带了一个 `.github/workflows/deploy.yml`。为了确保使用的是最新的、最稳定的 GitHub 官方 Actions 环境，我们把它稍微替换一下。

**1. 替换 Actions 脚本**
在 VS Code 中，打开 `.github/workflows/deploy.yml`（如果没有这个路径，就新建一个），将里面的内容替换为官方推荐的最新构建脚本：

```yaml
name: Deploy Hugo site to Pages

on:
  push:
    branches: ["main"]
  workflow_dispatch:

permissions:
  contents: read
  pages: write
  id-token: write

concurrency:
  group: "pages"
  cancel-in-progress: false

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout
        uses: actions/checkout@v4
        with:
          fetch-depth: 0
      - name: Setup Go
        uses: actions/setup-go@v5
        with:
          go-version: '1.21' # Stack v4 需要 Go 环境来拉取模块
      - name: Setup Hugo
        uses: peaceiris/actions-hugo@v3
        with:
          hugo-version: 'latest'
          extended: true
      - name: Build with Hugo
        run: hugo --minify
      - name: Upload artifact
        uses: actions/upload-pages-artifact@v3
        with:
          path: ./public

  deploy:
    environment:
      name: github-pages
      url: ${{ steps.deployment.outputs.page_url }}
    runs-on: ubuntu-latest
    needs: build
    steps:
      - name: Deploy to GitHub Pages
        id: deployment
        uses: actions/deploy-pages@v4
```

**2. 在 GitHub 建立仓库并设置权限**
* 去 GitHub 新建一个名为 你的用户名.github.io 的公开仓库。
* 在仓库的 **Settings -> Pages** 中，将 **Build and deployment -> Source** 改为 **GitHub Actions**。

**3. 一键推送到云端**
回到 VS Code 的终端，依次运行：
```bash
git add .
git commit -m "初始化 Stack v4 博客"
git branch -M main
git remote add origin git@github.com:你的用户名/你的用户名.github.io.git
git push -u origin main
```

**大功告成！**
现在去 GitHub 的 Actions 面板，等大概 15 秒钟绿色对勾亮起，你的博客就正式上线了！

之后每次写完文章（记得改 draft: false），直接用 VS Code 的源代码管理点一下**同步更改 (Sync Changes)**，剩下的交给 GitHub 云端去自动编译即可，你甚至不用在本地生成任何 HTML 文件。