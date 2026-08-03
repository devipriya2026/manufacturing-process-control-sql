/*
Manufacturing Process Control - volume and ranking analysis
*/

SET NOCOUNT ON;

-- 1. Calculate part volume and rank every item within its operator.
WITH PartVolume AS
(
    SELECT
        item_no,
        operator,
        [length],
        [width],
        height,
        CAST([length] * [width] * height AS decimal(18, 2)) AS volume
    FROM dbo.manufacturing_parts
),
RankedParts AS
(
    SELECT
        item_no,
        operator,
        [length],
        [width],
        height,
        volume,
        DENSE_RANK() OVER
        (
            PARTITION BY operator
            ORDER BY volume DESC
        ) AS volume_rank_within_operator
    FROM PartVolume
)
SELECT
    item_no,
    operator,
    [length],
    [width],
    height,
    volume,
    volume_rank_within_operator
FROM RankedParts
ORDER BY operator, volume_rank_within_operator, item_no;

-- 2. Return the three largest items by volume for each operator.
WITH PartVolume AS
(
    SELECT
        item_no,
        operator,
        CAST([length] * [width] * height AS decimal(18, 2)) AS volume
    FROM dbo.manufacturing_parts
),
RankedParts AS
(
    SELECT
        item_no,
        operator,
        volume,
        ROW_NUMBER() OVER
        (
            PARTITION BY operator
            ORDER BY volume DESC, item_no
        ) AS row_number_within_operator
    FROM PartVolume
)
SELECT
    item_no,
    operator,
    volume,
    row_number_within_operator
FROM RankedParts
WHERE row_number_within_operator <= 3
ORDER BY operator, row_number_within_operator;

-- 3. Find operators whose average part volume is above the overall average.
WITH PartVolume AS
(
    SELECT
        operator,
        CAST([length] * [width] * height AS decimal(18, 2)) AS volume
    FROM dbo.manufacturing_parts
),
OperatorAverages AS
(
    SELECT
        operator,
        AVG(volume) AS operator_average_volume
    FROM PartVolume
    GROUP BY operator
),
OverallAverage AS
(
    SELECT AVG(volume) AS overall_average_volume
    FROM PartVolume
)
SELECT
    oa.operator,
    oa.operator_average_volume,
    overall.overall_average_volume,
    oa.operator_average_volume - overall.overall_average_volume AS difference_from_overall
FROM OperatorAverages AS oa
CROSS JOIN OverallAverage AS overall
WHERE oa.operator_average_volume > overall.overall_average_volume
ORDER BY oa.operator_average_volume DESC;
