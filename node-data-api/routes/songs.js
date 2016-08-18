var express = require('express');
var router = express.Router();

var db = require('pg');
db.defaults.ssl = true;


function getSongs(user_id, res){
 
  db.connect(process.env.DATABASE_URL, function(err, client) {
  if (err) throw err;

  client
    .query('SELECT songname as value FROM songs WHERE user_id = $1', [user_id], function(err, result) {
      if(err) {
        return console.error('error running query', err);
      }
      var i = 0;
      var songs = [];
      while (result.rows[i] )
      {
        songs[i] = result.rows[i].value;
        i++;
      }
      var song_json = JSON.stringify({Songs:songs});      
      res.send(song_json);
    });
  });


};

function addSong(user_id, song, res){

  db.connect(process.env.DATABASE_URL, function(err, client) {
  if (err) throw err;

  client
    .query('INSERT INTO songs VALUES (100, $1, $2)', [song, user_id], function(err, result) {

      if(err) {
        return console.error('error running query', err);
      }
      res.send(song);
    });
  });

};

router.use(function timeLog(req, res, next) {
  next();
});


router.get('/get', function(req, res) {
   getSongs(req.user.sub, res);
});

router.post('/add', function(req, res) {
  var song = req.body.song;
  addSong(req.user.sub, song, res);
});

module.exports = router;