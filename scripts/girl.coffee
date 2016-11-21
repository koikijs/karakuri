# coffeelint: disable=max_line_length

module.exports = (robot) ->

  getGirls = (msg) ->
    robot.http('http://bjin.me/api/?type=rand&count=1&format=json')
      .get() (err, res, body) ->
        girls = JSON.parse(body)
        girls.map (data) ->
          imageURL = data.thumb.replace(/^http\:\/\//, '')
          msg.send """
                    今日の美女は こちらデス
                    #{data.category} https://images.weserv.nl/?url=#{imageURL}&w=200&h=200
                   """

  getJerkOffMaterials = (msg) ->
    robot.http('http://apiactress.appspot.com/api/1/getdata/ka')
      .get() (err, res, body) ->
        jerkOffMaterials = JSON.parse(body)

        index = Math.floor(Math.random() * (jerkOffMaterials.count - 1))
        
        actress = jerkOffMaterials.Actresses[index]
        imageURL = actress.thumb.replace("/thumbnail", "")
        
        msg.send """
                  今日のおかずは こちらデス
                  #{actress.yomi} #{imageURL}
                 """

  # Direct message
  robot.hear /^(美(女|人))$/, (msg) ->
    getGirls msg, true, "Asia/Tokyo"
  robot.hear /^(おかず)$/, (msg) ->
    getJerkOffMaterials msg, true, "Asia/Tokyo"
