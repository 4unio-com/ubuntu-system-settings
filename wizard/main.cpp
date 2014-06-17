/*
 * This file is part of system-settings
 *
 * Copyright (C) 2014 Canonical Ltd.
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

#include <csignal>
#include <libintl.h>
#include <qpa/qplatformnativeinterface.h>
#include <ubuntu/application/ui/session.h>
#include <QDebug>
#include <QGuiApplication>
#include <QLibrary>
#include <QProcess>
#include <QQmlContext>
#include <QQmlEngine>
#include <QQuickView>
#include <QTimer>

#include "PageList.h"

void quitViaUpstart()
{
    QProcess::startDetached("initctl start ubuntu-system-settings-wizard-cleanup");
}

int startShell(int argc, const char** argv, void* server)
{
    const bool isUbuntuMirServer = qgetenv("QT_QPA_PLATFORM") == "ubuntumirserver";

    QGuiApplication::setApplicationName("System Settings Wizard");
    QGuiApplication *application;

    if (isUbuntuMirServer) {
        QLibrary unityMir("unity-mir", 1);
        unityMir.load();

        typedef QGuiApplication* (*createServerApplication_t)(int&, const char **, void*);
        createServerApplication_t createQMirServerApplication = (createServerApplication_t) unityMir.resolve("createQMirServerApplication");
        if (!createQMirServerApplication) {
            qDebug() << "unable to resolve symbol: createQMirServerApplication";
            return 4;
        }

        application = createQMirServerApplication(argc, argv, server);
    } else {
        application = new QGuiApplication(argc, (char**)argv);
    }

    bindtextdomain(I18N_DOMAIN, NULL);
    textdomain(I18N_DOMAIN);

    QQuickView* view = new QQuickView();
    view->setResizeMode(QQuickView::SizeRootObjectToView);
    view->setTitle("Qml Phone Shell"); // Fake to be the shell

    QPlatformNativeInterface* nativeInterface = QGuiApplication::platformNativeInterface();
    nativeInterface->setProperty("session", U_SYSTEM_SESSION); // receive all input events

    QString rootDir = qgetenv("UBUNTU_SYSTEM_SETTINGS_WIZARD_ROOT"); // for testing
    if (rootDir.isEmpty())
        rootDir = WIZARD_ROOT;

    if (!isUbuntuMirServer) {
        view->engine()->addImportPath(PLUGIN_PRIVATE_MODULE_DIR "/Ubuntu/SystemSettings/Wizard/NonMir");
    }
    view->engine()->addImportPath(PLUGIN_PRIVATE_MODULE_DIR);
    view->engine()->addImportPath(PLUGIN_QML_DIR);
    view->engine()->addImportPath(SHELL_PLUGINDIR);

    PageList pageList;
    view->rootContext()->setContextProperty("pageList", &pageList);
    view->setSource(QUrl(rootDir + "/qml/main.qml"));
    view->setColor("transparent");

    QObject::connect(view->engine(), &QQmlEngine::quit, quitViaUpstart);

    if (isUbuntuMirServer) {
        view->showFullScreen();
    } else {
        view->show();
    }

    int result = application->exec();

    delete view;
    delete application;
    return result;
}

int main(int argc, const char *argv[])
{
    /* Workaround Qt platform integration plugin not advertising itself
       as having the following capabilities:
        - QPlatformIntegration::ThreadedOpenGL
        - QPlatformIntegration::BufferQueueingOpenGL
    */
    setenv("QML_FORCE_THREADED_RENDERER", "1", 1);
    setenv("QML_FIXED_ANIMATION_STEP", "1", 1);

    // For ubuntumirserver/ubuntumirclient
    if (qgetenv("QT_QPA_PLATFORM").startsWith("ubuntumir")) {
        setenv("QT_QPA_PLATFORM", "ubuntumirserver", 1);

        // If we use unity-mir directly, we automatically link to the Mir-server
        // platform-api bindings, which result in unexpected behaviour when
        // running the non-Mir scenario.
        QLibrary unityMir("unity-mir", 1);
        unityMir.load();
        if (!unityMir.isLoaded()) {
            qDebug() << "Library unity-mir not found/loaded";
            return 1;
        }

        class QMirServer;
        typedef QMirServer* (*createServer_t)(int, const char **);
        createServer_t createQMirServer = (createServer_t) unityMir.resolve("createQMirServer");
        if (!createQMirServer) {
            qDebug() << "unable to resolve symbol: createQMirServer";
            return 2;
        }

        QMirServer* mirServer = createQMirServer(argc, argv);

        typedef int (*runWithClient_t)(QMirServer*, std::function<int(int, const char**, void*)>);
        runWithClient_t runWithClient = (runWithClient_t) unityMir.resolve("runQMirServerWithClient");
        if (!runWithClient) {
            qDebug() << "unable to resolve symbol: runWithClient";
            return 3;
        }

        return runWithClient(mirServer, startShell);
    } else {
        if (qgetenv("UPSTART_JOB") == "unity8") {
            // Emit SIGSTOP as expected by upstart, under Mir it's unity-mir that will raise it.
            // see http://upstart.ubuntu.com/cookbook/#expect-stop
            raise(SIGSTOP);
        }
        return startShell(argc, argv, nullptr);
    }
}
