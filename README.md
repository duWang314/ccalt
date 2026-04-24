# 基于 Claw Cloud App Launchpad + Tailscale 的自建节点科学上网教程

*此教程写于 2026 年 1 月 23 日，其中部分内容可能会慢慢过时*

## 简介

- Claw Cloud 是一家设置**定期刷新免费额度**的、**无需额外认证**的云服务提供商。横向对比：**Azure**、Google、*Oracle*、*Amazon*
- Tailscale 是一款**客户端开源**、对个人和小型企业**免费**的内网穿透软件。免费政策：

> **Free**
>
> √ Limited to 3 users and 100 devices
>
> √ Access nearly all features
>
> √ Use Tailscale for free indefinitely

- 通过云服务提供商租用一台能够访问外网的**虚拟机实例**（Virtual Machine Instance），在这台机器上运行 Tailscale，让其成为我们的出口节点。注意：如果你已经有条件准备一台能访问外网、能稳定持续运行的机器——最好是电脑，则向云服务商**申请机器**的步骤可以直接跳过
    - 个人推荐的远程操作机器的方法：
        - Linux——SSH 命令行、**网页命令行**
        - Windows——Windows 远程桌面、远程控制类软件
        - 安卓手机——**Scrcpy**、远程控制类软件

## 你需要准备的

- 一个 github 账号，必须已注册 7 天以上，最好已注册半年以上——用于注册 Claw Cloud。注册及赠送额度政策：

> First-Time Benefit: \$5 Credit
>
> - For Github users, eligibility requires registration at least 7 days ago.
>
> - For Gmail users, no other requirements.
> 
> Recurring Monthly Benefit: \$5 Credit
>
> - Unlock by binding your Github account (Your GitHub account needs to be registered for 180+ days).

- 一个 微软 / 苹果 账号——用于注册 Tailscale
- 一点点 Linux 指令基础知识，但不强求——用于简单管理和维护机器

## 优缺点

### 优

- 完全免费，不用绑定任何支付方式，不存在被反薅的可能
- 额度永续，满足 180 天要求的 Github 账号每月刷新的额度可以将此机器一直维持下去
- 操作简单，跟着教程即可上手，没有 Linux / 网络 方面的知识也可以
- 网速快，最高清晰度 YouTube 视频任意拖动进度条不卡顿
- 网络稳定性尚可，高峰期依然保持高速。横向对比：免费机场、便宜节点
- 可以做到选择性地，不屏蔽内网访问
    - Windows 和 Linux 上的 Tailscale 客户端有 Allow local network access 功能，开启后能做到让你的电脑不屏蔽内网——正常访问无线打印机、访问内网网站
    - **安卓端**的 Tailscale 还额外实现了应用分流（App Split Tunneling）功能，能做到完全不影响国内应用，但仅限安卓手机。~~HCF 哭晕在厕所~~

### 劣

- 不同网络环境下的表现存在差异。根据我目前的观察，连接校园网时节点最流畅，家中网络次之，公共 Wifi 又次之。尚不清楚其中原理
- 虚拟机长时间不停运行，可能出现网络卡顿情况，需要尝试重启 Linux 机器。不过我实际使用下来发现些许波动是正常的，除非完全不可用，否则一点点卡顿不建议重启
- 无法自由切换节点所在地区，当前仅能白嫖新加坡、**日本**、德国、**美国东西部**节点中的一个
- 无法保证节点 IP 的干净。大致干净√，绝对干净×。毕竟此 IP 来自数据中心，也就是服务器机房云集的地方。登录 / *爬取* 某些网站时，你的请求可能被阻止，比较罕见的情况。主要出现在洁癖网站？**grok.com/signin:** `Blocked due to abusive traffic patterns`，更换至 Azure 虚拟机提供的节点后恢复正常
- Claw Cloud 免费用户每月必须至少访问并登录官网一次，否则机器可能被关停，届时需要手动启动。考虑使用保活脚本。节约资源政策：

> Starting **December 13, 2025**, the system will audit account activity for **Free Plan** users. If your account has **not logged into the ClawCloud Run console for the past 30 days**:
> 1. Your account will be classified as "Inactive".
> 2. The replica count for all your applications will be forcibly scaled down to **0**, and services will cease immediately.

### Pros & Cons 总结

**这篇教程适合谁？**

- 没钱的学生党
- 喜欢钻研 Linux 和 Docker 技术的爱好者
- 寻找备用梯子的人

**不适合谁？**

- 追求极致稳定、不想折腾的人
- 对隐私和安全性有极高要求的人

## 操作步骤

### 申请机器

- [ ] 1. 注册账号

https://run.claw.cloud/

可能会慢，请耐心等待。如果因 Github 访问不畅影响注册，尝试去 Microsoft Store 下载加速软件 Watt Toolkit

