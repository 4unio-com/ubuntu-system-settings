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
#ifndef MOCK_CLICK_MANAGER_H
#define MOCK_CLICK_MANAGER_H

#include <QDateTime>
#include <QObject>

class MockClickManager : public QObject
{
    Q_OBJECT
    Q_PROPERTY(bool authenticated READ authenticated
               NOTIFY authenticatedChanged)
public:
    explicit MockClickManager(QObject *parent = 0);
    ~MockClickManager() {}

    Q_INVOKABLE void check();
    Q_INVOKABLE void check(const QString &packageName);
    Q_INVOKABLE void cancel();
    Q_INVOKABLE void clickUpdateInstalled(const QString &packageName, const int &revision);

    bool authenticated();

    Q_INVOKABLE void mockCheckStarted(); // mock only
    Q_INVOKABLE void mockCheckComplete(); // mock only
    Q_INVOKABLE void mockCheckCanceled(); // mock only
    Q_INVOKABLE void mockCheckFailed(); // mock only
    Q_INVOKABLE void mockAuthenticated(const bool authenticated); // mock only
    Q_INVOKABLE void mockNetworkError(); // mock only
    Q_INVOKABLE void mockServerError(); // mock only
    Q_INVOKABLE void mockCredentialError(); // mock only
    Q_INVOKABLE bool isChecking() const; // mock only

signals:
    void authenticatedChanged();

    void checkStarted();
    void checkCompleted();
    void checkCanceled();
    void checkFailed();

    void networkError();
    void serverError();
    void credentialError();

private:
    bool m_authenticated;
    bool m_checking;
};

#endif // MOCK_CLICK_MANAGER_H