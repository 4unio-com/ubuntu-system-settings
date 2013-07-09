include(../../common-project-config.pri)
include($${TOP_SRC_DIR}/common-vars.pri)

TEMPLATE = lib
TARGET = orientation-lock

QML_SOURCES = \
    EntryComponent.qml

OTHER_FILES += \
    $${QML_SOURCES}

settings.files = $${TARGET}.settings
settings.path = $${PLUGIN_MANIFEST_DIR}
INSTALLS += settings

image.files = settings-orientation-lock.svg
image.path = $$INSTALL_PREFIX/share/settings/system/icons
INSTALLS += image

qml.files = $${QML_SOURCES}
qml.path = $${PLUGIN_QML_DIR}/$${TARGET}
INSTALLS += qml
