WITH
bounds AS (
	SELECT ST_Segmentize(ST_MakeEnvelope(_west, _south, _east, _north, 28992),_segmentlength) geom
)
,buildings AS (
	SELECT gebwbagid,height, (ST_DumpRings(a.geom)).geom
	FROM noisemodel.boxes_polygonizedz_distelbuurt a, bounds b
	WHERE ST_Intersects(a.geom, b.geom)
	AND ST_GeometryType(a.geom) = 'ST_Polygon'
)


SELECT _south::text || _west::text || p.gebwbagid AS id, 
'building' As type,
'building' As class,
'red' as color,
ST_AsX3D(ST_Extrude(ST_Tesselate(geom), 0,0,height)) geom
FROM buildings p
WHERE geom Is Not Null
AND ST_GeometryType(geom) = 'ST_Polygon'
--GROUP BY p.gebwbagid;