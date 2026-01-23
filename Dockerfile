# ===========================
# 第一阶段：构建 (Builder)
# ===========================
FROM golang:1.21-alpine AS builder

# 设置工作目录
WORKDIR /app

# --- 修复点开始 ---
# 1. 原来是 COPY go.mod go.sum ./ 
# 改为只复制 go.mod (因为你没有 go.sum)
COPY go.mod ./

# 2. 下载依赖
# 即使没有 go.sum，go mod download 也会尝试根据 go.mod 下载依赖
RUN go mod download
# --- 修复点结束 ---

# 3. 拷贝源码
COPY . .

# 4. 编译
# 补充：为了防止缺少 go.sum 导致构建不稳定，这里加一个 go mod tidy 自动整理依赖
RUN go mod tidy && CGO_ENABLED=0 go build -ldflags="-s -w" -o go-wxpush .

# ===========================
# 第二阶段：运行 (Runner)
# ===========================
FROM alpine:latest

# 安装基础依赖
RUN apk --no-cache add ca-certificates tzdata

WORKDIR /app

# 从第一阶段拷贝编译好的程序
COPY --from=builder /app/go-wxpush .

# 赋予执行权限
RUN chmod +x ./go-wxpush

# 设置入口点
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
