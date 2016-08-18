var express = require('express');
var router = express.Router();

var db = require('pg');
db.defaults.ssl = true;

function getPlays(user_id, res){
 
  db.connect(process.env.DATABASE_URL, function(err, client) {
  if (err) throw err;

  client
    .query('SELECT total_plays as value FROM playlists WHERE user_id = $1', [user_id], function(err, result) {
      if(err) {
        return console.error('error running query', err);
      }
      var plays = result.rows[0].value;
      res.send(plays);
    });
  });


};

router.use(function timeLog(req, res, next) {
  next();
});

router.get('/getPlays', function(req, res) {
  getPlays(req.user.sub, res);
});

module.exports = router;