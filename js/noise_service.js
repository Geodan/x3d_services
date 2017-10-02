var cors = require( 'cors' ) 
var express = require( 'express' );
var compress = require('compression');

var app = express( ); 
var fs = require( 'fs' ); 
var pg = require( 'pg' ); 
var sets = {
	roofplanes: { file: '../sql/noise_roofplanes.sql',sql: ''},
	buildingslod1plus: { file: '../sql/noise_buildingslod1plus.sql',sql: ''},
	roofoutline: { file: '../sql/noise_roofoutline.sql',sql: ''},
	buildup: { file : '../sql/noise_buildup.sql',sql: ''},
	water: { file: '../sql/bgt_water.sql',sql: ''},
	terrain: { file : '../sql/bgt_terrain.sql',sql: ''},
	roads: { file : '../sql/bgt_road.sql',sql: ''},
	treepoints: { file : '../sql/ahn3_treepoints.sql', sql : '' },
	buildingpoints: { file : '../sql/ahn3_buildingpoints.sql', sql : '' },
	buildings: { file : '../sql/noise_buildingsLOD1.sql', sql : '' },
	kade: { file: '../sql/bgt_kade.sql',sql: ''}
}; 
for( var s in sets ) { 
	sets [ s ].sql = fs.readFileSync( sets [ s ].file ).toString( ); 
};
app.use( cors( )); 
app.use(compress());  
app.get( '/noisemodel3d', function( req, res ) { 
		var north = req.query [ 'north' ]; 
		var south = req.query [ 'south' ]; 
		var west = req.query [ 'west' ]; 
		var east = req.query [ 'east' ]; 
		var set = req.query [ 'set' ];
		var eps = req.query [ 'eps' ] || 3;
		var minpoints = req.query [ 'minpoints' ] || 350;
		
		if (!north || !south || !west || !east || !set){
			res.send('Missing parameter');
			console.log('Missing parameter');
		}
		else if (!sets[set]){
			res.send('Not such set found: ' + set);
			console.log('Not such set found: ' + set);
		}
		else {
			var client = new pg.Client( { 
					user : 'postgres', 
					password : 'xxxxxxx', 
					database : 'research', 
					host : 'metis', 
					port : 5433 
			} ); 
			
			var querystring = fs.readFileSync( sets [ set ].file ).toString( );
			client.connect( function( err ) { 
					if( err ) {
						res.send(err)
					} 
					console.log('Set: ',set);
					//var querystring = sets [ set ].sql; 
					querystring = querystring
						.replace( /_west/g, west )
						.replace( /_east/g, east )
						.replace( /_south/g, south )
						.replace( /_north/g, north )
						.replace( /_eps/g ,eps)
						.replace( /_minpoints/g ,minpoints)
						.replace( /_zoom/g ,1)
						.replace( /_segmentlength/g,10); 
					client.query( querystring, function( err, result ) { 
							if( err ) { 
								console.warn( err, querystring );
							} 
							//console.log(querystring);
							var resultstring = '';
							for (var key in result.rows[0]){
								resultstring += key + ','
							}
							resultstring += "\n"; 
							result.rows.forEach( function( row ) {
									for (var key in row){
										resultstring += row[key] + ',' 
									}
									resultstring += '\n';
							} );
							res.set( "Content-Type", 'text/plain' );
							res.send(resultstring);
							/*
							res.set("Content-Type", 'text/javascript'); // i added this to avoid the "Resource interpreted as Script but transferred with MIME type text/html" message
							res.send(JSON.stringify({data: result.rows}));
							*/
							console.log( 'Sending results', result.rows.length ); 
							client.end( ); 
					} ); 
			} );
		}
} );
app.get( '/', function( req, res ) { 
		res.send( 'Nothing to see here, move on!' ); 
} );
app.listen( 8081, function( ) { 
		console.log( 'BGT X3D service listening on port 8081' ); 
} ); 
