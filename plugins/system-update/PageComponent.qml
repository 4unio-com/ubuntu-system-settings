/*
 * This file is part of system-settings
 *
 * Copyright (C) 2013-2014 Canonical Ltd.
 *
 * Contact: Didier Roche <didier.roches@canonical.com>
 * Contact: Diego Sarmentero <diego.sarmentero@canonical.com>
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
import SystemSettings 1.0
import Ubuntu.Components 0.1
import Ubuntu.Components.ListItems 0.1 as ListItem
import Ubuntu.Components.Popups 0.1
import Ubuntu.OnlineAccounts.Client 0.1
import Ubuntu.SystemSettings.Update 1.0
import Ubuntu.Connectivity 1.0


ItemPage {
    id: root
    objectName: "systemUpdatesPage"

    title: installingImageUpdate.visible ? "" : i18n.tr("Updates")
    flickable: (installingImageUpdate.visible || appHeaderHeight === 0) ? null : scrollWidget

    property bool installAll: false
    property bool includeSystemUpdate: false
    property bool systemUpdateInProgress: false
    property int updatesAvailable: 0
    property bool isCharging: indicatorPower.deviceState === "charging"
    property bool batterySafeForUpdate: isCharging || chargeLevel > 25
    property var chargeLevel: indicatorPower.batteryLevel || 0
    property var notificationAction;
    property string errorDialogText: ""

    //Needed for workaround to truly center the "No updates available" label in the free area, excluding the area covered by the header (see the updateNotification definition below)
    property real appHeaderHeight: 0

    onUpdatesAvailableChanged: {
        if (updatesAvailable < 1 && root.state != "SEARCHING")
            root.state = "NOUPDATES";
    }

    QDBusActionGroup {
        id: indicatorPower
        busType: 1
        busName: "com.canonical.indicator.power"
        objectPath: "/com/canonical/indicator/power"
        property variant batteryLevel: action("battery-level").state
        property variant deviceState: action("device-state").state
        Component.onCompleted: start()
    }

    Connections {
        id: networkingStatus
        target: NetworkingStatus
        onOnlineChanged: {
            if (NetworkingStatus.online) {
                activity.running = true;
                root.state = "SEARCHING";
                UpdateManager.checkUpdates();
            } else {
                activity.running = false;
            }
        }
    }

    Setup {
        id: uoaConfig
        applicationId: "ubuntu-system-settings"
        providerId: "ubuntuone"

        onFinished: {
            credentialsNotification.visible = false;
            root.state = "SEARCHING";
            UpdateManager.checkUpdates();
        }
    }

    Component {
         id: dialogInstallComponent
         Dialog {
             id: dialogueInstall
             title: i18n.tr("Update System")
             text: root.batterySafeForUpdate ? i18n.tr("The phone needs to restart to install the system update.") : i18n.tr("Connect the phone to power before installing the system update.")

             Button {
                 text: i18n.tr("Install & Restart")
                 visible: root.batterySafeForUpdate ? true : false
                 color: UbuntuColors.orange
                 onClicked: {
                     installingImageUpdate.visible = true;
                     UpdateManager.applySystemUpdate();
                     PopupUtils.close(dialogueInstall);
                 }
             }
             Button {
                 text: i18n.tr("Not Now")
                 color: UbuntuColors.warmGrey
                 onClicked: {
                     updateList.currentIndex = 0;
                     var item = updateList.currentItem;
                     var modelItem = UpdateManager.model[0];
                     item.actionButton.text = i18n.tr("Install");
                     item.progressBar.opacity = 0;
                     modelItem.updateReady = true;
                     modelItem.selected = false;
                     root.systemUpdateInProgress = false;
                     PopupUtils.close(dialogueInstall);
                 }
             }
         }
    }

    Component {
         id: dialogErrorComponent
         Dialog {
             id: dialogueError
             title: i18n.tr("Installation failed")
             text: root.errorDialogText

             Button {
                 text: i18n.tr("OK")
                 color: UbuntuColors.orange
                 onClicked: {
                     PopupUtils.close(dialogueError);
                 }
             }
         }
    }

    //states
    states: [
        State {
            name: "SEARCHING"
            PropertyChanges { target: installAllButton; visible: false}
            PropertyChanges { target: checkForUpdatesArea; visible: true}
            PropertyChanges { target: updateNotification; visible: false}
            PropertyChanges { target: activity; running: true}
        },
        State {
            name: "NOUPDATES"
            PropertyChanges { target: updateNotification; text: i18n.tr("Software is up to date")}
            PropertyChanges { target: updateNotification; visible: true}
            PropertyChanges { target: updateList; visible: false}
            PropertyChanges { target: installAllButton; visible: false}
        },
        State {
            name: "SYSTEMUPDATEFAILED"
            PropertyChanges { target: installingImageUpdate; visible: false}
            PropertyChanges { target: installAllButton; visible: false}
            PropertyChanges { target: checkForUpdatesArea; visible: false}
            PropertyChanges { target: updateNotification; visible: false}
        },
        State {
            name: "UPDATE"
            PropertyChanges { target: updateList; visible: true}
            PropertyChanges { target: installAllButton; visible: root.updatesAvailable > 1}
            PropertyChanges { target: updateNotification; visible: false}
        }
    ]

    Connections {
        id: updateManager
        target: UpdateManager
        objectName: "updateManager"

        Component.onCompleted: {
            credentialsNotification.visible = false;
            root.state = "SEARCHING";
            UpdateManager.checkUpdates();
        }

        onUpdateAvailableFound: {
            root.updatesAvailable = UpdateManager.model.length;
            if (root.updatesAvailable > 0)
                root.includeSystemUpdate = UpdateManager.model[0].systemUpdate
            root.state = "UPDATE";
            root.installAll = downloading;
        }

        onUpdatesNotFound: {
            if (!credentialsNotification.visible) {
                root.state = "NOUPDATES";
            }
        }

        onCheckFinished: {
            checkForUpdatesArea.visible = false;
        }

        onCredentialsNotFound: {
            credentialsNotification.visible = true;
        }

        onCredentialsDeleted: {
            credentialsNotification.visible = false;
            uoaConfig.exec();
        }

        onSystemUpdateDownloaded: {
            root.installAll = false;
        }

        onSystemUpdateFailed: {
            root.state = "SYSTEMUPDATEFAILED";
            root.errorDialogText = i18n.tr("Sorry, the system update failed.");
            PopupUtils.open(dialogErrorComponent);
        }

        onUpdateProcessFailed: {
            root.state = "SYSTEMUPDATEFAILED";
            root.errorDialogText = i18n.tr("Sorry, the system update failed.");
            PopupUtils.open(dialogErrorComponent);
        }

        onServerError: {
            activity.running = false;
        }

        onNetworkError: {
            activity.running = false;
        }

        onRebooting: {
            installingImageUpdate.message = i18n.tr("Restarting…");
        }
    }
    Flickable {
        id: scrollWidget

        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: configuration.top

        contentHeight: contentItem.childrenRect.height
        boundsBehavior: (contentHeight > root.height) ? Flickable.DragAndOvershootBounds : Flickable.StopAtBounds
        clip: true
        /* Set the direction to workaround https://bugreports.qt-project.org/browse/QTBUG-31905
           otherwise the UI might end up in a situation where scrolling doesn't work */
        flickableDirection: Flickable.VerticalFlick

        Column {
            id: columnId
            anchors {
                left: parent.left
                right: parent.right
            }
            height: childrenRect.height
            
            ListItem.Base {
                id: checkForUpdatesArea
                objectName: "checkForUpdatesArea"
                showDivider: false
                visible: false

                ActivityIndicator {
                    id: activity
                    running: checkForUpdatesArea.visible
                    visible: activity.running
                    anchors {
                        left: parent.left
                        top: parent.top
                    }
                    height: parent.height
                }

                Label {
                    text: activity.running ? i18n.tr("Checking for updates…") : i18n.tr("Connect to the Internet to check for updates")
                    verticalAlignment: Text.AlignVCenter
                    elide: Text.ElideRight
                    anchors {
                        left: activity.running ? activity.right : parent.left
                        top: parent.top
                        right: btnRetry.visible ? btnRetry.left : parent.right
                        rightMargin: units.gu(2)
                        leftMargin: units.gu(2)
                    }
                    height: parent.height
                }

                Button {
                    id: btnRetry
                    text: i18n.tr("Retry")
                    color: UbuntuColors.orange
                    anchors {
                        right: parent.right
                        top: parent.top
                        bottom: parent.bottom
                        margins: units.gu(1)
                    }
                    visible: !activity.visible

                    onClicked: {
                        activity.running = true;
                        root.state = "SEARCHING";
                        UpdateManager.checkUpdates();
                    }
                }
            }

            ListItem.SingleControl {
                height: installAllButton.visible ? units.gu(8) : units.gu(2)
                highlightWhenPressed: false
                control: Button {
                    id: installAllButton
                    objectName: "installAllButton"
                    property string primaryText: includeSystemUpdate ?
                                                     i18n.tr("Install %1 update…", "Install %1 updates…", root.updatesAvailable).arg(root.updatesAvailable) :
                                                     i18n.tr("Install %1 update", "Install %1 updates", root.updatesAvailable).arg(root.updatesAvailable)
                    property string secondaryText: i18n.tr("Pause All")
                    color: UbuntuColors.orange
                    text: root.installAll ? secondaryText : primaryText
                    width: parent.width - units.gu(4)

                    onClicked: {
                        for (var i=0; i < updateList.count; i++) {
                            updateList.currentIndex = i;
                            var item = updateList.currentItem;
                            var modelItem = UpdateManager.model[i];
                            if (item.installing || item.installed)
                                continue;
                            console.warn("AllClicked: " + modelItem.updateState + " " + modelItem.updateReady + " " +  modelItem.selected);
                            if (item.retry) {
                                item.retry = false;
                                UpdateManager.retryDownload(modelItem.packageName);
                                continue;
                            }
                            if (root.installAll && !modelItem.updateReady && modelItem.selected) {
                                item.pause();
                                continue;
                            }
                            console.warn("Past pause");
                            if (!root.installAll && !modelItem.updateReady && modelItem.selected) {
                                item.resume();
                                continue;
                            }
                            console.warn("Past resume");
                            if (!root.installAll && !modelItem.updateState && !modelItem.updateReady && !modelItem.selected) {
                                item.start();
                                continue;
                            }
                            console.warn("Past start");
                        }
                        root.installAll = !root.installAll;
                    }
                }
                showDivider: false
            }

            ListView {
                id: updateList
                objectName: "updateList"
                anchors {
                    left: parent.left
                    right: parent.right
                }
                model: UpdateManager.model
                height: childrenRect.height
                interactive: false
                spacing: units.gu(2)

                delegate: ListItem.Subtitled {
                    id: listItem
                    anchors {
                        left: parent.left
                        right: parent.right
                    }
                    iconSource: Qt.resolvedUrl(modelData.iconUrl)
                    iconFrame: modelData.systemUpdate ? false : true
                    height: visible ? textArea.height : 0
                    highlightWhenPressed: false
                    showDivider: false
                    visible: opacity > 0
                    opacity: installed ? 0 : 1
                    Behavior on opacity { PropertyAnimation { duration: UbuntuAnimation.SleepyDuration } }

                    property alias actionButton: buttonAppUpdate
                    property alias progressBar: progress
                    property bool installing: !modelData.systemUpdate && (modelData.updateReady || (progressBar.value === progressBar.maximumValue))
                    property bool installed: false
                    property bool retry: false

                    function pause () {
                        console.warn("PAUSE: " + modelData.packageName);
                        if (modelData.systemUpdate)
                            return UpdateManager.pauseDownload(modelData.packageName);
                        modelData.updateState = false;
                        tracker.pause();
                    }

                    function resume () {
                        console.warn("RESUME: " + modelData.packageName);
                        if (modelData.systemUpdate)
                            return UpdateManager.startDownload(modelData.packageName);
                        modelData.updateState = true;
                        tracker.resume();
                    }

                    function start () {
                        console.warn("START: " + modelData.packageName);
                        modelData.selected = true;
                        modelData.updateState = true;
                        UpdateManager.startDownload(modelData.packageName);
                    }
                    Column {
                        id: textArea
                        objectName: "textArea"
                        anchors {
                            left: parent.left
                            right: parent.right
                        }
                        spacing: units.gu(0.5)

                        Item {
                            anchors {
                                left: parent.left
                                right: parent.right
                            }
                            height: buttonAppUpdate.height
                            
                            Label {
                                id: labelTitle
                                objectName: "labelTitle"
                                anchors {
                                    left: parent.left
                                    right: buttonAppUpdate.visible ? buttonAppUpdate.left : parent.right
                                    verticalCenter: parent.verticalCenter
                                }
                                text: modelData.title
                                font.bold: true
                                elide: Text.ElideMiddle
                            }

                            Button {
                                id: buttonAppUpdate
                                objectName: "buttonAppUpdate"
                                anchors.right: parent.right
                                height: labelTitle.height + units.gu(1)
                                enabled: !installing 
                                text: {
                                    if (retry)
                                        return i18n.tr("Retry");
                                    if (modelData.systemUpdate) {
                                        if (modelData.updateReady) {
                                            return i18n.tr("Install…");
                                        } else if (!modelData.updateState && !modelData.selected) {
                                            return i18n.tr("Download");
                                        }
                                    }
                                    if (modelData.updateState) {
                                        return i18n.tr("Pause");
                                    } else if (modelData.selected) {
                                        return i18n.tr("Resume");
                                    }
                                    return i18n.tr("Update");
                                }

                                onClicked: {
                                    if (retry) {
                                        retry = false;
                                        return UpdateManager.retryDownload(modelData.packageName);
                                    }
                                    if (modelData.updateState)
                                        return pause();
                                    if (!modelData.updateState && modelData.selected)
                                        return resume();
                                    if (!modelData.updateState && !modelData.selected && !modelData.updateReady)
                                        return start();
                                    if (modelData.updateReady)
                                        PopupUtils.open(dialogInstallComponent);
                                }
                            }
                        } 
                        
                        Item {
                            id: labelUpdateStatus
                            anchors {
                                left: parent.left
                                right: parent.right
                            }
                            height: childrenRect.height
                            visible: opacity > 0
                            opacity: (modelData.updateState && modelData.selected && !modelData.updateReady) || (installing || installed) ? 1 : 0
                            Behavior on opacity { PropertyAnimation { duration: UbuntuAnimation.SleepyDuration } }
                            Label {
                                objectName: "labelUpdateStatus"
                                anchors.left: parent.left
                                anchors.right: updateStatusLabel.left
                                elide: Text.ElideMiddle
                                fontSize: "small"
                                text: {
                                    if (retry)
                                        return modelData.error;
                                    if (installing)
                                        return i18n.tr("Installing");
                                    if (installed)
                                        return i18n.tr("Installed");
                                    return i18n.tr("Downloading");
                                }
                            }
                            Label {
                                id: updateStatusLabel
                                anchors.right: parent.right
                                visible: !labelSize.visible && !installing && !installed
                                fontSize: "small"
                                text: {
                                    if (!labelUpdateStatus.visible)
                                        return Utilities.formatSize(modelData.binaryFilesize);

                                    return i18n.tr("%1 of %2").arg(
                                        Utilities.formatSize(modelData.binaryFilesize * (progress.value * 0.01))).arg(
                                        Utilities.formatSize(modelData.binaryFilesize)
                                    );
                                }
                            }
                        }

                        ProgressBar {
                            id: progress
                            objectName: "progress"
                            height: units.gu(2)
                            anchors {
                                left: parent.left
                                right: parent.right
                            }
                            visible: opacity > 0
                            opacity: modelData.selected && !modelData.updateReady && !installed ? 1 : 0
                            value: modelData.systemUpdate ? modelData.downloadProgress : tracker.progress
                            minimumValue: 0
                            maximumValue: 100

                            DownloadTracker {
                                id: tracker
                                objectName: "tracker"
                                packageName: modelData.packageName
                                clickToken: modelData.clickToken
                                download: modelData.downloadUrl
                                downloadSha512: modelData.downloadSha512

                                onFinished: {
                                    progress.visible = false;
                                    buttonAppUpdate.visible = false;
                                    installed = true;
                                    installing = false;
                                    root.updatesAvailable -= 1;
                                    modelData.updateRequired = false;
                                    UpdateManager.updateClickScope();
                                }

                                onProcessing: {
                                    console.warn("onProcessing: " + modelData.packageName + " " + path);
                                    buttonAppUpdate.enabled = false;
                                    installing = true;
                                    modelData.updateState = false;
                                }

                                onStarted: {
                                    console.warn("onStarted: " + modelData.packageName + " " + success);
                                    if (success)
                                        modelData.updateState = true;
                                    else
                                        modelData.updateState = false;
                                }

                                onPaused: {
                                    console.warn("onPaused: " + modelData.packageName + " " + success);
                                    if (success)
                                        modelData.updateState = false;
                                    else
                                        modelData.updateState = true;
                                }

                                onResumed: {
                                    console.warn("onResumed: " + modelData.packageName + " " + success);
                                    if (success)
                                        modelData.updateState = true;
                                    else
                                        modelData.updateState = false;
                                }

                                onCanceled: {
                                    console.warn("onCanceled: " + modelData.packageName + " " + success);
                                    if (success) {
                                        modelData.updateState = false;
                                        modelData.selected = false;
                                    }
                                }

                                onErrorFound: {
                                    console.warn("onErrorFound: " + modelData.packageName + " " + error);
                                    modelData.updateState = false;
                                    retry = true;
                                    installing = false;
                                }
                            }

                            Behavior on opacity { PropertyAnimation { duration: UbuntuAnimation.SleepyDuration } }
                        }

                        Item {
                            anchors {
                                left: parent.left
                                right: parent.right
                            }
                            height: childrenRect.height
                            Label {
                                id: labelVersion
                                objectName: "labelVersion"
                                anchors.left: parent.left
                                text: modelData.remoteVersion ? i18n.tr("Version: ") + modelData.remoteVersion : ""
                                elide: Text.ElideRight
                                fontSize: "small"
                            }

                            Label {
                                id: labelSize
                                objectName: "labelSize"
                                anchors.right: parent.right
                                text: Utilities.formatSize(modelData.binaryFilesize)
                                fontSize: "small"
                                visible: !labelUpdateStatus.visible && !installing && !installed
                            }
                        }
                    }
                }
            }

            Column {
                id: credentialsNotification
                objectName: "credentialsNotification"

                visible: false

                spacing: units.gu(2)
                anchors {
                    left: parent.left
                    right: parent.right
                }
                ListItem.ThinDivider {}

                Label {
                    text: i18n.tr("Sign in to Ubuntu One to receive updates for apps.")
                    horizontalAlignment: Text.AlignHCenter
                    wrapMode: Text.Wrap
                    anchors {
                        left: parent.left
                        right: parent.right
                    }
                }
                Button {
                    text: i18n.tr("Sign In…")
                    anchors {
                        left: parent.left
                        right: parent.right
                        leftMargin: units.gu(2)
                        rightMargin: units.gu(2)
                    }
                    onClicked: uoaConfig.exec()
                }

            }
        }
    }

    Rectangle {
        id: updateNotification
        objectName: "updateNotification"
        anchors {
            bottom: configuration.top
            left: parent.left
            right: parent.right
            top: parent.top
        }
        visible: false
        property string text: ""

        color: "transparent"

        Label {
            text: updateNotification.text
            width: updateNotification.width
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.Wrap

            //Workaround to truly center the label in the free area, excluding the area covered by the header

            anchors {
                centerIn: updateNotification
                verticalCenterOffset: appHeaderHeight / 2
            }

            Component.onCompleted: { //Determines header height (needed for offset), which automatically sets the flickable above
                appHeaderHeight = main.height - root.height //main is the MainView
            }
        }
    }

    Rectangle {
        id: installingImageUpdate
        objectName: "installingImageUpdate"
        anchors.fill: root
        visible: false
        z: 10
        color: "#221e1c"
        property string message: i18n.tr("Installing update…")

        Column {
            anchors.centerIn: parent
            spacing: units.gu(2)

            Image {
                source: Qt.resolvedUrl("file:///usr/share/ubuntu/settings/system/icons/distributor-logo.png")
                anchors.horizontalCenter: parent.horizontalCenter
                NumberAnimation on rotation {
                    from: 0
                    to: 360
                    running: installingImageUpdate.visible == true
                    loops: Animation.Infinite
                    duration: 2000
                }
            }

            ProgressBar {
                indeterminate: true
                anchors.horizontalCenter: parent.horizontalCenter
            }

            Label {
                text: installingImageUpdate.message
                anchors.horizontalCenter: parent.horizontalCenter
            }
        }
    }

    Column {
        id: configuration

        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        ListItem.ThinDivider {}
        ListItem.SingleValue {
            objectName: "configuration"
            text: i18n.tr("Auto download")
            value: {
                if (UpdateManager.downloadMode === 0)
                    return i18n.tr("Never")
                else if (UpdateManager.downloadMode === 1)
                    return i18n.tr("On wi-fi")
                else if (UpdateManager.downloadMode === 2)
                    return i18n.tr("Always")
            }
            progression: true
            onClicked: pageStack.push(Qt.resolvedUrl("Configuration.qml"))
        }
    }
}
