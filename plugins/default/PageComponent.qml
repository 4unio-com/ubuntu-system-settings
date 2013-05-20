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

import QMenuModel 0.1
import QtQuick 2.0
import Ubuntu.Components 0.1
import Ubuntu.SystemSettings.Utils 0.1

Page {
    id: root

    property variant item

    title: i18n.dtr(item.manifest.translations, item.manifest.name)

    Component.onCompleted: menuModel.start()

    QDBusMenuModel {
        id: menuModel
        busType: DBus.SessionBus
        busName: "com.canonical.indicator.messages"
        objectPath: "/com/canonical/indicator/messages/menu"
    }

    FlatModel {
        id: flatModel
        model: menuModel
        onCountChanged: console.log("flatmodel count: " + count)
    }

    ListView {
        id: view
        anchors.fill: parent
        model: flatModel
        spacing: 3
        delegate: MenuItemDelegate {
            anchors.left: parent.left
            anchors.right: parent.right
            menuModel: flatModel.model
            modelIndex: flatModel.modelIndex(index)
        }
    }
}
