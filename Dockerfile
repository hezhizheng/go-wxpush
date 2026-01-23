# ===========================
# 第一阶段：构建 (Builder)
# ===========================
FROM golang:1.21-alpine AS builder

# 设置工作目录
WORKDIR /app

# --- 关键修改 1 ---
# 你的目录里只有 go.mod，没有 go.sum，所以只复制这一个文件
COPY go.mod ./

# 因为没有 go.sum，我们需要先生成它并下载依赖
# go mod tidy 会自动整理依赖并生成 go.sum，防止构建报错
RUN go mod tidy && go mod download

# 拷贝所有源码
COPY . .

# 编译
# CGO_ENABLED=0 保证生成静态文件
# -ldflags="-s -w" 减小体积
RUN CGO_ENABLED=0 go build -ldflags="-s -w" -o go-wxpush .

# ===========================
# 第二阶段：运行 (Runner)
# ===========================
FROM alpine:latest

# 安装基础依赖（HTTPS证书 + 时区支持）
RUN apk --no-cache add ca-certificates tzdata

WORKDIR /app

# --- 关键修改 2 ---
# 复制编译好的二进制程序
COPY --from=builder /app/go-wxpush .

# [保险起见] 复制 HTML 模板文件
# 你的项目根目录下有这个文件，为了防止程序运行时找不到模板报错，我们把它也拷进去
COPY --from=builder /app/msg_detail.html .

# 注意：如果你的 img 目录里包含程序运行时需要的图片（而不是 README 截图），
# 请取消下面这行的注释：
# COPY --from=builder /app/img ./img

# 赋予执行权限
RUN chmod +x ./go-wxpush

# 入口
ENTRYPOINT ["./go-wxpush"]

# 默认参数
CMD ["-port", "5566", \
     "-appid", "", \
     "-secret", "", \
     "-userid", "", \
     "-template_id", "", \
     "-base_url", "https://push.hzz.cool/detail", \
     "-title", "", \
     "-content", "", \
     "-tz", ""]
