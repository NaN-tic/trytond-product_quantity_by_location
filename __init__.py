# The COPYRIGHT file at the top level of this repository contains the full
# copyright notices and license terms.
from trytond.pool import Pool
from .product_quantity_by_location import *


def register():
    Pool.register(
        ProductQuantityByLocation,
        module='product_quantity_by_location', type_='model')
