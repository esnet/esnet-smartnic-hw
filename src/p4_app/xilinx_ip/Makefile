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

compile: | $(APP_NAME)
	$(MAKE) -C $(APP_NAME) compile APP_DIR=$(abspath $(APP_DIR))

ip: | $(APP_NAME)
	$(MAKE) -C $(APP_NAME) ip APP_DIR=$(abspath $(APP_DIR))

synth: | $(APP_NAME)
	$(MAKE) -C $(APP_NAME) synth APP_DIR=$(abspath $(APP_DIR))

clean:
	@rm -rf $(APP_NAME)

.PHONY: all compile synth clean

$(APP_NAME):
	@mkdir -p $@
	@cp vitisnetp4.mk $(APP_NAME)/Makefile

$(APP_DIR)/.app_config.mk: $(APP_DIR)/Makefile
	$(MAKE) -C $(APP_DIR) config
