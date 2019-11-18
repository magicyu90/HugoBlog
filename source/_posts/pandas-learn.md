---
title: Pandas使用 (一)
date: 2019-11-01 13:58:25
tags: [pandas]
categories: Python
---

Pandas 是非常著名的开源数据处理库，我们可以通过它完成对数据集进行快速读取、转换、过滤、分析等一系列操作。本文会把平时里常用的Pandas操作进行总结。
<!-- more -->

### Group操作
Groupby 是pandas 中非常重要的一个函数, 主要用于数据聚合和分类计算. 其思想是“split-apply-combine”（拆分 - 应用 - 合并）。
{% asset_img 0.png groupby流程%}
只要理解好这个流程思想，进行groupby操作就会相对容易些。

在接下来的操作中，我们使用Pandas和Numpy类库，首选从网上down一个基础的DataFrame进行相关操作。

```
In [1]: import pandas as pd
In [2]: import numpy as np
In [3]: url = 'https://gist.githubusercontent.com/alexdebrie/b3f40efc3dd7664df5a20f5eee85e854/raw/ee3e6feccba2464cbbc2e185fb17961c53d2a7f5/stocks.csv'
In [4]: df=pd.read_csv(url)
In [5]: df
Out[5]: 
          date symbol     open     high      low    close    volume
0   2019-03-01   AMZN  1655.13  1674.26  1651.00  1671.73   4974877
1   2019-03-04   AMZN  1685.00  1709.43  1674.36  1696.17   6167358
2   2019-03-05   AMZN  1702.95  1707.80  1689.01  1692.43   3681522
3   2019-03-06   AMZN  1695.97  1697.75  1668.28  1668.95   3996001
4   2019-03-07   AMZN  1667.37  1669.75  1620.51  1625.95   4957017
5   2019-03-01   AAPL   174.28   175.15   172.89   174.97  25886167
6   2019-03-04   AAPL   175.69   177.75   173.97   175.85  27436203
7   2019-03-05   AAPL   175.94   176.00   174.54   175.53  19737419
8   2019-03-06   AAPL   174.67   175.49   173.94   174.52  20810384
9   2019-03-07   AAPL   173.87   174.44   172.02   172.50  24796374
10  2019-03-01   GOOG  1124.90  1142.97  1124.75  1140.99   1450316
11  2019-03-04   GOOG  1146.99  1158.28  1130.69  1147.80   1446047
12  2019-03-05   GOOG  1150.06  1169.61  1146.19  1162.03   1443174
13  2019-03-06   GOOG  1162.49  1167.57  1155.49  1157.86   1099289
14  2019-03-07   GOOG  1155.72  1156.76  1134.91  1143.30   1166559
```
我们接下来以symbol进行分组。

