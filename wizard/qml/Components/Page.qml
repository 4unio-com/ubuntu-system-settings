/*
 * Copyright (C) 2013 Canonical, Ltd.
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; version 3.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

import QtQuick 2.3
import Ubuntu.Components 1.1
import "." as LocalComponents

Item {
    readonly property real buttonMargin: units.gu(2)
    readonly property real buttonWidth: (width - buttonMargin * 2) / 2 -
                                        buttonMargin / 2
    readonly property real topMargin: units.gu(8)
    readonly property real leftMargin: units.gu(2)
    readonly property real rightMargin: units.gu(2)
    readonly property real bottomMargin: backButton.height + buttonMargin * 3

    property bool hasBackButton: true
    property bool customBack: false
    property alias forwardButtonSourceComponent: forwardButton.sourceComponent
    property alias content: contentItem

    property string title: ""

    signal backClicked()

    visible: false
    anchors.fill: parent

    // We want larger than even fontSize: "x-large", so we use a Text instead
    // of a Label.
    Text {
        id: titleLabel
        anchors {
            top: parent.top
            left: parent.left
            right: parent.right
            topMargin: topMargin
            leftMargin: leftMargin
            rightMargin: rightMargin
        }
        wrapMode: Text.Wrap
        text: title
        color: Theme.palette.normal.baseText
        font.pixelSize: units.gu(4)
    }

    Item {
        id: contentItem
        anchors {
            top: titleLabel.bottom
            left: parent.left
            right: parent.right
            bottom: parent.bottom
            topMargin: units.gu(4)
            leftMargin: leftMargin
            rightMargin: rightMargin
            bottomMargin: bottomMargin
        }
    }

    LocalComponents.StackButton {
        id: backButton
        width: buttonWidth
        anchors {
            left: parent.left
            bottom: parent.bottom
            leftMargin: buttonMargin
            bottomMargin: buttonMargin
        }
        z: 1
        text: i18n.tr("Back")
        visible: pageStack.depth > 1 && hasBackButton
        leftArrow: true

        onClicked: customBack ? backClicked() : pageStack.prev()
    }

    Loader {
        id: forwardButton
        width: buttonWidth
        anchors {
            right: parent.right
            bottom: parent.bottom
            rightMargin: buttonMargin
            bottomMargin: buttonMargin
        }
        z: 1
    }
}
