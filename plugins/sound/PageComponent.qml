/*
 * This file is part of system-settings
 *
 * Copyright (C) 2013 Canonical Ltd.
 *
 * Contact: Sebastien Bacher <sebastien.bacher@canonical.com>
 *
 * This program is free software: you can redistribute it and/or modify it
 * under the terms of the GNU General Public License version 3, as published
 * by the Free Software Foundation.
 *
 * This program is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranties of
 * MERCHANTABILITY, SATISFACTORY QUALITY, or FITNESS FOR A PARTICULAR
 * PURPOSE.  See the GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License along
 * with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

import GSettings 1.0
import QtQuick 2.0
import Ubuntu.Components 0.1
import Ubuntu.Components.ListItems 0.1 as ListItem
import SystemSettings 1.0
import Ubuntu.SystemSettings.Sound 1.0
import Ubuntu.Settings.Menus 0.1 as Menus
import QMenuModel 0.1

import "utilities.js" as Utilities

ItemPage {
    id: root

    objectName: "soundPage"

    title: i18n.tr("Sound")
    flickable: scrollWidget

    UbuntuSoundPanel { id: backendInfo }

    GSettings {
        id: keyboardSettings

        schema.id: "com.canonical.keyboard.maliit"
    }

    GSettings {
        id: soundSettings
        schema.id: "com.ubuntu.touch.sound"
    }

    Flickable {
        id: scrollWidget
        anchors.fill: parent
        contentHeight: contentItem.childrenRect.height
        boundsBehavior: (contentHeight > root.height) ?
                            Flickable.DragAndOvershootBounds :
                            Flickable.StopAtBounds
        /* Set the direction to workaround https://bugreports.qt-project.org/browse/QTBUG-31905
           otherwise the UI might end up in a situation where scrolling doesn't work */
        flickableDirection: Flickable.VerticalFlick

        Column {
            anchors.left: parent.left
            anchors.right: parent.right

            ListItem.Standard {
                control: Switch {
                    id: silentModeSwitch
                    objectName: "silentMode"
                    property bool serverChecked: soundActionGroup.silentMode.state
                    onServerCheckedChanged: checked = serverChecked
                    Component.onCompleted: checked = serverChecked
                    onTriggered: soundActionGroup.silentMode.activate()
                }
                text: i18n.tr("Silent Mode")
            }

            SettingsItemTitle {
                text: i18n.tr("Ringer:")
            }

            QDBusActionGroup {
                id: soundActionGroup
                busType: DBus.SessionBus
                busName: "com.canonical.indicator.sound"
                objectPath: "/com/canonical/indicator/sound"

                property variant volume: action("volume")
                property variant silentMode: action("silent-mode")
                property variant highVolume: action("high-volume")

                Component.onCompleted: start()
            }

            Binding {
                target: sliderMenu
                property: "value"
                value: soundActionGroup.volume.state
            }

            Menus.SliderMenu {
                id: sliderMenu
                objectName: "sliderMenu"
                enabled: soundActionGroup.volume.state != null
                minimumValue: 0.0
                maximumValue: 1.0
                minIcon: "image://theme/audio-volume-low-zero"
                maxIcon: "image://theme/audio-volume-high" 
                onUpdated: soundActionGroup.volume.updateState(value);
            }

            ListItem.Standard {
                id: highVolumeWarning
                visible: soundActionGroup.highVolume.state == true
                text: i18n.tr("High volume can damage your hearing.")
            }

            SettingsItemTitle {
                text: i18n.tr("Phone calls:")
            }

            ListItem.SingleValue {
                text: i18n.tr("Ringtone")
                value: Utilities.buildDisplayName(
                           backendInfo.incomingCallSound)
                progression: true
                onClicked: pageStack.push(
                               Qt.resolvedUrl("SoundsList.qml"),
                               { title: i18n.tr("Ringtone"),
                                 showStopButton: true,
                                 soundType: 0,
                                 soundsDir:
                                   "/usr/share/sounds/ubuntu/ringtones/" })
            }

            ListItem.Standard {
                control: CheckBox {
                    objectName: "callVibrate"
                    property bool serverChecked: backendInfo.incomingCallVibrate
                    onServerCheckedChanged: checked = serverChecked
                    Component.onCompleted: checked = serverChecked
                    onTriggered: backendInfo.incomingCallVibrate = checked
                }
                text: i18n.tr("Vibrate on ring")
            }

            ListItem.Standard {
                control: CheckBox {
                    objectName: "callVibrateSilentMode"
                    property bool serverChecked: backendInfo.incomingCallVibrateSilentMode
                    onServerCheckedChanged: checked = serverChecked
                    Component.onCompleted: checked = serverChecked
                    onTriggered: backendInfo.incomingCallVibrateSilentMode = checked
                }
                text: i18n.tr("Vibrate in Silent Mode")
            }

            ListItem.Standard {
                control: Switch {
                    objectName: "dialpadSounds"
                    property bool serverChecked: backendInfo.dialpadSoundsEnabled
                    onServerCheckedChanged: checked = serverChecked
                    Component.onCompleted: checked = serverChecked
                    onTriggered: backendInfo.dialpadSoundsEnabled = checked
                }
                text: i18n.tr("Dialpad tones")
            }

            SettingsItemTitle {
                text: i18n.tr("Messages:")
            }

            ListItem.SingleValue {
                text: i18n.tr("Message received")
                value:Utilities.buildDisplayName(
                          backendInfo.incomingMessageSound)
                progression: true
                onClicked: pageStack.push(
                               Qt.resolvedUrl("SoundsList.qml"),
                               { title: i18n.tr("Message received"),
                                  soundType: 1,
                                 soundsDir:
                                   "/usr/share/sounds/ubuntu/notifications/" })
            }

            ListItem.Standard {
                control: CheckBox {
                    objectName: "messageVibrate"
                    property bool serverChecked: backendInfo.incomingMessageVibrate
                    onServerCheckedChanged: checked = serverChecked
                    Component.onCompleted: checked = serverChecked
                    onTriggered: backendInfo.incomingMessageVibrate = checked
                }
                text: i18n.tr("Vibrate with message sound")
            }

            ListItem.Standard {
                control: CheckBox {
                    objectName: "messageVibrateSilentMode"
                    property bool serverChecked: backendInfo.incomingMessageVibrateSilentMode
                    onServerCheckedChanged: checked = serverChecked
                    Component.onCompleted: checked = serverChecked
                    onTriggered: backendInfo.incomingMessageVibrateSilentMode = checked
                }
                text: i18n.tr("Vibrate in Silent Mode")
            }

            SettingsItemTitle {
                text: i18n.tr("Other sounds:")
            }

            ListItem.Standard {
                text: i18n.tr("Keyboard sound")

                control: Switch {
                    objectName: "keyboardSoundSwitch"
                    property bool serverChecked: keyboardSettings.keyPressFeedback
                    onServerCheckedChanged: checked = serverChecked
                    Component.onCompleted: checked = serverChecked
                    onTriggered: keyboardSettings.keyPressFeedback = checked
                }
            }

            ListItem.Standard {
                id: lockSound
                control: Switch {
                    checked: false
                }
                text: i18n.tr("Lock sound")
                visible: showAllUI
            }
        }
    }
}
