/*
 * This file is part of system-settings
 *
 * Copyright (C) 2016 Canonical Ltd.
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

import QtQuick 2.4
import QtTest 1.0
import Ubuntu.Components 1.3
import Ubuntu.SystemSettings.Brightness 1.0
import Ubuntu.Test 0.1

import Source 1.0

Item {
    id: testRoot
    width: 300
    height: 500

    Component {
        id: wifiDisplays
        WifiDisplays {
            anchors.fill: parent
        }
    }

    UbuntuTestCase {
        name: "BrightnessWifiDisplays"
        when: windowShown

        property var instance: null

        function init() {
            instance = wifiDisplays.createObject(testRoot, {});
        }

        function cleanup() {
            instance.destroy();
        }

        function test_foo() {
            wait(3000)
        }

    }
}