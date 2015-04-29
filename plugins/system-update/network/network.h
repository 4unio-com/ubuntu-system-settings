/*
 * Copyright 2013 Canonical Ltd.
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of version 3 of the GNU Lesser General Public
 * License as published by the Free Software Foundation.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with this library; if not, write to the
 * Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
 * Boston, MA 02110-1301, USA.
 */

#ifndef NETWORK_H
#define NETWORK_H

#include <QObject>
#include <QtNetwork/QNetworkAccessManager>
#include <QtNetwork/QNetworkReply>
#include <QHash>
#include "../update.h"

#define X_CLICK_TOKEN "X-Click-Token"

namespace UpdatePlugin {

class RequestObject : public QObject
{
    Q_OBJECT
public:
    explicit RequestObject(QString oper, QObject *parent = 0) :
        QObject(parent)
    {
        operation = oper;
    }

    QString operation;
};

class Network : public QObject
{
    Q_OBJECT
public:
    explicit Network(QObject *parent = 0);

    void checkForNewVersions(QHash<QString, Update*> &apps);
    void getClickToken(Update *app, const QString &url,
                       const QString &authHeader);
    constexpr static const char* FRAMEWORKS_FOLDER {"/usr/share/click/frameworks/"};
    constexpr static const char* FRAMEWORKS_PATTERN {"*.framework"};
    constexpr static const int FRAMEWORKS_EXTENSION_LENGTH = 10; // strlen(".framework")

Q_SIGNALS:
    void updatesFound();
    void updatesNotFound();
    void errorOccurred();
    void networkError();
    void serverError();
    void clickTokenObtained(Update *app, const QString &clickToken);

private Q_SLOTS:
    void onReply(QNetworkReply*);

private:
    QNetworkAccessManager m_nam;
    QHash<QString, Update*> m_apps;

    QString getUrlApps();

protected:
    virtual std::vector<std::string> get_available_frameworks();
    virtual std::string get_architecture();
    virtual std::string architectureFromDpkg();
    virtual std::vector<std::string> list_folder(const std::string &folder, const std::string &pattern);

};

}

#endif // NETWORK_H
