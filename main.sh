#!/bin/bash
# STM32 PlatformIO项目创建向导
# 放置于STM32Fxxx_StdPeriph_Lib目录下运行

# 检查是否安装PlatformIO
if ! command -v pio &> /dev/null; then
    echo "错误：未检测到PlatformIO，请先安装VSCode+PlatformIO插件"
    exit 1
fi

# 检查当前目录是否为标准库目录
if [ ! -d "Libraries" ] || [ ! -d "Project" ] ; then
    echo "错误：请将本脚本放置在STM32标准库根目录下运行（如STM32F10x_StdPeriph_Lib_V3.6.0）"
    echo "如果您使用的是STM32F10x系列MCU,可前往官网：https://www.st.com/en/embedded-software/stsw-stm32054.html 获取标准库"
    exit 1
fi

# 欢迎信息
echo "======================================"
echo "     STM32 PlatformIO项目创建向导     "
echo "======================================"

# 获取用户输入
read -p "请输入项目名称（如stm32_project）: " PROJECT_NAME
read -p "请输入芯片型号（默认STM32F103C8T6）: " -i "STM32F103C8T6" -e CHIP_MODEL
read -p "请输入项目保存路径（将会在这个目录下创建项目目录）: " PROJECT_PATH

# 移除路径中可能包含的单引号和双引号
PROJECT_PATH="${PROJECT_PATH//\"/}"  # 移除双引号
PROJECT_PATH="${PROJECT_PATH//\'/}"  # 移除单引号

PROJECT_PATH=${PROJECT_PATH:-$(pwd)}
PROJECT_FULL_PATH="$PROJECT_PATH/$PROJECT_NAME"

# 芯片容量类型映射（根据实际库类型扩展）
case $CHIP_MODEL in
    *F103*C8*|*F103*C6*)
        CAPACITY="md"  # 中容量
        PIO_BOARD="genericSTM32F103C8"
        ;;
    *F103*R8*|*F103*R6*)
        CAPACITY="md"  # 中容量
        PIO_BOARD="genericSTM32F103R8"
        ;;
    *F103*V*|*F103*Z*)
        CAPACITY="hd"  # 大容量
        PIO_BOARD="genericSTM32F103VE"
        ;;
    *)
        echo "未识别的芯片型号，手动输入容量类型："
        echo "1 - 小容量（LD, 16KB以下）"
        echo "2 - 中容量（MD, 16-128KB）"
        echo "3 - 大容量（HD, 128KB以上）"
        read -p "请选择容量类型（1/2/3）: " CAP_SEL
        case $CAP_SEL in
            1) CAPACITY="ld"; PIO_BOARD="genericSTM32F103C6" ;;
            2) CAPACITY="md"; PIO_BOARD="genericSTM32F103C8" ;;
            3) CAPACITY="hd"; PIO_BOARD="genericSTM32F103VE" ;;
            *) echo "输入错误"; exit 1 ;;
        esac
        ;;
esac

# 询问是否为ST原厂芯片
echo
echo "如果您使用的是国产山寨版STM32 MCU，则会需要配置与ST原厂芯片不同的 CPUTAPID。"
echo "如果您不知道自己使用的 MCU 是否是ST原厂，可以先选择 Y。之后如果无法上传程序并提示“UNEXPECTED idcode“错误，可以手动在 platformio.ini 中加入一行 “upload_flags = -c set CPUTAPID 0x2ba01477“"
read -p "MCU是否为ST原厂（Y/n）: " IS_ST_MCU
if [ -z "$IS_ST_MCU" ] || [ "$IS_ST_MCU" = "Y" ] || [ "$IS_ST_MCU" = "y" ]; then
    IS_ST_MCU=true
else
    IS_ST_MCU=false
fi

# 显示配置信息
echo -e "\n===== 项目配置确认 ====="
echo "项目名称: $PROJECT_NAME"
echo "芯片型号: $CHIP_MODEL"
echo "容量类型: ${CAPACITY^^}（对应启动文件）"
echo "项目路径: $PROJECT_FULL_PATH"
echo "PIO开发板: $PIO_BOARD"
read -p "确认创建？(y/n) " CONFIRM
if [ "$CONFIRM" != "y" ] && [ "$CONFIRM" != "Y" ]; then
    echo "已取消创建"
    exit 0
fi

# 创建PIO项目
echo -e "\n===== 开始创建PIO项目 ====="

mkdir "$PROJECT_FULL_PATH"

echo "pio project init --board $PIO_BOARD --project-dir $PROJECT_FULL_PATH"
pio project init --board $PIO_BOARD --project-dir "$PROJECT_FULL_PATH"

# 创建必要目录
mkdir -p "$PROJECT_FULL_PATH/src"
mkdir -p "$PROJECT_FULL_PATH/include"

# 复制标准库驱动
echo -e "\n===== 复制标准库文件 ====="
cp -r "Libraries/STM32F10x_StdPeriph_Driver" "$PROJECT_FULL_PATH/src/" || { echo "复制驱动失败"; exit 1; }

# 复制CMSIS设备支持文件
CMSIS_DEVICE_DIR="Libraries/CMSIS/CM3/DeviceSupport/ST/STM32F10x"
cp "$CMSIS_DEVICE_DIR/stm32f10x.h" "$PROJECT_FULL_PATH/include/"
# cp "$CMSIS_DEVICE_DIR/system_stm32f10x.c" "$PROJECT_FULL_PATH/src/"
cp "$CMSIS_DEVICE_DIR/system_stm32f10x.h" "$PROJECT_FULL_PATH/include/"

