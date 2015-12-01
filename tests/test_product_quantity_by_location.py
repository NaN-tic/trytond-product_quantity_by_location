# This file is part of the product_quantity_by_location module for Tryton.
# The COPYRIGHT file at the top level of this repository contains the full
# copyright notices and license terms.
import unittest
import trytond.tests.test_tryton
from trytond.tests.test_tryton import ModuleTestCase


class ProductQuantityByLocationTestCase(ModuleTestCase):
    'Test Product Quantity By Location module'
    module = 'product_quantity_by_location'


def suite():
    suite = trytond.tests.test_tryton.suite()
    suite.addTests(unittest.TestLoader().loadTestsFromTestCase(
        ProductQuantityByLocationTestCase))
    return suite