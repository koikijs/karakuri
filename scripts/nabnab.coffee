# coffeelint: disable=max_line_length

moment = require 'moment'
moment.locale 'ja'
cron = require('cron').CronJob
mode = 'normal'

module.exports = (robot) ->

  # probability ... number, 0%~100%
  sendReaction = (msg, probability) ->
    randomInt = Math.floor(Math.random() * ((100/probability)*5))
    nabReaction = " (ナブチ様風 反応 デス)"
    switch randomInt
      when 0
        msg.send "!!!" + nabReaction
      when 1
        msg.send "！" + nabReaction
      when 2
        msg.send "おー" + nabReaction
      when 3
        msg.send "あー" + nabReaction
      when 4
        msg.send "おお" + nabReaction
      else

  # Nabuchi
  robot.hear /^nab put (.*)/, (msg) ->
    user = msg.envelope.user.name.trim().toLowerCase()
    if user != 'nabnab'
      nabs = JSON.parse(robot.brain.get('nabs')||'[]')
      nabs.push msg.match[1]
      robot.brain.set('nabs', JSON.stringify nabs)
      msg.send msg.match[1] + ' が追加されました　デス'
    else
      msg.send '403 ナブチ様の要求は　受け入れられません'

  robot.hear /^nab delete (\d+)/, (msg) ->
    user = msg.envelope.user.name.trim().toLowerCase()
    if user != 'nabnab'
      nabs = JSON.parse(robot.brain.get('nabs')||'[]')
      deleted = nabs.splice msg.match[1], 1
      robot.brain.set('nabs', JSON.stringify nabs)
      msg.send deleted[0] + ' が削除されました　デス'
    else
      msg.send '403 ナブチ様の要求は　受け入れられません'

  robot.hear /^nab all$/, (msg) ->
    nabs = JSON.parse(robot.brain.get('nabs')||'[]')
    msg.send nabs.join '\n'

  robot.hear /.*/, (msg) ->
    user = msg.envelope.user.name.trim().toLowerCase()

    if user == 'nabnab'
      msg.send msg.random JSON.parse(robot.brain.get('nabs')||'[]')
  
  robot.hear /.*/, (msg) ->
    sendReaction msg, 20

  robot.hear /^なぶち(|さん|様)$/, (msg) ->
    sendReaction msg, 100