- [ ] 2. 配置并申请机器

| 字段名           | 需要进行的操作                                               |
| ---------------- | ------------------------------------------------------------ |
| Application Name | 填写为`clawcloud-alpine-<申请该机器的区域，例如 japan、america>`，可以根据个人喜好命名，这是我自己的规范（**Kebab**, Camel, Snake, Pascal） |
| Image            | 选择 `Public`，并将 Image Name 填写为 `lscr.io/linuxserver/openssh-server:latest` |
| Usage            | 选择 `Fixed`，Replicas 选择 `1`，CPU 选择 `1`，Memory 选择 `512` |
| 中间一堆         | 无需操作                                                     |
| Local Storage    | 点击 `Add`，Capacity 填写为 `1`，Mount Path（挂载路径）设置为 `/root` |

操作完毕后，回到页面最上方，点右上角 `Deploy Application`

- [ ] 3. 网页版 SSH 连接机器

App Launchpad 界面，找到刚刚的机器，点击右侧命令行按钮

### 操作 Tailscale

- [ ] 1. Windows 登录并打开 Tailscale Admin 控制台

- [ ] 2. Windows 安装 Tailscale

https://dl.tailscale.com/stable/tailscale-setup-1.96.4.exe

这是官网直接给出的安装包，如果发现此安装包安装时报错，尝试微调下载地址以获取完整版安装包：

https://dl.tailscale.com/stable/tailscale-setup-full-1.96.4.exe

- [ ] 3. Linux 安装并登录 Tailscale

```sh
# 安装过程详解
cd ~ # 或者 cd root/
wget https://dl.tailscale.com/stable/tailscale_1.96.4_amd64.tgz # 获取可执行文件的压缩归档
tar -xf tailscale_1.96.4_amd64.tgz # 解压
cd tailscale_1.96.4_amd64/ # 进入解压后的目录
mv * .. # 将所有文件移入父目录中
cd ..

# 如果是正常系统无需进行此步骤
# 以用户态运行 tailscaled 然后挂起，并丢弃所有输出
# d -> daemon，守护进程。由于此 Alpine Linux 系统运行在 docker 中，且系统本身经过阉割，所以守护进程无法自动运行，也无法在常规内核态运行
nohup ./tailscaled --tun=userspace-networking --socks5-server=localhost:1055 > /dev/null 2>&1 &

# 启动后自动要求登录。通过链接，可以直接在 Windows 浏览器中登录，无需手动配置密钥，非常方便
./tailscale up
```

- [ ] 4. Linux、Windows 互相 ping 通

此步骤**非常重要**！如果互相 ping 不通则一切成为空谈

```bat
# 在 Windows cmd 中执行以下操作
ping <Linux tailnet IP>
# ↓↓↓ 如果不通则先从 Linux 回 ping ↓↓↓
```

```sh
# 在 Linux 命令行中执行以下操作
ping <Windows tailnet IP>
```

- [ ] 5. Linux 申请成为出口节点

```sh
./tailscale up --advertise-exit-node
```

- [ ] 6. Tailscale Admin 控制台批准 Linux 机器成为出口节点

- [ ] 7. Windows 使用节点并测试连接

- [ ] 8. Tailscale Admin 控制台的 Disable key expiry 操作（可选）

- [ ] 9. 其他平台安装 Tailscale（可选）

| 平台    | 安装方法                                                     |
| ------- | ------------------------------------------------------------ |
| Android | https://github.com/tailscale/tailscale-android ，不要去 Google Play，一来连接不上，二来要换区 |
| iOS     | App Store，需要换区                                          |
| Mac     | 直接官网下载安装包                                           |

- [ ] 10. Android 使用 Tailscale 节点（可选）

- [ ] 11. Android 上 App Split Tunneling 功能（可选）

- [ ] 12. Linux 编写 Shell 脚本方便快速启动（可选）

作为节点的虚拟机在连续几周不停运行后，梯子可能变卡，需要重启一下。重启指的是上官网，找到该机器，执行 restart 指令。这通常是一个计算资源的解分配和重新分配的过程。但这样一来，tailscale 和 tailscaled 两个进程就都会被“枪毙”，我们需要手动重启它们让节点再次发挥作用

```sh
cd ~
nano auto.sh # 此镜像自带一个 busybox，无需我们安装
```

```sh
# 在文本编辑器中粘贴刚刚的两句指令
nohup /root/tailscaled --tun=userspace-networking --socks5-server=localhost:1055 > /dev/null 2>&1 &
/root/tailscale up

# 记得保存并退出。留意 nano 下方的提示，一般是 CTRL + X，然后接一个 y
```

```sh
# 让脚本可执行
chmod +x auto.sh
```

重启完毕后使用 `root/auto.sh`，再 Ctrl + 左键 弹出的链接认证即可让节点恢复运作

