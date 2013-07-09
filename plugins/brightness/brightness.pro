include(../../common-project-config.pri)
include($${TOP_SRC_DIR}/common-vars.pri)

TEMPLATE = lib
TARGET = brightness

settings.files = $${TARGET}.settings
settings.path = $${PLUGIN_MANIFEST_DIR}
INSTALLS += settings

image.files = settings-brightness.svg
image.path = $$INSTALL_PREFIX/share/settings/system/icons
INSTALLS += image
