---
title: ASP.NET Web API-路由篇
date: 2017-01-18 20:45:10
tags: [ASP.NET Web API]
categories: .NET开发
---


由于项目的需要使用ASP.NET Web API进行开发，因此决定回顾下Web API，在ASP.NET Web API中，路由起到了定位controller、action，并将数据传入到action中，把客户端发来的请求**映射**到对应的action上的过程，它和ASP.NET MVC中的路由一个主要区别是MVC中的路由是基于URI的，而API中的路由是基于HTTP的，除此之外路由表、路由属性等知识都需要了解下。

<!-- more -->

### 路由
#### Route Table-路由表
在ASP.NET Web API中controller是一个处理http请求的类，在这个类中定义了一些方法,如果没有加**NonAction**标记的话都认为它是action。当API Framework收到请求后，会路由到对应action。在创建完API项目之后，VS会自动为我们创建一个默认路由：

```
routes.MapHttpRoute(
    name: "API Default",
    routeTemplate: "api/{controller}/{id}",
    defaults: new { id = RouteParameter.Optional }
);
```

在这个默认路由模板中，controller和id是两个变量，分别对应controller的名字和可选参数。

&emsp;&emsp;&emsp;/api/contacts

&emsp;&emsp;&emsp;/api/contacts/1

&emsp;&emsp;&emsp;/api/products/gizmo1

像类似的请求URI都是匹配默认路由的。API Framework首先会检查请求URL是否匹配默认路由，如果匹配的话，会进入选择controller和action阶段。通过URI中的{controller}进入到对应的controller。
一个controller中的方法有那么多路由引擎是如何找到对应的action呢？它会根据你定义的action名称来找，如果你定义的action以Get开头，类似"GetBook" "GetProduct"这样的action时候，路由引擎会认为这是一个Get请求，因此路有引擎根据action名称中是否含有**Get|Post|Put|Delete**关键字来匹配URI和action的。如果URI中如果有id这个可选参数的话，会把该参数传入到action内。
#### 路由action
可以想象出一个路由如果有多个以Get开头的action话就不太容易定位了，那么该怎么办呢，有两个选择改变默认路由模板，添加action变量到模板中，或者使用Attribute Routing。默认路由只精确到了controller，我们需要在默认路由的模板中添加{action}部分。可以自己新定义一个路由模板，路由中包含3个参数位置。

```
routes.MapHttpRoute(
    name: "ActionApi",
    routeTemplate: "api/{controller}/{action}/{id}",
    defaults: new { id = RouteParameter.Optional }
);
```

通过使用**ActionName**来覆盖action本身的方法名，在下面例子中，两个方法都可以map到"api/products/thumbnail/id"，其中一个是Get 另一个是Post。

```
public class ProductsController : ApiController
{
    [HttpGet]
    [ActionName("Thumbnail")]
    public HttpResponseMessage GetThumbnailImage(int id);
    [HttpPost]
    [ActionName("Thumbnail")]
    public void AddThumbnailImage(int id);
}
```
#### Attribute Routing-特性路由
convetion-based routing基于公约的路由是Web API最初版本使用的路由规则，它最大的好处就是在一个文件中定义一个或者多个路由模板方案用来匹配URI，这个规则可以应用到项目中的所有controller，
但是这种定义规则不适用于某些场景，比如一个controller中含有多个子资源，或者有关联关系的资源，比如我们想得到某一个客户底下的所有订单：`/customers/1/orders`这样的路由，
为了写出符合Restful规范的路由，传统的convention-based路由就显得有些吃力了，我么需要在每一个action中进行个性化定义路由，因此Web API 2.0版本推出了Attribute Routing。

```
[Route("customers/{customerId}/orders")]
public IEnumerable<Order> GetOrdersByCustomer(int customerId) { ... }
```

##### 好处：
* 在不改变action名称的情况下可以灵活修改
* 有关联资源时，可以创建更加符合Restful规范的路由
* 精细化控制

#### Route Prefixes-路由前缀定义

通过定义RoutePrefixes来为一个controller设置路由公用前缀。
```
[RoutePrefix("api/books")]
public class BooksController : ApiController
{
  ...
}
```

如果在一个action中不想使用RoutePrefix，可以使用**~**进行覆盖。

```
[RoutePrefix("api/books")]
public class BooksController : ApiController
{
    // GET /api/authors/1/books
    [Route("~/api/authors/{authorId:int}/books")]
    public IEnumerable<Book> GetByAuthor(int authorId) { ... }
}
```

#### Route Constraints-路由约束
路有约束用来指定路由中的参数名称和类型，句式为`{parameter:constraint}`,比如：
```
[Route("users/{id:int}"]
public User GetUserById(int id) { ... }
```
也可以进行多重约束，每个约束通过"/"进行分割。

```
[Route("users/{id:int:min(1)}")]
public User GetUserById(int id) { ... }
```
#### 自定义路由约束
[参考这里](https://www.asp.net/web-api/overview/web-api-routing-and-actions/attribute-routing-in-web-api-2)
#### Optional,default paramters-可选、默认参数
* 可选参数并具有默认值
```
public class BooksController : ApiController
{
    [Route("api/books/locale/{lcid:int?}")]
    public IEnumerable<Book> GetBooksByLocale(int lcid = 1033) { ... }
}
```
* 默认参数
```
public class BooksController : ApiController
{
    [Route("api/books/locale/{lcid:int=1033}")]
    public IEnumerable<Book> GetBooksByLocale(int lcid) { ... }
}
```
#### 定义路由名称
通过使用**Name**设置action的路由名称，并且可以生成这个action的URI通过定义的**Name**。
```
public class BooksController : ApiController
{
    [Route("api/books/{id}", Name="GetBookById")]
    public BookDto GetBook(int id) 
    {
        // Implementation not shown...
    }
    
    [Route("api/books")]
    public HttpResponseMessage Post(Book book)
    {
        var response = Request.CreateResponse(HttpStatusCode.Created);

        //可以传入参数到这个action中
        string uri = Url.Link("GetBookById", new { id = book.BookId });
        response.Headers.Location = new Uri(uri);
        return response;
    }
}
```


### 参考资料
------
* [官方路由讲解](https://www.asp.net/web-api/overview/web-api-routing-and-actions)