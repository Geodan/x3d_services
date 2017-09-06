WITH
bounds AS (
	SELECT ST_Segmentize(ST_MakeEnvelope(_west, _south, _east, _north, 28992),_segmentlength) geom
)
,exclusion_zone AS (
	SELECT ST_Union(wkb_geometry) as geom 
	FROM bgt.overbruggingsdeel_2dactueelbestaand a, bounds b
	WHERE ST_Intersects(a.wkb_geometry, b.geom)
)
,collections AS (
	SELECT ST_Buffer(ST_Union(ST_Buffer(a.geom, 10)),-9) geom
	FROM bagagn_201704.gebouwen a, bounds b, exclusion_zone c
	WHERE ST_Contains(b.geom,a.geom)
	AND ST_Disjoint(c.geom, a.geom)
	AND gebw_type = 'p'
)
,dump AS (
	SELECT (ST_Dump(a.geom)).geom geom 
	FROM collections a
),
polyz AS (
	SELECT patch_to_geom(PC_Union(PC_FilterEquals(pa,'classification',2)), geom) geom
	FROM ahn3_pointcloud.vw_ahn3, dump
	WHERE PC_Intersects(ST_ExteriorRing(geom), pa)
	GROUP BY geom
)

--SELECT (ST_Dump(ST_Intersection(ST_ConCaveHull(a.geom,0.999), b.geom))).geom geom
--FROM polyz a, bounds b


SELECT _south::text || _west::text || 'X' AS id, 
'buildup' As type,
'buildup' As class,
'red' as color,
ST_AsX3D(ST_Extrude((geom), 0,0,-1)) geom
FROM polyz p
WHERE geom Is Not Null
--GROUP BY fid, p.type,p.class
;