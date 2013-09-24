/*
 * This file is part of system-settings
 *
 * Copyright (C) 2013 Canonical Ltd.
 *
 * Contact: William Hua <william.hua@canonical.com>
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

#ifndef LANGUAGE_PLUGIN_H
#define LANGUAGE_PLUGIN_H

#include <QtCore>

class LanguagePlugin : public QObject
{
private:

    Q_OBJECT

    Q_PROPERTY(QStringList languages
               READ languages
               CONSTANT)

    Q_PROPERTY(QStringList languageCodes
               READ languageCodes
               CONSTANT)

    Q_PROPERTY(int currentLanguage
               READ currentLanguage
               WRITE setCurrentLanguage)

public:

    explicit LanguagePlugin(QObject *parent = NULL);

    const QStringList &languages() const;

    const QStringList &languageCodes() const;

    int currentLanguage() const;
    void setCurrentLanguage(int index);
};

#endif // LANGUAGE_PLUGIN_H
