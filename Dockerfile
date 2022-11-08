# Build stage
# FROM：定制的镜像都是基于 FROM 的镜像
FROM golang:1.19-alpine3.16 AS build-env
# ARG
# 构建参数，
ARG GOPROXY
# ENV
# 设置环境变量，定义了环境变量，那么在后续的指令中，就可以使用这个环境变量。
ENV GOPROXY ${GOPROXY:-direct}
# ARG
# 构建参数，
ARG GITEA_VERSION
ARG TAGS="sqlite sqlite_unlock_notify"
# ENV
# 设置环境变量，定义了环境变量，那么在后续的指令中，就可以使用这个环境变量。
ENV TAGS "bindata timetzdata $TAGS"
# ARG
# 构建参数，与 ENV 作用一致。不过作用域不一样。ARG 设置的环境变量仅对 Dockerfile 内有效，也就是说只有 docker build 的过程中有效，构建好的镜像内不存在此环境变量。
# 构建命令 docker build 中可以用 --build-arg <参数名>=<值> 来覆盖。
ARG CGO_EXTRA_CFLAGS

# Build deps
# RUN：用于执行后面跟着的命令行命令。
RUN apk --no-cache add build-base git nodejs npm

# Setup repo
# COPY
# 复制指令，从上下文目录中复制文件或者目录到容器里指定路径。
COPY . ${GOPATH}/src/code.gitea.io/gitea
# WORKDIR
# 指定工作目录。用 WORKDIR 指定的工作目录，会在构建镜像的每一层中都存在。（WORKDIR 指定的工作目录，必须是提前创建好的）。
# docker build 构建镜像过程中的，每一个 RUN 命令都是新建的一层。只有通过 WORKDIR 创建的目录才会一直存在。
WORKDIR ${GOPATH}/src/code.gitea.io/gitea

# Checkout version if set
# RUN：用于执行后面跟着的命令行命令。
RUN if [ -n "${GITEA_VERSION}" ]; then git checkout "${GITEA_VERSION}"; fi \
 && make clean-all build

# Begin env-to-ini build
# RUN：用于执行后面跟着的命令行命令。
RUN go build contrib/environment-to-ini/environment-to-ini.go
# FROM：定制的镜像都是基于 FROM 的镜像
FROM alpine:3.16
LABEL maintainer="maintainers@gitea.io"
# EXPOSE
# 仅仅只是声明端口。
# 作用：
#    帮助镜像使用者理解这个镜像服务的守护端口，以方便配置映射。
#    在运行时使用随机端口映射时，也就是 docker run -P 时，会自动随机映射 EXPOSE 的端口。
EXPOSE 22 3000
# RUN：用于执行后面跟着的命令行命令。
RUN apk --no-cache add \
    bash \
    ca-certificates \
    curl \
    gettext \
    git \
    linux-pam \
    openssh \
    s6 \
    sqlite \
    su-exec \
    gnupg
# RUN：用于执行后面跟着的命令行命令。
RUN addgroup \
    -S -g 1000 \
    git && \
  adduser \
    -S -H -D \
    -h /data/git \
    -s /bin/bash \
    -u 1000 \
    -G git \
    git && \
  echo "git:*" | chpasswd -e
# ENV
# 设置环境变量，定义了环境变量，那么在后续的指令中，就可以使用这个环境变量。
ENV USER git
# ENV
# 设置环境变量，定义了环境变量，那么在后续的指令中，就可以使用这个环境变量。
ENV GITEA_CUSTOM /data/gitea
# VOLUME
# 定义匿名数据卷。在启动容器时忘记挂载数据卷，会自动挂载到匿名卷。
# 作用：
#    避免重要的数据，因容器重启而丢失，这是非常致命的。
#    避免容器不断变大。
VOLUME ["/data"]
# ENTRYPOINT
# 类似于 CMD 指令，但其不会被 docker run 的命令行参数指定的指令所覆盖，而且这些命令行参数会被当作参数送给 ENTRYPOINT 指令指定的程序。
# 但是, 如果运行 docker run 时使用了 --entrypoint 选项，将覆盖 ENTRYPOINT 指令指定的程序。
# 优点：在执行 docker run 的时候可以指定 ENTRYPOINT 运行所需的参数。
# 注意：如果 Dockerfile 中如果存在多个 ENTRYPOINT 指令，仅最后一个生效。
ENTRYPOINT ["/usr/bin/entrypoint"]
# CMD
# 类似于 RUN 指令，用于运行程序，但二者运行的时间点不同:
#    CMD 在docker run 时运行。
#    RUN 是在 docker build。
# 作用：为启动的容器指定默认要运行的程序，程序运行结束，容器也就结束。CMD 指令指定的程序可被 docker run 命令行参数中指定要运行的程序所覆盖。
# 注意：如果 Dockerfile 中如果存在多个 CMD 指令，仅最后一个生效。
CMD ["/bin/s6-svscan", "/etc/s6"]
# 复制指令
COPY docker/root /
COPY --from=build-env /go/src/code.gitea.io/gitea/gitea /app/gitea/gitea
COPY --from=build-env /go/src/code.gitea.io/gitea/environment-to-ini /usr/local/bin/environment-to-ini
# RUN：用于执行后面跟着的命令行命令。
RUN chmod 755 /usr/bin/entrypoint /app/gitea/gitea /usr/local/bin/gitea /usr/local/bin/environment-to-ini
# RUN：用于执行后面跟着的命令行命令。
RUN chmod 755 /etc/s6/gitea/* /etc/s6/openssh/* /etc/s6/.s6-svscan/*
