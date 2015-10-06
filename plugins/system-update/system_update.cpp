/*
 * Copyright (C) 2013-2014 Canonical Ltd
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
 * Didier Roche <didier.roche@canonical.com>
 * Diego Sarmentero <diego.sarmentero@canonical.com>
 * Sergio Schvezov <sergio.schvezov@canonical.com>
 *
*/

#include "system_update.h"
#include <QEvent>
#include <QDateTime>
#include <QDBusReply>
#include <unistd.h>

// FIXME: need to do this better including #include "../../src/i18n.h"
// and linking to it
#include <libintl.h>
QString _(const char *text)
{
    return QString::fromUtf8(dgettext(0, text));
}

namespace UpdatePlugin {

SystemUpdate::SystemUpdate(QObject *parent) :
    QObject(parent),
    m_currentBuildNumber(-1),
    m_detailedVersion(),
    m_lastUpdateDate(),
    m_downloadMode(-1),
    m_systemBusConnection (QDBusConnection::systemBus()),
    m_SystemServiceIface ("com.canonical.SystemImage",
                         "/Service",
                         "com.canonical.SystemImage",
                         m_systemBusConnection)
{
    update = nullptr;

    qDBusRegisterMetaType<QMap<QString, QString> >();

    connect(&m_SystemServiceIface, SIGNAL(UpdateAvailableStatus(bool, bool, QString, int, QString, QString)),
               this, SLOT(ProcessAvailableStatus(bool, bool, QString, int, QString, QString)));
    // signals to forward directly to QML
    connect(&m_SystemServiceIface, SIGNAL(UpdateProgress(int, double)),
                this, SIGNAL(updateProgress(int, double)));
    connect(&m_SystemServiceIface, SIGNAL(UpdateProgress(int, double)),
                this, SLOT(updateDownloadProgress(int, double)));
    connect(&m_SystemServiceIface, SIGNAL(UpdatePaused(int)),
                this, SIGNAL(updatePaused(int)));
    connect(&m_SystemServiceIface, SIGNAL(UpdateDownloaded()),
                this, SIGNAL(updateDownloaded()));
    connect(&m_SystemServiceIface, SIGNAL(UpdateFailed(int, QString)),
                this, SIGNAL(updateFailed(int, QString)));
    connect(&m_SystemServiceIface, SIGNAL(SettingChanged(QString, QString)),
                this, SLOT(ProcessSettingChanged(QString, QString)));
    connect(&m_SystemServiceIface, SIGNAL(Rebooting(bool)),
                this, SIGNAL(rebooting(bool)));
}

SystemUpdate::~SystemUpdate() {
}

void SystemUpdate::checkForUpdate() {
    m_SystemServiceIface.asyncCall("CheckForUpdate");
}

void SystemUpdate::downloadUpdate() {
    m_SystemServiceIface.asyncCall("DownloadUpdate");
}

void SystemUpdate::applyUpdate() {
    QDBusReply<QString> reply = m_SystemServiceIface.call("ApplyUpdate");
    if (!reply.isValid())
        Q_EMIT updateProcessFailed(reply.value());
}

void SystemUpdate::cancelUpdate() {
    QDBusReply<QString> reply = m_SystemServiceIface.call("CancelUpdate");
    if (!reply.isValid())
        Q_EMIT updateProcessFailed(_("Can't cancel current request (can't contact service)"));
}

void SystemUpdate::pauseDownload() {
    QDBusReply<QString> reply = m_SystemServiceIface.call("PauseDownload");
    if (!reply.isValid())
        Q_EMIT updateProcessFailed(_("Can't pause current request (can't contact service)"));
}

void SystemUpdate::setCurrentDetailedVersion() {
    QDBusPendingReply<QMap<QString, QString> > reply = m_SystemServiceIface.call("Information");
    reply.waitForFinished();
    if (reply.isValid()) {
        QMap<QString, QString> result = reply.argumentAt<0>();
        m_currentBuildNumber = result["current_build_number"].toInt();
        m_deviceName = result["device_name"];
        m_lastUpdateDate = QDateTime::fromString(result["last_update_date"], Qt::ISODate);

        QMap<QString, QVariant> details;
        QString kvsep(",");
        QString eqsep("=");
        QStringList keyvalue = result["version_detail"].split(kvsep, QString::SkipEmptyParts);
        for (int i = 0; i < keyvalue.size(); ++i) {
            QStringList pair = keyvalue.at(i).split(eqsep);
            details[pair[0]] = QVariant(pair[1]);
        }
        m_detailedVersion = details;

        Q_EMIT versionChanged();
    } else {
        qWarning() << "Error when retrieving version information: " << reply.error();
    }
}

bool SystemUpdate::checkTarget() {
    int target = 0;
    int current = 0;
    QDBusPendingReply<QMap<QString, QString> > reply = m_SystemServiceIface.call("Information");
    reply.waitForFinished();
    if (reply.isValid()) {
        QMap<QString, QString> result = reply.argumentAt<0>();
        target = result.value("target_build_number", "0").toInt();
        current = result.value("current_build_number", "0").toInt();
    } else {
        qWarning() << "Error when retrieving version information: " << reply.error();
    }

    return target > current;
}

QString SystemUpdate::deviceName() {
        if (m_deviceName.isNull())
            setCurrentDetailedVersion();

        return m_deviceName;
}

QDateTime SystemUpdate::lastUpdateDate() {
    if (!m_lastUpdateDate.isValid())
        setCurrentDetailedVersion();

    return m_lastUpdateDate;
}

int SystemUpdate::currentBuildNumber() {
    if (m_currentBuildNumber == -1)
        setCurrentDetailedVersion();

    return m_currentBuildNumber;
}

QString SystemUpdate::currentUbuntuBuildNumber() {
    if (!m_detailedVersion.contains("ubuntu"))
        setCurrentDetailedVersion();
    QString val = m_detailedVersion.value("ubuntu").toString();
    return val.isEmpty() ? "Unavailable" : val;
}

QString SystemUpdate::currentDeviceBuildNumber() {
    if (!m_detailedVersion.contains("device"))
        setCurrentDetailedVersion();
    QString val = m_detailedVersion.value("device").toString();
    return val.isEmpty() ? "Unavailable" : val;
}

QString SystemUpdate::currentCustomBuildNumber() {
    if (!m_detailedVersion.contains("custom"))
        setCurrentDetailedVersion();
    QString val = m_detailedVersion.value("custom").toString();
    return val.isEmpty() ? "Unavailable" : val;
}

QMap<QString, QVariant> SystemUpdate::detailedVersionDetails() {
     if (m_detailedVersion.empty()) {
        setCurrentDetailedVersion();
     }

    return m_detailedVersion;
}

int SystemUpdate::downloadMode() {
    if (m_downloadMode != -1)
        return m_downloadMode;

    QDBusReply<QString> reply = m_SystemServiceIface.call("GetSetting", "auto_download");
    int default_mode = 1;
    if (reply.isValid()) {
        bool ok;
        int result;
        result = reply.value().toInt(&ok);
        if (ok)
            m_downloadMode = result;
        else
            m_downloadMode = default_mode;
    }
    else
        m_downloadMode = default_mode;
    return m_downloadMode;
}

void SystemUpdate::setDownloadMode(int value) {
    if (m_downloadMode == value)
        return;

    m_downloadMode = value;
    m_SystemServiceIface.asyncCall("SetSetting", "auto_download", QString::number(value));
}

void SystemUpdate::ProcessSettingChanged(QString key, QString newvalue) {
    if(key == "auto_download") {
        bool ok;
        int newintValue;
        newintValue = newvalue.toInt(&ok);
        if (ok) {
            m_downloadMode = newintValue;
            Q_EMIT downloadModeChanged();
        }
    }
}

void SystemUpdate::ProcessAvailableStatus(bool isAvailable,
                                          bool downloading,
                                          QString availableVersion,
                                          int updateSize,
                                          QString lastUpdateDate,
                                          QString errorReason)
{
    update = new Update(this);
    QString packageName(UBUNTU_PACKAGE_NAME);
    update->initializeApplication(packageName, "Ubuntu",
                                  QString::number(this->currentBuildNumber()));

    update->setSystemUpdate(true);
    update->setRemoteVersion(availableVersion);
    update->setBinaryFilesize(updateSize);
    update->setError(errorReason);
    update->setUpdateState(downloading);
    update->setSelected(downloading);
    update->setUpdateAvailable(isAvailable);
    update->setLastUpdateDate(lastUpdateDate);
    update->setIconUrl(QString("file:///usr/share/icons/suru/places/scalable/distributor-logo.svg"));

    if (update->updateRequired()) {
        Q_EMIT updateAvailable(packageName, update);
    } else {
        Q_EMIT updateNotFound();
    }

    if (downloading) {
        update->setSelected(true);
    }
}

void SystemUpdate::updateDownloadProgress(int percentage, double eta)
{
    Q_UNUSED(eta);
    if (update != nullptr) {
        update->setDownloadProgress(percentage);
    }
}

}
