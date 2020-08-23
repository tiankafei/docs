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

### 类加载器

> JVM中的所有的calss都是被类加载器加载到内存的（ClassLoader）

![类加载器](/images/类加载器.png)

### 类加载过程:双亲委派

![类加载过程](/images/类加载过程.png)

### 为什么要双亲委派

1. 主要是为了安全:自己定义一个java.lang.String类
2. 一个类只加载一次，减少资源浪费

### 自定义类加载器

1. 继承ClassLoader
2. 重写模板方法findClass，调用defineClass
3. 自定义类加载器加载自加密的class
   1. 防止反编译
   2. 防止篡改

### ClassLoader源码解析

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

### 混合模式

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

## 运行时内存结构



## JVM常用指令



## JVM调优



## 垃圾回收算法



## JVM调优实战



## JVM常见参数

