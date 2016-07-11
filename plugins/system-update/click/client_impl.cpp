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

#include "client_impl.h"
#include "helpers.h"
#include "systemupdate.h"

#include <QJsonArray>
#include <QJsonDocument>
#include <QJsonObject>
#include <QJsonValue>

#define X_CLICK_TOKEN "X-Click-Token"

namespace UpdatePlugin
{
namespace Click
{
ClientImpl::ClientImpl(QObject *parent)
    : Client(parent)
    , m_nam(SystemUpdate::instance()->nam())
{
    initializeNam();
}

ClientImpl::ClientImpl(UpdatePlugin::Network::Manager *nam, QObject *parent)
    : Client(parent)
    , m_nam(nam)
{
    initializeNam();
}

ClientImpl::~ClientImpl()
{
    cancel();
}

void ClientImpl::initializeNam()
{
    qWarning() << "\t\t!!!!!!!!!init nam";
    connect(m_nam, SIGNAL(finished(QNetworkReply *)),
            this, SLOT(requestFinished(QNetworkReply *)));
    connect(m_nam, SIGNAL(sslErrors(QNetworkReply *, const QList<QSslError>&)),
            this, SLOT(requestSslFailed(QNetworkReply *, const QList<QSslError>&)));
}

void ClientImpl::requestMetadata(const QUrl &url,
                             const QList<QString> &packages)
{
    // Create list of frameworks.
    std::stringstream frameworks;
    for (auto f : Helpers::getAvailableFrameworks()) {
        frameworks << "," << f;
    }

    // Create JSON bytearray of packages.
    QJsonObject serializer;
    QJsonArray array;
    Q_FOREACH(const QString &name, packages) {
        array.append(QJsonValue(name));
    }
    serializer.insert("name", array);

    QJsonDocument doc(serializer);
    QByteArray content = doc.toJson();

    QNetworkRequest request;
    request.setHeader(QNetworkRequest::ContentTypeHeader, "application/json");
    request.setRawHeader(QByteArray("X-Ubuntu-Frameworks"),
            QByteArray::fromStdString(frameworks.str()));
    request.setRawHeader(QByteArray("X-Ubuntu-Architecture"),
            QByteArray::fromStdString(Helpers::getArchitecture()));
    request.setUrl(url);
    request.setOriginatingObject(this);
    request.setAttribute(QNetworkRequest::User, "metadata-request");

    initializeReply(m_nam->post(request, content));
}

void ClientImpl::requestToken(const QUrl &url)
{
    QNetworkRequest request;
    request.setUrl(url);
    request.setOriginatingObject(this);
    request.setAttribute(QNetworkRequest::User, "token-request");
    initializeReply(m_nam->head(request));
}

void ClientImpl::initializeReply(QNetworkReply *reply)
{
    connect(this, SIGNAL(abortNetworking()), reply, SLOT(abort()));
}

void ClientImpl::requestSslFailed(QNetworkReply *reply,
                                      const QList<QSslError> &errors)
{
    QString errorString = "SSL error: ";
    foreach (const QSslError &err, errors) {
        errorString += err.errorString();
    }
    qCritical() << Q_FUNC_INFO << errorString;
    Q_EMIT serverError();
    reply->deleteLater();
}

void ClientImpl::requestFinished(QNetworkReply *reply)
{

    qWarning() << "requestFinished...";

    if (reply->request().originatingObject() != this) {
        qWarning() << "requestFinished, not handling!";
        return; // We did not create this request.
    }
    qWarning() << "requestFinished, handling!";

    if (!validReply(reply)) {
        // Error signals are already sent.
        reply->deleteLater();
        return;
    }

    switch (reply->error()) {
    case QNetworkReply::NoError:
        requestSucceeded(reply);
        return;
    case QNetworkReply::TemporaryNetworkFailureError:
    case QNetworkReply::UnknownNetworkError:
    case QNetworkReply::UnknownProxyError:
    case QNetworkReply::UnknownServerError:
        Q_EMIT networkError();
        break;
    default:
        Q_EMIT serverError();
    }

    reply->deleteLater();
}

void ClientImpl::requestSucceeded(QNetworkReply *reply)
{
    QString rtp = reply->request().attribute(QNetworkRequest::User).toString();
    if (rtp == "token-request") {
        if (reply->hasRawHeader(X_CLICK_TOKEN)) {
            QString header(reply->rawHeader(X_CLICK_TOKEN));
            Q_EMIT tokenRequestSucceeded(header);
        } else {
            Q_EMIT tokenRequestSucceeded("");
        }
    } else if (rtp == "metadata-request") {
        Q_EMIT metadataRequestSucceeded(reply->readAll());
    } else {
        qWarning() << "not handled";
    }

    reply->deleteLater();
}

bool ClientImpl::validReply(const QNetworkReply *reply)
{
    auto statusAttr = reply->attribute(
            QNetworkRequest::HttpStatusCodeAttribute);
    if (!statusAttr.isValid()) {
        Q_EMIT networkError();
        qCritical() << Q_FUNC_INFO << "Could not parse status code.";
        return false;
    }

    int httpStatus = statusAttr.toInt();

    if (httpStatus == 401 || httpStatus == 403) {
        qCritical() << Q_FUNC_INFO << QString("Server responded with %1.").arg(httpStatus);
        Q_EMIT credentialError();
        return false;
    }

    if (httpStatus == 404) {
        qCritical() << Q_FUNC_INFO << "Server responded with 404.";
        Q_EMIT serverError();
        return false;
    }

    return true;
}

void ClientImpl::cancel()
{
    // Tell each reply to abort. See initializeReply().
    Q_EMIT abortNetworking();
}
} // Click
} // UpdatePlugin