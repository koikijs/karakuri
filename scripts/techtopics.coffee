# coffeelint: disable=max_line_length

moment = require 'moment'
moment.locale 'ja'
cron = require('cron').CronJob
techtopics = room: "C2LKUHVPD" # techtopics
mode = 'normal'

module.exports = (robot) ->

  # Topics
  new cron '0 0 15 * * *', () ->
    robot.http("https://chaus.herokuapp.com/apis/karakuri/tags").get() (err, res, body) ->
      tags = JSON.parse(body).items.map (item) ->
        return item.name
      tag = tags[Math.floor(Math.random() * tags.length)]
      robot.http("http://qiita.com/api/v2/tags/#{tag}/items?page=1&per_page=1").get() (err, res, body) ->
        data = JSON.parse(body)
        robot.send techtopics, "３時の #{tag} オヤツ　デス #{data[0].url}"
  , null, true, "Asia/Tokyo"
