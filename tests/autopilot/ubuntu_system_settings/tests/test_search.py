# -*- Mode: Python; coding: utf-8; indent-tabs-mode: nil; tab-width: 4 -*-
# Copyright 2013 Canonical
#
# This program is free software: you can redistribute it and/or modify it
# under the terms of the GNU General Public License version 3, as published
# by the Free Software Foundation.

from testtools.matchers import Equals
from autopilot.matchers import Eventually

from ubuntu_system_settings.tests import UbuntuSystemSettingsTestCase
from ubuntu_system_settings.utils.i18n import ugettext as _


""" Tests for Ubuntu System Settings """


class SearchTestCases(UbuntuSystemSettingsTestCase):
    """ Tests for Search """

    def setUp(self):
        super(SearchTestCases, self).setUp()

    def _get_entry_component(self, name):
        return self.main_view.wait_select_single(
            objectName='entryComponent-' + name
        )

    def _get_all_entry_components(self):
        return self.main_view.select_many(
            'EntryComponent')

    def _type_into_search_box(self, text):
        search_box = self.main_view.select_single(
            objectName='searchTextField'
        )
        self.main_view.scroll_to_and_click(search_box)
        self.keyboard.type(_(text))
        self.assertThat(search_box.text, Eventually(Equals(text)))

    def test_search_filter_results(self):
        """ Checks whether Search box actually filters the results """
        self._type_into_search_box('WiFi')
        wifi_icon = self._get_entry_component('wifi')

        self.assertThat(wifi_icon.visible, Eventually(Equals(True)))
        self.assertThat(
            lambda: len(self._get_all_entry_components()),
            Eventually(Equals(1)))

    def test_search_filter_no_matches(self):
        """ Checks that no results are returned if nothing matches """
        self._type_into_search_box('foobar')
        self.assertEquals(len(self._get_all_entry_components()), 0)
