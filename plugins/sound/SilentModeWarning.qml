import QtQuick 2.4
import SystemSettings 1.0
import Ubuntu.Components 1.3
import Ubuntu.Components.ListItems 1.3 as ListItem

ListItem.Base {
    objectName: "silentModeWarning"
    height: itemId.height + units.gu(4)

    Item {
        id: itemId
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.centerIn: parent

        height: silentIcon.height + silentLabel.height
        Icon {
            id: silentIcon
            anchors.horizontalCenter: parent.horizontalCenter
            height: units.gu(3)
            width: height
            /* TODO: need a different icon */
            name: "speaker-mute"
        }
        Label {
            id: silentLabel
            anchors {
                horizontalCenter: parent.horizontalCenter
                top: silentIcon.bottom
            }
            text: i18n.tr("The phone is in Silent Mode.")
        }
    }

    showDivider: false
}
