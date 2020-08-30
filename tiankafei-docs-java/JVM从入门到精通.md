# JVM入门到精通

## 虚拟机基础概念

### Java 从编码到执行

![java从编码到执行](/images/java从编码到执行.png)

### JVM跨平台

> JVM跟Java无关，关键的原因就是class，任何语言只要能编译成class，符合class文件的规范，就可以在JVM虚拟机上执行。

![JVM跨平台](/images/JVM跨平台.png)

### JVM是一种规范

> 是一台虚拟的计算机

### Javac的过程

> 编译原理：
>
> 源码 -> 词法分析器 -> token流 -> 语法分析器 -> 抽象语法树 -> ByteCode -> 字节码生成器 -> 注解抽象语法树 -> 语义分析器

### 常见的JVM实现

> Hotspot：oracle官方
>
> TaobaoVM：hostpot深度定制版
>
> Jrockit：BEA，曾经号称世界上最快的JVM，被oracle收购，合并与Hotspot
>
> LiquidVM：直接针对硬件（底层没有操作系统）
>
> J9 -IBM
>
> azul zing：最新垃圾回收的业界标杆
>
> > 垃圾回收号称1ms实现，Hotspot吸收了其优点，升级到后来的ZGC
>
> Microsoft VM

### JDK JRE JVM的区别

![JDK-JRE-JVM](/images/JDK-JRE-JVM.png)

## class文件结构

### class文件二进制文件

![class二进制文件示例](/images/class二进制文件示例.png)

### class文件解析

![class文件解析](/images/class文件解析.png)

### class文件查看方法

- javap -v class文件名
- JBE（可以直接修改）
- JClassLib（IDEA插件之一）

### class文件结构

![java1.8类文件格式第一版](/images/java1.8类文件格式第一版.png)

## class文件内存加载过程

![class文件加载到内存](/images/class文件加载到内存.png)

1. loading:class文件被加载到内存
2. linking:
   1. verification:校验加载进来的class是否符合标准(前面四个字节是“cafe babe”等)
   2. preparation:class静态变量赋默认值(数值型默认值为0)
   3. resolution:class文件的常量池用到的那些符号引用转换为直接的内存地址，可以直接访问到
3. initializing:静态变量赋值为初始值
   - JVM规范并没有规定何时加载。Hotspot默认懒加载
   - 但是严格规定了什么时候必须初始化
     1. new getstatic putstatic invokestatic指定，访问final变量除外
     2. java.lang.reflect对类进行反射调用时
     3. 初始化子类的时候，父类首先初始化
     4. 虚拟机启动时，被执行的主类必须初始化
     5. 动态语言支持java.lang.invoke.MethodHandle解析的结果为REF_getstatic REF_putstatic REF_invokestatic的方法句柄时，该类必须初始化

### loading

> JVM中的所有的calss都是被类加载器加载到内存的（ClassLoader）

![类加载器](/images/类加载器.png)

#### 类加载过程:双亲委派

![类加载过程](/images/类加载过程.png)

#### 为什么要双亲委派

1. 主要是为了安全:自己定义一个java.lang.String类
2. 一个类只加载一次，减少资源浪费

#### 如何打破双亲委派

1. 重写loadClass()方法

#### 何时打破过双亲委派

1. JDK1.2之前，自定义ClassLoader都必须重写loadClass()方法
2. ThreadContextClassLoader可以实现基础类调用实现类代码，通过thread.setContextClassLoader指定
3. 热启动，热部署
   - osgi tomcat都有自己的模块指定ClassLoader（可以加载同一类库的不同版本）

#### 自定义类加载器

1. 继承ClassLoader
2. 重写模板方法findClass，调用defineClass
3. 自定义类加载器加载自加密的class
   1. 防止反编译
   2. 防止篡改

#### ClassLoader源码解析

```java
protected Class<?> loadClass(String name, boolean resolve)
    throws ClassNotFoundException {
    synchronized (getClassLoadingLock(name)) {
        // First, check if the class has already been loaded
        Class<?> c = findLoadedClass(name);
        if (c == null) {
            long t0 = System.nanoTime();
            try {
                if (parent != null) {
                    c = parent.loadClass(name, false);
                } else {
                    c = findBootstrapClassOrNull(name);
                }
            } catch (ClassNotFoundException e) {
                // ClassNotFoundException thrown if class not found
                // from the non-null parent class loader
            }
            if (c == null) {
                // If still not found, then invoke findClass in order
                // to find the class.
                long t1 = System.nanoTime();
                c = findClass(name);
                // this is the defining class loader; record the stats
                PerfCounter.getParentDelegationTime().addTime(t1 - t0);
                PerfCounter.getFindClassTime().addElapsedTimeFrom(t1);
                PerfCounter.getFindClasses().increment();
            }
        }
        if (resolve) {
            resolveClass(c);
        }
        return c;
    }
}
```