顺便一提：精简版系统（运行在 docker 中的系统镜像）crontab 和 systemctl 等工具无法正常使用，甚至 /etc/rc.local 都不行，否则可以做到没有上面一行所说的步骤

## 疑难杂症解答

有事问 AI。相信 AI，没有 AI 就没有这个教程。学会如何问 AI 也是这个时代的人们必须掌握的技能

## 可以尝试的探索

It's YY time now!

- 多账号
    - 当你有多个 github 账号时，免费的额度的总和就会有盈余，租多台机器、租不同服务区的机器也就不再是问题。可操作空间大大提高。难度指数：※
- 设计脚本控制
    - 保活脚本——写一个长期后台运行的程序，通过调用 Python 的 **selenium** / *requests* 包，定期向 Claw Cloud 发送登录请求以伪装成活跃用户。为了防止机器被封。难度指数：※※
    - 全自动脚本——给脚本一个 github 账号或浏览器 Cookie 等认证必要信息，自动完成上述教程的全部步骤。真正的解放双手，自动化大佬的玩具。难度指数：※※※※
    - 顺便一提，Github Actions 是运行这种简单的定时保活脚本的最佳免费平台，不需要用户本地一直开着电脑
    - 如果写好脚本了可以考虑给我发送 PR，我会非常感谢的
- 商业化
    - 说白了就是卖钱，将这一套逻辑搭出来的梯子卖给别人赚钱。不仅需要写用户使用的客户端软件，写管理服务和收费的服务器程序，更需要在打好法律的马虎眼的同时，做好宣传、想好用户政策。这是在做到前两步基础上的、野心勃勃的再跨越。超出了技术、编程、方便自己使用的范畴，转向盈利、商业化、与资本相结合的境界。难度指数：※※※※※※

## 附录

### Windows 卸载 Tailscale 的方法

```bat
# 在 cmd 或 powershell 中使用自带的包管理器 winget 完成卸载
winget list
winget uninstall Tailscale
```

### 一些 Tailscale 指令

```sh
tailscale down # 断连
tailscale logout # 断联并退出登录
tailscale up --exit-node= # 停止使用出口节点。在 Windows 上直接打勾即可
tailscale up --advertise-exit-node=false # 停止申请成为出口节点
```

### 重启机器全流程（使用 `auto.sh`）

1. 浏览器打开 Claw Cloud 官网，进入 App Launchpad
2. 机器右侧 Operation，选择 Restart
3. 待机器重新回到 Running 状态后，点击机器名称进入详情页面
4. 往下拉找到右下角 Operation，点击带命令行图案的按钮连接机器，它在 Logs, Restart 按钮的右边
5. 注意连接的机器名称一定要对，比如 root@clawcloud-alpine-japan-0。不要按回车重新连接，重连到的机器必不对
6. 输入指令：`/root/auto.sh`
7. 按住 ctrl 点击弹出的链接，将机器加入 Tailnet 中
8. 回到命令行，输入指令：`/root/tailscale up --advertise-exit-node`
9. 在 Tailscale 的 Admin 控制台批准成为出口节点

### 本教程历史更新记录

2025 年 5 月，发现 Tailscale 作为出口节点软件的可行性

2025 年 9 月，使用 Github 学生开发者包免费租用到了 Azure 的虚拟机，成功实现了 Tailscale + VPS 搭建节点，此方法技术门槛已经非常低了

2025 年 10 月，基于 Azure 平台做出 v1.0 版本教程。但 Azure 刚需学生开发者包或信用卡，这使得此教程注定不能适用于多数人

2025 年 11 月，考虑到 Azure 的学生许可并非永久，开始寻找其他租用虚拟机的解决方案

2025 年 11 月，成功使用 Claw Cloud 上的 Devbox 虚拟机搭建节点，了解了如何将 Linux 的 Docker 镜像用作 VPS

2025 年 12 月，做出 v2.0 版本教程，命名为“基于 Claw Cloud Devbox + Tailscale 的自建节点科学上网教程”

2026 年 1 月，Claw Cloud 宣布停止 Devbox 服务。不过我既已知道如何容器化 VPS，转向使用 App Launchpad 也就不是什么难事，只是操作步骤变多了

2026 年 1 月，更新出 v3.0 版教程，当时选用的镜像名为“rastasheep/ubuntu-sshd”，为机器开启了公网访问端口，以方便在 cmd 中进行 ssh 连接。不过，在公网上暴露的公共镜像使得此教程存在较大的安全问题

2026 年 1 月，完善并改进教程（v3.1），更换镜像为现在的 alpine 镜像，取消机器的公网暴露而改为网页版 SSH 命令行连接，既提高了安全性，端口节省出的额度还能将 CPU 由 0.5 升级到 1 而让机器在高负载情况下表现更好，同时操作步骤更加精简
