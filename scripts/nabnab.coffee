# coffeelint: disable=max_line_length

moment = require 'moment'
moment.locale 'ja'
cron = require('cron').CronJob
mode = 'normal'

module.exports = (robot) ->
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
