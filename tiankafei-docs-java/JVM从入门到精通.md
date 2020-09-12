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

hotspot源码的实现

![java对象头01](/images/java对象头01.png)

表格展示

![java对象头02](/images/java对象头02.png)

<font color="red">**当一个对象计算过identityHashCode之后，不能进入偏向锁状态**</font>

1. https://cloud.tencent.com/developer/article/1480590
2. https://cloud.tencent.com/developer/article/1484167
3. https://cloud.tencent.com/developer/article/1485795
4. https://cloud.tencent.com/developer/article/1482500

#### 4. 对象怎么定位？

https://blog.csdn.net/clover_lily/article/details/80095580

1. 句柄池
2. 直接指针

#### 5. 对象怎么分配？

![对象分配过程](/images/对象分配过程.png)

#### 6. Object o = new Object() 在内存中占用多少字节？

##### 自定义Agnet（1.8）

1. 创建文件TiankafeiAgent

   ```java
   package org.tiankafei.agent;
   import java.lang.instrument.Instrumentation;
   /**
    * @author tiankafei
    * @since 1.0
    **/
   public class TiankafeiAgent {
       private static Instrumentation inst;
       public static void premain(String agentArgs, Instrumentation _inst) {
           inst = _inst;
       }
       public static long sizeOf(Object o) {
           return inst.getObjectSize(o);
       }
   }
   ```

2. src目录下创建META-INF/MANIFEST.MF

   ```txt
   Manifest-Version: 1.0
   Created-By: tiankafei
   Premain-Class: org.tiankafei.agent.TiankafeiAgent
   
   ```

   注意Premain-Class这行必须是新的一行（回车 + 换行），确认idea不能有任何错误提示

3. 打包jar文件

4. 在需要使用该Agent Jar的项目中引入该Jar包

   project structure -> project settings -> library 添加该jar包

5. 运行时需要该Agent Jar的类，加入参数（VM options）：

   ```java
   -javaagent:agent的jar包绝对路径
   ```

6. 如何使用该类

   ```java
   package org.tiankafei.base;
   import org.tiankafei.agent.TiankafeiAgent;
   /**
    * @author tiankafei
    * @since 1.0
    **/
   public class TestAgent {
       public static void main(String[] args) {
           System.out.println(TiankafeiAgent.sizeOf(new Object()));
           System.out.println(TiankafeiAgent.sizeOf(new int[] {}));
           System.out.println(TiankafeiAgent.sizeOf(new P()));
       }
       private static class P {
           //8 _markword
           //4 _oop指针
           int id;         //4
           String name;    //4
           int age;        //4
           byte b1;        //1
           byte b2;        //1
           Object o;       //4
           byte b3;        //1
       }
   }
   ```

   输出结果：

   ```txt
   16
   16
   32
   ```

##### 分析对象大小-16

```java
-XX:+UseCompressedClassPointers
```

1. 对象头`markword`占8个字节
2. class指针`class pointer`占8个字节，当开启`-XX:+UseCompressedClassPointers`时，class指针会被压缩成4个字节
3. padding对齐，占了4个字节（对齐不一定时4个字节，）

##### 分析数组大小-16

```java
-XX:+UseCompressedClassPointers
```

1. 对象头`markword`占8个字节
2. class指针`class pointer`占8个字节，当开启`-XX:+UseCompressedClassPointers`时，class指针会被压缩成4个字节
3. 数组长度4个字节
4. padding对齐，0个字节（上面的大小已经时对齐的了，故padding对齐为0个字节）

##### 分析数组大小-24（关闭UseCompressedClassPointers）

```java
-XX:-UseCompressedClassPointers
```

1. 对象头`markword`占8个字节
2. class指针`class pointer`占8个字节
3. 数组长度4个字节
4. padding对齐，4个字节

##### 分析对象大小（带属性的对象）

```java
private static class P {
    			   //8 _markword
    			   //4 _oop指针
    int id;         //4
    String name;    //4（引用类型默认占用8个字节，当开启-XX:+UseCompressedOops时会被压缩成4个字节）
    int age;        //4
    byte b1;        //1
    byte b2;        //1
    Object o;       //4
    byte b3;        //1
}
```

> ```java
> Oops = ordinary object pointers（普通对象指针）
> ```

1. 引用类型占用大小：默认为8个字节，当开启`-XX:+UseCompressedOops`时会被压缩成4个字节。

## Java运行时数据区

![Java运行时数据区](/images/Java运行时数据区.png)

### 1. Program Counter：PC程序计数器

存放下一条指令位置的内存区域

虚拟机的运行，类似于这样的循环：

while( not end ){

  取PC中的位置，找到对应位置的指令；

  执行该指令；

  PC++；

}

### 2. JVM Stack

JVM虚拟机管理的栈

自己的方法对应的栈帧，**每个线程对应一个栈，每个方法对应一个栈帧。**

#### 栈帧Frame包含的内容

1. Local Variables：本地变量（局部变量）

2. Operand Stacks：操作数栈

   对于long的处理（store and load），多数虚拟机的实现都是原子的，JLS17.7，没有必要加volatile

3. Dynamic Linking：动态链接

   https://blog.csdn.net/qq_41813060/article/details/88379473

   jvms 2.6.3

   运行时常量池里面的符号链接。如果没有解析，就动态解析；如果已经解析了，就直接使用。

4. Return Address：a()->b()，方法a调用了方法b()，b方法的返回值放在什么地方。

### 3. Native Method Stacks

本地方法栈，一般使用C\C++写的，或者通过JNI调用Java自己的方法，一般涉及不到，也没法调优，没有办法去管理它。

### 4. Direct Memory

直接内存：NIO。Java的内存一般是由JVM管理的，但是为了增加性能，在JDK1.4之后，增加了NIO，可以直接访问操作系统的内存的，这部分内存归操作系统进行管理。Zero Copy！！！

### 5. Method Area：逻辑的概念

> 思考：如何证明1.7字符串常量位于Perm，而1.8位于Heap?
>
> 提示：结合GC，一直创建字符常量，观察堆和MetaSpace的情况。

#### Perm Space（<1.8）

1. 字符串常量位于Perm Space
2. FGC不会清理
3. 大小启动的时候指定，不能变

#### Meta Space（>1.8）

1. 字符串常量位于堆
2. 会触发FGC清理
3. 不设定的话，最大就是物理内存

### 6. Run-Time Constant Pool

