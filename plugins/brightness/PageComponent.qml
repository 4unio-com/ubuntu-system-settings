/*
 * This file is part of system-settings
 *
 * Copyright (C) 2013-14 Canonical Ltd.
 *
 * Contact: Iain Lane <iain.lane@canonical.com>
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
import QtQuick 2.4
import SystemSettings 1.0
import Ubuntu.Components 1.3
import Ubuntu.Components.ListItems 1.3 as ListItem
import Ubuntu.SystemSettings.Brightness 1.0
import Ubuntu.Settings.Menus 0.1 as Menus
import Ubuntu.Settings.Components 0.1 as USC
import QMenuModel 0.1

ItemPage {
    id: root
    objectName: "brightnessPage"

    title: i18n.tr("Brightness")

    UbuntuBrightnessPanel {
        id: brightnessPanel
    }

    Column {
        anchors.left: parent.left
        anchors.right: parent.right

        QDBusActionGroup {
            id: indicatorPower
            busType: 1
            busName: "com.canonical.indicator.power"
            objectPath: "/com/canonical/indicator/power"

            property variant brightness: action("brightness")

            Component.onCompleted: start()
        }

        ListItem.Standard {
            text: i18n.tr("Display brightness")
            showDivider: false
        }

        /* Use the SliderMenu component instead of the Slider to avoid binding
           issues on valueChanged until LP: #1388094 is fixed.
        */
        Menus.SliderMenu {
            id: brightnessSlider
            objectName: "sliderMenu"
            enabled: indicatorPower.brightness.state != null
            live: true
            minimumValue: 0.0
            maximumValue: 100.0
            minIcon: "image://theme/display-brightness-min"
            maxIcon: "image://theme/display-brightness-max"

            property real serverValue: enabled ? indicatorPower.brightness.state * 100 : 0.0

            USC.ServerPropertySynchroniser {
                userTarget: brightnessSlider
                userProperty: "value"
                serverTarget: brightnessSlider
                serverProperty: "serverValue"
                maximumWaitBufferInterval: 16

                onSyncTriggered: indicatorPower.brightness.updateState(value / 100.0)
            }
        }

        ListItem.Standard {
            id: adjust
            text: i18n.tr("Adjust automatically")
            visible: brightnessPanel.powerdRunning &&
                     brightnessPanel.autoBrightnessAvailable
            control: CheckBox {
                id: autoAdjustCheck
                property bool serverChecked: gsettings.autoBrightness
                onServerCheckedChanged: checked = serverChecked
                Component.onCompleted: checked = serverChecked
                onTriggered: gsettings.autoBrightness = checked
            }
            showDivider: false
        }
        ListItem.Caption {
            text: i18n.tr(
                    "Brightens and dims the display to suit the surroundings.")
            visible: adjust.visible
        }
    }

    GSettings {
        id: gsettings
        schema.id: "com.ubuntu.touch.system"
    }
}
