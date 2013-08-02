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

ItemPage {
    id: root

    title: i18n.tr("Sound")
    flickable: scrollWidget

    GSettings {
        id: soundSettings
        schema.id: "com.ubuntu.touch.sound"
    }

    Flickable {
        id: scrollWidget
        anchors.fill: parent
        contentHeight: contentItem.childrenRect.height
        boundsBehavior: (contentHeight > root.height) ? Flickable.DragAndOvershootBounds : Flickable.StopAtBounds

        Column {
            anchors.left: parent.left
            anchors.right: parent.right

            SilentModeWarning { visible: soundSettings.silentMode }

            ListItem.Standard {
                text: i18n.tr("Phone calls:")
            }

            ListItem.SingleValue {
                text: i18n.tr("Ringtone")
                value: "Theremin"   // TODO: get sound effect
                progression: true
                onClicked: pageStack.push(Qt.resolvedUrl("SoundsList.qml"), {title: i18n.tr("Ringtone"),
                                          showStopButton: true, soundSettings: soundSettings})
            }

            SettingsCheckEntry {
                checkStatus: false
                textEntry: i18n.tr("Vibrate when ringing")
            }

            SettingsCheckEntry {
                checkStatus: true
                textEntry: i18n.tr("Vibrate in silent mode")
            }

            SettingsCheckEntry {
                checkStatus: true
                textEntry: i18n.tr("Vibrate with alert sound")
            }

            SettingsCheckEntry {
                checkStatus: true
                textEntry: i18n.tr("Vibrate in silent mode")
            }

            ListItem.Standard {
                text: i18n.tr("Other sounds:")
            }

            ListItem.SingleValue {
                text: i18n.tr("Message received")
                value: "Xylophone"   // TODO: get sound effect
                progression: true
                onClicked: pageStack.push(Qt.resolvedUrl("SoundsList.qml"), {title: i18n.tr("Message received"),
                                          soundSettings: soundSettings})
            }

            SettingsCheckEntry {
                checkStatus: false
                textEntry: i18n.tr("Keyboard sounds")
            }

            SettingsCheckEntry {
                checkStatus: false
                textEntry: i18n.tr("Lock sound")
            }
        }
    }
}
