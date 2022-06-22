# ----------------------------------------------------
# Application config
# ----------------------------------------------------
APP_DIR ?= ..
include $(APP_DIR)/.app_config.mk

# -----------------------------------------------
# IP config (for compilation library setup)
# -----------------------------------------------
IP_ROOT = ..
include $(IP_ROOT)/config.mk

# ----------------------------------------------------
# Compile Targets
# ----------------------------------------------------
all: compile

compile: config
	$(MAKE) -s -C $(APP_NAME) compile APP_DIR=$(abspath $(APP_DIR))

config: | $(APP_NAME)

clean:
	@rm -rf $(APP_NAME)

.PHONY: all config compile clean

$(APP_NAME):
	@mkdir -p $@
	@cp app.mk $(APP_NAME)/Makefile

$(APP_DIR)/.app_config.mk: $(APP_DIR)/Makefile
	$(MAKE) -s -C $(APP_DIR) config
