SELECT
    a.location * 100000 + a.product AS id,
    0 AS create_uid,
    (SELECT CURRENT_DATE)::TIMESTAMP WITHOUT TIME ZONE AS create_date,
    NULL::INTEGER AS write_uid,
    NULL::TIMESTAMP WITHOUT TIME ZONE AS write_date,
    a.location AS location,
    a.product AS product,
    SUM(a.quantity) AS quantity,
    SUM(a.quantity_estimed) AS quantity_estimed,
    SUM(a.quantity + a.quantity_assigned) AS quantity_available
FROM (
    SELECT
        b.to_location AS location,
        SUM(CASE WHEN b.state = 'done' THEN b.internal_quantity ELSE 0 END) AS quantity,
        SUM(b.internal_quantity) AS quantity_estimed,
        SUM(0) as quantity_assigned,
        b.product AS product
    FROM
            stock_move AS b
        LEFT JOIN
            stock_location AS c ON b.to_location = c.id
    WHERE
        c.type NOT IN ('supplier', 'customer')  AND
	      (((COALESCE(b.effective_date, b.planned_date, '9999-12-31') > (SELECT date FROM stock_period WHERE state = 'closed' ORDER BY date DESC LIMIT 1)) AND
	      (b.state ='done') ) OR
	       ((b.state in ('draft','assigned')) AND (
	          (b.effective_date IS NULL  AND COALESCE(b.planned_date, '9999-12-31') <= (SELECT CURRENT_DATE)) OR
		          (b.effective_date <= (SELECT CURRENT_DATE)) )))
      GROUP BY
        b.to_location,
        b.product
UNION ALL
SELECT
        b.from_location AS location,
        sum(-CASE WHEN b.state = 'done' THEN b.internal_quantity ELSE 0 END) AS quantity,
        (-SUM(b.internal_quantity)) AS quantity_estimed,
        sum(- CASE WHEN b.state != 'done' THEN quantity ELSE 0 END) AS quantity_assigned,
        b.product AS product
    FROM
            stock_move AS b
        LEFT JOIN
            stock_location AS c ON b.to_location = c.id
    WHERE
        c.type NOT IN ('supplier', 'customer')  AND
	      (((COALESCE(b.effective_date, b.planned_date, '9999-12-31') > (SELECT date FROM stock_period WHERE state = 'closed' ORDER BY date DESC LIMIT 1)) AND
	       (b.state ='done') ) OR
	        ((b.state in ('draft','assigned')) AND (
	           (b.effective_date IS NULL  AND COALESCE(b.planned_date, '9999-12-31') <= (SELECT CURRENT_DATE)) OR
		           (b.effective_date <= (SELECT CURRENT_DATE)) )))
    GROUP BY
        b.from_location,
        b.product
UNION ALL
    SELECT
        e.location AS location,
        e.internal_quantity AS quantity,
        e.internal_quantity AS quantity_estimed,
        0 AS quantity_assigned,
        e.product AS product
    FROM
            stock_period_cache AS e
        LEFT JOIN
            stock_location AS c ON e.location = c.id
    WHERE
        ((e.period = ( -- Id of last closed period
          SELECT id FROM stock_period WHERE state = 'closed' ORDER BY date DESC LIMIT 1 ) )
          AND c.type IN ('storage'))
    ) AS a
GROUP BY
    a.location,
    a.product
HAVING
    SUM(a.quantity) <> 0