# 复制启动文件
echo -e "\n===== 查找并复制启动文件 ====="
STARTUP_DIR="$CMSIS_DEVICE_DIR/startup/gcc_ride7"
STARTUP_FILE="startup_stm32f10x_$CAPACITY.s"
if [ -f "$STARTUP_DIR/$STARTUP_FILE" ]; then
    cp "$STARTUP_DIR/$STARTUP_FILE" "$PROJECT_FULL_PATH/src/"
else
    echo "警告：未找到启动文件$STARTUP_FILE，可能需要手动添加"
fi

# 复制模板配置文件
TEMPLATE_DIR="Project/STM32F10x_StdPeriph_Template"
cp "$TEMPLATE_DIR/stm32f10x_conf.h" "$PROJECT_FULL_PATH/include/"
cp "$TEMPLATE_DIR/stm32f10x_it.h" "$PROJECT_FULL_PATH/include/"
cp "$TEMPLATE_DIR/system_stm32f10x.c" "$PROJECT_FULL_PATH/src/"
cp "$TEMPLATE_DIR/stm32f10x_it.c" "$PROJECT_FULL_PATH/src/"


# 生成platformio.ini配置
echo -e "\n===== 配置platformio.ini ====="
CAPACITY_UPPER=$(echo "$CAPACITY" | tr '[:lower:]' '[:upper:]')
cat > "$PROJECT_FULL_PATH/platformio.ini" << EOF
[env:$PIO_BOARD]
platform = ststm32
board = $PIO_BOARD
framework = cmsis
upload_protocol = stlink
debug_tool = stlink

build_flags = 
    -D STM32F10X_$CAPACITY_UPPER
    -I src/STM32F10x_StdPeriph_Driver/inc
    -D USE_STDPERIPH_DRIVER  
EOF

# 如果不是ST原厂芯片，添加upload_flags
if [ "$IS_ST_MCU" = false ]; then
    echo "upload_flags = -c set CPUTAPID 0x2ba01477" >> "$PROJECT_FULL_PATH/platformio.ini"
fi

# 生成main.c示例
echo -e "\n===== 正在生成 main.c 示例，感谢江协科技的点灯程序～ ====="
cat > "$PROJECT_FULL_PATH/src/main.c" << EOF
#include "stm32f10x.h"                  // Device header

int main(void)
{
	/*开启时钟*/
	RCC_APB2PeriphClockCmd(RCC_APB2Periph_GPIOA, ENABLE);	//开启GPIOA的时钟
															//使用各个外设前必须开启时钟，否则对外设的操作无效
	
	/*GPIO初始化*/
	GPIO_InitTypeDef GPIO_InitStructure;					//定义结构体变量
	
	GPIO_InitStructure.GPIO_Mode = GPIO_Mode_Out_PP;		//GPIO模式，赋值为推挽输出模式
	GPIO_InitStructure.GPIO_Pin = GPIO_Pin_0;				//GPIO引脚，赋值为第0号引脚
	GPIO_InitStructure.GPIO_Speed = GPIO_Speed_50MHz;		//GPIO速度，赋值为50MHz
	
	GPIO_Init(GPIOA, &GPIO_InitStructure);					//将赋值后的构体变量传递给GPIO_Init函数
															//函数内部会自动根据结构体的参数配置相应寄存器
															//实现GPIOA的初始化

	GPIO_SetBits(GPIOA, GPIO_Pin_0);				    	//将PA0引脚设置为高电平
	/*主循环，循环体内的代码会一直循环执行*/
	while (1)
	{
		
	}
}

EOF


FRAMEWORK_PATH="$HOME/.platformio/packages/framework-cmsis-stm32f1"
echo "PlatformIO 自动安装的 STM32 支持会与项目中的标准库产生冲突，需要移除一些文件来保证项目可以正常编译。"
echo "将删除以下文件/目录："
echo "1. $FRAMEWORK_PATH/Include/*"
echo "2. $FRAMEWORK_PATH/Source/Templates/system_stm32f1xx.c"
echo "3. $FRAMEWORK_PATH/Source/Templates/gcc/startup*.[sS]"
echo
read -p "是否继续？(Y/n) " -n 1 -r -e -i "Y"
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "操作已取消"
    # 完成提示
    echo -e "\n======================================"
    echo "项目创建完成！路径：$PROJECT_FULL_PATH"
    echo "由于没有删除定义冲突，项目不一定能直接成功编译。"
    echo "======================================"
    exit 0
fi

if [ ! -d "$FRAMEWORK_PATH" ]; then
    echo "错误：未找到CMSIS-STM32F1框架目录"
    echo "路径：$FRAMEWORK_PATH ：若.platformio不在默认位置请打开脚本修改FRAMEWORK_PATH"
    exit 1
fi

rm -rf $FRAMEWORK_PATH/Include/*
rm -rf $FRAMEWORK_PATH/Source/Templates/system_stm32f1xx.c
rm -rf $FRAMEWORK_PATH/Source/Templates/gcc/startup*.[sS]


# 完成提示
echo -e "\n======================================"
echo "项目创建完成！路径：$PROJECT_FULL_PATH"
echo "下一步操作："
echo "1. 用VSCode打开项目目录"
echo "2. 如需修改编译配置，编辑platformio.ini"
echo "3. 在src/main.c中编写应用代码"
echo "======================================"

echo
read -p "是否打开VSCode？(Y/n) " -n 1 -r -e -i "Y"
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    exit 0
fi

code $PROJECT_FULL_PATH