WITH
bounds AS (
	SELECT ST_MakeEnvelope(_west, _south, _east, _north, 28992) geom
	--geom
	--ST_Segmentize((ST_Dump(ST_Intersection(ST_MakeEnvelope(_west, _south, _east, _north, 28992),geom))).geom,_segmentlength) geom
	--	FROM noisemodel.demo_area
)
,breaklines AS (
	SELECT 
		ST_Force3D(wkb_geometry) as geom
	FROM noisemodel.breaklines_chopped a, bounds b 
	WHERE ST_Intersects(wkb_geometry, geom)
	UNION ALL
	SELECT 
		ST_Force3D(ST_ExteriorRing(ST_Buffer(geom,10))) as geom 
	FROM bounds
)
,breakpolys AS (
	SELECT 
	ST_MakePolygon(
			ST_ExteriorRing(
				(ST_Dump(
					ST_Triangulate2DZ(ST_Node(ST_Collect(geom)))
				)).geom
			)
		) 
	geom
	FROM breaklines a

)

,water as (
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
,breakoutline AS (
	SELECT 
		ST_Translate((ST_Dump(ST_Intersection(p.geom, b.geom))).geom,0,0,0.1) geom
	FROM breaklines p, bounds b
	WHERE p.geom Is Not Null
)

SELECT 1 || 'Y' AS id, 
'breakline' As type,
'breakline' As class,
'0.6 0.6 0.6' as color,
--ST_AsX3D(ST_Collect(ST_Translate(ST_Intersection(p.geom,b.geom),0,0,1.5))) geom
ST_AsX3D(ST_Collect(p.geom)) geom
FROM breakoutline p



UNION ALL
SELECT 2 || 'X' AS id, 
'breakline' As type,
'breakline' As class,
'0 0.6 0' as color,
ST_AsX3D(ST_Intersection(p.geom,b.geom)) geom
FROM breakpolys p, bounds b
WHERE p.geom Is Not Null
AND ST_Intersects(p.geom, b.geom)

--GROUP BY fid, p.type,p.class
;