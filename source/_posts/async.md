---
title: Async 和 Await总结
date: 2017-01-22 23:04:00
tags: [异步]
categories: .NET开发
---

一开始自己翻译了一篇外国技术大牛关于async、await的博文，感觉没法使用特别自然的语言进行描述，索性就把翻译的文章一股脑清空了，然后上网看了些其他博友的讲解，有的讲
的过于深刻不便于理解，因此我以自己关于这部分曾经思考过的问题与大家分享下。

<!-- more -->

### 问题一：异步方法一定需要等待吗？
首先要明确谁等，怎么等，请先看一段常见代码。
```
 namespace AsyncAwaitTest
{
    class Program
    {
        static void Main(string[] args)
        {
            Console.WriteLine("-------主线程启动-------");
            Task<int> task = GetLengthAsync();
            Console.WriteLine("Main方法做其他事情");
            Console.WriteLine("Task返回的值" + task.Result);
            Console.WriteLine("-------主线程结束-------");
        }
 
        static async Task<int> GetLengthAsync()
        {
            Console.WriteLine("GetLengthAsync Start");  
            string str = await GetStringAsync();
            Console.WriteLine("GetLengthAsync End");
            return str.Length;
        }
 
        static Task<string> GetStringAsync()
        {
            return Task<string>.Run(() => { Thread.Sleep(2000); return "finished"; });
        }
    }
}
```
当调用GetLengthAsync方法时候，注意此处没有加await关键字，它会像正常的执行同步代码一样执行Console.WriteLine("GetLengthAsync Start")，直到遇到await关键字后，
程序首先做的是判断该任务是否执行完毕，通常是没有完毕，不管它有没有完毕，程序先把控制权返回给调用异步任务的**调用者（caller）**，因此调用者此时没有等待，会继续执行，
执行到下一行Console.WriteLine("Task返回的值" + task.Result)，程序明确表示我要这个结果，此时调用者只好等待，会等待任务GetLengthAsync返回结果，返回结果后才能继续执行。
因此当一个方法去call一个含有await关键字的异步任务时候是不需要等待的，只有需要这个任务(task)的结果,使用task.resut，这个方法才会暂停等待异步任务返回结果（正常返回值或者exception）。


### 问题二：是否开启了新的线程

要看异步任务中调用的方法是否会使用**Task.Run(()=>{}),Task.Factory.StartNew(()=>{})**以及NET内置带有Async结尾的异步方法，只有await这些方法时才会从
线程池中寻找空闲的线程去执行这些方法。

### 问题三：任务一定是异步的吗

不一定，看你如何调用，比如创建一个简单任务。
```
public Task<string> CreateTask(){
   Task.Run(()=>{
     return "Hello hugo...";
  });
}
```
这就是个最普通的任务，如果你有一个方法使用await CreateTask()的话，那么这个方法将会变成需要使用**async**标记的异步方法，其返回值是Task<string>。如果使用
CreateTask.Result或者CreateTask.Wait()方法，这个方法依旧是普通同步方法，因为Result和Wait()都是本身就是阻塞方法。

### 问题四：await究竟干了啥（从代码角度）

await关键字告诉编译器在async方法中插入一个可能唤醒、继续的操作点。

await smth时候，编译器生成相应代码，代码第一步先检查smth这个耗时操作是否完成，如果已经完成，则继续运行await标记点之后的代码；如果没有完成，编译器生成一个需要**后续操作的委托**，同时return到调用异步任务的方法中去，也就是所谓的将控制权返回给调用者（caller）。

