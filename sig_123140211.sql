SELECT
    id,
    nama,
    ST_IsValid(geom)   AS valid,
    ST_IsSimple(geom)  AS simple,
    GeometryType(geom) AS tipe,
    ST_NumPoints(geom) AS jumlah_titik
FROM wilayah;

