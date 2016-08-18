var express = require('express');
var path = require('path');
var logger = require('morgan');
var cookieParser = require('cookie-parser');
var bodyParser = require('body-parser');
var dotenv = require('dotenv');
var jwt = require('express-jwt');
var cors = require('cors');
var http = require('http');
var request = require('request');
var db = require('pg');

db.defaults.ssl = true;

var app = express();
var router = express.Router();

app.use(cors());
app.use(logger('dev'));
app.use(bodyParser.json());
app.use(bodyParser.urlencoded({ extended: false }));
app.use(cookieParser());


var genres = require('./routes/genres');
var songs = require('./routes/songs');
var playlists = require('./routes/playlists');
var displayName = require('./routes/displayName');

dotenv.load();

var authenticate = jwt({
  secret: new Buffer(process.env.AUTH0_CLIENT_SECRET, 'base64'),
  audience: process.env.AUTH0_CLIENT_ID
});

app.use('/genres', authenticate, genres);
app.use('/songs', authenticate, songs);
app.use('/playlists', authenticate, playlists);
app.use('/displayName', authenticate, displayName);


module.exports = app;

