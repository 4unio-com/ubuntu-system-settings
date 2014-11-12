/*
 * Copyright (C) 2014 Canonical Ltd
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License version 3 as
 * published by the Free Software Foundation.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 * Authors:
 * Jonas G. Drange <jonas.drange@canonical.com>
 *
*/
import QtQuick 2.0
import SystemSettings 1.0
import Ubuntu.Components 0.1
import Ubuntu.Components.ListItems 0.1 as ListItem

ItemPage {
    id: root
    title: i18n.tr("Carrier & APN")
    objectName: "carrierApnPage"

    property var sim

    Flickable {
        anchors.fill: parent
        contentWidth: parent.width
        contentHeight: contentItem.childrenRect.height
        boundsBehavior: (contentHeight > root.height) ? Flickable.DragAndOvershootBounds : Flickable.StopAtBounds

        Column {
            anchors.left: parent.left
            anchors.right: parent.right

            ListItem.SingleValue {
                text: i18n.tr("Carrier")
                objectName: "carrier"
                value: sim.netReg.name ? sim.netReg.name : i18n.tr("N/A")
                enabled: sim.netReg.status !== ""
                progression: enabled
                onClicked: pageStack.push(Qt.resolvedUrl("PageChooseCarrier.qml"), {
                    sim: sim,
                    title: i18n.tr("Carrier")
                })
            }

            ListItem.Standard {
                text: i18n.tr("APN")
                objectName: "apn"
                progression: enabled
                enabled: sim.connMan.powered
                onClicked: pageStack.push(Qt.resolvedUrl("PageChooseApn.qml"), {
                    sim: sim
                })
            }
        }
    }
}
