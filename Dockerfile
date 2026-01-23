# ===========================
# 第一阶段：构建 (Builder)
# ===========================
FROM golang:1.21-alpine AS builder

# 设置工作目录
WORKDIR /app

# 1. 预下载依赖 (利用 Docker 缓存层加速构建)
COPY go.mod go.sum ./
# 如果在 Github Actions 里跑，不需要设置 GOPROXY，如果在国内本地跑需解开下面注释
# RUN go env -w GOPROXY=https://goproxy.cn,direct
RUN go mod download

# 2. 拷贝源码
COPY . .

# 3. 编译
# CGO_ENABLED=0: 禁用 CGO，确保生成静态链接的二进制文件
# -ldflags="-s -w": 去除调试信息，减小体积
# -o go-wxpush: 输出文件名为 go-wxpush (不再带架构后缀)
RUN CGO_ENABLED=0 go build -ldflags="-s -w" -o go-wxpush .

# ===========================
# 第二阶段：运行 (Runner)
# ===========================
FROM alpine:latest

# 安装必要的依赖
# ca-certificates: 访问 HTTPS 接口(微信API)必须的根证书
# tzdata: 支持 -tz 参数设置时区
RUN apk --no-cache add ca-certificates tzdata

WORKDIR /app

# 从第一阶段拷贝编译好的程序
COPY --from=builder /app/go-wxpush .

# 赋予执行权限
RUN chmod +x ./go-wxpush

# 设置入口点
ENTRYPOINT ["./go-wxpush"]

# 恢复你原来的默认参数 (注意：二进制文件名已统一，这里只写参数)
CMD ["-port", "5566", \
     "-appid", "", \
     "-secret", "", \
     "-userid", "", \
     "-template_id", "", \
     "-base_url", "https://push.hzz.cool/detail", \
     "-title", "", \
     "-content", "", \
     "-tz", ""]
