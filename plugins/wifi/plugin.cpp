/*
 * Copyright (C) 2013 Canonical Ltd
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
*/

#include "plugin.h"

#include <QtQml>
#include <QtQml/QQmlContext>
#include "unitymenumodelstack.h"
#include "wifidbushelper.h"
#include "previousnetworkmodel.h"
#include "certhandler.h"
#include "aethercast_helper.h"
#include "displays.h"
#include "device.h"

namespace {

WifiDbusHelper *s = nullptr;

QObject* dbusProvider(QQmlEngine* engine, QJSEngine* /* scriptEngine */)
{
    // Why are we not using static WifiDbusHelper here, you ask?
    // Because I'm not sure if the Qml engine tries to delete the
    // pointer we return when it is shuts down.
    if(!s)
        s = new WifiDbusHelper(engine);
    return s;
}

}

void BackendPlugin::registerTypes(const char *uri)
{
    Q_ASSERT(uri == QLatin1String("Ubuntu.SystemSettings.Wifi"));

    // Register additional QtDBus types we need
    qDBusRegisterMetaType<InterfaceList>();
    qDBusRegisterMetaType<ManagedObjectList>();

    qmlRegisterType<UnityMenuModelStack>(uri, 1, 0, "UnityMenuModelStack");
    qmlRegisterSingletonType<WifiDbusHelper>(uri, 1, 0, "DbusHelper", dbusProvider);
    qmlRegisterType<PreviousNetworkModel>(uri, 1, 0, "PreviousNetworkModel");
    qmlRegisterType<CertificateListModel>(uri, 1, 0, "CertificateListModel");
    qmlRegisterType<PrivatekeyListModel>(uri, 1, 0, "PrivatekeyListModel");
    qmlRegisterType<PacFileListModel>(uri, 1, 0, "PacFileListModel");
    qmlRegisterType<FileHandler>(uri, 1, 0, "FileHandler");
    qmlRegisterType<Device>(uri, 1, 0, "Device");
    qmlRegisterType<Displays>(uri, 1, 0, "Displays");
}

void BackendPlugin::initializeEngine(QQmlEngine *engine, const char *uri)
{
    QQmlExtensionPlugin::initializeEngine(engine, uri);
}
