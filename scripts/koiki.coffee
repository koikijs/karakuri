# coffeelint: disable=max_line_length

moment = require 'moment'
moment.locale 'ja'
cron = require('cron').CronJob
envelope = room: "C0JHEPQ94" # general
taka66 = room: "C0JHEPQ94", user: "U0JH92D60" # taka66
# envelope = room: "C217B7QG0" # test
mode = 'normal'

module.exports = (robot) ->

  # Koiki
  new cron '0 35 9 * * *', () ->
    robot.http('https://monstera.herokuapp.com/api/koikijs/next').get() (err, res, body) ->
      data = JSON.parse(body)
      date = moment.utc(data.date).startOf('date').format()
      if data.date == undefined
        robot.send envelope, '開催可能な日が　見つけられない　デス'
        robot.send envelope, 'https://monstera.herokuapp.com/events/koikijs'
        robot.send envelope, 'みなさん　予定の空いている日を入れてほしい　デス'
      if data.date && date == moment.utc().startOf('date').format()
        robot.send envelope, '本日は　koiki　の開催日　デス'
        robot.send envelope, 'みなさま　お遅れにならないよう　お願いします　デス'
        robot.send envelope, 'ご飯　隊長: ninja-inc'
        robot.send envelope, '場所取り　隊長: sideroad'
        robot.send envelope, '議事録　隊長: nabnab'
        robot.send envelope, 'デザイン　隊長: taka66'
      if data.date && date == moment.utc().startOf('date').add(1, 'days').format()
        robot.send envelope, '明日は　koiki　の開催日　デス'
        robot.send envelope, 'みなさま　お忘れの無いよう　お願いします　デス'
      if data.date && date == moment.utc().startOf('date').add(3, 'days').format()
        robot.send envelope, '三日後に　koiki　が開催されます　デス'
        robot.send envelope, "グーグルカレンダーに登録してください　デス\n https://www.google.com/calendar/render?action=TEMPLATE&text=koikijs&dates=#{moment(data.date).format('YYYYMMDD')}T000000/#{moment(data.date).format('YYYYMMDD')}T235959&trp=undefined&trp=true&sprop="
        robot.send envelope, 'みなさま　お忘れの無いよう　お願いします　デス'
      if data.date && date == moment.utc().startOf('date').add(7, 'days').format() ||
         data.date && date == moment.utc().startOf('date').add(10, 'days').format() ||
         data.date && date == moment.utc().startOf('date').add(14, 'days').format()
        robot.send envelope, "次回　koiki　の開催予定日は　#{moment(data.date).format('LL (ddd)')}　デス"
        robot.send envelope, "グーグルカレンダーに登録してください　デス\n https://www.google.com/calendar/render?action=TEMPLATE&text=koikijs&dates=#{moment(data.date).format('YYYYMMDD')}T000000/#{moment(data.date).format('YYYYMMDD')}T235959&trp=undefined&trp=true&sprop="
        robot.send taka66,   "場所の予約のほど　よろしくお願いします　デス"
  , null, true, "Asia/Tokyo"

  robot.hear /(次|つぎ)の(| |　)(小粋|koiki|こいき)(| |　)(|は)(| |　)いつ(|ごろ|頃)(|になる|になりそう|ですか|になりそうですか|にする)(？|\?)/i, (msg) ->
    msg.send 'ただいま確認中　デス'
    robot.http('https://monstera.herokuapp.com/api/koikijs/next').get() (err, res, body) ->
      data = JSON.parse(body)
      if data.date == undefined
        msg.send '開催可能な日が　見つけられない　デス'
        msg.send 'https://monstera.herokuapp.com/events/koikijs'
        msg.send 'みなさん　予定の空いている日を入れてほしい　デス'
      else
        msg.send "つぎの開催予定日は　#{moment(data.date).format('LL (ddd)')}　デス"
        msg.send "次回　koiki　の開催予定日は　#{moment(data.date).format('LL (ddd)')}　デス"
        msg.send "グーグルカレンダーに登録してください　デス\n https://www.google.com/calendar/render?action=TEMPLATE&text=koikijs&dates=#{moment(data.date).format('YYYYMMDD')}T000000/#{moment(data.date).format('YYYYMMDD')}T235959&trp=undefined&trp=true&sprop="