class字节码中的常量池存放在这里

### 7. Heap

堆内存

### 8.总结：线程共享区域

![线程共享数据区](/images/线程共享数据区.png)

## JVM常用指令集

> 1. 基于栈的指令集
> 2. 基于寄存器的指令集（hotspot的local variable table类似于寄存器）

### 1. 示例性demo

```java
public class TestIPulsPlus {
    public static void main(String[] args) {
        int i = 8;
        i = i++;
//        i = ++i;
        System.out.println(i);
    }
}
输出结果：
8
字节码如下：
 0 bipush 8					// 8压栈
 2 istore_1					// 把栈顶上的值出栈，放在局部变量表中下标为1的位置
 3 iload_1					// 把局部变量表下标为1位置上的值压栈
 4 iinc 1 by 1				// 把局部变量表下标为1上的数+1
 7 istore_1					// 把栈顶上的值出栈，放在局部变量表中下标为1的位置
 8 getstatic #2 <java/lang/System.out>
11 iload_1
12 invokevirtual #3 <java/io/PrintStream.println>
15 return
```

```java
public class TestIPulsPlus {
    public static void main(String[] args) {
        int i = 8;
//        i = i++;
        i = ++i;
        System.out.println(i);
    }
}
输出结果：
9
字节码如下：
 0 bipush 8					// 8压栈
 2 istore_1					// 把栈顶上的值出栈，放在局部变量表中下标为1的位置
 3 iinc 1 by 1				// 把局部变量表下标为1上的数+1
 6 iload_1					// 把局部变量表下标为1位置上的值压栈
 7 istore_1					// 把栈顶上的值出栈，放在局部变量表中下标为1的位置
 8 getstatic #2 <java/lang/System.out>
11 iload_1
12 invokevirtual #3 <java/io/PrintStream.println>
15 return
```

> 非静态方法的第一个局部变量表存储的是this。

### 2. 常用指令

1. iadd：弹出两个int类型的数据执行相加，然后把结果入栈顶
2. new：在堆内存构造一个对象(默认值)，对象地址会压栈，
3. dup：复制对象地址放在栈顶，
4. invokeSpecial：执行特殊的方法：可以直接定位的，不需要多态的方法，<init>和private的方法。当执行构造方法时会把栈顶的对象地址弹出，然后调用构造方法并赋值给堆里面的具体对象，此时这个对象才算时构造完成。此时栈里面仍然有一个指向堆对象地址的值。
5. invokeVirtual：调用对象的具体方法
6. invokeStatic：调用具体的静态方法
7. invokeInterface：通过接口调用的方法
8. invokeDynamic：Lambda表达式，反射，其他动态语言scala、kotlin，Cglib，ASM，动态产生的calss会用到的指令。
9. pop：弹出栈顶的值扔掉
10. if_icmpne n：比较，如果不等，则跳到n的位置继续执行
11. <init>：构造方法
12. <clinit>：静态语句块

![常用指令练习](/images/常用指令练习.png)

![递归调用的方法栈帧](/images/递归调用的方法栈帧.png)

## JVM调优理论

### 1. 垃圾

> 没有引用指向的任何对象就叫做垃圾

**Java VS C++：**

- Java
  1. GC处理垃圾
  2. 开发效率高，执行效率低
- C++
  1. 手工处理垃圾
  2. 忘记回收
     - 内存泄漏
  3. 回收多次
     - 非法访问
  4. 开发效率低，执行效率高

### 2. 垃圾定位算法

#### 1. 引用计数：reference count

> 没有引用指向它的时候，就是垃圾；不能解决循环引用的问题

#### <font color="red">2. 根可达算法：root searching</font>

> 从根对象开始寻找，不能被引用到的对象就是垃圾

![根可达算法](/images/根可达算法.png)

根对象种类：

1. main方法开始执行时的线程栈的变量
2. 静态变量
3. 常量池引用的对象
4. JNI指针，调用C/C++方法引用的对象

换句话说：

1. jvm stack
2. native method
3. run-time constant pool
4. static references in method area
5. Clazz

### <font color="red">3. 垃圾回收算法</font>

#### 1. Mark-Sweep（标记清除）

![垃圾定位算法-标记清除算法](/images/垃圾定位算法-标记清除算法.png)

优点：

- 直接把标记为垃圾的对象清空即可，算法比较简单
- 当存活对象比较多的情况下，效率比较高

缺点：

- 需要经过两次扫描（第一遍标记，第二遍清除），执行效率偏低
- 容易产生碎片

#### 2. Copying（拷贝）

![垃圾定位算法-拷贝清除算法](/images/垃圾定位算法-拷贝清除算法.png)

优点：

- 适用于存活对象较少的情况
- 只扫描一次，效率提高
- 没有碎片

缺点：

- 空间浪费
- 移动复制对象
- 需要调整对象引用

#### 3. Mark-Compact（标记压缩）

![垃圾定位算法-标记压缩算法](/images/垃圾定位算法-标记压缩算法.png)

优点：

- 不会产生碎片，
- 方便对象分配
- 不会产生内存减半

缺点：

- 扫描两次
- 需要移动对象
- 执行效率偏低

### 4. JVM内存分代模型

> 用于分代垃圾回收算法

![堆内存逻辑分区](/images/堆内存逻辑分区.png)

#### 1. 部分垃圾回收器使用的模型

1. 不分代模型
   - Epsilon（用于做调试用的，起到一个占位符的作用）
   - ZGC
   - Shenandoah
2. 逻辑分代，物理不分代
   - G1
3. 逻辑分代，物理也分代
   - 其他

#### 2. 新生代 + 老年代 + 

> 永久代（1.7）Perm Generation/元数据区（1.8）Metaspace

1. 永久代：元数据-Class
2. 永久代必须制定大小限制，元数据可以设置，也可以不设置，无上限（受限于物理内存）
3. 字符串常量1.7 永久代，1.8在堆
4. Method Area逻辑概念：永久代、元数据

#### 3. 新生代 = Eden + 2个suvivor区

1. YGC回收之后，大多数的对象会被回收，或者的进入s0
2. 再次YGC，活着的对象 Eden + s0 -> s1
3. 再次YGC，Eden + s1 -> s0
4. 年龄足够 -> 老年代（15 CMS 6）
5. s区装不下 -> 老年代

#### 4. 老年代

1. 顽固分子
2. 老年代满了 FGC（Full GC）

