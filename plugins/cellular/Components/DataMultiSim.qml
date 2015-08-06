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
import Ubuntu.Components 1.3
import Ubuntu.Components.ListItems 1.3 as ListItem

Column {

    property string prevOnlineModem: parent.prevOnlineModem

    function getNameFromIndex (index) {
        if (index === 0) {
            return i18n.tr("Off");
        } else if (index > 0) {
            return sims[index - 1].title;
        }
    }

    height: childrenRect.height

    SettingsItemTitle { text: i18n.tr("Cellular data:") }

    ListItem.ItemSelector {
        id: use
        objectName: "data"
        expanded: true
        model: {
            // create a model of 'off' and all sim paths
            var m = ['off'];
            sims.forEach(function (sim) {
                m.push(sim.path);
            });
            return m;
        }
        delegate: OptionSelectorDelegate {
            objectName: "use" + modelData
            text: getNameFromIndex(index)
        }
        selectedIndex: {
            if (prevOnlineModem) {
                return model.indexOf(prevOnlineModem);
            } else {
                return [true, sims[0].connMan.powered, sims[1].connMan.powered]
                    .lastIndexOf(true);
            }
        }

        onDelegateClicked: {
            // power all sims on or off
            sims.forEach(function (sim) {
                sim.connMan.powered = (model[index] === sim.path);
            });
        }
    }

    ListItem.Standard {
        id: dataRoamingItem
        text: i18n.tr("Data roaming")
        enabled: use.selectedIndex !== 0
        control: Switch {
            id: dataRoamingControl
            objectName: "roaming"

            property bool serverChecked: poweredSim && poweredSim.connMan.roamingAllowed
            onServerCheckedChanged: checked = serverChecked
            Component.onCompleted: checked = serverChecked
            onTriggered: {
                if (poweredSim) {
                    poweredSim.connMan.roamingAllowed = checked;
                }
            }
        }
        showDivider: false
    }
}
