# 运维记录服务 ops-notes

面向 11 月 11 至 13 日 Linux、Git、Docker 与安全运维教学。

这是隔离实验环境中的教学服务，使用 Python 标准库和 SQLite，无第三方 Python 依赖。Python http.server 不用于真实生产流量；项目未实现用户登录和业务授权，不接入真实数据，不直接发布到公网。生产迁移需采用适当的应用服务器、认证授权、审计与正式证书。

## 环境

Ubuntu Server 24.04，Python 3.12，Git 2.43 或更新兼容版，systemd，Docker Engine 28 或更新受支持版，Docker Compose 插件 2.20 或更新兼容版。项目命令在 Ubuntu 的 Bash 中执行；手册 S02 的管理客户端部分明确标为 Windows PowerShell。

## 初始化

将整个项目放在 `~/course-kit/ops-notes`。执行 `bash scripts/prepare-lab.sh`，在 `~/training` 创建演示远端、种子仓库和学员仓库。目录已存在时脚本退出，不覆盖。

进入 `~/training/ops-notes`，阅读 `git log --oneline --decorate --all`。远端已经有 v1.0.0、v1.1.0 两个教学版本。无网络时使用本地 bare 仓库完成 clone、fetch、push、pull；有网络且讲师已创建 GitHub 仓库时，可按操作手册配置 GitHub。

## 接口

- GET /version：返回版本。
- GET /health：同时检查数据库读取，返回 status=ok。
- GET /notes：列出训练记录。
- POST /notes：JSON 请求体，例如 `{"text":"first check"}`。
- GET /debug/config：APP_DEBUG=1 时可用，关闭后为 404；仅展示非敏感配置。

## 容器

`git switch --detach v1.0.0` 后复制 `.env.example` 为 `.env`，执行 `sudo docker compose config` 与 `sudo docker compose up -d --build`。访问 `http://127.0.0.1:8080/health`。

客户端进入 gateway 容器的 8080 端口，gateway 通过 Compose 网络中 `app:8000` 访问应用。app 没有对宿主机发布端口。`notes_data` 保存 SQLite 数据。

## 数据保护

`bash scripts/backup.sh` 使用 SQLite 在线备份接口，再复制到宿主机 backups 目录；`bash scripts/restore.sh backups/文件名.db` 会停服并恢复训练数据，需要输入 RESTORE 确认。恢复前先另做备份。

安全课切换至 `compose.secure.yaml` 后，先 `export COMPOSE_FILE=compose.secure.yaml`，再运行备份脚本。证书、数据、备份及 .env 文件不提交到 Git。

## 镜像

基础镜像为 `python:3.12-slim`、`nginx:stable-alpine`。这些标签可更新；教师课前应拉取、记录镜像 digest、预构建 v1.0.0 与 v1.1.0 并导出离线镜像，保持全班一致。正式交付应固定经验证的 digest。
