
WITH
bounds AS (
	SELECT 
		(ST_Dump(ST_Intersection(ST_Segmentize(ST_MakeEnvelope(_west, _south, _east, _north, 28992),_segmentlength),geom))).geom geom
		FROM noisemodel.demo_area
),
pointcloud_ground AS (
	SELECT PC_FilterEquals(pa,'classification',2) pa 
	FROM ahn3_pointcloud.vw_ahn3, bounds
	WHERE PC_Intersects(geom, pa)
),
terrein AS (
	SELECT nextval('counter') id,'weg' as type, 'flups' as class, (wkb_geometry) geom FROM 
	(
		SELECT wkb_geometry 
		FROM bgt.wegdeel_2dactueelbestaand, bounds
		WHERE ST_Intersects(wkb_geometry, geom)
		AND bgt_functie != 'spoorbaan'
		AND relatievehoogteligging = 0 --later ook nog set met 1 maken
		UNION ALL
		SELECT wkb_geometry 
		FROM bgt.ondersteunendwegdeel_2dactueelbestaand, bounds
		WHERE ST_Intersects(wkb_geometry, geom)
		AND relatievehoogteligging = 0 --later ook nog set met 1 maken
		UNION ALL 
		SELECT wkb_geometry 
		FROM bgt.onbegroeidterreindeel_2dactueelbestaand, bounds
		WHERE ST_Intersects(wkb_geometry, geom)
		AND relatievehoogteligging = 0 --later ook nog set met 1 maken
		AND onbegroeidterreindeeloptalud = 'f'
	) foo
	
	
	UNION ALL
	
	SELECT nextval('counter') id,'spoorbaan' as type, 'flups' as class, ST_Buffer((wkb_geometry),-0.2,'join=mitre mitre_limit=5.0') geom 
	FROM bgt.wegdeel_2dactueelbestaand, bounds
	WHERE ST_Intersects(wkb_geometry, geom)
	AND relatievehoogteligging = 0 --later ook nog set met 1 maken
	AND bgt_functie = 'spoorbaan'
	UNION ALL
	
	SELECT nextval('counter') id,'terrein' as type, 'flups' as class, ST_Buffer((wkb_geometry),-0.2,'join=mitre mitre_limit=5.0') geom 
	FROM bgt.onbegroeidterreindeel_2dactueelbestaand, bounds
	WHERE ST_Intersects(wkb_geometry, geom)
	AND relatievehoogteligging = 0 --later ook nog set met 1 maken
	AND onbegroeidterreindeeloptalud = 't'
	UNION ALL
	SELECT nextval('counter') id,'terrein' as type, 'flups' as class, ST_Buffer((wkb_geometry),-0.2,'join=mitre mitre_limit=5.0') geom 
	FROM bgt.begroeidterreindeel_2dactueelbestaand, bounds
	WHERE ST_Intersects(wkb_geometry, geom)
	AND relatievehoogteligging = 0 --later ook nog set met 1 maken
	AND begroeidterreindeeloptalud = 't'
	
	UNION ALL
	
	SELECT nextval('counter') id,'water' as type, 'flups' as class, ST_Buffer((wkb_geometry),-0.2,'join=mitre mitre_limit=5.0') geom 
	FROM bgt.waterdeel_2dactueelbestaand, bounds
	WHERE ST_Intersects(wkb_geometry, geom)
	AND relatievehoogteligging = 0 --later ook nog set met 1 maken
)
,polygons AS (
	SELECT id, type, class, (ST_Dump(ST_Intersection(b.geom, a.geom))).geom
	FROM terrein a, bounds b
)
,polygonsz AS (
	SELECT id, type, class, patch_to_geom(PC_Union(b.pa), geom) geom
	FROM polygons a 
	LEFT JOIN pointcloud_ground b
	ON PC_Intersects(geom,b.pa)
	WHERE ST_GeometryType(geom) = 'ST_Polygon'
	GROUP BY id, type, class, geom
)
,basepoints AS (
	SELECT id,type, class, geom FROM polygonsz
	WHERE ST_IsValid(geom)
)
,triangles AS (
	SELECT 
		id,
		ST_MakePolygon(
			ST_ExteriorRing(
				(ST_Dump(ST_Triangulate2DZ(ST_Collect(a.geom)))).geom
			)
		)geom
	FROM basepoints a
	GROUP BY id, type, class
)
,assign_triags AS (
	SELECT 	a.*, b.type, b.class
	FROM triangles a
	INNER JOIN polygons b
	ON ST_Contains(b.geom, a.geom)
	,bounds c
	WHERE ST_Intersects(ST_Centroid(b.geom), c.geom)
	AND a.id = b.id
)

SELECT _south::text || _west::text || p.id as id, p.type as type,
	ST_AsX3D(ST_Collect(p.geom),5) geom
FROM assign_triags p
GROUP BY p.id, p.type