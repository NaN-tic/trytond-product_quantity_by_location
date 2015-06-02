# The COPYRIGHT file at the top level of this repository contains the full
# copyright notices and license terms.
from os import path
from sql import Table
from trytond.model import ModelView, ModelSQL, fields
from trytond.transaction import Transaction


__all__ = ['ProductQuantityByLocation']


class ProductQuantityByLocation(ModelSQL, ModelView):
    'Product Quantity By Location'
    __name__ = 'product.quantity.by.location'
    _table = 'product_quantity_by_location'
    location = fields.Many2One('stock.location', 'Location')
    product = fields.Many2One('product.product', 'Product')
    quantity = fields.Float('Quantity')

    @classmethod
    def __register__(cls, module_name):
        transaction = Transaction()
        cursor = transaction.cursor
        super(ProductQuantityByLocation, cls).__register__(module_name)
        query = (path.dirname(path.realpath(__file__)) +
            '/%s.sql' % cls._table)
        query = open(query, 'r').read()
        cursor.execute(
            'CREATE OR REPLACE VIEW %s AS (%s)' % (cls._table, query))

    @classmethod
    def table_query(cls):
        table = Table(cls._table)
        query = table.select()
        return query
