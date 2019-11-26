---
title: flask_socketio深入探究
date: 2019-05-04 17:04:56
tags: [flask,socketio,websocket]
categories: Python
---

在开发的项目中使用flask作为后台主要技术栈，对于WebSocket来说使用的是flask-socketio，今天我们一起深入探究下，flask-socketio的部署方式、使用过程中的发现的一些有趣的用法。

<!-- more -->

flask-socketio是flask技术栈中关于WebSocket的解决方案，[WebSocket](https://zh.wikipedia.org/wiki/WebSocket)是一种在单个TCP连接上进行全双工通信的协议，它帮助客户端与服务器之间建立稳定的长连接会话，传递消息。本次不涉及WebSocket的深入探讨，主要想分享写flask-socketio的实践经验。

### 部署方式

项目初期，flask-socketio是通过gunicorn(单工作者)+nginx+supervisor的方式进行部署，nginx使用ip_hash的方式进行负载均衡。有一次在和同事聊天过程中，讨论到基于ip_hash的方式可能对于在互联网上进行访问的话效果不好，没法做到真正的负载均衡，设想下，一个局域网内有若干台客户端访问服务器，如果基于ip_hash的话，nginx很可能将这些客户端都指向同一台服务器，因为他们的公网ip是一样的。访问过程如下：

192.168.0.101(用户电脑ip)->192.168.0.1/116.1.2.3(路由器的局域网ip及路由器得到的电信公网ip)–>119.147.19.234(负载均衡的nginx服务器)–>192.168.126.127(业务应用服务器)。

为了做到真正的负载均衡，因此将目前项目中nginx的ip_hash方式替换为nginx-sticky-module，sticky就是基于cookie的一种负载均衡解决方案，通过cookie实现客户端与后端服务器的会话保持, 在一定条件下可以保证同一个客户端访问的都是同一个后端服务器。请求来了，服务器发个cookie，并说：下次来带上，直接来找我。该模块支持粘性会话的同时(客户端保持和同一台服务器进行会话访问)可以做到水平扩展。

理想的flask-socketio架构图：

{% asset_img 1.jpg 架构图 %}

它可以保证即使在同一个局域网内的计算机，也可以访问不同的应用服务器，方便以后进行水平扩展。在这里注意的是，在使用gunicorn进行部署的时候，由于gunicorn多工作者(workers)不支持粘性会话，因此运行gunicorn时候确保只有一个工作者启用，启动命令如下:

```
gunicorn --worker-class eventlet -w 1 module:app
```

参考架构图，我们使用的部署方式是nginx作为负载平衡器，使用nginx-sticky(基于cookie)路由，在每一个应用服务器上都运行一个gunicorn进程，每个gunicorn进行使用**单worker**启动。

在架构图中，可以看到多个应用服务器之间是通过rabbitmq中转的，这是由于每台服务器只拥有客户端连接的一部分，当某一台服务器要进行广播时，有些客户端却连接到了另一台服务器，换句话说服务器只能发送消息给连接到自身服务器的客户端，如果要广播到其他服务器所连接的客户端的话，需要通过rabbitmq或者redis进行中转和协调。

在使用rabbitmq部署之后，会发现rabbitmq控制面板中会出现应用服务器对应的队列，说明flask-socketio应用服务器之间通过rabbitmq通信来实现跨服务器广播等操作。

{% asset_img 3.png rabbitmq %}

使用消息队列时，还需要安装其他依赖项：
* 对于Redis，必须安装软件包redis（pip install redis）。
* 对于RabbitMQ，必须安装软件包kombu（pip install kombu）。
* 对于Kombu支持的其他消息队列，请参阅Kombu文档以了解需要哪些依赖关系。
* 如果使用eventlet或gevent，那么通常需要修补Python标准库来强制消息队列包使用协程友好的函数和类。

### socketio中namespace和room

namespace 和room的概念其实用来同一个服务端socket多路复用的。namespace，room和socketio的关系如下。socket会属于某一个room，如果没有指定，那么会有一个default的room。这个room又会属于某个namespace，如果没有指定，那么就是默认的namespace /。

客户端连接时指定自己属于哪个namespace。服务端看到namespace就会把这个socket加入指定的namespace。socketio广播时以namespace为单位，如果广播给某个room的话需要额外指定room的名字。


对于namespace和room的概念，如图：
{% asset_img 2.png namespace和room %}


### 外部使用

在项目开发过程中，也对在非flask-socketio项目外发布消息进行了使用，这意味着有的时候我们可以直接emit消息通过一个非socketio服务应用，socketio服务应用需要建立flask实例，并把该实例传入socketio构造函数中，类似这样:

```
app = Flask("EMDP_WS")
socketio = SocketIO(app, async_mode="eventlet")
```

对于在外部使用socketio发布消息，可以通过rabbitmq或者redis进行消息中转，需要指定**message_queue**参数，参考官网如下：

```
socketio = SocketIO(message_queue='redis://')
socketio.emit('my event', {'data': 'foo'}, namespace='/test')
```



### 参考资料
------
* [Nginx Sticky的使用及踩过的坑（nginx-sticky-module）](https://blog.csdn.net/yu870646595/article/details/52056340)
* [flask-socketio 项目部署](https://inkgenius.github.io/flak-SocketIO%E9%A1%B9%E7%9B%AE%E9%83%A8%E7%BD%B2/)
* [socket.io 中namespace 和 room的概念。](https://blog.csdn.net/lijiecong/article/details/50781417)