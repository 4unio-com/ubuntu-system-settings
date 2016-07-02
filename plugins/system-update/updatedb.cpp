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

#include "systemupdate.h"
#include "updatedb.h"
#include "updatemodel.h"

#include <QDir>
#include <QSqlError>
#include <QSqlQuery>
#include <QSqlRecord>
#include <QSqlField>
#include <QStandardPaths>

namespace UpdatePlugin
{
namespace {
const QString ALL = "kind, id, local_version, remote_version, revision, \
    installed, created_at_utc, updated_at_utc, title, download_hash, size, \
    icon_url, download_url, command, changelog, token, \
    update_state, progress, automatic, error";

const QString GET_SINGLE = "SELECT " + ALL + " FROM updates WHERE id=:id \
    AND revision=:revision";

const QString GET_SINGLE_DOWNLOAD = "SELECT " + ALL + " FROM updates \
    WHERE id=:id AND revision=:revision";

const QString GET_ALL = "SELECT " + ALL + " FROM updates";

const QString GET_ALL_KIND = "SELECT " + ALL + " FROM \
    updates WHERE kind=:kind ORDER BY title ASC";

const QString GET_PENDING = "SELECT " + ALL + ", MAX(revision) FROM \
    updates WHERE installed=0 GROUP BY id ORDER BY title ASC";

const QString GET_PENDING_KIND = "SELECT " + ALL + ", MAX(revision) FROM \
    updates WHERE installed=0 AND kind=:kind GROUP BY id ORDER BY title ASC";

const QString GET_INSTALLED = "SELECT " + ALL + " FROM updates \
    WHERE installed=1 ORDER BY updated_at_utc DESC";

const QString GET_INSTALLED_KIND = "SELECT " + ALL + " FROM updates \
    WHERE installed=1 AND kind=:kind ORDER BY updated_at_utc DESC";
}

UpdateDb::UpdateDb(QObject *parent)
    : QObject(parent)
    , m_dbpath("")
{
    QString dataPath = QStandardPaths::writableLocation(
        QStandardPaths::AppDataLocation);
    if (Q_UNLIKELY(!QDir().mkpath(dataPath))) {
        qCritical() << "Could not create" << dataPath;
        return;
    }
    m_dbpath = dataPath + QLatin1String("/updatestore.db");

    initializeDb();
}

UpdateDb::UpdateDb(const QString &dbpath, QObject *parent)
    : QObject(parent)
    , m_dbpath(dbpath)
{
    initializeDb();
}

QSqlDatabase UpdateDb::db()
{
    return m_db;
}

void UpdateDb::initializeDb()
{
    // Create a unique connection name
    int connI = 0;
    while (m_connectionName.isEmpty()) {
        QString tmpl("system-settings-update-%1");
        if (!QSqlDatabase::contains(tmpl.arg(connI)))
            m_connectionName = tmpl.arg(connI);
        connI++;
    }

    m_db = QSqlDatabase::addDatabase(QLatin1String("QSQLITE"), m_connectionName);
    m_db.setDatabaseName(m_dbpath);
    if (!openDb()) return;
    QSqlQuery q(m_db);

    // Check whether the table already exists
    q.exec("SELECT name FROM sqlite_master WHERE type='table' AND name='updates'");
    if (!q.next() && !createDb()) {
        qCritical() << "Could not create updates database:" << m_dbpath
            << m_db.lastError().text();
            return;
    }
}

UpdateDb::~UpdateDb()
{
    m_db.close();
    m_db = QSqlDatabase();
    QSqlDatabase::removeDatabase(m_connectionName);
}

void UpdateDb::add(const QSharedPointer<Update> &update)
{
    if (!openDb()) return;

    QSqlQuery q(m_db);
    q.prepare("INSERT OR REPLACE INTO updates (id, revision, installed,"
              "created_at_utc, download_hash, title, size, icon_url,"
              "download_url, changelog, command, token, progress, "
              "local_version, remote_version, kind, update_state, automatic) "
              "VALUES (:id, :revision, :installed, :created_at_utc, "
              ":download_hash, :title, :size, :icon_url, :download_url,"
              ":changelog, :command, :token, :progress, :local_version,"
              ":remote_version, :kind, :update_state, :automatic)");
    q.bindValue(":id", update->identifier());
    q.bindValue(":revision", update->revision());
    q.bindValue(":installed", update->installed());
    q.bindValue(":created_at_utc",
                QDateTime::currentDateTimeUtc().currentMSecsSinceEpoch());;
    q.bindValue(":download_hash", update->downloadHash());
    q.bindValue(":title", update->title());
    q.bindValue(":size", update->binaryFilesize());
    q.bindValue(":icon_url", update->iconUrl());
    q.bindValue(":download_url", update->downloadUrl());
    q.bindValue(":changelog", update->changelog());
    q.bindValue(":command", update->command().join(" "));
    q.bindValue(":token", update->token());
    q.bindValue(":progress", update->progress());
    q.bindValue(":local_version", update->localVersion());
    q.bindValue(":remote_version", update->remoteVersion());
    q.bindValue(":kind", Update::kindToString(update->kind()));
    q.bindValue(
        ":update_state",
        Update::stateToString(Update::State::StateAvailable)
    );
    q.bindValue(":automatic", update->automatic());

    if (!q.exec()) {
        qCritical() << "Could not add update" << q.lastError().text();
    }

    Q_EMIT changed();
}

void UpdateDb::remove(const QSharedPointer<Update> &update)
{
    if (!openDb()) return;

    QSqlQuery q(m_db);
    q.prepare("DELETE FROM updates WHERE id=:id AND revision=:revision");
    q.bindValue(":id", update->identifier());
    q.bindValue(":revision", update->revision());

    if (!q.exec()) {
        qCritical() << "Could not delete update" << q.lastError().text();
    }

    Q_EMIT changed();
}

void UpdateDb::update(const QSharedPointer<Update> &update, const QSqlQuery &query)
{
    update->setKind(Update::stringToKind(
        query.value("kind").toString()
    ));
    update->setIdentifier(query.value("id").toString());
    update->setLocalVersion(query.value("local_version").toString());
    update->setRemoteVersion(query.value("remote_version").toString());
    update->setRevision(query.value("revision").toUInt());
    update->setInstalled(query.value("installed").toBool());
    update->setCreatedAt(QDateTime::fromMSecsSinceEpoch(
        query.value("created_at_utc").toLongLong()
    ));
    update->setUpdatedAt(QDateTime::fromMSecsSinceEpoch(
        query.value("updated_at_utc").toLongLong()
    ));
    update->setTitle(query.value("title").toString());
    update->setDownloadHash(query.value("download_hash").toString());
    update->setBinaryFilesize(query.value("size").toUInt());
    update->setIconUrl(query.value("icon_url").toString());
    update->setDownloadUrl(query.value("download_url").toString());
    update->setCommand(query.value("command").toString().split(" "));
    update->setChangelog(query.value("changelog").toString());
    update->setToken(query.value("token").toString());
    update->setState(Update::stringToState(
        query.value("update_state").toString()
    ));
    update->setProgress(query.value("progress").toInt());
    update->setAutomatic(query.value("automatic").toBool());
    update->setError(query.value("error").toString());
}

void UpdateDb::setInstalled(const QString &id, const uint &revision)
{
    if (!openDb()) return;

    QSqlQuery q(m_db);
    q.prepare("UPDATE updates SET installed=:installed, update_state=:state, "
              "updated_at_utc=:updated_at_utc "
              "WHERE id=:id AND revision=:revision");
    q.bindValue(":installed", true);
    q.bindValue(":state", Update::stateToString(Update::State::StateInstallFinished));
    q.bindValue(":updated_at_utc",
                QDateTime::currentDateTimeUtc().currentMSecsSinceEpoch());
    q.bindValue(":id", id);
    q.bindValue(":revision", revision);

    if (!q.exec()) {
        qCritical() << "could not mark download" << id << revision
                    << "as installed" << q.lastError().text();
    }

    Q_EMIT changed();
}

void UpdateDb::setStarted(const QString &id, const uint &revision)
{
    setState(id, revision, Update::State::StateDownloading);
    changed(id, revision);
}

void UpdateDb::setQueued(const QString &id, const uint &revision)
{
    setState(id, revision, Update::State::StateQueuedForDownload);
    changed(id, revision);
}

void UpdateDb::setProcessing(const QString &id, const uint &revision)
{
    setState(id, revision, Update::State::StateInstalling);
    changed(id, revision);
}

void UpdateDb::setError(const QString &id, const uint &revision, const QString &msg)
{
    if (!openDb()) return;

    QSqlQuery q(m_db);
    q.prepare("UPDATE updates SET error=:error, update_state=:state "
              "WHERE id=:id AND revision=:revision");
    q.bindValue(":error", msg);
    q.bindValue(":state", Update::stateToString(Update::State::StateFailed));
    q.bindValue(":id", id);
    q.bindValue(":revision", revision);

    if (!q.exec()) {
        qCritical() << "could not set error on " << id << revision
                    << q.lastError().text();
    }

    changed(id, revision);
}

void UpdateDb::setDownloaded(const QString &id, const uint &revision)
{
    setState(id, revision, Update::State::StateDownloaded);
    changed(id, revision);
}

void UpdateDb::setState(const QString &id, const uint &revision,
                        const Update::State &state)
{
    if (!openDb()) return;

    QSqlQuery q(m_db);
    q.prepare("UPDATE updates SET update_state=:state"
              " WHERE id=:id AND revision=:revision");
    q.bindValue(":state", Update::stateToString(state));
    q.bindValue(":id", id);
    q.bindValue(":revision", revision);

    if (!q.exec()) {
        qCritical() << "could not change state on " << id << revision
                    << q.lastError().text();
    }
}

void UpdateDb::setProgress(const QString &id, const uint &revision,
                           const int &progress)
{
    if (!openDb()) return;

    QSqlQuery q(m_db);
    q.prepare("UPDATE updates SET progress=:progress, "
              "update_state=:state WHERE id=:id AND revision=:revision");
    q.bindValue(":progress", progress);
    q.bindValue(":state",
                Update::stateToString(Update::State::StateDownloading));
    q.bindValue(":id", id);
    q.bindValue(":revision", revision);

    if (!q.exec()) {
        qCritical() << "could not set progress on " << id << revision
                    << q.lastError().text();
    }

    changed(id, revision);
}

void UpdateDb::setPaused(const QString &id, const uint &revision)
{
    setState(id, revision, Update::State::StateDownloadPaused);
    changed(id, revision);
}

void UpdateDb::setResumed(const QString &id, const uint &revision)
{
    setState(id, revision, Update::State::StateDownloading);
    changed(id, revision);
}

void UpdateDb::setCanceled(const QString &id, const uint &revision)
{
    // FIXME: consolidate
    setState(id, revision, Update::State::StateAvailable);
    // unsetDownloadId(downloadId);
    changed(id, revision);
}

bool UpdateDb::createDb()
{
    if (Q_UNLIKELY(!m_db.transaction())) return false;

    QSqlQuery q(m_db);
    bool ok;
    ok = q.exec("CREATE TABLE meta(checked_at_utc BIGINT)");
    if (Q_UNLIKELY(!ok)) {
        m_db.rollback();
        return false;
    }

    ok = q.exec("CREATE TABLE updates ("
                "kind TEXT NOT NULL,"
                "id TEXT NOT NULL,"
                "local_version TEXT,"
                "remote_version TEXT,"
                "revision INTEGER NOT NULL,"
                "installed INTEGER NOT NULL,"
                "created_at_utc BIGINT NOT NULL,"
                "updated_at_utc BIGINT,"
                "title TEXT NOT NULL,"
                "download_hash TEXT,"
                "size INTEGER NOT NULL,"
                "icon_url TEXT NOT NULL,"
                "download_url TEXT,"
                "command TEXT,"
                "changelog TEXT,"
                "token TEXT,"
                "update_state TEXT DEFAULT 'unknown',"
                "progress INTEGER,"
                "automatic INTEGER DEFAULT 0,"
                "error TEXT,"
                "PRIMARY KEY (id, revision))");
    if (Q_UNLIKELY(!ok)) {
        m_db.rollback();
        return false;
    }

    return m_db.commit();
}

bool UpdateDb::openDb()
{
    if (m_db.isOpen()) return true;
    if (Q_UNLIKELY(!m_db.open())) {
        qCritical() << "Could not open updates database:" << m_db.lastError();
        return false;
    }
    return true;
}

void UpdateDb::pruneDb()
{
    if (!openDb()) return;

    QSqlQuery q(m_db);
    QDateTime monthAgo = QDateTime::currentDateTime().addMonths(-1).toUTC();
    q.prepare("DELETE FROM updates WHERE updated_at_utc < :updated");
    q.bindValue(":updated", monthAgo.toMSecsSinceEpoch());

    if (!q.exec()) {
        qCritical() << "could not prune db" << q.lastError().text();
    }
}

QDateTime UpdateDb::lastCheckDate()
{
    QDateTime d;
    if (!openDb()) return d;

    QSqlQuery q(m_db);
    q.exec("SELECT checked_at_utc FROM meta ORDER BY checked_at_utc DESC;");

    if (q.next()) {
        d = QDateTime::fromMSecsSinceEpoch(q.value(0).toLongLong());
    }

    return d.toUTC();
}

void UpdateDb::setLastCheckDate(const QDateTime &lastCheckUtc)
{
    if (!openDb()) return;

    QSqlQuery q(m_db);
    q.prepare("REPLACE INTO meta (checked_at_utc) VALUES (:checked_at_utc)");
    q.bindValue(":checked_at_utc", lastCheckUtc.toMSecsSinceEpoch());

    if (!q.exec()) {
        qCritical() << "could not update checked at value" << q.lastError().text();
    }
}

QList<QSharedPointer<Update> > UpdateDb::updates(const uint &filter)
{
    QList<QSharedPointer<Update> > list;

    UpdateModel::Filter eFilter = (UpdateModel::Filter) filter;

    if (!openDb()) {
        qWarning() << "could not open db";
        return list;
    }

    QSqlQuery q(m_db);
    switch (eFilter) {
    case UpdateModel::Filter::All:
        q.prepare(GET_ALL);
        break;
    case UpdateModel::Filter::Pending:
        q.prepare(GET_PENDING);
        break;
    case UpdateModel::Filter::PendingClicks:
        q.prepare(GET_PENDING_KIND);
        q.bindValue(":kind", Update::kindToString(
            Update::Kind::KindClick)
        );
        break;
    case UpdateModel::Filter::PendingImage:
        q.prepare(GET_PENDING_KIND);
        q.bindValue(":kind", Update::kindToString(
            Update::Kind::KindImage)
        );
        break;
    case UpdateModel::Filter::Installed:
        q.prepare(GET_INSTALLED);
        break;
    case UpdateModel::Filter::InstalledClicks:
        q.prepare(GET_INSTALLED_KIND);
        q.bindValue(":kind", Update::kindToString(
            Update::Kind::KindClick)
        );
        break;
    case UpdateModel::Filter::InstalledImage:
        q.prepare(GET_INSTALLED_KIND);
        q.bindValue(":kind", Update::kindToString(
            Update::Kind::KindImage)
        );
        break;
    }

    if (!q.exec()) {
        qCritical() << "could not create list of updates" << q.lastError().text() << q.executedQuery();
        return list;
    }

    while (q.next()) {
        QSharedPointer<Update> u = QSharedPointer<Update>(new Update);
        update(u, q);
        list.append(u);
    }

    return list;
}

QSharedPointer<Update> UpdateDb::get(const QString &id, const uint &revision)
{
    QSharedPointer<Update> u = QSharedPointer<Update>(new Update);
    if (!openDb()) return u;

    QSqlQuery q(m_db);
    q.prepare(GET_SINGLE_DOWNLOAD);
    q.bindValue(":id", id);
    q.bindValue(":revision", revision);

    if (!q.exec()) {
        qCritical() << "could not get update" << q.lastError().text();
    }

    if (q.next()) {
        update(u, q);
    }
    return u;
}
} // UpdatePlugin