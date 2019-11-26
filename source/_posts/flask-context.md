---
title: flask context深入探究
date: 2019-11-26 21:04:34
tags: [flask,context]
categories: Python
---

上下文这个词语多见于文章中，代表一句话中的语境，在实际开发中特别是WEB开发中也经常遇到。上下文通常是一种属性的有序系列，以字典的方式贮存在服务器内存中。在对象的激活过程中创建上下文，对象被配置为要求某些额外属性，如请求内容、会话、安全性等等。本文主要探究Flask上下文。

<!-- more -->

Flask提供了两种上下文，一种是[<font color=#FFD700 size=3>应用上下文</font>](https://flask.palletsprojects.com/en/1.1.x/appcontext/#purpose-of-the-context)，一种是[<font color=#FFD700 size=3>请求上下文</font>](https://flask.palletsprojects.com/en/1.1.x/reqcontext/)。

首先通俗地解释下**应用上下文**和**请求上下文**：
1. application 指的就是当你调用app = Flask(name)创建的这个对象app；
2. request 指的是每次http请求发生时，WSGI server(比如gunicorn)调Flask.call()之后，在Flask对象内部创建的Request对象；
3. application 表示用于响应WSGI请求的应用本身，request 表示每次http请求;
4. application的生命周期大于request，一个application存活期间，可能发生多次http请求，所以，也就会有多个request；

这里科普下WSGI服务器作用：
> Web服务器网关接口（Python Web Server Gateway Interface，缩写为WSGI）是为Python语言定义的Web服务器和Web应用程序或框架之间的一种简单而通用的接口。

> Python Web 开发中，服务端程序可以分为两个部分，一是服务器程序，二是应用程序。前者负责把客户端请求接收，整理，后者负责具体的逻辑处理。为了方便应用程序的开发，我们把常用的功能封装起来，成为各种Web开发框架，例如 Django, Flask, Tornado。不同的框架有不同的开发方式，但是无论如何，开发出的应用程序都要和服务器程序配合，才能为用户提供服务。这样，服务器程序就需要为不同的框架提供不同的支持。这样混乱的局面无论对于服务器还是框架，都是不好的。对服务器来说，需要支持各种不同框架，对框架来说，只有支持它的服务器才能被开发出的应用使用。

>这时候，标准化就变得尤为重要。我们可以设立一个标准，只要服务器程序支持这个标准，框架也支持这个标准，那么他们就可以配合使用。一旦标准确定，双方各自实现。这样，服务器可以支持更多支持标准的框架，框架也可以使用更多支持标准的服务器。

>Python Web开发中，这个标准就是 The Web Server Gateway Interface, 即 WSGI. 这个标准在PEP 333中描述，后来，为了支持 Python 3.x, 并且修正一些问题，新的版本在PEP 3333中描述。

### 应用上下文

应用上下问存在的主要原因是，在过去，请求上下文被附加了一堆函数，但是又没有什么好的解决方案。因为 Flask 设计的支柱之一是你可以在一个 Python 进程中拥有多个应用。首先看一下应用上下文定义类的代码:
```
class AppContext(object):
    """The application context binds an application object implicitly
    to the current thread or greenlet, similar to how the
    :class:`RequestContext` binds request information.  The application
    context is also implicitly created if a request context is created
    but the application is not on top of the individual application
    context.
    """

    def __init__(self, app):
        self.app = app
        self.url_adapter = app.create_url_adapter(None)

        # Like request context, app contexts can be pushed multiple times
        # but there a basic "refcount" is enough to track them.
        self._refcnt = 0

    def push(self):
        """Binds the app context to the current context."""
        self._refcnt += 1
        _app_ctx_stack.push(self)

    def pop(self, exc=None):
        """Pops the app context."""
        self._refcnt -= 1
        if self._refcnt <= 0:
            if exc is None:
                exc = sys.exc_info()[1]
            self.app.do_teardown_appcontext(exc)
        rv = _app_ctx_stack.pop()
        assert rv is self, 'Popped wrong app context.  (%r instead of %r)' \
            % (rv, self)

    def __enter__(self):
        self.push()
        return self

    def __exit__(self, exc_type, exc_value, tb):
        self.pop(exc_value)
```
应用上下文一个主要作用就是<font color=#1E90FF size=5>确定请求所在的应用</font>。“应用上下文”也是一个上下文对象，可以使用with语句构造一个上下文环境，它也实现了push、pop等方法。

既然“请求上下文”中也包含app等和当前应用相关的信息，那么只要调用_request_ctx_stack.top.app或者current_app就可以确定请求所在的应用了，那为什么还需要“应用上下文”对象呢？对于单应用单请求来说，使用“请求上下文”确实就可以了。**然而，Flask的设计理念之一就是多应用的支持。**当在一个应用的请求上下文环境中，需要嵌套处理另一个应用的相关操作时，“请求上下文”显然就不能很好地解决问题了。如何让请求找到“正确”的应用呢？

为了应对这个问题，Flask中将应用相关的信息单独拿出来，形成一个“应用上下文”对象。这个对象可以和“请求上下文”一起使用，也可以单独拿出来使用。不过有一点需要注意的是：在创建“请求上下文”时一定要创建一个“应用上下文”对象。有了“应用上下文”对象，便可以很容易地确定当前处理哪个应用，这就是魔法current_app。

下面以一个多应用的例子进行说明:
```
# example - Flask v0.9
>>> from flask import Flask, _request_ctx_stack, _app_ctx_stack
# 创建两个Flask应用
>>> app = Flask(__name__)
>>> app2 = Flask(__name__)
# 先查看两个栈中的内容
>>> _request_ctx_stack._local.__storage__
{}
>>> _app_ctx_stack._local.__storage__
{}
# 构建一个app的请求上下文环境，在这个环境中运行app2的相关操作
>>> with app.test_request_context():
        print "Enter app's Request Context:"
        print _request_ctx_stack._local.__storage__
        print _app_ctx_stack._local.__storage__
        print
        with app2.app_context():
            print "Enter app2's App Context:"
            print _request_ctx_stack._local.__storage__
            print _app_ctx_stack._local.__storage__
            print
            # do something
        print "Exit app2's App Context:"
        print _request_ctx_stack._local.__storage__
        print _app_ctx_stack._local.__storage__
        print
# Result
Enter app's Request Context:
{<greenlet.greenlet object at 0x000000000727A178>: {'stack': [http://localhost/' [GET] of __main__>]}}
{<greenlet.greenlet object at 0x000000000727A178>: {'stack': [<flask.ctx.AppContext object at 0x0000000005DD0DD8>]}}

Enter app2's App Context:
{<greenlet.greenlet object at 0x000000000727A178>: {'stack': [http://localhost/' [GET] of __main__>]}}
{<greenlet.greenlet object at 0x000000000727A178>: {'stack': [<flask.ctx.AppContext object at 0x0000000005DD0DD8>, <flask.ctx.AppContext object at 0x0000000007313198>]}}

Exit app2's App Context
{<greenlet.greenlet object at 0x000000000727A178>: {'stack': [http://localhost/' [GET] of __main__>]}}
{<greenlet.greenlet object at 0x000000000727A178>: {'stack': [<flask.ctx.AppContext object at 0x0000000005DD0DD8>]}}
```
上述例子中：
1. 我们首先创建了两个Flask应用app和app2；
2. 接着我们构建了一个app的请求上下文环境。当进入这个环境中时，这时查看两个栈的内容，发现两个栈中已经有了当前请求的请求上下文对象和应用上下文对象。并且栈顶的元素都是app的请求上下文和应用上下文；
3. 之后，我们再在这个环境中嵌套app2的应用上下文。当进入app2的应用上下文环境时，两个上下文环境便隔离开来，此时再查看两个栈的内容，发现**_app_ctx_stack栈**中推入了app2的应用上下文对象，并且栈顶指向它。这时在app2的应用上下文环境中，current_app便会一直指向app2；
4. 当离开app2的应用上下文环境，**_app_ctx_stack栈**便会销毁app2的应用上下文对象。这时查看两个栈的内容，发现两个栈中只有app的请求的请求上下文对象和应用上下文对象。
5. 最后，离开app的请求上下文环境后，两个栈便会销毁app的请求的请求上下文对象和应用上下文对象，栈为空。

### 参考资料
------
* [Flask的Context(上下文)学习笔记](https://www.jianshu.com/p/7a7efbb7205f)
* [WSGI简介](https://blog.csdn.net/on_1y/article/details/18803563)
* [Flask中的请求上下文和应用上下文](https://zhuanlan.zhihu.com/p/26097310)