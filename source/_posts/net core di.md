---
title: .NET Core依赖注入
date: 2017-06-05 19:36:16
tags: [.NET Core]
categories: .NET开发
---


依赖注入在实际项目中用处很广，用的不好会导致莫名其妙的结果，本人也在实践中经历了它所带来的坑，因此有必要需要搞清楚.NET Core中的依赖注入实现原理。

<!-- more -->

IoC主要体现了这样一种设计思想：通过将一组通用流程的控制从应用转移到框架之中以实现对流程的复用，同时采用“好莱坞原则”是应用程序以被动的方式实现对流程的定制。我们可以采用若干设计模式以不同的方式实现IoC，比如我们在上面介绍的模板方法、工厂方法和抽象工厂，接下来我们介绍一种更为有价值的IoC模式，即依赖注入（DI：Dependency Injection，以下简称DI）。

### 什么是依赖注入

依赖注入是为了达到解耦对象和其依赖的一项技术。一个类为了完成自身某些操作所需的对象是通过某种方式提供的，而不是使用静态引用或者直接实例化。通常情况下，类通过构造器来声明其依赖，遵循显式依赖原则。这种方式称作构造器注入。

当以DI思想来设计类时，这些类更加松耦合，因为他们不直接硬编码的依赖其合作者。这遵循了依赖倒置原则，即高层模块不应依赖底层模块，两者都应依赖抽象。类在构建时所需是抽象（如接口interface），而不是具体的实现。把依赖抽离成接口，把这些接口的实现作为参数也是策略设计模式的例子。在实际项目中，高层类库需要使用底层基础类库的功能，但是过多的在高层类库通过实例化的方法引入底层方法会使得项目的耦合性过高，不利于后期的开发和测试，我们希望每次一层的代码更加专注和独立。

把这几个问题搞明白了，我想依赖注入和控制反转（DI/IOC）也就明白了。

* 参与者都有谁?

一般有三方参与者，一个是某个对象；一个是IoC/DI的容器；另一个是某个对象的外部资源。又要名词解释一下，某个对象指的就是任意的、普通的Java对象; IoC/DI的容器简单点说就是指用来实现IoC/DI功能的一个框架程序；对象的外部资源指的就是对象需要的，但是是从对象外部获取的，都统称资源，比如：对象需要的其它对象、或者是对象需要的文件资源等等。


* 谁依赖于谁?

当然是某个对象依赖于IoC/DI的容器。

* 谁注入谁？

IOC/DI容器注入某个需要依赖的对象。

* 到底注入什么？

就是注入某个对象所需要的外部资源。

* 谁控制谁？

当然是IoC/DI的容器来控制对象了。

* 控制什么？

主要是控制对象实例的创建。

* 为何叫反转？

反转是相对于正向而言的，那么什么算是正向的呢？考虑一下常规情况下的应用程序，如果要在A里面使用C，你会怎么做呢？当然是直接去创建C的对象，也就是说，是在A类中主动去获取所需要的外部资源C，这种情况被称为正向的。那么什么是反向呢？就是A类不再主动去获取C，而是被动等待，等待IoC/DI的容器获取一个C的实例，然后反向的注入到A类中。

* 依赖注入和控制反转是同一个概念吗？

根据上面的讲述，应该能看出来，依赖注入和控制反转是对同一件事情的不同描述，从某个方面讲，就是它们描述的角度不同。依赖注入是从应用程序的角度在描述，可以把依赖注入描述完整点：应用程序依赖容器创建并注入它所需要的外部资源；而控制反转是从容器的角度在描述，描述完整点：容器控制应用程序，由容器反向的向应用程序注入应用程序所需要的外部资源。


### ASP.NET Core中的依赖注入

ASP.NET Core包含一个简单的内置容器（由IServiceProvider接口表示），默认情况下支持构造函数注入，ASP.NET通过DI提供某些服务。可以在Startup类中的ConfigureServices方法中配置内需要注入的服务。

