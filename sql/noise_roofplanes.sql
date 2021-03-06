WITH
bounds AS (
	SELECT ST_Segmentize(ST_MakeEnvelope(_west, _south, _east, _north, 28992),_segmentlength) geom
)
,buildings AS (
	SELECT blockid,3 as height, (ST_DumpRings(a.geom)).geom
	--FROM noisemodel.planesz a, bounds b, noisemodel.demo_area c
	FROM tmp.tmp5 a, bounds b
	WHERE 1=1
	AND ST_Intersects(a.geom, b.geom)
	--AND ST_Contains(c.geom, a.geom)
	AND ST_GeometryType(a.geom) = 'ST_Polygon'
)


SELECT _south::text || _west::text || p.blockid AS id, 
'building' As type,
'building' As class,
'red' as color,
ST_AsX3D(geom) geom
FROM buildings p
WHERE geom Is Not Null
AND ST_GeometryType(geom) = 'ST_Polygon'

--GROUP BY p.gebwbagid;