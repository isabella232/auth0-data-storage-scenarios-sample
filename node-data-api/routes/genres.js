var express = require('express');
var router = express.Router();

var db = require('pg');
db.defaults.ssl = true;

function queryGenre(user_id, res){
	
  db.connect(process.env.DATABASE_URL, function(err, client) {
  if (err) throw err;

  client
    .query('SELECT fav_genre as value FROM user_data WHERE user_id = $1', [user_id], function(err, result) {

      if(err) {
        return console.error('error running query', err);
      }
      res.send(result.rows[0].value);
    });
  });

};

router.use(function timeLog(req, res, next) {
  next();
});

router.get('/getFav', function(req, res) {
   queryGenre(req.user.sub, res);
});

module.exports = router;