使用.NET Core内置的服务。

| 服务类         | 生命周期           | 
| ------------- |:-------------:| 
| Microsoft.AspNetCore.Hosting.IHostingEnvironment | Singleton | 
| Microsoft.Extensions.Logging.ILoggerFactory |Singleton
| Microsoft.Extensions.Logging.ILogger<T>  | Singleton
| Microsoft.AspNetCore.Hosting.Builder.IApplicationBuilderFactory | Transient
| Microsoft.AspNetCore.Http.IHttpContextFactory	| Transient
| Microsoft.Extensions.Options.IOptions&lt;T&gt; | Singleton
| System.Diagnostics.DiagnosticSource | Singleton
| System.Diagnostics.DiagnosticListener	| Singleton
| Microsoft.AspNetCore.Hosting.IStartupFilter | Transient
| Microsoft.Extensions.ObjectPool.ObjectPoolProvider | Singleton
| Microsoft.Extensions.Options.IConfigureOptions<T> | Transient
| Microsoft.AspNetCore.Hosting.Server.IServer | Singleton
| Microsoft.AspNetCore.Hosting.IStartup | Singleton
| Microsoft.AspNetCore.Hosting.IApplicationLifetime | Singleton


在.net core源码的ServiceCollectionExtensions的实现中，有三个注册的方法AddScoped、AddSingleton、AddTransient。这其中的三个选项（Singleton、Scoped和Transient）体现三种对服务对象生命周期的控制形式。

**Singleton**：ServiceProvider创建的服务实例保存在作为根节点的ServiceProvider上，所有具有同一根节点的所有ServiceProvider提供的服务实例均是同一个对象。适合于单例模式。

**Scoped**：ServiceProvider创建的服务实例由自己保存，所以同一个ServiceProvider对象提供的服务实例均是同一个对象。 可以简单的认为是每请求（Request）一个实例，在一个请求中的对象实例都是同一个。

**Transient**：针对每一次服务提供请求，ServiceProvider总是创建一个新的服务实例。 每次访问时被创建，适合轻量级的，无状态的服务。

> Entity Framework上下文需要使用Scoped生命周期注入到服务容器内，同样使用Entity Framework的Repository需要同样使用Scoped生命周期注入到服务容器。


### 实际使用

```
 #region 依赖注入
// 创建数据库上下文
var contextOptions = new DbContextOptionsBuilder<NuctechDbContext>().UseSqlServer(Configuration.GetConnectionString("Nuctech.OnlineTax.DbConnStr")).Options;

#region 仓储部分 DbContextOptions作为单例进行注册，EFCoreContext和Repository作为Scoped进行注册，每请求一个新实例

services.AddSingleton(contextOptions).AddScoped<NuctechDbContext>();
services.AddScoped<IRepositoryContext, EntityFrameworkRepositoryContext>();
services.AddScoped<IEntityFrameworkRepositoryContext, EntityFrameworkRepositoryContext>();
services.AddScoped<IPassengerRepository, PassengerRepo>();
services.AddScoped<IContactRepository, ContactRepository>();
services.AddScoped<IDeclarationRepository, DeclarationRepository>();
services.AddScoped<IDeclarationItemRepository, DeclarationItemRepository>();
services.AddScoped<ICategoryRepository, CategoryRepository>();
services.AddScoped<IAnnouncementRepository, AnnouncementRepository>();
#endregion

#region 服务部分 每次访问都创建新的实例

services.AddTransient<IResponseService, ResponseService>();
services.AddTransient<IContactService, ContactService>();
services.AddTransient<IPassengerService, PassengerService>();
services.AddTransient<IDeclarationService, DeclarationService>();
services.AddTransient<ICategoryService, CategorySevice>();
services.AddTransient<IAnnouncementService, AnnoucementService>();
#endregion

#endregion

```