WITH
bounds AS (
	SELECT ST_Segmentize(ST_MakeEnvelope(_west, _south, _east, _north, 28992),_segmentlength) geom
)
,buildings AS (
	SELECT gebwbagid,height, (St_Dump(a.geom)).geom
	FROM tmp.polygonized_height a, bounds b
	WHERE ST_Intersects(a.geom, b.geom)
)


SELECT _south::text || _west::text || p.gebwbagid AS id, 
'building' As type,
'building' As class,
'red' as color,
ST_AsX3D(ST_Extrude(ST_Tesselate(geom), 0,0,COALESCE(height,4))) geom
FROM buildings p
WHERE geom Is Not Null
--GROUP BY fid, p.type,p.class
;