```java
/**
 * Finds the class with the specified <a href="#binary-name">binary name</a>.
 * This method should be overridden by class loader implementations that
 * follow the delegation model for loading classes, and will be invoked by
 * the {@link #loadClass loadClass} method after checking the
 * parent class loader for the requested class.
 * @implSpec The default implementation throws {@code ClassNotFoundException}.
 * @param  name
 *         The <a href="#binary-name">binary name</a> of the class
 * @return  The resulting {@code Class} object
 * @throws  ClassNotFoundException
 *          If the class could not be found
 * @since  1.2
 */
protected Class<?> findClass(String name) throws ClassNotFoundException {
    throw new ClassNotFoundException(name);
}
```

#### 混合加载模式

> - -Xmixed 默认为混合模式
>
>   开始解释执行，启动速度较快，对热点代码实行检测和编译
>
> - -Xint
>
>   使用解释模式，启动很快，执行稍慢
>
> - -Xcomp
>
>   使用纯编译模式，执行很快，启动很慢

- 解释器
  - bytecode intepreter
- JIT
  - just In-Time compiler
- 混合模式
  - 混合使用解释器 + 热点代码编译
  - 起始阶段采用解释执行
  - 热点代码检测:-XX:CompileThreshold=10000
    1. 多次被调用的方法（方法计数器：检测方法执行频率）
    2. 多次被调用的循环（循环计数器：检测循环执行效率）
    3. 进行编译

### linking

#### verification

1. 验证文件是否符合JVM标准规范

#### preparation

1. 静态成员变量赋默认值

#### resolution

1. 将类、方法、属性等符号引用解析为直接引用
2. 常量池中的各种符号引用解析为指针、偏移量等内存地址的直接引用

### initializing

1. 调用类的初始化代码<init>

## 运行时内存结构

### 硬件层

#### 存储器的层次结构

![存储器的层次机构](/images/存储器的层次机构.png)

CPU:内存 = 1:100；内存:磁盘 = 1:100000

#### 多核CPU一致性的硬件层支持

![多核CPU一致性的硬件层支持](/images/多核CPU一致性的硬件层支持.png)

总线锁会锁住总线，使得其他CPU甚至不能访问内存中其他的地址，因而效率较低

#### 缓存行

> 读取缓存以cache line为基本单位，目前时64个字节

![cache line 的概念，缓存行对齐 伪共享](/images/cache line 的概念，缓存行对齐 伪共享.png)

#### 各种各样的缓存一致性协议

> 现在CPU的数据一致性实现 = 缓存锁(MESI...) + 总线锁

1. MSI

2. MESI：（`Intel`的CPU所采用的缓存一致性协议）

   - Modified，更改过就标记为这个状态
   - Exclusive，独享就标记为这个状态
   - Shared，我读的时候，别人也在读，就标记为这个状态
   - Invalid，我读的时候，别的CPU已经改过了，就标记为这个状态

   ![MESI缓存一致性协议](/images/MESI缓存一致性协议.png)

   <font color="red">**有些无法被缓存的数据，或者跨越多个缓存行的数据依然必须使用总线锁**</font>

3. MOSI 

4. Synapse

5. Firefly

6. Dragon

#### CPU合并写技术

CPU为了提高指令执行效率，会再一条指令执行过程中（比如去内存读取数据慢了100倍），去同时执行另一条指令。（前提是，两条指定没有依赖关系）

https://www.cnblogs.com/liushaodong/p/4777308.html

写操作也可以进行合并

#### 乱序执行的证明

```java

```

#### 如何保证特定情况下的有序性（x86）

有序性保障：CPU内存屏障（CPU的汇编指令）

sfence:在sfence指令前的写操作当必须在sfence指令后的写操作前完成。

ifence:在ifence指令前的读操作当必须在ifence指令后的读操作前完成。

mfence:在mfence指令前的读写操作当必须在mfence指令后的读写操作前完成。

lock指令，cmpxchg 

### JVM层

#### 如何保证特定情况下的有序性

1. LoadLoad屏障

   对于这样的语句：Load1;LoadLoad;Load2

   在Load2及后续读取操作要读取的数据访问前，保证Load1要读取的数据读取完毕。

2. StoreStore屏障

   对于这样的语句：Store1;StoreStore;Store2

   在Store2及后续写入操作执行前，保证Store1的写入操作对其它处理器可见。

3. LoadStore屏障

   对于这样的语句：Load1;LoadStore;Store2

   在Store2及后续写入操作被刷出前，保证Load1要读取的数据被读取完毕。

4. StoreLoad屏障

   对于这样的语句：Store1;StoreLoad;Load2

   在Load2及后续所有读取操作执行前，保证Store1的写入对其它处理器可见。

##### volatile指令的实现细节

1. 字节码层面 (ACC_VOLATILE访问修饰符)

   只是在属性的访问修饰符后面加了一个`[volatile]`

2. JVM层面

   > StoreStoreBarrier
>
   > volatile 写操作
>
   > StoreLoadBarrier

   > LoadLoadBarrier