```
In [6]:symbols=df.groupby('symbol')
In [7]:print(symbols.groups)
{'AAPL': Int64Index([5, 6, 7, 8, 9], dtype='int64'), 'AMZN': Int64Index([0, 1, 2, 3, 4], dtype='int64'), 'GOOG': Int64Index([10, 11, 12, 13, 14], dtype='int64')}
```
groupby方法是相当灵活的，可以对多个列进行分组。我们可以对symbol和date两列或者更多列进行分组。
```
In [21]: df.groupby(['date','symbol']).groups
Out[21]: 
{('2019-03-01', 'AAPL'): Int64Index([5], dtype='int64'),
 ('2019-03-01', 'AMZN'): Int64Index([0], dtype='int64'),
 ('2019-03-01', 'GOOG'): Int64Index([10], dtype='int64'),
 ('2019-03-04', 'AAPL'): Int64Index([6], dtype='int64'),
 ('2019-03-04', 'AMZN'): Int64Index([1], dtype='int64'),
 ('2019-03-04', 'GOOG'): Int64Index([11], dtype='int64'),
 ('2019-03-05', 'AAPL'): Int64Index([7], dtype='int64'),
 ('2019-03-05', 'AMZN'): Int64Index([2], dtype='int64'),
 ('2019-03-05', 'GOOG'): Int64Index([12], dtype='int64'),
 ('2019-03-06', 'AAPL'): Int64Index([8], dtype='int64'),
 ('2019-03-06', 'AMZN'): Int64Index([3], dtype='int64'),
 ('2019-03-06', 'GOOG'): Int64Index([13], dtype='int64'),
 ('2019-03-07', 'AAPL'): Int64Index([9], dtype='int64'),
 ('2019-03-07', 'AMZN'): Int64Index([4], dtype='int64'),
 ('2019-03-07', 'GOOG'): Int64Index([14], dtype='int64')}
```
使用自定义方法进行groupby操作，在groupby方法中传递自定义方法，该自定义方法需要传递每行的index并返回进行group的值。
```
In [16]: def increased(idx):
    ...:     return df.loc[idx].close > df.loc[idx].open
    ...: 

In [17]: df.groupby(increased).groups
Out[17]: 
{False: Int64Index([2, 3, 4, 7, 8, 9, 13, 14], dtype='int64'),
 True: Int64Index([0, 1, 5, 6, 10, 11, 12], dtype='int64')}
```
对pandas分组的结果进行后续操作，我们对分组结果计算平均值，如下。
```
In [39]: symbols['volume'].agg(np.mean)
Out[39]: 
symbol
AAPL    23733309.4
AMZN     4755355.0
GOOG     1321077.0
Name: volume, dtype: float64
```
我们也可以同时返回多个需要聚合计算的结果，如下：
```
In [40]: symbols['volume'].agg(['min','max','sum','mean'])
Out[40]: 
             min       max        sum        mean
symbol                                           
AAPL    19737419  27436203  118666547  23733309.4
AMZN     3681522   6167358   23776775   4755355.0
GOOG     1099289   1450316    6605385   1321077.0
```
遍历并选择group
```
In [43]: for symbol,group in symbols:
    ...:     print(symbol)
    ...:     print(group)
    ...:     
AAPL
         date symbol    open    high     low   close    volume
5  2019-03-01   AAPL  174.28  175.15  172.89  174.97  25886167
6  2019-03-04   AAPL  175.69  177.75  173.97  175.85  27436203
7  2019-03-05   AAPL  175.94  176.00  174.54  175.53  19737419
8  2019-03-06   AAPL  174.67  175.49  173.94  174.52  20810384
9  2019-03-07   AAPL  173.87  174.44  172.02  172.50  24796374
AMZN
         date symbol     open     high      low    close   volume
0  2019-03-01   AMZN  1655.13  1674.26  1651.00  1671.73  4974877
1  2019-03-04   AMZN  1685.00  1709.43  1674.36  1696.17  6167358
2  2019-03-05   AMZN  1702.95  1707.80  1689.01  1692.43  3681522
3  2019-03-06   AMZN  1695.97  1697.75  1668.28  1668.95  3996001
4  2019-03-07   AMZN  1667.37  1669.75  1620.51  1625.95  4957017
GOOG
          date symbol     open     high      low    close   volume
10  2019-03-01   GOOG  1124.90  1142.97  1124.75  1140.99  1450316
11  2019-03-04   GOOG  1146.99  1158.28  1130.69  1147.80  1446047
12  2019-03-05   GOOG  1150.06  1169.61  1146.19  1162.03  1443174
13  2019-03-06   GOOG  1162.49  1167.57  1155.49  1157.86  1099289
14  2019-03-07   GOOG  1155.72  1156.76  1134.91  1143.30  1166559
```
获取group全部的keys：
```
In [44]: symbols.groups.keys()
Out[44]: dict_keys(['AAPL', 'AMZN', 'GOOG'])
```
获取group的某一组：
```
In [47]: symbols.get_group('AAPL')
Out[47]: 
         date symbol    open    high     low   close    volume
5  2019-03-01   AAPL  174.28  175.15  172.89  174.97  25886167
6  2019-03-04   AAPL  175.69  177.75  173.97  175.85  27436203
7  2019-03-05   AAPL  175.94  176.00  174.54  175.53  19737419
8  2019-03-06   AAPL  174.67  175.49  173.94  174.52  20810384
9  2019-03-07   AAPL  173.87  174.44  172.02  172.50  24796374
```
count()方法，获取DataFrame每列value的个数:
```
In [51]: df.count()
Out[51]: 
date      15
symbol    15
open      15
high      15
low       15
close     15
volume    15
dtype: int64
```
value_counts()方法，该方法返回某一列的不同的个数，bins参数用来指定多少个设置多少个箱：
```
In [61]: df['volume'].value_counts(bins=4)
Out[61]: 
(1072952.085, 7683517.5]    10
(20851974.5, 27436203.0]     3
(14267746.0, 20851974.5]     2
(7683517.5, 14267746.0]      0
Name: volume, dtype: int64
```
counts()和value_counts()方法可以用来快速确定DataFrame的大小。

