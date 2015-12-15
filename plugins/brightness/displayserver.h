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

#ifndef DISPLAYSERVER_H
#define DISPLAYSERVER_H

#include <mir_toolkit/mir_client_library.h>

typedef struct DisplayServerConnection
{
    MirConnection *connection;
} DisplayServerConnection;


DisplayServerConnection get_display_server_connection();

MirConnection *get_mir_display_server_connection();

#endif // DISPLAYSERVER_H
