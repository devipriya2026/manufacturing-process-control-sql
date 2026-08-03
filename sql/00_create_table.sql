/*
Manufacturing Process Control - table setup

Run this script in the database selected for the training project. It creates the
table only when the table does not already exist. Then import manufacturing_parts.csv
with the SQL Server Management Studio Import Flat File wizard.
*/

SET NOCOUNT ON;

IF OBJECT_ID(N'dbo.manufacturing_parts', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.manufacturing_parts
    (
        item_no  int           NOT NULL,
        [length] decimal(10, 2) NOT NULL,
        [width]  decimal(10, 2) NOT NULL,
        height   decimal(10, 2) NOT NULL,
        operator varchar(20)    NOT NULL,
        CONSTRAINT PK_manufacturing_parts PRIMARY KEY (item_no)
    );

    PRINT 'Created dbo.manufacturing_parts.';
END;
ELSE
BEGIN
    PRINT 'dbo.manufacturing_parts already exists. No table was replaced.';
END;

-- Run after importing the CSV.
SELECT
    COUNT(*) AS imported_row_count,
    COUNT(DISTINCT operator) AS operator_count,
    MIN(item_no) AS minimum_item_number,
    MAX(item_no) AS maximum_item_number
FROM dbo.manufacturing_parts;