### Grouper操作
首先，我们从网上把数据下载下来，后面的操作都是基于这份数据的：
```
In [1]: import pandas as pd
In [2]: df = pd.read_excel("https://github.com/chris1610/pbpython/blob/master/data/sample-salesv3.xlsx?raw=True")
In [3]: df
```
{% asset_img 1.png %}

下面，我们统计'ext price'这个属性在每个月的累和(sum)值，resample 只有在index为**date**类型的时候才能用：
```
In [17]: df.set_index('date').resample('M')['ext price'].sum()
Out[17]: 
date
2014-01-31    185361.66
2014-02-28    146211.62
2014-03-31    203921.38
2014-04-30    174574.11
2014-05-31    165418.55
2014-06-30    174089.33
2014-07-31    191662.11
2014-08-31    153778.59
2014-09-30    168443.17
2014-10-31    171495.32
2014-11-30    119961.22
2014-12-31    163867.26
Freq: M, Name: ext price, dtype: float64
```
另外关于resample中用到的**M**代表的是聚合时间参数rule，一般是时间参数，比如“M”，“A”，“Q”，“BM”，“BA”，“BQ”和“W”。
{% asset_img 2.png 时间聚合参数 %}

如果我们想知道每个用户每个月的sum值，那么就需要一个groupby了：
```
In [20]: df.set_index('date').groupby('name')['ext price'].resample('M').sum()
Out[20]: 
name                             date      
Barton LLC                       2014-01-31     6177.57
                                 2014-02-28    12218.03
                                 2014-03-31     3513.53
                                 2014-04-30    11474.20
                                 2014-05-31    10220.17
                                 2014-06-30    10463.73
                                 2014-07-31     6750.48
                                 2014-08-31    17541.46
                                 2014-09-30    14053.61
                                 2014-10-31     9351.68
                                 2014-11-30     4901.14
                                 2014-12-31     2772.90
Cronin, Oberbrunner and Spencer  2014-01-31     1141.75
                                 2014-02-28    13976.26
                                 2014-03-31    11691.62
                                 2014-04-30     3685.44
                                 2014-05-31     6760.11
                                 2014-06-30     5379.67
                                 2014-07-31     6020.30
                                 2014-08-31     5399.58
                                 2014-09-30    12693.74
                                 2014-10-31     9324.37
                                 2014-11-30     6021.11
                                 2014-12-31     7640.60
```
以上写法不是很直观，可以使用[Grouper](https://pandas.pydata.org/pandas-docs/stable/reference/api/pandas.Grouper.html)写得更加简洁：
```
In [22]: df.groupby(['name',pd.Grouper(key='date',freq='M')])['ext price'].sum()
Out[22]: 
name                             date      
Barton LLC                       2014-01-31     6177.57
                                 2014-02-28    12218.03
                                 2014-03-31     3513.53
                                 2014-04-30    11474.20
                                 2014-05-31    10220.17
                                 2014-06-30    10463.73
                                 2014-07-31     6750.48
                                 2014-08-31    17541.46
                                 2014-09-30    14053.61
                                 2014-10-31     9351.68
                                 2014-11-30     4901.14
                                 2014-12-31     2772.90
Cronin, Oberbrunner and Spencer  2014-01-31     1141.75
                                 2014-02-28    13976.26
                                 2014-03-31    11691.62
                                 2014-04-30     3685.44
                                 2014-05-31     6760.11
                                 2014-06-30     5379.67
                                 2014-07-31     6020.30
                                 2014-08-31     5399.58
                                 2014-09-30    12693.74
                                 2014-10-31     9324.37
                                 2014-11-30     6021.11
                                 2014-12-31     7640.60
```

### 参考资料
------
* [python处理数据的风骚操作[pandas 之 groupby&agg]](https://segmentfault.com/a/1190000012394176)