/*
 * This file is part of system-settings
 *
 * Copyright (C) 2013 Canonical Ltd.
 *
 * Contact: Alberto Mardegan <alberto.mardegan@canonical.com>
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

import QtQuick 2.0
import Ubuntu.Components 0.1
import SystemSettings 1.0
import Ubuntu.Components.ListItems 0.1 as ListItem

ItemPage {
    id: root

    title: i18n.tr("About this phone")
    flickable: scrollWidget

    Flickable {
        id: scrollWidget
        anchors.fill: parent
        contentHeight: contentItem.childrenRect.height
        boundsBehavior: Flickable.StopAtBounds

        Column {
            anchors.left: parent.left
            anchors.right: parent.right
            ListItem.Base {
                // This should be treated like a ListItem.Standard, but with 2
                // rows.  So we'll set the height equal to that of one already
                // defined multipled by 2.
                height: storageItem.height * 2
                Column {
                    anchors {
                        left: parent.left
                        right: parent.right
                        verticalCenter: parent.verticalCenter
                    }
                    Row {
                        anchors.horizontalCenter: parent.horizontalCenter
                        height: ubuntuLogo.height
                        Item {
                            id: ubuntuLogo
                            height: childrenRect.height
                            width: childrenRect.width
                            Label {
                                id: ubuntuLogoName
                                text: "Ubuntu"
                                fontSize: "large"
                            }
                            Label {
                                anchors.left: ubuntuLogoName.right
                                text: ""
                                fontSize: "small"
                            }
                        }
                    }
                    Item {
                        id: vendorItm
                        anchors.horizontalCenter: parent.horizontalCenter
                        height: serialItem.height
                        width: childrenRect.width
                        Label {
                            id: vendorLabel
                            anchors.verticalCenter: parent.verticalCenter
                            text: "Vendor" + " " + "Model" // TODO: get manufactor and model infos from the system
                        }
                    }
                }
            }

            ListItem.SingleValue {
                id: serialItem
                text: i18n.tr("Serial")
                value: "FAKE-SERIAL-ID-NUMBER"   // TODO: read serial number from the device
            }

            ListItem.SingleValue {
                text: "IMEI"
                value: "FAKE-IMEI-ID-NUMBER"     // TODO: read IMEI number from the device
            }

            ListItem.Standard {
                text: i18n.tr("Software:")
            }

            ListItem.SingleValue {
                text: i18n.tr("OS")
                value: "Ubuntu Version 0.3"      // TODO: read version number from the device
            }

            ListItem.SingleValue {
                text: i18n.tr("Last Updated")
                value: "2013-04-09"              // TODO: read update infos from the device
            }

            // TOFIX: use ListItem.SingleControl when lp #1194844 is fixed
            ListItem.Base {
                Button {
                    anchors {
                        verticalCenter: parent.verticalCenter
                        right: parent.right
                        left: parent.left
                    }
                    text: i18n.tr("Check for updates")
                }
            }

            ListItem.Standard {
                id: storageItem
                text: i18n.tr("Storage")
                progression: true
                onClicked: pageStack.push(Qt.resolvedUrl("Storage.qml"))
            }

            ListItem.Standard {
                text: i18n.tr("Legal:")
            }

            ListItem.Standard {
                text: i18n.tr("Software licenses")
                progression: true
            }

            ListItem.Standard {
                text: i18n.tr("Regulatory info")
                progression: true
            }
        }
    }
}
