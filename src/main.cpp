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

#include "debug.h"
#include "i18n.h"
#include "plugin-manager.h"
#include "utils.h"

#include <QByteArray>
#include <QGuiApplication>
#include <QProcessEnvironment>
#include <QQmlContext>
#include <QUrl>
#include <QQuickView>
#include <QtGlobal>
#include <QtQml>
#include <QtQml/QQmlDebuggingEnabler>
static QQmlDebuggingEnabler debuggingEnabler(false);

using namespace SystemSettings;

int main(int argc, char **argv)
{
    QGuiApplication app(argc, argv);
    QByteArray mountPoint = qEnvironmentVariableIsSet("SNAP") ? qgetenv("SNAP") : "";

    /* The testability driver is only loaded by QApplication but not by
     * QGuiApplication.  However, QApplication depends on QWidget which would
     * add some unneeded overhead => Let's load the testability driver on our
     * own.
     */
    if (app.arguments().contains(QStringLiteral("-testability"))) {
        QLibrary testLib(QStringLiteral("qttestability"));
        if (testLib.load()) {
            typedef void (*TasInitialize)(void);
            TasInitialize initFunction =
                (TasInitialize)testLib.resolve("qt_testability_init");
            if (initFunction) {
                initFunction();
            } else {
                qCritical("Library qttestability resolve failed!");
            }
        } else {
            qCritical("Library qttestability load failed!");
        }
    }

    /* read environment variables */
    QProcessEnvironment environment = QProcessEnvironment::systemEnvironment();
    if (environment.contains(QLatin1String("SS_LOGGING_LEVEL"))) {
        bool isOk;
        int value = environment.value(
            QLatin1String("SS_LOGGING_LEVEL")).toInt(&isOk);
        if (isOk)
            setLoggingLevel(value);
    }

    initTr(I18N_DOMAIN, nullptr);
    /* HACK: force the theme until lp #1098578 is fixed */
    QIcon::setThemeName("suru");

    /* Parse the commandline options to see if we've been given a panel to load,
     * and other options for the panel.
     */
    QString defaultPlugin;
    QVariantMap pluginOptions;
    parsePluginOptions(app.arguments(), defaultPlugin, pluginOptions);

    QQuickView view;
    Utilities utils;
    QObject::connect(view.engine(), SIGNAL(quit()), &app, SLOT(quit()),
                     Qt::QueuedConnection);
    qmlRegisterType<QAbstractItemModel>();
    qmlRegisterType<SystemSettings::PluginManager>("SystemSettings", 1, 0, "PluginManager");
    view.engine()->rootContext()->setContextProperty("Utilities", &utils);
    view.setResizeMode(QQuickView::SizeRootObjectToView);
    view.engine()->addImportPath(
        QByteArray(mountPoint).append(PLUGIN_PRIVATE_MODULE_DIR)
    );
    view.engine()->addImportPath(
        QByteArray(mountPoint).append(PLUGIN_QML_DIR)
    );
    view.rootContext()->setContextProperty("defaultPlugin", defaultPlugin);
    view.rootContext()->setContextProperty(
        "i18nDirectory", QByteArray(mountPoint).append(I18N_DIRECTORY)
    );
    view.rootContext()->setContextProperty("pluginOptions", pluginOptions);
    view.rootContext()->setContextProperty("view", &view);
    view.setSource(QUrl("qrc:/qml/MainWindow.qml"));
    view.show();

    return app.exec();
}
