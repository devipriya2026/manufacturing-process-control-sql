/*
Manufacturing Process Control - operator statistics and size categories
*/

SET NOCOUNT ON;

-- 1. Compare every item's dimensions with its operator's averages.
SELECT
    item_no,
    operator,
    [length],
    AVG([length]) OVER (PARTITION BY operator) AS operator_average_length,
    [length] - AVG([length]) OVER (PARTITION BY operator) AS length_deviation,
    [width],
    AVG([width]) OVER (PARTITION BY operator) AS operator_average_width,
    [width] - AVG([width]) OVER (PARTITION BY operator) AS width_deviation,
    height,
    AVG(height) OVER (PARTITION BY operator) AS operator_average_height,
    height - AVG(height) OVER (PARTITION BY operator) AS height_deviation
FROM dbo.manufacturing_parts
ORDER BY operator, item_no;

-- 2. Calculate each operator's percentage contribution to total volume.
WITH PartVolume AS
(
    SELECT
        operator,
        CAST([length] * [width] * height AS decimal(18, 2)) AS volume
    FROM dbo.manufacturing_parts
),
OperatorVolume AS
(
    SELECT
        operator,
        SUM(volume) AS operator_total_volume
    FROM PartVolume
    GROUP BY operator
)
SELECT
    operator,
    operator_total_volume,
    CAST
    (
        100.0 * operator_total_volume
        / NULLIF(SUM(operator_total_volume) OVER (), 0)
        AS decimal(8, 4)
    ) AS percentage_of_total_volume
FROM OperatorVolume
ORDER BY operator_total_volume DESC;

-- 3. Count items in the size categories used by the training project.
WITH CategorizedParts AS
(
    SELECT
        item_no,
        CAST([length] * [width] * height AS decimal(18, 2)) AS volume,
        CASE
            WHEN [length] * [width] * height < 100000 THEN 'small'
            WHEN [length] * [width] * height < 125000 THEN 'medium'
            ELSE 'large'
        END AS size_category
    FROM dbo.manufacturing_parts
)
SELECT
    size_category,
    COUNT(*) AS item_count,
    MIN(volume) AS minimum_volume,
    MAX(volume) AS maximum_volume
FROM CategorizedParts
GROUP BY size_category
ORDER BY
    CASE size_category
        WHEN 'small' THEN 1
        WHEN 'medium' THEN 2
        ELSE 3
    END;
