<div align="center">
  <img src="non-app-file/icon.png" width="128" height="128" alt="Flippy Lid 图标">
  <h1>💻 Flippy Lid 🦅</h1>
  <p>
    <strong>史上第一个靠你合上又打开笔记本屏幕来干活的“生产力”工具！</strong><br>
    用 <strong>SwiftUI</strong> + <strong>私有 IOKit 传感器</strong> + <strong>一点混乱精神</strong> 搞出来的
  </p>

  <p>
    <img src="https://img.shields.io/badge/macOS-Big%20Sur%20%2B-blue?style=flat-square" alt="macOS">
    <img src="https://img.shields.io/badge/Architecture-Apple%20Silicon%20(ARM)-ff0000?style=for-the-badge&logo=arm&logoColor=white" alt="仅限 Apple Silicon">
    <img src="https://img.shields.io/badge/License-MIT-green?style=for-the-badge" alt="MIT 许可证">
  </p>
  
  <p>
    <a href="README.md">English</a> | <a href="README_zh.md">中文</a>
  </p>
</div>

---

### 🧐 这玩意儿到底是干啥的？

**Flippy Lid** 把你的 MacBook 屏幕变成了一种物理输入设备——没错，真的。

app偷偷摸摸地读取了藏在转轴里的角度传感器（用了点不太见光的 IOKit 技术 🧙‍♂️），只要一开一合屏幕，就能触发各种操作。

说白了，这就是个让你一边摸鱼、一边顺便给电脑转轴做“体能测试”的应用。

---

### 🌟 能干点啥？

#### 1. 🎮 FLAPPY 小游戏  
就是那个经典的 Flappy Bird，但你得**真动手拍屏幕**来控制小鸟飞。
*   **打开屏幕** = 小鸟往上飞  
*   **友情提示**：别太猛，小心把屏幕拍歪了

<img src="non-app-file/demo_video-ezgif.com-optimize.gif" height="300" alt="演示动图">

#### 2. ⌨️ 万能按键模拟器  
你可以把“开合屏幕”这个动作绑定成**任意键盘按键**。
*   绑定成 **空格键** → 用拍屏幕的方式玩 Chrome 的小恐龙游戏  
*   绑定成 **W 键** → 在《我的世界》里靠晃屏幕往前走  
*   理论上你想干啥都行（虽然大部分想法都很离谱）

<img src="non-app-file/key-simu.gif" height="300" alt="按键模拟演示">

#### 3. 🔐 屏幕密码（007 特工模式 🕵🏻‍♂️）  
设置一个“秘密握手”动作，自动输入密码。
*   **怎么触发**：快速开合屏幕三次
*   **效果**：在任何需要输密码的地方，它会自动敲出你设好的密码  
*   **装逼指数**：在咖啡馆里用这招，回头率直接拉满 （也有可能“社死”）

<img src="non-app-file/lid-password.gif" height="300" alt="密码功能演示">


#### 4. 💡 想要更多脑洞大开的功能

点击这里创建 [issue](https://github.com/huanglizhuo/Flappy.Lid/issues/new)， 或者直接提交 PR
---

### 💡 它到底是怎么做到的？

其实我们是站在别人肩膀上搞事情的：

*   **传感器原理**：MacBook 本来就有霍尔传感器之类的东西，用来判断屏幕开合状态，好决定要不要休眠。我们只是想办法读了它的原始数据。
*   **技术先驱**：特别感谢 [LidAngleSensor](https://github.com/samhenrigold/LidAngleSensor) 的作者 **Sam Henri Gold**，是从他的 repo 里知道这个隐藏传感器。
*   **灵感来源**：看到推特上 [@rebane2001](https://x.com/rebane2001/status/2007198231479103611) 做了一个用折叠屏转轴传感器玩 flappy bird——我就想： MacBook 貌似也可以吧！

---

### ⚠️ 重要提醒：动手前先看这个！

> [!WARNING]
> **出了事别找我们，后果自负！**

1.  **别把转轴玩坏**：MacBook 的转轴不是为高频拍打设计的。要是哪天屏幕松了、歪了、掉下来了……我们可不背锅。
2.  **社死预警**：在图书馆、办公室或者咖啡店用这玩意儿，**百分百**会被路人当成怪人盯着看。做好心理准备。
3.  **只支持 Apple Silicon**：
    *   专为 M1/M2/M3 系列 MacBook 打造。
    *   Intel 机型不行——它们用的传感器不一样，而且据说太烫，传感器都快烤熟了（认真脸 :doge）。
    *   另外，由于用了苹果没公开的接口，哪天系统更新把它封了，这软件就废了。趁现在还能用，赶紧玩！

---

### 🎮🕹️👾 怎么开始玩？

去 [Releases 页面](https://github.com/huanglizhuo/Flappy.Lid/releases) 下载最新版 `.dmg` 文件，双击安装就行。

### 🛠️ 想自己编译？

1.  克隆这个仓库  
2.  用 **Xcode** 打开 `Flappy.Lid.xcodeproj`  
3.  直接点 **Build & Run**  
4.  第一次运行时，记得在“系统设置 > 隐私与安全性 > 辅助功能”里给它授权（不然没法模拟按键）  
5.  开始疯狂拍屏幕吧！🦅



---

<div align="center">
  <sub>由 Lizhuo 用 ❤️ 和一丢丢不靠谱的脑洞制作</sub>
</div>