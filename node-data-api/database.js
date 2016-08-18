var pg = require('pg');
var connectionString = process.env.DATABASE_URL || 'postgres://localhost:3001';

var client = new pg.Client(connectionString);
client.connect();
