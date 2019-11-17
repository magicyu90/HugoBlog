---
title: 你了解BSON吗
date: 2017-01-19 16:58:34
tags: [BSON]
categories: 理解计算机
---


我们都使用过JSON，也听说过BSON（Binary Serialized Document Format）是一种基于二进制形式的存储格式，具有轻量性、高效性的特点，可是为什么它很高效呢，为什么MongoDB会选择使用这种事格式来存储数据呢，跟着本文一探究竟吧。

<!-- more -->

####  BSON 格式
```
{
  "Name":"Hugo",
  "Age":25,
  "Address": ["8 Rue Sevin","3 Rue Tronchet"]
}
```
上述例子就是一个最简单的BSON存储格式，外面的"{}"来告诉BSON解释其这是一个Document，我之所以说成Document是为了让你联想到MongoDB，因为MongoDB也是用Document存储数据的。在一个Document中包含着若干个element-元素，每个Element由3部分组成，**名称**，**类型**，**值**，上面例子中"Name"就是element的名称，"Hugo"就是这个element的值，BSON所支持的类型包括：
* String
* Interger（Int32 和Int64）
* double（64位）
* date（UTC格式）
* byte数组
* boolean
* null
* BSON object
* BSON array
* JavaScript Code
* 正则表达式

#### 高效性
跟JSON相比，BSON最初的设计方案就是为了提高数据检索的，特别对于一个很大的Document来说，BSON就有很高的检索速度，BSON在存储数据时候会记录长度前缀-length prefix和explicit array indice-明确的说明。
#### 存储类型
BSON最新的1.1版本中，一共定义了6个类型来序列化数据存储到计算机中。`byte,int32,int64,uint64,double,decimal128`。比较常用的是前四种。在存储数据的时候使用的是little-endian-小端存储，即低位字节存放在较低的存储器地址,[了解更多](http://blog.magicyu.com/%E5%AD%97%E7%AC%A6%E7%BC%96%E7%A0%81/)。

#### 存储规则
根据BSON规则，一个Document被分解成三部分，**Int32，e_list，"\x00"**。

* Int32：记录该Document的总长度，使用Int32存储，占用了4个字节，这个总长度也包括了Int32本身的长度，安小端排序存储。
* e_list：作为BSON规则中的一个中间内容，它包括两部分，**element,e_list**，注意这里要有递归思想，解释器肯定是依次解释element的，对于还没有进行解释的，BSON称之为e_list，这是一个**中间形式**，解释器的最终结果是把document中的element都解释出来。
* "\x00"：这个16进制相当于一个结束符，表示该部分解释已经结束。

##### 举例说明
我使用ASP.NET Web API输出一个BSON数据，通过Fiddler可以看出其结果的Hexstring。

{% asset_img bson1.jpg BSON结果 %}

绿色部分是Http Response中的Header部分，黑色部分是Body部分。我们首先自己试着解析出结果，看能否与输出结果匹配。

对于`"Name":"Hugo"`，首先根据BSON规则，

{% asset_img bson.png BSON规则 %}

element需要解析成 **数据类型部分  e_name  值**三部分，因为这个element是个string类型，因此数据类型部分被解释成"\x02"，e_name需要解释成cstring，
然后cstrig又被解释成(byte*) "\x00"，byte*代表一个或多个byte，查询ASCII码表，知道Name为4E 61 6D 65，加上\x00，完整的Name为4E 61 6D 65 00，
值等于string，string又被解释成int32 (byte*) "\x00"，
分别代表字符串的个数+1（+1是因为算上"\x00"结束符），每个字符对应的UTF8编码，结束符。值是Hugo，
被解析成05 00 00 00 48 75 67 6F 00，**注意**Int32总是按**4个字节小端存储**。
一个完整的Name对应的16进制字符串是`02 4E 61 6D 65 00 05 00 00 00 48 75 67 6F 00` 和 Fiddler给出的结果完全匹配。

#### 总结
由于每个元素的长度都存储在元素的头部，因此可以根据这个长度直接进行seek到指定的点上就可以读到内容了，这就是为什么遍历速度快！额外的存储空间是BSON一个劣势势，比如对{“field”:2}，在JSON的存储上7只使用了一个字节，而如果用BSON，那就是至少4个字节（32位），因为BSON没有Int 16类型，哈哈。

JSON是一个很方便的数据交换格式，但是其类型比较有限。BSON在其基础上增加了“byte array”数据类型。这使得二进制的存储不再需要先base64转换后再存成JSON。大大减少了计算开销和数据大小。

对于BSON的设计，确实达到了这三点目标：**更快的遍历速度、操作更简易、增加了额外的数据类型**

#### 参考资料
------
* [BSON官方文档](http://bsonspec.org/)
* [BSON特性探讨及基于其特性的MongoDB优化](http://blog.nosqlfan.com/html/2914.html)


