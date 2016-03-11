/*
 * Copyright (C) 2016 Canonical Ltd
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
 * Ken VanDine <ken.vandine@canonical.com>
 *
*/

#include "cellular.h"
#include <QDebug>

#define AS_INTERFACE "com.ubuntu.touch.AccountsService.Phone"

Cellular::Cellular(QObject *parent) :
    QObject(parent)
{
    connect (&m_accountsService,
             SIGNAL (propertyChanged (QString, QString)),
             this,
             SLOT (slotChanged (QString, QString)));

    connect (&m_accountsService,
             SIGNAL (nameOwnerChanged()),
             this,
             SLOT (slotNameOwnerChanged()));
}

void Cellular::slotChanged(QString interface,
                                  QString property)
{
    if (interface != AS_INTERFACE)
        return;

    if (property == "DefaultSimForCalls") {
        Q_EMIT defaultSimForCallsChanged();
    } else if (property == "DefaultSimForMessages") {
        Q_EMIT defaultSimForMessagesChanged();
    } else if (property == "SimNames") {
        Q_EMIT simNamesChanged();
    }
}

void Cellular::slotNameOwnerChanged()
{
    // Tell QML so that it refreshes its view of the property
    Q_EMIT defaultSimForCallsChanged();
    Q_EMIT defaultSimForMessagesChanged();
    Q_EMIT simNamesChanged();
}

QString Cellular::getDefaultSimForCalls()
{
    return m_accountsService.getUserProperty(AS_INTERFACE,
                                             "DefaultSimForCalls").toString();
}

void Cellular::setDefaultSimForCalls(QString sim)
{
    if (sim == getDefaultSimForCalls())
        return;

    m_accountsService.setUserProperty(AS_INTERFACE,
                                      "DefaultSimForCalls",
                                      QVariant::fromValue(sim));
    Q_EMIT(defaultSimForCallsChanged());
}

QString Cellular::getDefaultSimForMessages()
{
    return m_accountsService.getUserProperty(AS_INTERFACE,
                                             "DefaultSimForMessages").toString();
}

void Cellular::setDefaultSimForMessages(QString sim)
{
    if (sim == getDefaultSimForMessages())
        return;

    m_accountsService.setUserProperty(AS_INTERFACE,
                                      "DefaultSimForMessages",
                                      QVariant::fromValue(sim));

    Q_EMIT(defaultSimForMessagesChanged());
}

QVariantMap Cellular::getSimNames()
{
    QVariantMap map = m_accountsService.getUserProperty(AS_INTERFACE,
                                                        "SimNames").toMap();
    for(QVariantMap::const_iterator iter = map.begin(); iter != map.end(); ++iter) {
        qWarning() << Q_FUNC_INFO << "Key: " << iter.key() << "Value: " << iter.value();
    }
    return map;
}

void Cellular::setSimNames(QVariantMap sims)
{
    QMap<QString, QString> map;
    for(QVariantMap::const_iterator iter = sims.begin(); iter != sims.end(); ++iter) {
        qWarning() << Q_FUNC_INFO << "Key: " << iter.key() << "Value: " << iter.value();
        map.insert(iter.key(), iter.value().toString());
    }
    m_accountsService.setUserProperty(AS_INTERFACE,
                                      "SimNames",
                                      QVariant::fromValue(map));

    Q_EMIT(simNamesChanged());
}
