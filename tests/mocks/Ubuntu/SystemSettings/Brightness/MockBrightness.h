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

#ifndef MOCK_BRIGHTNESS_H
#define MOCK_BRIGHTNESS_H

#include "MockDisplayModel.h"

#include <QAbstractItemModel>
#include <QObject>
#include <QSortFilterProxyModel>

class MockBrightness : public QObject
{
    Q_OBJECT
    Q_PROPERTY( bool powerdRunning
                READ getPowerdRunning
                NOTIFY powerdRunningChanged)
    Q_PROPERTY (bool autoBrightnessAvailable
                READ getAutoBrightnessAvailable
                NOTIFY autoBrightnessAvailableChanged)
    Q_PROPERTY (bool widiSupported
                READ getWidiSupported
                NOTIFY widiSupportedChanged)
    Q_PROPERTY (QAbstractItemModel* allDisplays
                READ allDisplays
                CONSTANT)
    Q_PROPERTY (QAbstractItemModel* changedDisplays
                READ changedDisplays
                CONSTANT)

public:
    explicit MockBrightness(QObject *parent = 0);
    bool getPowerdRunning() const;
    bool getAutoBrightnessAvailable() const;
    bool getWidiSupported() const;
    Q_INVOKABLE void setPowerdRunning(const bool running);
    Q_INVOKABLE void setAutoBrightnessAvailable(const bool available);
    Q_INVOKABLE void setWidiSupported(const bool supported);
    QAbstractItemModel* allDisplays();
    QAbstractItemModel* changedDisplays();
    Q_INVOKABLE void applyDisplayConfiguration();
    Q_INVOKABLE MockDisplayModel* displayModel(); // mock only

Q_SIGNALS:
    void powerdRunningChanged(); // mock only
    void autoBrightnessAvailableChanged(); // mock only
    void widiSupportedChanged(); // mock only

private:
    bool m_powerdRunning = false;
    bool m_autoBrightnessAvailable = false;
    bool m_widiSupported = false;
    MockDisplayModel m_displays;
    DisplaysFilter m_changedDisplays;
};

#endif // MOCK_BRIGHTNESS_H