#### 5. GC Teunring（Generation）

![GC概念](/images/GC概念.png)

1. 尽量减少FGC
2. MinorGC = YGC：在年轻代空间耗尽时触发：-Xmn 
3. MajorGC = FGC：在老年代无法继续分配空间时触发，新生代老年代同时进行回收：-Xms  -Xmx

#### 6. 一个对象从出生到消亡的历程

![一个对象从出生到消亡的历程](/images/一个对象从出生到消亡的历程.png)

- 栈上分配
  - 线程私有小对象
  - 无逃逸（就在这段代码中使用，出了这段代码，就没有人认识它了）
  - 支持标量替换（用普通的属性代替整个对象）
  - 无需调整
- 线程本地分配TLAB（Thread Local Allocation Buffer）
  - 占用eden，默认1%
  - 多线程的时候不用竞争eden就可以申请空间，提高效率
  - 小对象
  - 无需调整
- 老年代
  - 大对象
- eden

```java
//-XX:-DoEscapeAnalysis -XX:-EliminateAllocations -XX:-UseTLAB -Xlog:c5_gc*
// 逃逸分析 标量替换 线程专有对象分配
public class TestTLAB {
    //User u;
    class User {
        int id;
        String name;
        public User(int id, String name) {
            this.id = id;
            this.name = name;
        }
    }
    void alloc(int i) {
        new User(i, "name " + i);
    }
    public static void main(String[] args) {
        TestTLAB t = new TestTLAB();
        long start = System.currentTimeMillis();
        for(int i=0; i<1000_0000; i++) {
            t.alloc(i);
        }
        long end = System.currentTimeMillis();
        System.out.println(end - start);
        //for(;;);
    }
}

```

#### 7. 对象分配过程图

![对象分配过程详解](/images/对象分配过程详解.png)

- 动态年龄：
  - https://www.jianshu.com/p/989d3b06a49d
- 分配担保：
  - YGC期间 survivor区空间不够了 空间担保直接进入老年代
  - https://cloud.tencent.com/developer/article/1082730

#### 8. 常用JVM参数

- -XX:-DoEscapeAnalysis：逃逸分析

- -XX:-EliminateAllocations：标量替换

- -XX:-UseTLAB：线程专有对象分配

- -XX:MaxTenuringThreshold：s0-s1之间的复制年龄（YGC次数）超过限制，进入old区的参数；

  - 对象头的分代年龄是4bit，最大值是15

  - 如果不指定，Parallel Scavenge 默认值15

  - 如果不指定，CMS 默认6

  - 如果不指定，G1 默认15

  - 动态年龄：s0比s1超过50%时，把年龄最大的放入old区。（年龄1的占用了33%，年龄2的占用了33%，累加和超过默认的TargetSurvivorRatio（50%），年龄2和年龄3的对象都要晋升到老年代）

    https://www.jianshu.com/p/989d3b06a49d

- -Xmn：年轻代内存大小设置

- -Xms：老年代内存的最小值

- -Xmx：老年代内存的最大值

> - 命令行输入java：以横杠开头的命令是标准参数，所有java版本都支持
> - 命令行输入java -X：非标准参数
> - 命令行输入java -XX：不稳定参数，有些版本支持这个参数，有些版本支持那个参数，有些版本根本就不支持
> - 命令行输入java -XX:+PrintFlagsFinal -version，得到所有的参数列表，在linux上可以在后面追加 | grep xxx进行搜索

## <font color="red">常见垃圾回收器</font>

![常用垃圾回收器](/images/常用垃圾回收器.png)

> JDK诞生Serial追随；为了在多线程的情况下提高效率，诞生了Parallel Scavenge（PS）；为了配合CMS，诞生了ParNew（PN）；CMS是1.4版本后期引入，CMS是里程碑式的GC，它开启了并发回收的过程，但是CMS毛病较多，因此目前任何一个JDK版本默认是CMS。并发垃圾回收是因为无法忍受STW（stop the work）。

> 常见的垃圾回收器的组合：
>
> 1. Serial + Serial Old
> 2. Parallel Scavenge + Parallel Old
> 3. ParNew  + CMS

### 1. Serial 年轻代 

> 串行回收（单进程 单线程）

![垃圾回收器-Serial](/images/垃圾回收器-Serial.png)

### 2. Serial Old 老年代 

> 串行回收（单进程 单线程）

![垃圾回收器-Serial Old](/images/垃圾回收器-Serial Old.png)

### 3. Parallel Scavenge 年轻代 

> 并行回收（多线程）

![垃圾回收器-Parallel Scavenge](/images/垃圾回收器-Parallel Scavenge.png)

### 4. Parallel Old 老年代 

> 并行回收（多线程）

![垃圾回收器-Parallel Old](/images/垃圾回收器-Parallel Old.png)

### 5. ParNew 年轻代 

> 配合CMS的并行回收（Parallel Scavenge的变种，为了和CMS配合）

![垃圾回收器-ParNew](/images/垃圾回收器-ParNew.png)

Parallel Scavenge 和 ParNew 的区别：

- ParNew 响应时间有限，配合CMS
- Parallel Scavenge 吞吐量优先

https://docs.oracle.com/en/java/javase/13/gctuning/ergonomics.html#GUID-3D0BB91E-9BFF-4EBB-B523-14493A860E73

### 6. CMS 老年代

> ConcurrentMarkSweep 老年代 并发的， 垃圾回收和应用程序同时运行，降低STW的时间(200ms)
> CMS问题比较多，所以现在没有一个版本默认是CMS，只能手工指定。

![垃圾回收器-CMS](/images/垃圾回收器-CMS.png)

#### 1. 使用的算法

1. 三色标记（白	灰	黑）

2. Incremental Update

   当一个白色对象被一个黑色对象引用，将黑色对象重新标记为灰色，让collector重新扫描

#### 2. 初始标记：STW

单线程：找到根对象进行标记

#### 3. 并发标记

多线程：和应用程序同时运行，进行标记（80%GC的时间都是浪费在这里），一边标记一边会产生新的垃圾

#### 4. 重新标记：STW

多线程：在并发标记过程中产生的新的垃圾进行重新标记

#### 5. 并发清理

多线程：根据标记的指针进行并行清理，在清理的过程中依然会产生新的垃圾（浮动垃圾，等待下一次GC时进行回收）

#### 6. 存在的问题

##### 1. Memory Fragmentation（碎片化）

