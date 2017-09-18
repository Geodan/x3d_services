WITH
bounds AS (
	SELECT ST_Segmentize(ST_MakeEnvelope(_west, _south, _east, _north, 28992),_segmentlength) geom
)
,breakpolys AS (
	SELECT 
	
	ST_MakePolygon(
			ST_ExteriorRing(
				(ST_Dump(ST_Triangulate2DZ(ST_Collect(ST_Force3D(wkb_geometry))))).geom
			)
		) geom
		
		
	FROM noisemodel.breaklines_chopped a, bounds b 
	WHERE ST_Intersects(wkb_geometry, geom)
)
,breaklines AS (
	SELECT 
		ST_Force3D(wkb_geometry) as geom
	FROM noisemodel.breaklines_chopped a, bounds b 
	WHERE ST_Intersects(wkb_geometry, geom)
),
water as (
	SELECT ST_Buffer(ST_Union(wkb_geometry),1) as wkb_geometry
	FROM bgt.waterdeel_2dactueelbestaand, bounds
	WHERE ST_Intersects(wkb_geometry,geom)
	
)
,cutwater AS (
	SELECT a.geom 
	FROM breaklines a
	LEFT JOIN water b ON (St_Contains(b.wkb_geometry, a.geom))
	WHERE b.wkb_geometry Is Null

)


SELECT _south::text || _west::text || 'X' AS id, 
'breakline' As type,
'breakline' As class,
'0 1 0' as color,
ST_AsX3D(ST_Translate(geom,0,0,-0.5)) geom
FROM breaklines p
WHERE geom Is Not Null
UNION ALL
SELECT _south::text || _west::text || 'X' AS id, 
'breakline' As type,
'breakline' As class,
'1 0.3 0.3' as color,
ST_AsX3D(ST_Translate(geom,0,0,-0.5)) geom
FROM breakpolys p
WHERE geom Is Not Null
--GROUP BY fid, p.type,p.class
;