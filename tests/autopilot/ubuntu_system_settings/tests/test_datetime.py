# -*- Mode: Python; coding: utf-8; indent-tabs-mode: nil; tab-width: 4 -*-
# Copyright 2013 Canonical
#
# This program is free software: you can redistribute it and/or modify it
# under the terms of the GNU General Public License version 3, as published
# by the Free Software Foundation.

import dbusmock
import subprocess
from time import sleep

from autopilot.matchers import Eventually
from testtools.matchers import Equals, NotEquals, GreaterThan

from ubuntu_system_settings.tests import UbuntuSystemSettingsTestCase
from ubuntu_system_settings.utils.i18n import ugettext as _

from ubuntuuitoolkit import emulators as toolkit_emulators


class TimeDateTestCase(UbuntuSystemSettingsTestCase,
                       dbusmock.DBusTestCase):
    """ Tests for the Time & Date Page """

    @classmethod
    def setUpClass(cls):
        cls.start_system_bus()
        cls.dbus_con = cls.get_dbus(True)
        (cls.p_mock, cls.obj_timedate1) = cls.spawn_server_template(
            'timedated', {}, stdout=subprocess.PIPE
        )

    @classmethod
    def tearDownClass(cls):
        super(TimeDateTestCase, cls).tearDownClass()
        cls.p_mock.terminate()
        cls.p_mock.wait()

    def setUp(self):
        """ Go to Time & Date page """
        self.obj_timedate1.Reset()
        super(TimeDateTestCase, self).setUp()
        self.page = self.main_view.go_to_datetime_page()

    @property
    def tz_page(self):
        return self.main_view.select_single(
            objectName='timeZone'
        )

    @staticmethod
    def wait_select_listview_first(listview):
        ntries = 0
        while True:
            try:
                return listview.select_many(toolkit_emulators.Standard)[0]
            except IndexError as e:
                if ntries < 10:
                    ntries += 1
                    sleep(1)
                else:
                    raise e

    def click_tz_search_field(self):
        self.main_view.pointing_device.click_object(self.tz_page)
        text_field = self.main_view.wait_select_single(
            objectName='selectTimeZoneField'
        )
        self.main_view.pointing_device.move_to_object(
            text_field)

    def test_time_date_page(self):
        """ Checks whether Time & Date page is available """
        self.assertThat(self.page, NotEquals(None))
        self.assertThat(self.page.title, Equals(_('Time & Date')))

    def test_tz_list_initially_empty(self):
        """ Checks that no list is displayed initially """
        self.main_view.scroll_to_and_click(self.tz_page)
        labelVisible = self.main_view.wait_select_single(
            objectName='nothingLabel').visible
        self.assertThat(labelVisible, Equals(True))

    def test_searching_tz(self):
        """ Check that searching for a valid location shows something """
        self.click_tz_search_field()
        self.keyboard.type('London, United Kingdom')
        listview = self.main_view.select_single(
            objectName='locationsListView'
        )
        self.assertThat(listview.count, Eventually(GreaterThan(0)))

    def test_searching_tz_not_found(self):
        """ Check that searching for an invalid location shows nothing """
        self.click_tz_search_field()
        self.keyboard.type('Oh no you don\'t!')
        listview = self.main_view.select_single(
            objectName='locationsListView'
        )
        self.assertThat(listview.count, Equals(0))
        labelVisible = self.main_view.select_single(
            objectName='nothingLabel').visible
        self.assertThat(labelVisible, Equals(True))

    def test_manual_tz_selection(self):
        """ Check that manually selecting a timezone sets it properly """
        self.click_tz_search_field()
        self.keyboard.type('London, United Kingdom')
        listview = self.main_view.select_single(
            objectName='locationsListView'
        )
        london = TimeDateTestCase.wait_select_listview_first(listview)
        self.main_view.pointing_device.click_object(london)
        header = self.main_view.select_single(
            objectName='MainView_Header'
        )
        self.assertThat(header.title, Eventually(Equals(_('Time & Date'))))
        self.assertThat(self.tz_page.text, Equals('Europe/London'))

    def test_same_tz_selection(self):
        """Check that manually setting a timezone then setting the same one
        doesn't take you back to the index.
        """
        self.test_manual_tz_selection()
        self.click_tz_search_field()
        # This is also in Europe/London
        self.keyboard.type('Preston, United Kingdom')
        listview = self.main_view.select_single(
            objectName='locationsListView'
        )

        preston = TimeDateTestCase.wait_select_listview_first(listview)
        self.main_view.pointing_device.click_object(preston)

        # The timer is 1 second, wait and see that we haven't moved pages
        sleep(2)
        header = self.main_view.select_single(
            objectName='MainView_Header'
        )
        self.assertThat(header.title, Eventually(Equals(_('Time zone'))))
