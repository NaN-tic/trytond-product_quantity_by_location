# The COPYRIGHT file at the top level of this repository contains the full
# copyright notices and license terms.
from os import path
from trytond.model import ModelView, ModelSQL, fields
from trytond.wizard import Wizard, StateView, Button
from trytond.transaction import Transaction
from trytond.config import config, parse_uri
from trytond.pool import Pool


__all__ = ['ProductQuantityByLocationStart', 'ProductQuantityByLocation',
    'ProductQuantityByLocationValues']


class ProductQuantityByLocationValues(ModelView):
    'Product Quantity By Location Values'
    __name__ = 'product.quantity.by.location.values'
    location = fields.Many2One('stock.location', 'Location')
    product = fields.Many2One('product.product', 'Product')
    quantity = fields.Float('Quantity')

    @classmethod
    def set_values(cls, location, product, quantity):
        return {
            'product': product.id,
            'product.rec_name': product.rec_name,
            'location': location.id,
            'location.rec_name': location.rec_name,
            'quantity': quantity,
            }


class ProductQuantityByLocation(ModelView):
    'Product Quantity By Location'
    __name__ = 'product.quantity.by.location'
    prod_loc_tree = fields.One2Many('product.quantity.by.location.values',
        None, 'Product Location Tree', readonly=True)


class ProductQuantityByLocationStart(Wizard):
    'Gather Product By Location Start'
    __name__ = 'product.quantity.by.location.start'
    _table = 'product_quantity_by_location'
    start = StateView('product.quantity.by.location',
        'product_quantity_by_location.product_quantity_by_location_view_list', [
            Button('Close', 'end', 'tryton-cancel'),
            ])

    def default_start(self, fields):
        pool = Pool()
        Product = pool.get('product.product')
        Template = pool.get('product.template')
        Location = pool.get('stock.location')
        ProductLocation = pool.get('product.quantity.by.location.values')

        transaction = Transaction()
        product_ids = transaction.context.get('active_ids')
        active_model = transaction.context.get('active_model')
        if active_model == 'product.template':
            new_product_ids = []
            for template in product_ids:
                variants = Template(template).products
                new_product_ids += [variant.id for variant in variants]
            product_ids = new_product_ids

        cursor = transaction.connection.cursor()

        uri = parse_uri(config.get('database', 'uri'))
        class_ = self.__class__
        res = []

        if uri.scheme == 'postgresql':
            query = (path.dirname(path.realpath(__file__)) +
                '/%s.sql' % class_._table)
            query = open(query, 'r').read()
            cursor.execute('''
                SELECT *
                    FROM (%s) AS foo
                    WHERE foo.product in (%s)''' %
                (query, ','.join(map(str, product_ids))))
            for value in cursor.fetchall():
                id, _, _, _, _, location_id, product_id, quantity = value
                res.append(ProductLocation.set_values(Location(location_id),
                    Product(product_id), quantity))
        return {
            'prod_loc_tree': res
        }
