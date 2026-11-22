################################################################################
# CustomIoT Sensor Gateway
################################################################################

SENSOR_GATEWAY_SITE = $(BR2_EXTERNAL_CUSTOMIOT_PATH)/../app
SENSOR_GATEWAY_SITE_METHOD = local

SENSOR_GATEWAY_LICENSE = MIT
SENSOR_GATEWAY_LICENSE_FILES = LICENSE

define SENSOR_GATEWAY_BUILD_CMDS
	$(TARGET_CC) $(TARGET_CFLAGS) \
		-Wall -Wextra -O2 \
		$(@D)/sensor-gateway.c \
		-o $(@D)/sensor-gateway

	$(TARGET_CC) $(TARGET_CFLAGS) \
		-Wall -Wextra -O2 \
		$(@D)/gateway-supervisor.c \
		-o $(@D)/gateway-supervisor

	$(TARGET_CC) $(TARGET_CFLAGS) \
		-Wall -Wextra -O2 \
		$(@D)/uart-sensor-reader.c \
		-o $(@D)/uart-sensor-reader
endef

define SENSOR_GATEWAY_INSTALL_TARGET_CMDS
	$(INSTALL) -D -m 0755 \
		$(@D)/sensor-gateway \
		$(TARGET_DIR)/usr/bin/sensor-gateway

	$(INSTALL) -D -m 0755 \
		$(@D)/gateway-supervisor \
		$(TARGET_DIR)/usr/bin/gateway-supervisor

	$(INSTALL) -D -m 0755 \
		$(@D)/uart-sensor-reader \
		$(TARGET_DIR)/usr/bin/uart-sensor-reader
endef

define SENSOR_GATEWAY_USERS
	customiot 450 customiot 450 * - - - CustomIoT_gateway
endef

$(eval $(generic-package))
