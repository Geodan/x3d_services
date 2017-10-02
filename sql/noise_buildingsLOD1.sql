WITH 
bounds AS (
	SELECT ST_Segmentize((ST_Dump(ST_Intersection(ST_MakeEnvelope(_west, _south, _east, _north, 28992),geom))).geom,_segmentlength) geom
		FROM noisemodel.demo_area
), 
polygons AS (
	SELECT 
		gebwbagid, bouwjaar,
		(
			ST_Extrude(
				ST_Translate(a.geom2d,0,0, Lmv) --pull 1 meter down
			, 0,0,L95)
		) 
		geom 
	FROM noisemodel.lod1 a, bounds b
	WHERE ST_Intersects(a.geom2d, b.geom) AND ST_Intersects(ST_Centroid(a.geom2d),b.geom)
	
)
SELECT gebwbagid as id,
--s.type as type,
'building' as type,
'red' color, ST_AsX3D((p.geom)) geom
FROM polygons p
WHERE p.geom Is Not Null --this can happen with not patch
