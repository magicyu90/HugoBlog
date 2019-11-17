---
title: 简析.NET Core
date: 2017-01-16 22:12:46
tags: [.NET Core]
categories: .NET开发
---

.NET Core已经诞生了一年多了，作为一个从.NET做起的的开发人员，肯定希望.NET可以逐渐壮大，在Mac、Linux平台上都可以大显神威，微软每走一步都会都广大的开人人员有很不少影响，所以有必要了解.NET Core体系结构。

<!-- more -->

### 为什么我们需要.NET Core
#### 跨平台的需要
如果你的目标是创建一个应用可以运行到多个平台(Windows,Linux,MacOS)，最好的选择是使用.Net Core作为运行时(CoreCLR)和跨平台的类库。另外一个选择就是使用[Mono Project](https://github.com/mono)。

两个选择都是开源的，但是微软明确，官方的表示将会投入大量兵力去开发.NET Core。

当使用.NET Core跨平台时，最好的开发体验还是在Windows下使用Visual Studio进行开发，因为它支持了许多提高生产力的功能，比如项目管理（TFS）、本地调试、远程调试、智能编辑器、测试等等。但这并不表示在其他平台开发.NET Core就会使生产力降低，本人在Mac上使用VSCode开发感觉很有快感，体积小并且快速是VSCode的一个亮点，再也不会像过去在Windows上打开项目会很久的情况出现，同时VSCode也支持debug，总之对于常见功能都可以在VSCode上找到。对于其他第三方编辑器Sublime，Emacs，Atom来说，只要装上Omnisharp插件，开发.NET Core应用将会变得更加方便。

#### 微服务-Microservices

试想下当你开发一个Microservice的应用时候，最大的好处就是微服务中的每一部分可以使用不同的技术、framework、编程语言进行开发。如果你想创建一个高效、覆盖面广的微服务，你应该试一试.NET Core。

#### 高可用性，高扩展性

当你的平台需要良好的可用性、高扩展性的时候，.NETCore 和ASP.NET Core有着不俗的表现，


#### 基于命令行的开发方式

如果你曾经或者现在是个使用轻量级的文本编辑器并擅长使用命令进行开发的技术人员的话，那么.NET Core可以让你有同样的感觉，.NET Core当初就是被设计成CLI的。在VS Code工具中，常用的命令需要在命令行中进行完成，而不会在像Visual Studio那样提供很庞大甚至臃肿的操作界面了，轻便简介是微软为了更好的拥抱开源所作出对编译器的改变。


### .NET Framework vs .NET Core
#### .NET Framwork
对于.NET Framework来说，从微软推出的第一个Framework到现在，数年间每个Framework都有类似的体系但又有自己的特有功能，以用于在不同的设备和平台上运行。

![.NET Framework](http://qiniu.xdpie.com/c6c5a11235efd0aac9620cdbcaae2633.png?imageView2/2/w/700&_=5603928)
-

#### .NET Core

为了改进上述问题，微软开发出来了.NET Core，是一个开源的模块化的Framework，不管是开发web或移动设备都在同一个Framework（.NET Core）下运行，而且 .NET Core也可在不同的操作系统上运行，包括Windows、linux、MacOS，实现了跨平台跨设备。

![.NET Core](http://qiniu.xdpie.com/539007367e8973b9b97b49b2f2d3450e.png?imageView2/2/w/700&_=5613373)

上图描述了 .NET Core的系统构成，最上层是应用层，是开发基于UI应用的框架集，包括了ASP.NET Core(用于创建web app)，和 UWP(用于创建Windows10 app)。

中间层是公共库(CoreFX),实现了.NET Standard Library ,囊括了常用系统级操作例如（文件、网络等）。

在CoreFx下是运行时环境，.NET Core 包含了两种运行时(CoreCLR、CoreRT),CoreCLR是一种基于即时编译程序(Just in time compiler,JIT)的运行时,它使用了跨平台开源的编译器RyuJIT,而CoreRT是使用提前编译器(Ahead of time compiler,AOT)的运行时,它既可以使用RyuJIT来实现AOT编译也可以使用其他的AOT编译器。由于AOT提前编译IL成了机器码，在移动设备上也具有更好的启动速度和节能性。

#### 与**.NET Framwork**比较

* 应用模型 -- .NET Core 不支持所有 .NET Framework 应用模型，某种程序上是因为其中许多模型都是基于 Windows 技术，如 WPF（基于 DirectX 生成）。 但 .NET Core 和 .NET Framework 两者都支持控制台和 ASP.NET Core 应用模型。

* API -- .NET Core 包含很多与 .NET Framework 相同，但数量较少的 API，并且具有不同的组成要素（程序集名称不同；关键用例中的类型形状不同）。 目前，这些差异通常都需要更改，以将源移植到 .NET Core。 .NET Core 实现 .NET 标准库 API，该 API 将随着时间推移而增长，以便包含更多 .NET Framework BCL API。

* 子系统 -- .NET Core 实现 .NET Framework 中子系统的子级，目的是实现更简单的实现和编程模型。 例如，不支持代码访问安全性 (CAS)，但支持反射。

* 平台 -- .NET Framework 支持 Windows 和 Windows Server，而 NET Core 还支持 macOS 和 Linux。

* 开放源 -- .NET Core 属于开放源，而 .NET Framework 的只读子集属于开放源。


### 参考资料
------
* [简析.NET Core 以及与 .NET Framework的关系](http://www.cnblogs.com/vipyoumay/p/5603928.html)
* [简析.NET Core 体系](http://www.cnblogs.com/vipyoumay/p/5613373.html)
* [.NET Core指南](https://docs.microsoft.com/zh-cn/dotnet/articles/core/)
