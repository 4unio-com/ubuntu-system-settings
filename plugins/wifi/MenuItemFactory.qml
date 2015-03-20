/*
 * Copyright 2013 Canonical Ltd.
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
 *
 * Authors:
 *      Nick Dedekind <nick.dedekind@canonical.com>
 */

import QtQuick 2.0
import QMenuModel 0.1 as QMenuModel
import Ubuntu.Settings.Menus 0.1 as Menus
import Ubuntu.Settings.Components 0.1 as USC

Item {
    id: menuFactory

    property var model: null

    property var _map:  {
        "unity.widgets.systemsettings.tablet.switch"        : switchMenu,

        "com.canonical.indicator.div"       : divMenu,
        "com.canonical.indicator.section"   : sectionMenu,
        "com.canonical.indicator.switch"    : switchMenu,

        "com.canonical.unity.switch"    : switchMenu,

        "unity.widgets.systemsettings.tablet.wifisection" : wifiSection,
        "unity.widgets.systemsettings.tablet.accesspoint" : accessPoint,
    }

    Component { id: divMenu; DivMenuItem {} }

    Component {
        id: sectionMenu;
        SectionMenuItem {
            property QtObject menu: null

            text: menu && menu.label ? menu.label : ""
        }
    }

    Component {
        id: standardMenu;
        StandardMenuItem {
            property QtObject menu: null

            text: menu && menu.label ? menu.label : ""
            icon: menu ? menu.icon : ""
            checkable: menu ? (menu.isCheck || menu.isRadio) : false
            checked: checkable ? menu.isToggled : false
            enabled: menu ? menu.sensitive : false

            onActivate: model.activate(modelIndex);
        }
    }

    Component {
        id: switchMenu;
        Menus.SwitchMenu {
            id: switchItem
            property QtObject menu: null
            property bool serverChecked: menu && menu.isToggled || false

            text: menu && menu.label || ""
            iconSource: menu && menu.icon || ""
            checked: serverChecked
            enabled: menu && menu.sensitive || false

            USC.ServerPropertySynchroniser {
                userTarget: switchItem
                userProperty: "checked"
                serverTarget: switchItem
                serverProperty: "serverChecked"

                onSyncTriggered: model.activate(modelIndex)
            }
        }
    }

    Component {
        id: wifiSection;
        SectionMenuItem {
            property QtObject menu: null

            text: menu && menu.label ? menu.label : ""
            busy: menu ? menu.ext.xCanonicalBusyAction : false

            Component.onCompleted: {
                model.loadExtendedAttributes(modelIndex, {'x-canonical-busy-action': 'bool'});
            }
        }
    }

    Component {
        id: accessPoint;
        AccessPoint {
            id: apItem
            property QtObject menu: null
            property var strenthAction: QMenuModel.UnityMenuAction {
                model: menuFactory.model ? menuFactory.model : null
                name: menu ? menu.ext.xCanonicalWifiApStrengthAction : ""
            }
            property bool serverChecked: menu && menu.isToggled || false

            text: menu && menu.label ? menu.label : ""
            secure: menu ? menu.ext.xCanonicalWifiApIsSecure : false
            adHoc: menu ? menu.ext.xCanonicalWifiApIsAdhoc : false
            checked: serverChecked
            signalStrength: strenthAction.valid ? strenthAction.state : 0
            enabled: menu ? menu.sensitive : false

            Component.onCompleted: {
                model.loadExtendedAttributes(modelIndex, {'x-canonical-wifi-ap-is-adhoc': 'bool',
                                                          'x-canonical-wifi-ap-is-secure': 'bool',
                                                          'x-canonical-wifi-ap-strength-action': 'string'});
            }

            USC.ServerPropertySynchroniser {
                userTarget: apItem
                userProperty: "active"
                userTrigger: "onActivate"
                serverTarget: apItem
                serverProperty: "serverChecked"

                onSyncTriggered: model.activate(apItem.menuIndex)
            }
        }
    }

    function load(modelData) {
        if (modelData.type !== undefined) {
            var component = _map[modelData.type];
            if (component !== undefined) {
                return component;
            }
        } else {
            if (modelData.isSeparator) {
                return divMenu;
            }
        }
        return standardMenu;
    }
}
