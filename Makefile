# 项目编译目标名
TARGET = IrisLink
# 调试信息
DEBUG = 1
# 优化等级
OPT = -O2
# 链接时优化
LTO = -flto


# 编译临时文件目录
BUILD_DIR = build
EXEC_DIR = build_exec


# C源文件宏定义
C_DEFS += -DCONFIG_USB_HS
C_DEFS += -DCONFIG_CHERRYDAP_USE_CUSTOM_HID
C_DEFS += -DCONFIG_CHERRYDAP_USE_MSC 

# C头文件目录
C_INCLUDES += -ICode/app/
C_INCLUDES += -ICode/core/
C_INCLUDES += -ICode/drv/
C_INCLUDES += -ICode/usb/

C_INCLUDES += -ILibrary/DriverLib/inc

C_INCLUDES += -IMiddleware/CherryUSB/common
C_INCLUDES += -IMiddleware/CherryUSB/core
C_INCLUDES += -IMiddleware/CherryUSB/class/hid
C_INCLUDES += -IMiddleware/CherryUSB/class/cdc
C_INCLUDES += -IMiddleware/CherryUSB/class/msc
C_INCLUDES += -IMiddleware/CherryUSB/port/ch32/ch32hs

C_INCLUDES += -IMiddleware/CherryRB
C_INCLUDES += -IMiddleware/CMSIS-DAP

