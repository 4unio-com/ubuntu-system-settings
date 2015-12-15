/*
 * Copyright (C) 2015 Canonical Ltd
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

#ifndef DISPLAYS_H
#define DISPLAYS_H

#include <QObject>
#include <QDebug>
#include <mir_toolkit/mir_client_library.h>

#include "displaymodel.h"

class Displays : public QObject
{
    Q_OBJECT

public:
    explicit Displays(QObject *parent = 0);
    ~Displays();
    QAbstractItemModel * displays();

private:
    bool makeDisplayServerConnection();
    void updateAvailableDisplays();
    DisplayListModel m_displaysModel;
    MirConnection *m_mir_connection;
};

#endif // DISPLAYS_H
