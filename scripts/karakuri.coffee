# coffeelint: disable=max_line_length

moment = require 'moment'
moment.locale 'ja'
cron = require('cron').CronJob
envelope = room: "C0JHEPQ94" # general
test = room: "C217B7QG0" # test
gohan = room: "C2L1Y13R6" # gohan
techtopics = room: "C2LKUHVPD" # techtopics
taka66 = room: "C0JHEPQ94", user: "U0JH92D60" # taka66
# envelope = room: "C217B7QG0" # test
mode = 'normal'

module.exports = (robot) ->

  robot.hear /^channels$/, (msg) ->
    channels = robot.adapter.client.rtm.dataStore.channels
    Object.keys(channels).map (id) ->
      msg.reply "#{id} #{channels[id].name}"

  robot.hear /^users$/, (msg) ->
    users = robot.adapter.client.rtm.dataStore.users
    Object.keys(users).map (id) ->
      msg.reply "#{id} #{users[id].name}"

  sendDM = (name, message) ->
    room = robot.adapter.client.rtm.dataStore.getDMByName name
    robot.messageRoom room.id, message

  # error handling
  robot.error (err, res) ->
    robot.logger.error err
    robot.logger.error res

  robot.hear /^(js|sh)$/, (msg) ->
    mode = msg.match[1];
    msg.send "#{mode} モードを起動します　デス"

  robot.hear /^balse$/, (msg) ->
    msg.send "#{mode} モードを終了します　デス"
    mode = 'normal';

  robot.hear /^(?!(js|sh|balse)).+$/, (msg) ->
    if msg.match[0]
      switch mode
        when 'js'
          evaluated = String( eval msg.match[0] )
          msg.send evaluated
        when 'sh'
          String( eval "require('child_process').exec('#{msg.match[0]}', function(e, so, se){msg.send(so)})" )

  robot.hear /^karakuri put (.*)/, (msg) ->
    msgs = JSON.parse(robot.brain.get('msgs')||'[]')
    msgs.push msg.match[1]
    robot.brain.set('msgs', JSON.stringify msgs)
    msg.send msg.match[1] + ' が追加されました　デス'

  robot.hear /^karakuri delete (\d+)/, (msg) ->
    msgs = JSON.parse(robot.brain.get('msgs')||'[]')
    deleted = msgs.splice msg.match[1], 1
    robot.brain.set('msgs', JSON.stringify msgs)
    msg.send deleted[0] + ' が削除されました　デス'

  robot.hear /^karakuri all$/, (msg) ->
    msgs = JSON.parse(robot.brain.get('msgs')||'[]')
    msg.send msgs.join '\n'

  robot.hear /(|いま|今)(| |　)何時(？|\?)/i, (msg) ->
    msg.send "現在の時刻は　#{moment().format('lll')}　デス"

  # JS eval
  robot.hear /^js (.+)/i, (msg) ->
    console.log 'matched', msg.match[1]
    evaluated = String( eval msg.match[1] )
    console.log 'evaluated', evaluated
    msg.send evaluated

  # startup
  robot.send test, 'むくり'
  robot.send envelope, 'ナブチ様　起きてください　デス'
  robot.http('https://nabnab-bot.herokuapp.com/').get() (err, res, body) ->
    robot.send envelope, 'ナブチ様　遅刻　デス'
  setTimeout () ->
    msgs = JSON.parse(robot.brain.get('msgs')||'[]')
    message = msgs[Math.floor(Math.random() * msgs.length)] || ''
    robot.send test, message
  , 5000