1. -XX:+UseCMSCompactAtFullCollection
2. -XX:CMSFullGCsBeforeCompaction 默认为0 指的是经过多少次FGC才进行压缩
3. -XX:CMSInitiatingOccupancyFraction 68%-> 90%（可以降低这个值，让CMS老年代有足够的空间）

CMS既然是MarkSweep，就一定会有碎片化的问题，碎片到达一定程度，CMS的老年代分配对象分配不下的时候，使用SerialOld 进行老年代回收。

##### 2. Floating Garbage（浮动垃圾）

#### 7. CMS日志分析









### 7. G1（10ms）

#### 1. 使用的算法

1. 三色标记（白	灰	黑）
2. STAB
   - snapshot at the beginning
   - 在起始的时候做一个快照
   - 当B->D消失时，要把这个引用推到GC的堆栈，保证D还能被GC扫描到

### 8. ZGC (1ms) PK C++
算法：ColoredPointers + LoadBarrier

### 9. Shenandoah
算法：ColoredPointers + WriteBarrier

### 10. Eplison

### 11. PS 和 PN区别的延伸阅读：
▪[https://docs.oracle.com/en/java/javase/13/gctuning/ergonomics.html#GUID-3D0BB91E-9BFF-4EBB-B523-14493A860E73](https://docs.oracle.com/en/java/javase/13/gctuning/ergonomics.html)

### 12. 垃圾收集器跟内存大小的关系

1. Serial 几十兆
2. PS 上百兆 - 几个G
3. CMS - 20G
4. G1 - 上百G
5. ZGC - 4T - 16T（JDK13）

### 13. 1.8默认的垃圾回收：PS + ParallelOld

## 常见的垃圾回收算法详解



## 常见垃圾回收器组合参数设定

### 1. Serial New + Serial Old

```java
-XX:+UseSerialGC = Serial New (DefNew) + Serial Old
```

小型程序。默认情况下不会是这种选项，HotSpot会根据计算及配置和JDK版本自动选择收集器

### 2. ParNew + SerialOld

```java
-XX:+UseParNewGC = ParNew + SerialOld
```

这个组合已经很少用（在某些版本中已经废弃）

https://stackoverflow.com/questions/34962257/why-remove-support-for-parnewserialold-anddefnewcms-in-the-future

### 3. ParNew + CMS + Serial Old

```java
-XX:+UseConc(urrent)MarkSweepGC = ParNew + CMS + Serial Old
```

### 4. Parallel Scavenge + Parallel Old

```java
-XX:+UseParallelGC = Parallel Scavenge + Parallel Old (1.8默认) 【PS + SerialOld】
```

### 5. Parallel Scavenge + Parallel Old

```java
-XX:+UseParallelOldGC = Parallel Scavenge + Parallel Old
```

### 6. G1

```java
-XX:+UseG1GC = G1
```

### 7. Linux中没找到默认GC的查看方法，而windows中会打印UseParallelGC 

* java +XX:+PrintCommandLineFlags -version
* 通过GC的日志来分辨

### 8. Linux下1.8版本默认的垃圾回收器到底是什么？

1. 1.8.0_181 默认（看不出来）Copy MarkCompact
2. 1.8.0_222 默认 PS + PO

## JVM调优实战

> 了解JVM常用命令行参数；JVM的命令行参数参考：https://docs.oracle.com/javase/8/docs/technotes/tools/unix/java.html

### 1. HotSpot参数分类

- 标准： - 开头，所有的HotSpot都支持
- 非标准：-X 开头，特定版本HotSpot支持特定命令
- 不稳定：-XX 开头，下个版本可能取消
- java -version；java -X

### 2. demo示例

```java
import java.util.List;
import java.util.LinkedList;

public class HelloGC {
  public static void main(String[] args) {
    System.out.println("HelloGC!");
    List list = new LinkedList();
    for(;;) {
      byte[] b = new byte[1024*1024];
      list.add(b);
    }
  }
}
```

1. 区分概念：内存泄漏memory leak，内存溢出out of memory
2. java -XX:+PrintCommandLineFlags HelloGC
3. java -Xmn10M -Xms40M -Xmx60M -XX:+PrintCommandLineFlags -XX:+PrintGC  HelloGC
   PrintGCDetails PrintGCTimeStamps PrintGCCauses
4. java -XX:+UseConcMarkSweepGC -XX:+PrintCommandLineFlags HelloGC
5. java -XX:+PrintFlagsInitial 默认参数值
6. java -XX:+PrintFlagsFinal 最终参数值
7. java -XX:+PrintFlagsFinal | grep xxx 找到对应的参数
8. java -XX:+PrintFlagsFinal -version | grep GC

### 3. PS GC日志详解

> 每种垃圾回收器的日志格式是不同的！

PS日志格式

![GC日志详解](/images/GC日志详解.png)

heap dump部分：

```java
eden space 5632K, 94% used [0x00000000ff980000,0x00000000ffeb3e28,0x00000000fff00000)
                            后面的内存地址指的是，起始地址，使用空间结束地址，整体空间结束地址
```

![GCHeapDump](/images/GCHeapDump.png)

total = eden + 1个survivor

### 4. 调优前的基础概念

1. 吞吐量：用户代码时间 /（用户代码执行时间 + 垃圾回收时间）
2. 响应时间：STW越短，响应时间越好

> 所谓调优，首先确定，追求啥？吞吐量优先，还是响应时间优先？还是在满足一定的响应时间的情况下，要求达到多大的吞吐量...

问题：

1. 科学计算，吞吐量。数据挖掘，thrput。吞吐量优先的一般：（PS + PO）
2. 响应时间：网站 GUI API （1.8 G1）

### 5. 什么是调优

1. 根据需求进行JVM规划和预调优
2. 优化运行JVM运行环境（慢，卡顿）
3. 解决JVM运行过程中出现的各种问题(OOM)

### 6. 调优，从规划开始

> 1. 调优，从业务场景开始，没有业务场景的调优都是耍流氓
> 2. 无监控（压力测试，能看到结果），不调优

#### 1. 调优步骤

1. 熟悉业务场景（没有最好的垃圾回收器，只有最合适的垃圾回收器）
   - 响应时间、停顿时间 [CMS G1 ZGC] （需要给用户作响应）
   - 吞吐量 = 用户时间 /( 用户时间 + GC时间) [PS]
2. 选择回收器组合
3. 计算内存需求（经验值 1.5G 16G）
4. 选定CPU（越高越好）
5. 设定年代大小、升级年龄
6. 设定日志参数
   - -Xloggc:/opt/xxx/logs/xxx-xxx-gc-%t.log -XX:+UseGCLogFileRotation -XX:NumberOfGCLogFiles=5 -XX:GCLogFileSize=20M -XX:+PrintGCDetails -XX:+PrintGCDateStamps -XX:+PrintGCCause
   - 或者每天产生一个日志文件
7. 观察日志情况



### 7. 解决JVM运行中遇到的问题

#### 1. 一个案例理解常用工具

1. demo示例

   ```java
   import java.math.BigDecimal;
   import java.util.ArrayList;
   import java.util.Date;
   import java.util.List;
   import java.util.concurrent.ScheduledThreadPoolExecutor;
   import java.util.concurrent.ThreadPoolExecutor;
   import java.util.concurrent.TimeUnit;
   
   /**
    * 从数据库中读取信用数据，套用模型，并把结果进行记录和传输
    */
   public class T15_FullGC_Problem01 {
       private static class CardInfo {
           BigDecimal price = new BigDecimal(0.0);
           String name = "张三";
           int age = 5;
           Date birthdate = new Date();
           public void m() {
           }
       }
       private static ScheduledThreadPoolExecutor executor = new ScheduledThreadPoolExecutor(50, new ThreadPoolExecutor.DiscardOldestPolicy());
       
       public static void main(String[] args) throws Exception {
           executor.setMaximumPoolSize(50);
           for (;;){
               modelFit();
               Thread.sleep(100);
           }
       }
       private static void modelFit(){
           List<CardInfo> taskList = getAllCardInfo();
           taskList.forEach(info -> {
               // do something
               executor.scheduleWithFixedDelay(() -> {
                   //do sth with info
                   info.m();
               }, 2, 3, TimeUnit.SECONDS);
           });
       }
       private static List<CardInfo> getAllCardInfo(){
           List<CardInfo> taskList = new ArrayList<>();
           for (int i = 0; i < 100; i++) {
               CardInfo ci = new CardInfo();
               taskList.add(ci);
           }
           return taskList;
       }
   }
   ```

2. java -Xms200M -Xmx200M -XX:+PrintGC com.mashibing.jvm.gc.T15_FullGC_Problem01

3. 一般是运维团队首先受到报警信息（CPU Memory）

4. top命令观察到问题：内存不断增长 CPU占用率居高不下

5. top -Hp 观察进程中的线程，哪个线程CPU和内存占比高

6. jps定位具体java进程

   ```java
   jstack 进程id/或者(--top -Hp 列表pid转换成16进制) 定位线程状况，重点关注：WAITING BLOCKED
   eg.
   waiting on <0x0000000088ca3310> (a java.lang.Object)
   假如有一个进程中100个线程，很多线程都在waiting on <xx>，一定要找到是哪个线程持有这把锁。
   怎么找？搜索jstack dump的信息，找<xx>，看哪个线程持有这把锁(这个线程状态很可能是RUNNABLE)
   demo：1：写一个死锁程序，用jstack观察 2 ：写一个程序，一个线程持有锁不释放，其他线程等待
   ```

7. 为什么阿里规范里规定，线程的名称（尤其是线程池）都要写有意义的名称

   怎么样自定义线程池里的线程名称？（自定义ThreadFactory）

8. jinfo pid 

9. jstat -gc 动态观察gc情况 / 阅读GC日志发现频繁GC / arthas观察 / jconsole / jvisualVM / Jprofiler（最好用）

   jstat -gc pid 毫秒数 : 每个500个毫秒打印GC的情况

   ```java
   如果面试官问你是怎么定位OOM问题的？如果你回答用图形界面（错误）
   1：已经上线的系统不用图形界面用什么？（cmdline arthas）
   2：图形界面到底用在什么地方？测试！测试的时候进行监控！（压测观察）
   ```

10. jmap -histo 4655 | head -20，查找有多少对象产生

11. jmap -dump:format=b,file=xxx pid（手动导出堆转储文件）

    <font color="red">**线上系统，内存特别大，jmap导出堆转储文件执行期间会对进程产生很大影响**</font>

    ```java
    1. 设定了参数HeapDump，OOM的时候会自动产生堆转储文件（其次）
    2. 很多服务器备份（高可用），停掉这台服务器对其他服务器不影响（最好）
    3. 在线定位：arthas（一般小点儿的公司用不到）
    4. 如果程序宕了，先不要着急重启，可以先使用此命令把内存中的堆信息导出
    ```

12. java -Xms20M -Xmx20M -XX:+UseParallelGC -XX:+HeapDumpOnOutOfMemoryError  com.mashibing.jvm.gc.T15_FullGC_Problem01

13. 使用MAT / jhat /jvisualvm 进行dump文件分析

14. 找到代码的问题

#### 2. jconsole远程连接

1. 程序启动加入参数：

   ```java
   java -Djava.rmi.server.hostname=192.168.1.102 -Dcom.sun.management.jmxremote -Dcom.sun.management.jmxremote.port=11111 -Dcom.sun.management.jmxremote.authenticate=false -Dcom.sun.management.jmxremote.ssl=false XXX
   ```

2. 如果遭遇 Local host name unknown：XXX的错误，修改/etc/hosts文件，把XXX加入进去

   ```java
   192.168.17.11 basic localhost localhost.localdomain localhost4 localhost4.localdomain4
   ::1         localhost localhost.localdomain localhost6 localhost6.localdomain6
   ```

3. 关闭linux防火墙（实战中应该打开对应端口）

   ```shell
   service iptables stop
   chkconfig iptables off #永久关闭
   ```

4. windows上打开 jconsole远程连接 192.168.1.102:11111

#### 3. jvisualvm远程连接

 https://www.cnblogs.com/liugh/p/7620336.html （简单做法）

#### 4. jprofiler (收费)

#### 5. arthas在线排查工具

> https://github.com/alibaba/arthas
>
> https://github.com/alibaba/arthas/blob/master/README_CN.md
>
> https://arthas.aliyun.com/doc/

1. 为什么需要在线排查？

   > 在生产上我们经常会碰到一些不好排查的问题，例如线程安全问题，用最简单的threaddump或者heapdump不好查到问题原因。为了排查这些问题，有时我们会临时加一些日志，比如在一些关键的函数里打印出入参，然后重新打包发布，如果打了日志还是没找到问题，继续加日志，重新打包发布。对于上线流程复杂而且审核比较严的公司，从改代码到上线需要层层的流转，会大大影响问题排查的进度。 

2. 下载arthas：https://arthas.aliyun.com/arthas-boot.jar

3. 启动arthas：java -jar arthas-boot.jar

   启动之后，会找到所有的java进程，列表展示，最前面有一个进程号的数字；输入那个数字，就可以让arthas挂载到相对应的进程上，然后就可以通过arthas的命令去观察这个进程。

4. arthas常用命令：

   1. help；可以看到arthas支持的n多个命令

   2. jvm（jinfo）；jvm相关的非常详细的信息

   3. thread ；显示所有线程列表

   4. thread 线程号；显示当前线程的信息

   5. dashboard ；命令行模拟图形界面观察系统情况（类似top命令）

   6. heapdump xxx.dump ；导出堆转储文件，类似（jmap -dump命令），对系统性能有很大影响，慎用！

   7. jhat xxx.dump（jdk自带的命令，不是arthas的命令）；用于对堆存储文件进行分析；分析完成之后，会启动一个服务，然后通过浏览器访问这地址，可以看到`jhat`的分析结果；支持OQL查询语法；

      ```java
      https://www.cnblogs.com/baihuitestsoftware/articles/6406271.html
      jhat -J-mx512M xxx.dump
      http://192.168.17.11:7000
      拉到最后：找到对应链接
      可以使用OQL查找特定问题对象
      ```

   8. jad class完全限定名；

      - 动态代理生成类的问题定位
      - 第三方的类（观察代码）
      - 版本问题（确定自己最新提交的版本是不是被使用）

   9. redefine class文件路径；热替换某个class：需要自己修改那个类，然后重新编译成class，然后再使用该命令进行热替换

      目前有些限制条件：只能改方法实现（方法已经运行完成），不能改方法名， 不能改属性

   10. sc ；search class

   11. watch ；watch method

5. 没有包含的功能：jmap -histo 4655 | head -20，查找有多少对象产生

### 8. 调优案例汇总

> OOM产生的原因多种多样，有些程序未必产生OOM，但是会不断FGC(CPU飙高，但内存回收特别少) 
>
> 用jvm都会溢出，mycat用崩过，1.6.5某个临时版本解析sql子查询算法有问题，9个exists的联合sql就导致生成几百万的对象

#### 1. 案例1：每日百万订单

<font color="red">**垂直电商，最高每日百万订单，处理订单系统需要什么样的服务器配置？**</font>

> 每天百万订单，预计每天晚上5-7点这两个小时产生72万订单，则1个小时会产生36万个订单；精确到秒，则每秒会产生100个订单，如果预计峰值每秒会产生1000个订单来计算，然后根据每个订单会产生多少个java内存对象，占用多少内存空间，然后*1000即可计算得出内存的内存的占用量。
>
> 要求响应时间100ms呢？如果预计峰值每秒会产生1000个订单，则可以按照并发量为1000来进行架构设计，如果每台应用服务器可以支持100的并发，则可以搭建10台这样的应用服务器，然后进行负载均衡。
>
> <font color="red">**每台应用服务器支持的最大并发数，需要进行压测**</font>

#### 2. 案例2：12306抢票

<font color="red">**12306遭遇春节大规模抢票应该如何支撑？**</font>

> 12306应该是中国并发量最大的秒杀网站：号称并发量100W最高
>
> 策略：CDN -> LVS -> NGINX -> 业务系统 -> 每台机器1W并发（10K问题） 100台机器
>
> 1. 普通电商订单： -> 下单 ->订单系统（IO）减库存 ->等待用户付款
> 2. 12306的一种可能的模型：下单 -> 减库存 和 订单(redis kafka) 同时异步进行 ->等付款
>
> 减库存最后还会把压力压到一台服务器；可以做分布式本地库存 + 单独服务器做库存均衡
>
> 大流量的处理方法：**分而治之，多级缓存**

#### 3. 案例3：50万PV的资料类网站

有一个50万PV的资料类网站（从磁盘提取文档到内存）原服务器32位，1.5G的堆，用户反馈网站比较缓慢，因此公司决定升级，新的服务器为64位，16G的堆内存，结果用户反馈卡顿十分严重，反而比以前效率更低了？

1. 为什么原网站慢?

   很多用户浏览数据，很多数据load到内存，内存不足，频繁GC，STW长，响应时间变慢

2. 为什么会更卡顿？

   内存越大，FGC时间越长（内存大了，占满的时间长了，也就是频率低了，但是卡顿时间更长了）

3. 咋办？

   更换垃圾回收器：PS -> PN + CMS 或者 G1

#### 4. 系统CPU经常100%如何调优？

> CPU100%那么一定有线程在占用系统资源，

1. 找出哪个进程cpu高（top）
2. 该进程中的哪个线程cpu高（top -Hp）
3. 导出该线程的堆栈 (jstack)
4. 查找哪个方法（栈帧）消耗时间 (jstack)
5. 工作线程占比高 | 垃圾回收线程占比高

#### 5. 系统内存飙高如何查找问题？

1. 导出堆内存 (jmap)
2. 分析 (jhat jvisualvm mat jprofiler ... )

#### 6. 案例6：内存不高，FGC很频繁

如果有一个系统，内存一直消耗不超过10%，但是观察日志，发现FGC总是频繁产生，会是什么原因引起的？

1. 有人在程序中显式的不停的调用System.gc()

#### 7. 硬件升级系统反而卡顿的问题

同案例3；

#### 8. 线程池不当运用产生OOM问题

同7.1.1（一个案例理解常用工具中的demo，不断产生对象；不断往List中加对象太Low）

#### 9. 频繁FGC，系统卡顿

> 可能的原因：使用的人太多了，内存不够用；把很多数据load到内存，然后不会被释放，每次FGC回收的太少，导致频繁FGC，系统卡顿
>
> 同案例3；

再找不到原因的情况下可以尝试下面几种方案：

1. 扩内存，可以延长FGC的时间；等开发FGC时，重启服务；
2. 更换垃圾回收器G1；

#### 10. tomcat http-header-size过大

server.max-http-header-size=10000000（默认4096字节）每一个连接进来头部都会占用100M的内存，所以很难扛得住高并发。

org.apache.coyote.http11.Http11OutputBuffer 对象特别多，且内存占用很大；当请求过多，设置堆内存太小，会导致OOM问题。

#### 11. Lambda导致方法区溢出

> MethodArea：1.7 Perm / 1.8 Metaspace

LambdaGC.java     -XX:MaxMetaspaceSize=9M -XX:+PrintGCDetails

```java
public class LambdaGC {
    public static void main(String[] args) {
        for(;;) {
            I i = C::n;
        }
    }
    public static interface I {
        void m();
    }
    public static class C {
        static void n() {
            System.out.println("hello");
        }
    }
}
```

每一个Lambda表达式都会产生一个Class（Class会分配到MethodArea），频繁创建Lambda表达式，会导致MethodArea溢出

```java
"C:\Program Files\Java\jdk1.8.0_181\bin\java.exe" -XX:MaxMetaspaceSize=9M -XX:+PrintGCDetails "-javaagent:C:\Program Files\JetBrains\IntelliJ IDEA Community Edition 2019.1\lib\idea_rt.jar=49316:C:\Program Files\JetBrains\IntelliJ IDEA Community Edition 2019.1\bin" -Dfile.encoding=UTF-8 -classpath "C:\Program Files\Java\jdk1.8.0_181\jre\lib\charsets.jar;C:\Program Files\Java\jdk1.8.0_181\jre\lib\deploy.jar;C:\Program Files\Java\jdk1.8.0_181\jre\lib\ext\access-bridge-64.jar;C:\Program Files\Java\jdk1.8.0_181\jre\lib\ext\cldrdata.jar;C:\Program Files\Java\jdk1.8.0_181\jre\lib\ext\dnsns.jar;C:\Program Files\Java\jdk1.8.0_181\jre\lib\ext\jaccess.jar;C:\Program Files\Java\jdk1.8.0_181\jre\lib\ext\jfxrt.jar;C:\Program Files\Java\jdk1.8.0_181\jre\lib\ext\localedata.jar;C:\Program Files\Java\jdk1.8.0_181\jre\lib\ext\nashorn.jar;C:\Program Files\Java\jdk1.8.0_181\jre\lib\ext\sunec.jar;C:\Program Files\Java\jdk1.8.0_181\jre\lib\ext\sunjce_provider.jar;C:\Program Files\Java\jdk1.8.0_181\jre\lib\ext\sunmscapi.jar;C:\Program Files\Java\jdk1.8.0_181\jre\lib\ext\sunpkcs11.jar;C:\Program Files\Java\jdk1.8.0_181\jre\lib\ext\zipfs.jar;C:\Program Files\Java\jdk1.8.0_181\jre\lib\javaws.jar;C:\Program Files\Java\jdk1.8.0_181\jre\lib\jce.jar;C:\Program Files\Java\jdk1.8.0_181\jre\lib\jfr.jar;C:\Program Files\Java\jdk1.8.0_181\jre\lib\jfxswt.jar;C:\Program Files\Java\jdk1.8.0_181\jre\lib\jsse.jar;C:\Program Files\Java\jdk1.8.0_181\jre\lib\management-agent.jar;C:\Program Files\Java\jdk1.8.0_181\jre\lib\plugin.jar;C:\Program Files\Java\jdk1.8.0_181\jre\lib\resources.jar;C:\Program Files\Java\jdk1.8.0_181\jre\lib\rt.jar;C:\work\ijprojects\JVM\out\production\JVM;C:\work\ijprojects\ObjectSize\out\artifacts\ObjectSize_jar\ObjectSize.jar" com.mashibing.jvm.gc.LambdaGC
[GC (Metadata GC Threshold) [PSYoungGen: 11341K->1880K(38400K)] 11341K->1888K(125952K), 0.0022190 secs] [Times: user=0.00 sys=0.00, real=0.00 secs] 
[Full GC (Metadata GC Threshold) [PSYoungGen: 1880K->0K(38400K)] [ParOldGen: 8K->1777K(35328K)] 1888K->1777K(73728K), [Metaspace: 8164K->8164K(1056768K)], 0.0100681 secs] [Times: user=0.02 sys=0.00, real=0.01 secs] 
[GC (Last ditch collection) [PSYoungGen: 0K->0K(38400K)] 1777K->1777K(73728K), 0.0005698 secs] [Times: user=0.00 sys=0.00, real=0.00 secs] 
[Full GC (Last ditch collection) [PSYoungGen: 0K->0K(38400K)] [ParOldGen: 1777K->1629K(67584K)] 1777K->1629K(105984K), [Metaspace: 8164K->8156K(1056768K)], 0.0124299 secs] [Times: user=0.06 sys=0.00, real=0.01 secs] 
java.lang.reflect.InvocationTargetException
	at sun.reflect.NativeMethodAccessorImpl.invoke0(Native Method)
	at sun.reflect.NativeMethodAccessorImpl.invoke(NativeMethodAccessorImpl.java:62)
	at sun.reflect.DelegatingMethodAccessorImpl.invoke(DelegatingMethodAccessorImpl.java:43)
	at java.lang.reflect.Method.invoke(Method.java:498)
	at sun.instrument.InstrumentationImpl.loadClassAndStartAgent(InstrumentationImpl.java:388)
	at sun.instrument.InstrumentationImpl.loadClassAndCallAgentmain(InstrumentationImpl.java:411)
Caused by: java.lang.OutOfMemoryError: Compressed class space
	at sun.misc.Unsafe.defineClass(Native Method)
	at sun.reflect.ClassDefiner.defineClass(ClassDefiner.java:63)
	at sun.reflect.MethodAccessorGenerator$1.run(MethodAccessorGenerator.java:399)
	at sun.reflect.MethodAccessorGenerator$1.run(MethodAccessorGenerator.java:394)
	at java.security.AccessController.doPrivileged(Native Method)
	at sun.reflect.MethodAccessorGenerator.generate(MethodAccessorGenerator.java:393)
	at sun.reflect.MethodAccessorGenerator.generateSerializationConstructor(MethodAccessorGenerator.java:112)
	at sun.reflect.ReflectionFactory.generateConstructor(ReflectionFactory.java:398)
	at sun.reflect.ReflectionFactory.newConstructorForSerialization(ReflectionFactory.java:360)
	at java.io.ObjectStreamClass.getSerializableConstructor(ObjectStreamClass.java:1574)
	at java.io.ObjectStreamClass.access$1500(ObjectStreamClass.java:79)
	at java.io.ObjectStreamClass$3.run(ObjectStreamClass.java:519)
	at java.io.ObjectStreamClass$3.run(ObjectStreamClass.java:494)
	at java.security.AccessController.doPrivileged(Native Method)
	at java.io.ObjectStreamClass.<init>(ObjectStreamClass.java:494)
	at java.io.ObjectStreamClass.lookup(ObjectStreamClass.java:391)
	at java.io.ObjectOutputStream.writeObject0(ObjectOutputStream.java:1134)
	at java.io.ObjectOutputStream.defaultWriteFields(ObjectOutputStream.java:1548)
	at java.io.ObjectOutputStream.writeSerialData(ObjectOutputStream.java:1509)
	at java.io.ObjectOutputStream.writeOrdinaryObject(ObjectOutputStream.java:1432)
	at java.io.ObjectOutputStream.writeObject0(ObjectOutputStream.java:1178)
	at java.io.ObjectOutputStream.writeObject(ObjectOutputStream.java:348)
	at javax.management.remote.rmi.RMIConnectorServer.encodeJRMPStub(RMIConnectorServer.java:727)
	at javax.management.remote.rmi.RMIConnectorServer.encodeStub(RMIConnectorServer.java:719)
	at javax.management.remote.rmi.RMIConnectorServer.encodeStubInAddress(RMIConnectorServer.java:690)
	at javax.management.remote.rmi.RMIConnectorServer.start(RMIConnectorServer.java:439)
	at sun.management.jmxremote.ConnectorBootstrap.startLocalConnectorServer(ConnectorBootstrap.java:550)
	at sun.management.Agent.startLocalManagementAgent(Agent.java:137)

```

#### 12. Distuptor链的长度

Distuptor有个可以设置链的长度，如果过大，然后对象大，消费完不主动释放，会溢出。

#### 13. 直接内存溢出问题

《深入理解Java虚拟机》P59，使用Unsafe分配直接内存，或者使用NIO的问题

#### 14. 栈溢出问题

```java
public class StackOverFlow {
    public static void main(String[] args) {
        m();
    }
    static void m() {
        m();
    }
}
```

-Xss（线程内存空间）设定太小；一个方法会产生一个栈帧，方法调用的方法过多时，会产生栈溢出；最简单的示例：递归调用，没有跳出的条件

#### 15. 内存占用问题优化

```java
Object o = null;
for(int i=0; i<100; i++) {
    o = new Object();
    //业务处理
}
```

```java
for(int i=0; i<100; i++) {
    Object o = new Object();
}
```

推荐使用上面的写法。

#### 16. 重写finalize引发频繁GC

小米云，HBase同步系统，系统通过nginx访问超时报警，最后排查，C++程序员重写finalize引发频繁GC问题。

为什么C++程序员会重写finalize？

因为C++程序员需要手动回收内存；过程：new delete；调用new的时候，会默认调用构造函数；调用delete的时候，会默认调用析构函数；然后他会理所当然的认为java里面也有一个类似析构函数的方法，故把finalize方法重写了。可能在finalize写了一些耗时比较长的逻辑（200ms）

#### 17. new大量线程，会产生native thread OOM

new 大量线程，会产生 native thread OOM，（low）应该用线程池，

解决方案：

减少堆空间（太TMlow了），预留更多内存产生native thread；JVM内存占物理内存比例 50% - 80%

## JVM常见问题

### 1. 内存溢出的几种情况

> https://www.cnblogs.com/chbin/p/10656566.html

#### 1. 堆栈溢出

##### 报错关键信息

1. java.lang.OutOfMemoryError: ......java heap space.....
2. java.lang.OutOfMemoryError:GC over head limit exceeded

##### 原因及解决方案

1. 当代码没有问题的情况下，适当调整-Xmx和-Xms是可以避免的；为什么会溢出呢，要么代码有问题，要么访问量太多并且每个访问的时间太长或者数据太多，导致数据释放不掉，因为垃圾回收器是要找到那些是垃圾才能回收，这里它不会认为这些东西是垃圾，自然不会去回收了
2. 这种情况是当系统处于高频的GC状态，而且回收的效果依然不佳的情况，就会开始报这个错误，这种情况一般是产生了很多不可以被释放的对象，有可能是引用使用不当导致，或申请大对象导致

#### 2. Method Area的溢出

##### 报错关键信息

1. java.lang.OutOfMemoryError: PermGen space（JDK1.7之前）
2. 

##### 原因及解决方案

1. 系统的代码非常多或引用的第三方包非常多、或代码中使用了大量的常量、或通过intern注入常量、或者通过动态代码加载等方法，导致常量池的膨胀；增加-XX:PermSize和-XX:MaxPermSize的大小。
2. 

#### 3. 直接内存溢出

> 在使用ByteBuffer中的allocateDirect()的时候会用到（经常发生于JavaNIO框架中）。

##### 报错关键信息

java.lang.OutOfMemoryError: Direct buffer memory

##### 原因及解决方案

如果你在直接或间接使用了ByteBuffer中的allocateDirect方法的时候，而不做clear的时候就会出现类似的问题；直接内存就是由OS和应用程序共同管理的，JVM垃圾回收不会回收掉直接内存的这部分内存，所以需要注意。

**如果经常有类似的操作，可以考虑设置参数：-XX:MaxDirectMemorySize**

#### 4. 线程的内存空间溢出

##### 报错关键信息

java.lang.StackOverflowError

##### 原因及解决方案

这个参数直接说明一个内容，就是-Xss太小了，我们申请很多局部调用的栈针等内容是存放在用户当前所持有的线程中的，线程在jdk 1.4以前默认是256K，1.5以后是1M，如果报这个错，只能说明-Xss设置得太小，当然有些厂商的JVM不是这个参数，本文仅仅针对Hotspot VM而已；不过在有必要的情况下可以对系统做一些优化，使得-Xss的值是可用的。

#### 5. 无法创建本地线程

##### 报错关键信息

java.lang.OutOfMemoryError: unable to create new native thread

##### 原因及解决方案

当JVM向OS申请创建线程，而OS不能分配一个本地线程时抛出。增加linux最大线程数及打开文件最大数。

#### 6. 地址空间不够

##### 报错关键信息

java.lang.OutOfMemoryError: request {} byte for {}out of swap

##### 原因及解决方案

这类错误一般是由于地址空间不够而导致。

### 2. 

## JVM常见参数



