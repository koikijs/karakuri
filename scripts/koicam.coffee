# coffeelint: disable=max_line_length

moment = require 'moment'
moment.locale 'ja'
cron = require('cron').CronJob
envelope = room: "C5XAG9EET" # camp
mode = 'normal'

module.exports = (robot) ->

  next = () ->
    robot.http('https://monstera.herokuapp.com/api/koicam/next').get() (err, res, body) ->
      data = JSON.parse(body)
      if data.candidates.length == 0 && data.noplans.length
        robot.send envelope, "開催可能な日が　見つけられないぞ！\n" +
                             "https://monstera.herokuapp.com/events/koicam/availables\n" +
                             "#{data.noplans.join(', ')} の予定が一つも入ってないぞ！\n" +
                             "苦しいときこそ頑張るんだ。カモーン、俺について来い！"
      else if data.candidates.length == 0 && !data.noplans.length
        robot.send envelope, "開催可能な日が　見つけられないぞ！\n" +
                             "https://monstera.herokuapp.com/events/koicam/availables\n" +
                             "みんなの予定が合わないぞ！　予定をこじ開けろ！カモーン！"
      else
        dates = data.candidates.map (item) ->
          return "#{moment.utc(item.date).startOf('date').format('LL (ddd)')}: #{item.users.join(', ')}"
        .join('\n')
        robot.send envelope, "koicam　の開催可能日は\n#{dates}\nだ！"
        robot.send taka66,   "カモーン、俺について来い！"

  new cron '0 35 9 * * *', () ->
    next ""
  , null, true, "Asia/Tokyo"

  robot.hear /(koicam|こいきゃん|キャンプ)(| |　)(|は)(| |　)いつ(|ごろ|頃)(|になる|になりそう|ですか|になりそうですか|にする)(？|\?)/i, (msg) ->
    msg.send '確認してやるぜ！'
    next ""
