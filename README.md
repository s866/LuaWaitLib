# LuaWaitLib

## 设计原理

* 规划Task为协程的一个包装，Event为可等待Task的一个包装。
* 协程的创建为树形创建，创建后会赋予parent和children，并且每个协程只能被持有一个引用，保证每个协程的有效性，而且被杀死时能真正杀死。
* coroutine.yield()被包装为WaitWrapper，使其支持迭代（WaitUpdate）和快进（HurryUp）两种功能

## 引入库

1. 修改 COConf.lua ，可以将里面的所有接口改为你自己项目工程内的接口
2. 修改 Lib.lua 文件里的CurLibSavePath的值，改为 `{该库位于你工程的相对路径}/?.lua`
3. 调用代码 `require '{库位于你工程的相对路径}.Lib'`

## 注意事项

使用 `CO.Wait:WaitEvent` 类型的等待方法，必须注意超时情况和错误处理，保证出现意外情况可以让代码正确的运行，否则协程将以中断的形式进行处理，必须记得使用完毕后的清理！！！

## 使用方法

1. 完成引入库后，在项目的 `Tick` 中添加 `Coroutine:Update(deltaTime)`
2. 在主线程使用 `CoroutineFactory:CreateTask()` 创建根协程，如果有等待需求 `CoroutineFactory:CreateEvent()` 也可以。
3. 在协程方法内使用 `CO.Wait` 方法库调用等待方法进行等待，并处理异常情况，也可使用 `CO.AsyncDo` 方法库内的预制功能方法进行快捷处理逻辑，当然如果使用 `coroutine.yield()` 方法也是可以的，不过将会失去HurryUp的统一管理，并且可能某些操作未经过测试。
4. 如需要特化等待方法，可以使用 `CO.Wait:CustomWait` 方法，也可以创建特化的 `Wait/Wait_Ext.lua` 文件，和新的WaitWrapper类，并编写项目的特化等待方法。
5. 如需要添加新的预制功能方法，也可创建 `AsyncDo/AsyncDo_Ext.lua` 文件。
6. 使用完毕后必须调用各种 Kill 方法杀死对应的根节点或指定节点！！！
