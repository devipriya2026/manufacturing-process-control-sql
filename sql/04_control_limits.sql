/*
Manufacturing Process Control - five-item rolling control limits

The assignment requires a five-row window per operator, including the current row.
Incomplete windows are excluded. The documented workbook formula scales three
standard deviations by the square root of the five-row window. SQL Server uses
bit values (1/0) for the alert.
*/

SET NOCOUNT ON;

WITH RollingStatistics AS
(
    SELECT
        item_no,
        operator,
        ROW_NUMBER() OVER
        (
            PARTITION BY operator
            ORDER BY item_no
        ) AS row_number,
        height,
        COUNT(*) OVER
        (
            PARTITION BY operator
            ORDER BY item_no
            ROWS BETWEEN 4 PRECEDING AND CURRENT ROW
        ) AS window_size,
        AVG(height) OVER
        (
            PARTITION BY operator
            ORDER BY item_no
            ROWS BETWEEN 4 PRECEDING AND CURRENT ROW
        ) AS avg_height,
        STDEV(height) OVER
        (
            PARTITION BY operator
            ORDER BY item_no
            ROWS BETWEEN 4 PRECEDING AND CURRENT ROW
        ) AS stddev_height
    FROM dbo.manufacturing_parts
),
ControlLimits AS
(
    SELECT
        item_no,
        operator,
        row_number,
        height,
        avg_height,
        stddev_height,
        avg_height + (3 * (stddev_height / SQRT(5.0))) AS ucl,
        avg_height - (3 * (stddev_height / SQRT(5.0))) AS lcl
    FROM RollingStatistics
    WHERE window_size = 5
)
SELECT
    operator,
    row_number,
    height,
    avg_height,
    stddev_height,
    ucl,
    lcl,
    CAST(CASE WHEN height > ucl OR height < lcl THEN 1 ELSE 0 END AS bit) AS alert
FROM ControlLimits
ORDER BY item_no;

-- Summary for validation. Re-run before quoting any count publicly.
WITH RollingStatistics AS
(
    SELECT
        item_no,
        operator,
        height,
        COUNT(*) OVER
        (
            PARTITION BY operator
            ORDER BY item_no
            ROWS BETWEEN 4 PRECEDING AND CURRENT ROW
        ) AS window_size,
        AVG(height) OVER
        (
            PARTITION BY operator
            ORDER BY item_no
            ROWS BETWEEN 4 PRECEDING AND CURRENT ROW
        ) AS avg_height,
        STDEV(height) OVER
        (
            PARTITION BY operator
            ORDER BY item_no
            ROWS BETWEEN 4 PRECEDING AND CURRENT ROW
        ) AS stddev_height
    FROM dbo.manufacturing_parts
),
ControlLimits AS
(
    SELECT
        item_no,
        operator,
        height,
        avg_height + (3 * (stddev_height / SQRT(5.0))) AS ucl,
        avg_height - (3 * (stddev_height / SQRT(5.0))) AS lcl
    FROM RollingStatistics
    WHERE window_size = 5
)
SELECT
    COALESCE(operator, 'ALL OPERATORS') AS operator,
    COUNT(*) AS complete_windows,
    SUM(CASE WHEN height > ucl OR height < lcl THEN 1 ELSE 0 END) AS alert_count
FROM ControlLimits
GROUP BY GROUPING SETS ((operator), ())
ORDER BY
    CASE WHEN operator IS NULL THEN 1 ELSE 0 END,
    operator;