# C源文件
C_SOURCES += $(wildcard Library/DriverLib/src/*.c)

C_SOURCES += $(wildcard Code/app/*.c)
C_SOURCES += $(wildcard Code/core/*.c)
C_SOURCES += $(wildcard Code/drv/*.c)
C_SOURCES += $(wildcard Code/usb/*.c)

C_SOURCES += $(wildcard Middleware/CherryRB/*.c)
C_SOURCES += $(wildcard Middleware/CherryUSB/class/msc/*.c)
C_SOURCES += $(wildcard Middleware/CherryUSB/class/hid/*.c)
C_SOURCES += $(wildcard Middleware/CherryUSB/class/cdc/*.c)
C_SOURCES += $(wildcard Middleware/CherryUSB/port/ch32/ch32hs/*.c)
C_SOURCES += $(wildcard Middleware/CherryUSB/core/*.c)
C_SOURCES += $(wildcard Middleware/CMSIS-DAP/*.c)


# 汇编文件宏定义
AS_DEFS += 

# 汇编头文件目录
AS_INCLUDES +=

# 汇编源文件（starup）
ASM_SOURCES += ./Library/Startup/startup_ch32v30x_D8C.s

# 链接库
LIBS += -lc -lm -lnosys
# 库文件路径
LIBDIR += 

#######################################
# 编译器指定
#######################################
PREFIX = riscv-wch-elf-
# 启用下一项以指定GCC目录
# GCC_PATH = C:/MounRiver/MounRiver_Studio2/resources/app/resources/win32/components/WCH/Toolchain/RISC-V Embedded GCC12/bin

ifdef GCC_PATH
CC = "$(GCC_PATH)/$(PREFIX)gcc"
AS = "$(GCC_PATH)/$(PREFIX)gcc" -x assembler-with-cpp
CP = "$(GCC_PATH)/$(PREFIX)objcopy"
DUMP = "$(GCC_PATH)/$(PREFIX)objdump"
SZ = "$(GCC_PATH)/$(PREFIX)size"
else
CC = $(PREFIX)gcc
AS = $(PREFIX)gcc -x assembler-with-cpp
CP = $(PREFIX)objcopy
DUMP = $(PREFIX)objdump
SZ = $(PREFIX)size
endif
HEX = $(CP) -O ihex
BIN = $(CP) -O binary -S
 
#######################################
# 目标单片机配置信息
#######################################
# cpu
CPU = -march=rv32imacxw

# fpu
FPU = 

# float-abi
FLOAT-ABI = -mabi=ilp32

# mcu
MCU = $(CPU) $(FPU) $(FLOAT-ABI)

# -mcmodel=medany

# link script
LDSCRIPT = Library/Ld/CH32V307VC.ld



# compile gcc flags
ASFLAGS = $(MCU) $(AS_DEFS) $(AS_INCLUDES) $(OPT) $(LTO) -Wall -fdata-sections -ffunction-sections

CFLAGS += $(MCU) $(C_DEFS) $(C_INCLUDES) $(OPT) $(LTO) -Wall -msmall-data-limit=8 -msave-restore -fmessage-length=0 -fsigned-char -ffunction-sections -fdata-sections -fno-common

ifeq ($(DEBUG), 1)
CFLAGS += -g -gdwarf-2 
endif


# Generate dependency information
CFLAGS += -MMD -MP -MF"$(@:%.o=%.d)"


#######################################
# LDFLAGS
#######################################

# libraries
LDFLAGS = $(MCU) --specs=nano.specs --specs=nosys.specs -T$(LDSCRIPT) $(LIBDIR) $(LIBS) \
-Wl,-Map=$(BUILD_DIR)/$(TARGET).map,--cref -Wl,--gc-sections -msmall-data-limit=8 \
-msave-restore -fmessage-length=0 -fsigned-char -ffunction-sections -fdata-sections -fno-common -nostartfiles $(LTO) -Xlinker --print-memory-usage

# default action: build all
all: $(EXEC_DIR)/$(TARGET).elf $(EXEC_DIR)/$(TARGET).hex $(EXEC_DIR)/$(TARGET).bin POST_BUILD


#######################################
# build the application
#######################################
# list of objects
OBJECTS = $(addprefix $(BUILD_DIR)/,$(notdir $(C_SOURCES:.c=.o)))
vpath %.c $(sort $(dir $(C_SOURCES)))
# list of ASM program objects
OBJECTS += $(addprefix $(BUILD_DIR)/,$(notdir $(ASM_SOURCES:.s=.o)))
vpath %.s $(sort $(dir $(ASM_SOURCES)))

$(BUILD_DIR)/%.o: %.c Makefile | $(BUILD_DIR) 
	@echo "[CC]    $<"
	@$(CC) -c $(CFLAGS) $< -o $@

$(BUILD_DIR)/%.o: %.s Makefile | $(BUILD_DIR)
	@echo "[AS]    $<"
	@$(AS) -c $(ASFLAGS) $< -o $@

$(EXEC_DIR)/$(TARGET).elf: $(OBJECTS) Makefile | $(EXEC_DIR)
	@echo "[LD]    $@"
	@$(CC) $(OBJECTS) $(LDFLAGS) -o $@

$(EXEC_DIR)/%.hex: $(EXEC_DIR)/%.elf | $(EXEC_DIR)
	@echo "[HEX]   $< -> $@"
	@$(HEX) $< $@
	
$(EXEC_DIR)/%.bin: $(EXEC_DIR)/%.elf | $(EXEC_DIR)
	@echo "[BIN]   $< -> $@"
	@$(BIN) $< $@
	
$(BUILD_DIR):
	@mkdir $@

$(EXEC_DIR):
	@mkdir $@

#######################################
# POST_BUILD
#######################################
.PHONY: POST_BUILD
POST_BUILD: $(EXEC_DIR)/$(TARGET).elf $(EXEC_DIR)/$(TARGET).bin
	@echo "[DUMP]  $< -> $(EXEC_DIR)/$(TARGET).s"
	@$(DUMP) -d $< > $(EXEC_DIR)/$(TARGET).s

# 	@echo "[SIZE]  $<"
# 	@$(SZ) $<

	@echo -e "$(OK_COLOR)Build Finish$(NO_COLOR)"

#######################################
# 清除中间文件
#######################################
.PHONY: clean
clean:
	@rm -rf $(BUILD_DIR)
	@echo -e "$(OK_COLOR)Clean Build Finish$(NO_COLOR)"

.PHONY: cleanall
cleanall: clean
	@rm -rf $(EXEC_DIR)
	@echo -e "$(OK_COLOR)Clean Exec Finish$(NO_COLOR)"
	

#######################################
# 依赖文件
#######################################
-include $(wildcard $(BUILD_DIR)/*.d)

# *** EOF ***