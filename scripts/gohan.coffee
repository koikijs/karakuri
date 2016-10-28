# coffeelint: disable=max_line_length

moment = require 'moment'
moment.locale 'ja'
cron = require('cron').CronJob
gohan = room: "C2L1Y13R6" # gohan

module.exports = (robot) ->

  getFoods = (datestr, daynight, cafeteriaId) ->
    toYYYYMMDD = (date) ->
      return date.getFullYear() + ('0' + (date.getMonth() + 1)).slice(-2) + ('0' + date.getDate()).slice(-2)
     date = if datestr == '今日の' then moment().toDate() else
            if datestr == '本日の' then moment().toDate() else
            if datestr == '明日の' then moment().add(1, 'days').toDate() else
            if datestr == '明後日の' then moment().add(2, 'days').toDate() else
            if datestr == '明々後日の' then moment().add(3, 'days').toDate() else moment().toDate()

    mealTime = {
       'ひる': 1,
       '昼': 1,
       'よる': 2,
       '夜': 2,
       'ばん': 2,
       '晩': 2
    }[daynight]
    cafeteriaApi = 'https://rakuten-towerman.azurewebsites.net/towerman-restapi/rest/cafeteria/menulist'
    robot.http(cafeteriaApi)
      .query(menuDate: toYYYYMMDD(date), mealTime: mealTime, cafeteriaId: cafeteriaId)
      .get() (err, res, body) ->
        foods = JSON.parse(body)['data']
        robot.send gohan, "#{datestr}#{daynight}ごはん　#{cafeteriaId}は　こちらデス"
        attachments = []
        foods.map (data) ->
          imageURL = data.imageURL.replace(/^https\:\/\//, '')
          price = if data.price > 0 then ", #{data.price}円" else ""
          attachments.push({
            "color": "#36a64f",
            "title": "#{data.title}",
            "text": "#{data.menuType} (#{cafeteriaId})",
            "image_url": "https://images.weserv.nl/?url=#{imageURL}&w=200&h=200",
            "footer": "#{data.calories} kcal #{price}"
          })
        json = JSON.stringify({attachments: attachments});
        payload = "payload=" + encodeURIComponent(json)
        robot.http(process.env.HUBOT_SLACK_INCOMING_WEBHOOK_GOHAN)
          .header('content-type', 'application/x-www-form-urlencoded')
          .post(payload) (err, res, body) ->
            console.log err

  # Direct message
  robot.hear /^(|今日の|本日の|明日の|明後日の|明々後日の)(|ひる|昼|よる|夜|ばん|晩)(ごはん|ご飯|めし|飯)( |　)?(9|22)?F?$/i, (msg) ->
     datestr = if msg.match[1] then msg.match[1] else '本日の'
     daynight = if msg.match[2] then msg.match[2] else
                if new Date().getHours() < 15 then 'ひる' else 'よる'
     floor = if msg.match[5] then msg.match[5] else '9'
     cafeteriaId = floor.match(/^(\d+)/)[1] + 'F'

     getFoods datestr, daynight, cafeteriaId

  new cron '0 0 11 * * 1-5', () ->
    getFoods '本日の', '昼', '9F'
  , null, true, "Asia/Tokyo"

  new cron '0 0 19 * * 1-5', () ->
    getFoods '本日の', '夜', '9F'
  , null, true, "Asia/Tokyo"