```C#
   public class Program11
    {

        static void Main(string[] args)
        {
            Console.WriteLine("----主线程启动----"); ::

            Console.WriteLine("主线程执行线程:" + Thread.CurrentThread.ManagedThreadId + " 是否后台:" + Thread.CurrentThread.IsBackground);

            Task<int> task =  GetStringLengthAsync();

            Console.WriteLine("----主线程继续执行----");

            Console.WriteLine("Task返回值:" + task.Result);

            Console.WriteLine("主线程执行线程:" + Thread.CurrentThread.ManagedThreadId);

            Console.WriteLine("---主线程结束----");

            Console.ReadKey();
        }



        static async Task<int> GetStringLengthAsync()
        {

            Console.WriteLine("GetStringLengthAsync方法开始执行...");
            Console.WriteLine("GetStringLengthAsync 执行线程:" + Thread.CurrentThread.ManagedThreadId);

            string str = await GetStringTask();
            Console.WriteLine("GetStringLengthAsync 执行线程:" + Thread.CurrentThread.ManagedThreadId + "是否后台：" + Thread.CurrentThread.IsBackground);
            return str.Length;
        }
        static Task<string> GetStringTask()
        {
            var client = new HttpClient();
            Task<string> task = client.GetStringAsync("http://blog.stephencleary.com/2012/02/async-and-await.html");

            Console.WriteLine("GetStringTask 执行线程:" + Thread.CurrentThread.ManagedThreadId);
            return task;

        }

    }
```
这是执行结果，看看跟你想的一样不。
[![运行结果](https://s23.postimg.org/bs5rynbmj/QQ_20170124120621.jpg)](https://postimg.org/image/iim982ys7/)

然后我们使用.NET Reflector反编译下程序，看看编译器如何处理await smth的。

```
public class Program11
{
    ...
    // Nested Types
    [CompilerGenerated]
 //这是一个带有状态机的类，状态机，是不是让你联想到可以检测状态，状态恢复之类的
    private sealed class <GetStringLengthAsync>d__1 : IAsyncStateMachine
    {
        // Fields
        // 初始化相关字段
        public int <>1__state;
        private string <>s__2;
        public AsyncTaskMethodBuilder<int> <>t__builder;
        private TaskAwaiter<string> <>u__1;
        private string <str>5__1;

        // Methods
        // 关键看这里
        private void MoveNext()
        {
            int length;
            int num = this.<>1__state;
            try
            {
                //创建一个等待着，等待着专门用来等待异步任务，并检测任务是否完毕
                TaskAwaiter<string> awaiter;
                //一开始num不等于0，所以直接进入
                if (num != 0)
                {
                    Console.WriteLine("GetStringLengthAsync方法开始执行...");
                    Console.WriteLine("GetStringLengthAsync 执行线程:" + Thread.CurrentThread.ManagedThreadId);
                    //为等待者着赋值，注意这里的代码是在线程池运行的
                    awaiter = Program11.GetStringTask().GetAwaiter();
                    //一开始时候是没有完成，所以进入该方法
                    if (!awaiter.IsCompleted)
                    {   
                       
                        this.<>1__state = num = 0;
                        this.<>u__1 = awaiter;
                        
                        Program11.<GetStringLengthAsync>d__1 stateMachine = this;
                        //创建一个需要后续操作的委托，通过AwaitUnsafeOnCompleted实现，当操作完成时候，程序再次调用MoveNext()方法，这次就会直接进入程序的下半部分，从else进入                 
                        this.<>t__builder.AwaitUnsafeOnCompleted<TaskAwaiter<string>, Program11.<GetStringLengthAsync>d__1>(ref awaiter, ref stateMachine);
                        //很重要，返回控制权给调用者，所以不会阻塞调用者(caller)
                        return;
                    }
                }
                else
                {
                    awaiter = this.<>u__1;
                    this.<>u__1 = new TaskAwaiter<string>();
                    this.<>1__state = num = -1;
                }
                //这块就是任务完成之后的后续操作
                string result = awaiter.GetResult();
                awaiter = new TaskAwaiter<string>();
                this.<>s__2 = result;
                this.<str>5__1 = this.<>s__2;
                this.<>s__2 = null;
                Console.WriteLine(string.Concat(new object[] { "GetStringLengthAsync 执行线程:", Thread.CurrentThread.ManagedThreadId, "是否后台：", Thread.CurrentThread.IsBackground.ToString() }));
                length = this.<str>5__1.Length;
            }
            catch (Exception exception)
            {
                this.<>1__state = -2;
                this.<>t__builder.SetException(exception);
                return;
            }
            this.<>1__state = -2;
            this.<>t__builder.SetResult(length);
        }

  
    }
}

```

### 进阶
* [Best Practices in Asynchronous Programming](https://msdn.microsoft.com/en-us/magazine/jj991977.aspx)：深刻解释async await void和configure context
* [使用async/await异步编程-微软官方](https://msdn.microsoft.com/en-us/library/hh191443.aspx)
* [async/await常见问题](https://blogs.msdn.microsoft.com/pfxteam/2012/04/12/asyncawait-faq/)