>
   > volatile 读操作
>
   > LoadStoreBarrier
>
   > 

3. 操作系统及硬件层面

   使用`hsdis`观察汇编码，lock指令 xxx 执行 xxx 指令的时候保证对内存区域加锁

   hsdis -> HotSpot Dis Assembler

   https://blog.csdn.net/qq_26222859/article/details/52235930

   windows 使用`lock`指令实现

##### synchronized指令的实现细节

1. 字节码层面 (ACC_VOLATILE访问修饰符)

   如果在方法上使用synchronized，则会在方面的访问修饰符后面加一个`[synchronized]`

   如果在方法块上使用synchronized，则会在字节码层面增加相关指令：monitorenter,monitorexit

   ![synchronized字节码编译效果](/images/synchronized字节码编译效果.png)

   为什么会有两条`monitorexit`，包含正常退出和异常退出。

2. JVM层面

   C\C++调用了操作系统提供的同步机制

3. 操作系统及硬件层面

   https://blog.csdn.net/21aspnet/article/details/88571740

   X86：lock cmpxchg xxxx

### Java并发内存模型

![Java并发内存模型](/images/Java并发内存模型.png)

### Java8大原子操作（虚拟机规范，已弃用）

> 最新的JSR-133已经放弃这种描述，但是JMM没有变化。《深入理解Java虚拟机》P364

1. lock：主内存，标识变量为线程独占
2. unlock：主内存，解锁线程独占变量
3. read：主内存，读取内容到工作内存
4. load：工作内存，read后的值放入线程本地变量副本
5. use：工作内存，传值给执行引擎
6. assign：工作内存，执行引擎结果赋值给线程本地变量
7. store：工作内存，存值到主内存给write备用
8. write：主内存，写变量值

### hanppens-before原则

1. 程序次序规则：同一个线程内，按照代码出现的顺序，前面的代码先行于后面的代码，准确的说是控制流顺序，因为要考虑到分支和循环结构。
2. 管程锁定规则：一个unlock操作先行发生于后面（时间上）对同一个锁的lock操作。
3. volatile变量规则：对一个volatile变量的写操作先行发生于后面（时间上）对这个变量的读操作。
4. 线程启动规则：Thread的start()方法先行发生于这个线程的每一个操作。
5. 线程终止规则：线程的所有操作都先行与此线程的终止检测。可以通过Thread.join()方法结束、Thread.isAlive()的返回值等手段检测线程的终止。
6. 线程中断规则：对线程interrupt()方法的调用先行发生于被中断线程的代码检测到中断事件的发生，可以通过Thread.interrupt()方法检测线程是否中断。
7. 对象终结规则：一个对象的初始化完成先行于发生它的finalize()方法的开始。
8. 传递性：如果操作A先行于操作B，操作B先行于操作C，那么操作A先行于操作C。

### as if serial

不管如果重排序，单线程执行结果不会改变。

## Object对象的内存布局

#### 1. 请解释以下对象的创建过程？

##### 1. class加载到内存的过程

1. class loading
2. class linking（verification,preparation,resolution)
3. class initializing

##### 2. new对象的过程

1. 申请对象内存
2. 成员变量赋默认值
3. 调用构造方法<init>
   1. 成员变量顺序赋初始值
   2. 执行构造方法语句(先调用super)

#### 2. 对象在内存中的存储布局？

##### 观察虚拟机的配置

> 对象的大小具体跟虚拟机的实现以及虚拟机的设置都很有关系。
>
> ![观察虚拟机的配置](/images/观察虚拟机的配置.png)

```java
java -XX:+PrintCommandLineFlags -version

C:\Users\tiankafei>java -XX:+PrintCommandLineFlags -version
-XX:InitialHeapSize=16777216 -XX:MaxHeapSize=268435456 -XX:+PrintCommandLineFlags -XX:-UseLargePagesIndividualAllocation
java version "1.8.0_261"
Java(TM) SE Runtime Environment (build 1.8.0_261-b12)
Java HotSpot(TM) Client VM (build 25.261-b12, mixed mode)
```

##### 普通对象

1. 对象头：mardword 8
2. ClassPointer指针：-XX:+UseCompressedClassPointers为4字节 不开启为8字节
3. 实例数据
   - 引用类型：-XX:+UseCompressedOops为4字节 不开启为8字节
   - Oops：Ordinary Object Pointers
4. Padding对齐，8的倍数

##### 数组对象

1. 对象头：mardwork 8
2. ClassPointer指针同上
3. 数组长度：4个字节
4. 数组数据
5. Padding对齐，8的倍数

#### 3. 对象头具体包括什么？



#### 4. 对象怎么定位？

https://blog.csdn.net/clover_lily/article/details/80095580



#### 5. 对象怎么分配？

#### 6. Object o = new Object() 在内存中占用多少字节？

## JVM常用指令



## JVM调优



## 垃圾回收算法



## JVM调优实战



## JVM常见参数

