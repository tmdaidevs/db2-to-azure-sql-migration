CREATE OR ALTER FUNCTION SAMPLE.FN_FORMAT_TIMESTAMP
(
    @TS datetime2(6),
    @FMT varchar(20)
)
RETURNS varchar(50)
AS
BEGIN
    RETURN CASE UPPER(@FMT)
        WHEN 'YYYYMMDD' THEN CONVERT(char(8), @TS, 112)
        ELSE 'date format not recognized.'
    END;
END;

