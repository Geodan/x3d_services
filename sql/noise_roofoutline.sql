WITH
bounds AS (
	SELECT ST_Segmentize(ST_MakeEnvelope(_west, _south, _east, _north, 28992),_segmentlength) geom
)
,buildings AS (
	SELECT blockid as gebwbagid, a.geom
	FROM noisemodel.planeintersections a,
	bounds b
	WHERE ST_Intersects(ST_Force2D(a.geom), b.geom)
)


SELECT _south::text || _west::text || p.gebwbagid AS id, 
'building' As type,
'building' As class,
'red' as color,
ST_AsX3D(ST_Collect(geom)) geom
FROM buildings p
WHERE geom Is Not Null
GROUP BY p.gebwbagid;