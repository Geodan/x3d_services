WITH
bounds AS (
	SELECT ST_Segmentize(ST_MakeEnvelope(_west, _south, _east, _north, 28992),_segmentlength) geom
)
,buildings AS (
	SELECT blockid,height, (ST_DumpRings(a.geom)).geom
	FROM noisemodel.planesz a, bounds b, noisemodel.demo_area c
	WHERE ST_Intersects(a.geom, b.geom)
	AND ST_Contains(c.geom, a.geom)
	AND ST_GeometryType(a.geom) = 'ST_Polygon'
)
,blocks AS (
	SELECT a.blockid, 
		COALESCE(b.height, a.height) height, 
		COALESCE(ST_ZMax(b.geom),ST_ZMax(a.geom)) zmax,
		COALESCE(ST_Union(ST_Force2D(a.geom), ST_Force2D(b.geom)), ST_Force2D(a.geom)) geom
		
	FROM buildings a
	LEFT JOIN buildings b ON (a.blockid = b.blockid AND ST_Contains(ST_Buffer(ST_Force2D(b.geom),1.5), ST_Force2D(a.geom)) AND b.height > a.height)
)

SELECT _south::text || _west::text || p.blockid AS id, 
'building' As type,
'building' As class,
'red' as color,
ST_AsX3D(ST_Extrude(ST_Tesselate(ST_Force2D(geom)), 0,0,height + zmax)) geom
FROM blocks p
WHERE geom Is Not Null
AND ST_GeometryType(geom) = 'ST_Polygon'
--GROUP BY p.gebwbagid;