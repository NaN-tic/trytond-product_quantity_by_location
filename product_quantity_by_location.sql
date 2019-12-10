SELECT
    CAST(a.location AS BIGINT) * 100000 + CAST(a.product AS BIGINT) AS id,
    0 AS create_uid,
    now()::TIMESTAMP WITHOUT TIME ZONE AS create_date,
    NULL::INTEGER AS write_uid,
    NULL::TIMESTAMP WITHOUT TIME ZONE AS write_date,
    a.location AS location,
    a.product AS product,
    SUM(a.quantity) AS quantity,
    SUM(a.quantity_estimed) AS quantity_estimed,
    SUM(a.quantity + a.quantity_assigned) AS quantity_available
FROM (
    SELECT
        to_location AS location,
        SUM(CASE WHEN state = 'done' THEN internal_quantity ELSE 0 END) AS quantity,
        SUM(internal_quantity) AS quantity_estimed,
        SUM(0) as quantity_assigned,
        product AS product
    FROM
        stock_move
    WHERE (
        state = 'done'
        AND COALESCE(effective_date, planned_date, '9999-12-31') > (SELECT date FROM stock_period WHERE state = 'closed' ORDER BY date DESC LIMIT 1)
        ) OR (
        state IN ('draft', 'assigned')
        AND COALESCE(effective_date, planned_date, '9999-12-31') <= now()::DATE
        )
    GROUP BY
        to_location,
        product
UNION ALL
SELECT
        from_location AS location,
        sum(-CASE WHEN state = 'done' THEN internal_quantity ELSE 0 END) AS quantity,
        (-SUM(internal_quantity)) AS quantity_estimed,
        sum(- CASE WHEN state != 'done' THEN internal_quantity ELSE 0 END) AS quantity_assigned,
        product AS product
    FROM
        stock_move
    WHERE (
        state = 'done'
        AND COALESCE(effective_date, planned_date, '9999-12-31') > (SELECT date FROM stock_period WHERE state = 'closed' ORDER BY date DESC LIMIT 1)
        ) OR (
        state IN ('draft', 'assigned')
        AND COALESCE(effective_date, planned_date, '9999-12-31') <= now()::DATE
        )
    GROUP BY
        from_location,
        product
UNION ALL
    SELECT
        e.location AS location,
        e.internal_quantity AS quantity,
        e.internal_quantity AS quantity_estimed,
        0 AS quantity_assigned,
        e.product AS product
    FROM
        stock_period_cache AS e
    WHERE
        e.period = (SELECT id FROM stock_period WHERE state = 'closed' ORDER BY date DESC LIMIT 1)
) AS a,
    stock_location sl
WHERE
    a.location = sl.id
    AND sl.type = 'storage'
GROUP BY
    a.location,
    a.product
HAVING
    SUM(a.quantity) <> 0 or
    SUM(a.quantity_estimed) <> 0
