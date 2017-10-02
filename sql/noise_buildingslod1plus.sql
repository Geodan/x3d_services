WITH
bounds AS (
	SELECT ST_MakeEnvelope(_west, _south, _east, _north, 28992) geom
)
,buildings AS (
	SELECT a.gebwbagid, Lmv, LnokRel, (ST_Dump(a.geom2d)).geom
	FROM noisemodel.lod1plus a, bounds b, noisemodel.demo_area c
	WHERE ST_Intersects(a.geom2d, b.geom)
	AND ST_Contains(c.geom, a.geom2d)
)
SELECT _south::text || _west::text || p.gebwbagid AS id, 
'building' As type,
'building' As class,
'red' as color,
ST_AsX3D(ST_Extrude(ST_Translate(ST_Tesselate(geom),0,0,Lmv), 0,0,LnokRel)) geom
FROM buildings p
WHERE geom Is Not Null;