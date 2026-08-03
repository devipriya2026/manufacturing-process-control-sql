/*
Manufacturing Process Control - Z-score review and rolling averages

A Z-score flag marks an observation for investigation. It does not prove that a
part is defective or that an operator caused a problem.
*/

SET NOCOUNT ON;

-- 1. Calculate overall Z-scores for height, length, and width.
WITH DimensionStatistics AS
(
    SELECT
        item_no,
        operator,
        [length],
        [width],
        height,
        AVG([length]) OVER () AS average_length,
        STDEV([length]) OVER () AS stdev_length,
        AVG([width]) OVER () AS average_width,
        STDEV([width]) OVER () AS stdev_width,
        AVG(height) OVER () AS average_height,
        STDEV(height) OVER () AS stdev_height
    FROM dbo.manufacturing_parts
),
ZScores AS
(
    SELECT
        item_no,
        operator,
        [length],
        [width],
        height,
        ([length] - average_length) / NULLIF(stdev_length, 0) AS length_zscore,
        ([width] - average_width) / NULLIF(stdev_width, 0) AS width_zscore,
        (height - average_height) / NULLIF(stdev_height, 0) AS height_zscore
    FROM DimensionStatistics
)
SELECT
    item_no,
    operator,
    [length],
    [width],
    height,
    length_zscore,
    width_zscore,
    height_zscore,
    CAST
    (
        CASE
            WHEN ABS(length_zscore) > 3
              OR ABS(width_zscore) > 3
              OR ABS(height_zscore) > 3
            THEN 1 ELSE 0
        END AS bit
    ) AS requires_outlier_review
FROM ZScores
ORDER BY requires_outlier_review DESC, operator, item_no;

-- 2. Calculate the current and previous two items' average length per operator.
SELECT
    item_no,
    operator,
    [length],
    COUNT(*) OVER
    (
        PARTITION BY operator
        ORDER BY item_no
        ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
    ) AS rolling_window_size,
    AVG([length]) OVER
    (
        PARTITION BY operator
        ORDER BY item_no
        ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
    ) AS rolling_three_item_average_length
FROM dbo.manufacturing_parts
ORDER BY operator, item_no;
