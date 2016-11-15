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

#ifndef DISPLAY_PLUGIN_HELPERS_H
#define DISPLAY_PLUGIN_HELPERS_H

#include "display.h"

#include <mir_toolkit/mir_client_library.h>

namespace DisplayPlugin
{
struct Helpers
{
public:
    static Display::Orientation mirOrientationToOrientation(const MirOrientation &mirOrientation);
    static MirOrientation orientationToMirOrientation(const Display::Orientation &orientation);
    static QString mirTypeToString(const MirDisplayOutputType &type);
    static QString mirModeToString(const MirDisplayOutputType &type);
    static Display::PowerMode mirPowerModeToPowerMode(const MirPowerMode &mode);
    static MirPowerMode powerModeToMirPowerMode(const Display::PowerMode &mode);
};
} // DisplayPlugin

#endif // DISPLAY_PLUGIN_HELPERS_H
