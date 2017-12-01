# coffeelint: disable=max_line_length

moment = require 'moment'
moment.locale 'ja'
cron = require('cron').CronJob
taka66 = room: "C0JHEPQ94", user: "U0JH92D60" # taka66
# envelope = room: "C217B7QG0" # test
mode = 'normal'

module.exports = (robot) ->

  next = (event, envelope) ->
    robot.http('https://monstera.herokuapp.com/api/' + event + '/next').get() (err, res, body) ->
      if res.statusCode isnt 200
        robot.send envelope, "そんなイベントは　無いデス　ボケ　デス"
      data = JSON.parse(body)
      if data.candidates.length == 0 && data.noplans.length
        robot.send envelope, "開催可能な日が　見つけられない　デス\n" +
                             "https://monstera.herokuapp.com/events/" + event + "/availables\n" +
                             "#{data.noplans.join(', ')} の予定が一つも入ってない　デス\n" +
                             "はやく　いれんかい　ボケ　デス"
      else if data.candidates.length == 0 && !data.noplans.length
        robot.send envelope, "開催可能な日が　見つけられない　デス\n" +
                             "https://monstera.herokuapp.com/events/" + event + "/availables\n" +
                             "みんなの予定が合わない　デス"
      else
        dates = data.candidates.map (item) ->
          return "#{moment.utc(item.date).startOf('date').format('LL (ddd)')}: #{item.users.join(', ')}"
        .join('\n')
        robot.send envelope, "次回　koiki　の開催可能日は\n#{dates}\nデス"
        robot.send taka66,   "場所の予約のほど　よろしくお願いします　デス"

  # Koiki
  new cron '0 35 9 * * *', () ->
    next ""
  , null, true, "Asia/Tokyo"

  robot.hear /(次|つぎ)の(| |　)(小粋|[a-zA-Z0-9]+)(| |　)(|は)(| |　)いつ(|ごろ|頃)(|になる|になりそう|ですか|になりそうですか|にする)(？|\?)/i, (msg) ->
    event =  msg.match[3]
    if event == 'koiki' || event == '小粋'
      event = 'koikijs'
      envelope = room: "C0JHEPQ94" # general
    else
      console.log(msg.message.room)
      envelope = room: msg.message.room

    msg.send 'ただいま確認中　デス'
    next event, envelope
