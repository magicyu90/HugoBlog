---
title: https初探
date: 2017-01-11 23:07:42
tags: [https,网络]
categories: 网络
---


HTTPS作为Web开发中必不可缺的一个重要知识点，我今天打算总结一下。

HTTPS（全称：Hyper Text Transfer Protocol over Secure Socket Layer），是以安全为目标的HTTP通道，简单讲是HTTP的安全版。即HTTP下加入SSL层，HTTPS的安全基础是SSL，因此加密的详细内容就需要SSL。
HTTPS可以说是HTTP的一个强化版本，加强的部分主要是对于传输信息的加密，保证信息在传输的过程中无法被篡改，从而保证了信息的安全性。

<!-- more -->

HTTPS（全称：Hyper Text Transfer Protocol over Secure Socket Layer），是以安全为目标的HTTP通道，简单讲是HTTP的安全版。即HTTP下加入SSL层，HTTPS的安全基础是SSL，因此加密的详细内容就需要SSL。


## SSL/TLS由来
不使用SSL/TLS的HTTP通信，就是不加密的通信。所有信息明文传播，带来了三大风险。
1. 窃听风险（eavesdropping）：第三方可以获知通信内容。
2. 篡改风险（tampering）：第三方可以修改通信内容。
3. 冒充风险（pretending）：第三方可以冒充他人身份参与通信。

SSL/TLS协议是为了解决这三大风险而设计的，希望达到：
1. 所有信息都是加密传播，第三方无法窃听。
2. 具有校验机制，一旦被篡改，通信双方会立刻发现。
3. 配备身份证书，防止身份被冒充。

## SSL介绍
  SSL（Secure Sockets Layer，安全套接层），及其继任者 TLS（Transport Layer Security，传输层安全）是为网络通信提供安全及数据完整性的一种安全协议。TLS与SSL在传输层对网络连接进行加密。

## SSL/TSL 基本过程：
1. 客户端向服务器端索要并验证公钥。
2. 双方协商生成"对话密钥"。
3. 双方采用"对话密钥"进行加密通信。

上面过程的前两步，又称为”握手阶段”（handshake）。
由于证书中使用公约加密信息的计算量太大，因此客户端和服务器端协商生成一个对话秘钥，使用对话秘钥对以后传输的信息进行加密，减少了使用证书公钥耗用的时间，但是协商秘钥期间，会使用证书的公钥进行加密传输。

## 实战说明：测试与pro.ihealthlabs.com进行连接 使用**WireShark**进行抓包分析

### 第一步：TCP三次握手

位码即tcp标志位，有6种标示：SYN(synchronous建立联机) ACK(acknowledgement 确认) PSH(push传送) FIN(finish结束) RST(reset重置) URG(urgent紧急)。<br>tcp包重要信息：Sequence number(顺序号码) Acknowledge number(确认号码)。

**第一次握手**:客户端192.168.1.31 发送位码syn包，并随机产生一个seq number=0(由于wireshark为了便于观察，初始化这个随机值为0,后面的seq和ack都在此基础上累加)
**第二次握手**:pro主机54.76.150.159 收到syn包之后，必须确认客户端的syn包，发送ack包，因此添加位码ack number=1(上一步的seq number+1) ,ack=1 并随机一个seq number=0回复给客户端
**第三次握手**:客户端发送确认包 ack number=1 (上一步的seq number+1) 和ack=1发送给服务器，完成三次握手。 客户端与服务器开始进入https重要环节，协商秘钥。


### 第二步：协商秘钥

{% asset_img 1.png HTTPS handshake %}

* 客户端发送请求client hello

在这一步中，客户端重要向服务器提供以下信息: 支持的协议版本，如图TLSv1.2版, 客户端生成的随机数(第一次）支持的加密算法,比如RSA公钥加密，支持的压缩方法。

{% asset_img 2.png Client hello %}
 
需要注意的是，原本客户端发送的信息中不包括服务器的域名，也就是说服务器只包含一个网站，服务器用一个证书。但是对于虚拟主机用户来说这样很不方便， 因此2006年TLS协议加了一个Server name的扩展。

* 服务器回应Server hello

（1） 确认使用的加密通信协议版本，比如TLS 1.0版本。如果浏览器与服务器支持的版本不一致，服务器关闭加密通信。
（2） 一个服务器生成的随机数(第二次)，稍后用于生成"会话密钥"(session secret)。
（3） 确认使用的加密方法，比如RSA公钥加密。
（4） 服务器证书。

{% asset_img 3.png Server hello %}

* 客户端再次回应

 客户端收到服务器回应以后，首先验证服务器证书。如果证书不是可信机构颁布、或者证书中的域名与实际域名不一致、或者证书已经过期，就会向访问者显示一个警告，由其选择是否还要继续通信。如果证书没有问题，客户端就会从证书中取出服务器的公钥。然后，向服务器发送下面三项信息。
（1） 一个随机数(第三次), 该随机数用上一步确定的加密算法（RSA或者Diffie-Hellman得到），又称"pre-master key"该随机数用服务器公钥加密，防止被窃听。
（2） 编码改变通知，表示随后的信息都将用双方商定的加密方法和密钥发送。
（3） 客户端握手结束通知，表示客户端的握手阶段已经结束。这一项同时也是前面发送的所有内容的hash值，用来供服务器校验。
          
 >不管是客户端还是服务器，都需要随机数，这样生成的密钥才不会每次都一样。由于SSL协议中证书是静态的，因此十分有必要引入一种随机因素来保证协商出来的密钥的随机性。
 >对于RSA密钥交换算法来说，pre-master-key本身就是一个随机数，再加上hello消息中的随机，三个随机数通过一个密钥导出器（Master Secret）最终导出一个对称密钥。
 >pre master的存在在于SSL协议不信任每个主机都能产生完全随机的随机数，如果随机数不随机，那么pre master secret就有可能被猜出来，那么仅适用pre master secret作为密钥就不合适了，因此必须引入新的随机因素，那么客户端和服务器加上pre master secret三个随机数一同生成的密钥就不容易被猜出了，一个伪随机可能完全不随机，可是是三个伪随机就十分接近随机了，每增加一个自由度，随机性增加的可不是一。"

{% asset_img 4.png Client response %}

* 服务器最后回应
  
服务器收到客户端的第三个随机数pre-master key之后，计算生成本次会话所用的”会话密钥”。然后，向客户端最后发送下面信息。
（1）编码改变通知，表示随后的信息都将用双方商定的加密方法和密钥发送。
（2）服务器握手结束通知，表示服务器的握手阶段已经结束。这一项同时也是前面发送的所有内容的hash值，用来供客户端校验。

{% asset_img 5.png Server response %}

### 第三步：双方采用对话秘钥进行加密通信

{% asset_img 6.png Application data %}


## Secret Key 生成过程流程图:

{% asset_img 7.png Secret key %}


### 参考资料
------
* [HTTPS详解SSL/TLS | 皓眸大前端](http://www.haomou.net/2014/08/30/2014)