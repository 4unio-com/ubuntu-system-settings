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
import GSettings 1.0
import Ubuntu.Components 1.1
import Ubuntu.SystemSettings.SecurityPrivacy 1.0
import Unity.Application 0.1
import Unity.Notifications 1.0 as NotificationBackend
import "Components"
import "file:///usr/share/unity8/Notifications" as Notifications // FIXME This should become a module or go away

Item {
    id: root
    width: units.gu(40)
    height: units.gu(71)

    // These should be set by a security page and we apply the settings when
    // the user exits the wizard.
    property int passwordMethod: UbuntuSecurityPrivacyPanel.Passcode
    property string password: ""

    Component.onCompleted: {
        Theme.name = "Ubuntu.Components.Themes.SuruGradient"
        i18n.domain = "ubuntu-system-settings"
    }

    UbuntuSecurityPrivacyPanel {
        id: securityPrivacy
    }

    function quitWizard() {
        // Immediately go to black to give quick feedback
        blackCover.visible = true

        var errorMsg = securityPrivacy.setSecurity("", password, passwordMethod)
        if (errorMsg !== "") {
            // Ignore (but log) any errors, since we're past where the user set
            // the method.  Worst case, we just leave the user with a swipe
            // security method and they fix it in the system settings.
            console.log("Error setting security method:", errorMsg)
        }

        Qt.quit()
    }

    // This is just a little screen to immediately go to black once the wizard
    // is done, to give quick feedback to the user.
    Rectangle {
        id: blackCover
        color: "#000000"
        anchors.fill: parent
        z: 1
        visible: false
    }

    MainView {
        anchors.fill: parent
        headerColor: "#57365E"
        backgroundColor: "#A55263"
        footerColor: "#D75669"
        anchorToKeyboard: true
        useDeprecatedToolbar: false

        GSettings {
            id: background
            schema.id: "org.gnome.desktop.background"
        }

        Image {
            id: image
            anchors.fill: parent
            source: background.pictureUri
            fillMode: Image.PreserveAspectCrop
            visible: status === Image.Ready
        }

        PageStack {
            id: pageStack

            function next() {
                // If we've opened any extra (non-main) pages, pop them before
                // continuing so back button returns to the previous main page.
                while (pageList.index < pageStack.depth - 1)
                    pop()
                load(pageList.next())
            }

            function prev() {
                if (pageList.index >= pageStack.depth - 1)
                    pageList.prev() // update pageList.index, but not for extra pages
                pop()
            }

            function load(path) {
                // First load it invisible, check that we should actually use
                // this page, and either skip it or continue.
                push(path, {"opacity": 0, "enabled": false})

                // Check for immediate skip or not.  We may have to wait for
                // skipValid to be assigned (see Connections object below)
                _checkSkip()
            }

            function _checkSkip() {
                if (!currentPage) { // may have had a parse error
                    next()
                } else if (currentPage.skipValid) {
                    if (currentPage.skip) {
                        pop()
                        next()
                    } else {
                        currentPage.opacity = 1
                        currentPage.enabled = true
                    }
                }
            }

            Connections {
                target: pageStack.currentPage
                onSkipValidChanged: pageStack._checkSkip()
            }

            Component.onCompleted: next()
        }
    }

    Rectangle {
        id: modalNotificationBackground
        visible: notifications.useModal && (notifications.state == "narrow")
        anchors.fill: parent
        color: "#80000000"

        MouseArea {
            anchors.fill: parent
        }
    }

    InputMethod {
        anchors.fill: parent
    }

    Notifications.Notifications {
        id: notifications
        model: NotificationBackend.Model
        margin: units.gu(1)
        anchors {
            top: parent.top
            right: parent.right
            bottom: parent.bottom
        }
        states: [
            State {
                name: "narrow"
                when: parent.width <= units.gu(60)
                AnchorChanges { target: notifications; anchors.left: parent.left }
            },
            State {
                name: "wide"
                when: parent.width > units.gu(60)
                AnchorChanges { target: notifications; anchors.left: undefined }
                PropertyChanges { target: notifications; width: units.gu(38) }
            }
        ]
    }
}
