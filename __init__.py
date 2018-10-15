# The COPYRIGHT file at the top level of this repository contains the full
# copyright notices and license terms.
from trytond.pool import Pool
from . import product


def register():
    Pool.register(
        product.ProductQuantityByLocationValues,
        product.ProductQuantityByLocation,
        module='product_quantity_by_location', type_='model')
    Pool.register(
        product.ProductQuantityByLocationStart,
        module='product_quantity_by_location', type_='wizard')
