# coffeelint: disable=max_line_length

girl = room: "C2L1Y13R7" # girl

module.exports = (robot) ->

  getGirls = () ->
    robot.http('http://bjin.me/api/?type=rand&count=1&format=json')
      .get() (err, res, body) ->
        girls = JSON.parse(body)
        robot.send girl, "今日の美女は　こちらデス"
        girls.map (data) ->
          imageURL = data.thumb.replace(/^http\:\/\//, '')
          robot.send girl, data.category + " " + "https://images.weserv.nl/?url=#{imageURL}&w=200&h=200"

  getJerkOffMaterials = () ->
    robot.http('http://apiactress.appspot.com/api/1/getdata/ka')
      .get() (err, res, body) ->
        jerkOffMaterials = JSON.parse(body)

        index = Math.floor(Math.random() * (jerkOffMaterials.count - 1))
        
        robot.send girl, "今日のおかずは　こちらデス"
        actress = jerkOffMaterials.Actresses[index]
        imageURL = actress.thumb.replace("/thumbnail", "")
        
        robot.send girl, actress.yomi + " " + imageURL

  # Direct message
  robot.hear /^(美(女|人))$/, () ->
    getGirls null, true, "Asia/Tokyo"
  robot.hear /^(おかず)$/, () ->
    getJerkOffMaterials null, true, "Asia/Tokyo"
