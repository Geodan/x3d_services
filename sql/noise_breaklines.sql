WITH 
bounds AS (
	SELECT ST_Segmentize(ST_MakeEnvelope(_west, _south, _east, _north, 28992),_segmentlength) geom
),
breaklines AS (
	SELECT nextval('counter') id, 
		type AS type, 
		 --ST_ExteriorRing((ST_DumpRings(a.wkb_geometry)).geom) as geom
		 --(ST_Dump(ST_Triangulate2dz(ST_Union(
		 ST_Intersection(a.wkb_geometry,b.geom) 
		 --)))).geom
		 as geom
	FROM noisemodel.breaklines_chopped a, bounds b
	WHERE ST_Intersects(a.wkb_geometry, b.geom)
)

SELECT _south::text || _west::text || p.id AS id, 
type as type,
CASE 'type'
	WHEN 'water' THEN 'blue'
	WHEN 'breakline' THEN 'green'
	WHEN 'kade' THEN 'grey'
	WHEN 'buildup' THEN 'orange'
END AS color,
ST_AsX3D(ST_Collect(geom),3) as geom
FROM breaklines p
GROUP BY p.id, p.type