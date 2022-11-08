1. 构建 

`docker build -t gitea:v1 .`

参数说明：

    -t ：指定要创建的目标镜像名

    . ：Dockerfile 文件所在目录，可以指定Dockerfile 的绝对路径

2. 我们可以使用 docker images 来列出本地主机上的镜像。 

`docker images`


```
REPOSITORY   TAG               IMAGE ID       CREATED          SIZE
gitea        v1                3240858872e9   25 minutes ago   256MB
<none>       <none>            31f37a5faafa   25 minutes ago   3.21GB
golang       1.19-alpine3.16   6e31dcd72d8f   6 days ago       352MB
alpine       3.16              9c6f07244728   3 months ago     5.54MB
```


各个选项说明:

    REPOSITORY：表示镜像的仓库源

    TAG：镜像的标签

    IMAGE ID：镜像ID

    CREATED：镜像创建时间

    SIZE：镜像大小

同一仓库源可以有多个 TAG，代表这个仓库源的不同个版本，如 ubuntu 仓库源里，有 15.10、14.04 等多个不同的版本，我们使用 REPOSITORY:TAG 来定义不同的镜像。

所以，我们如果要使用版本为15.10的ubuntu系统镜像来运行容器时，命令如下：

runoob@runoob:~$ docker run -t -i ubuntu:15.10 /bin/bash 
root@d77ccb2e5cca:/#

参数说明：

    -i: 交互式操作。
    -t: 终端。
    ubuntu:15.10: 这是指用 ubuntu 15.10 版本镜像为基础来启动容器。
    /bin/bash：放在镜像名后的是命令，这里我们希望有个交互式 Shell，因此用的是 /bin/bash。

如果要使用版本为 14.04 的 ubuntu 系统镜像来运行容器时，命令如下：

runoob@runoob:~$ docker run -t -i ubuntu:14.04 /bin/bash 
root@39e968165990:/# 

如果你不指定一个镜像的版本标签，例如你只使用 ubuntu，docker 将默认使用 ubuntu:latest 镜像。

3. 