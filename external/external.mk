# Custom packages will be added here in Module 04.
include $(sort $(wildcard $(BR2_EXTERNAL_CUSTOMIOT_PATH)/package/*/*.mk))
