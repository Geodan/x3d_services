WITH 
bounds AS (
	SELECT ST_MakeEnvelope(_west, _south, _east, _north, 28992) geom
),
pointcloud_unclassified AS(
	SELECT 
		PC_FilterEquals(pa,'classification',6)
	 pa  
	FROM noisemodel.roofpatches, bounds 
	WHERE ST_DWithin(geom, PC_Envelope(pa),10) --patches should be INSIDE bounds
),
patches AS (
	SELECT a.pa FROM pointcloud_unclassified a
	--LIMIT 1000 --SAFETY
),
points AS (
	SELECT PC_Explode(pa) pt
	FROM patches
),
points_filtered AS (
	SELECT * FROM points 
	WHERE PC_Get(pt,'coplanar') = 1
	
)
SELECT nextval('counter') as id, 'building' as type, random() * 0.1 ||' 0 0' as color, ST_AsX3D(ST_Collect(Geometry(pt))) geom
FROM points_filtered a;