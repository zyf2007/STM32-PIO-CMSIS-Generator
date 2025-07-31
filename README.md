# STM32 PlatformIO 项目创建向导

<script src="https://asciinema.org/a/RbwxP2R09OGZvWgoNzNGQ5pc2.js" id="asciicast-RbwxP2R09OGZvWgoNzNGQ5pc2" async="true"></script>

一个用于快速创建基于 STM32 标准库的 PlatformIO 项目的脚本工具。

## 功能介绍

该脚本能够自动完成以下工作：
- 引导用户输入项目信息（名称、芯片型号等）
- 自动创建 PlatformIO 项目结构
- 复制 STM32 标准库文件到项目中
- 配置编译参数和启动文件
- 添加国产兼容芯片的特殊参数
- 包含一个示例点灯程序
- 移除 PlatformIO 自带的冲突文件以确保编译正常

## 前置要求

1. 安装 VSCode + PlatformIO 插件
2. 安装 PlatformIO 并添加到环境变量以便脚本能够使用 pio 命令
3. 下载 STM32 标准库（如 STM32F10x_StdPeriph_Lib_V3.6.0）
   - STM32F10x系列可从 [ST官网](https://www.st.com/en/embedded-software/stsw-stm32054.html) 获取

## 使用方法

1. 将本脚本（`main.sh`）放入 STM32 标准库的根目录下
   - 标准库目录应包含 `Libraries` 和 `Project` 两个子目录
   
2. 赋予脚本执行权限：
   ```bash
   chmod +x main.sh
   ```

3. 运行脚本：
   ```bash
   ./main.sh
   ```

4. 按照提示完成以下配置：
   - 项目名称（如 stm32_project）
   - 芯片型号（默认 STM32F103C8T6）
   - 项目保存路径

5. 脚本会自动完成项目创建，最后可选择是否用 VSCode 打开项目

## 支持的芯片型号

脚本已预设支持以下类型芯片，其他型号可手动选择容量类型：
- 中容量（MD, 16-128KB）：STM32F103C8、STM32F103C6、STM32F103R8、STM32F103R6
- 大容量（HD, 128KB以上）：STM32F103Vx、STM32F103Zx

对于未识别的芯片型号，可手动选择：
1. 小容量（LD, 16KB以下）
2. 中容量（MD, 16-128KB）
3. 大容量（HD, 128KB以上）


