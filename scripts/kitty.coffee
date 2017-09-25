# coffeelint: disable=max_line_length
_ = require 'lodash'
moment = require 'moment'
moment.locale 'ja'
cron = require('cron').CronJob

module.exports = (robot) ->

  robot.hear /^\/kitty(| help)$/i, (msg) ->
    msg.reply(
      "/kitty events : show all events\n" +
      "/kitty make event {event name} : make new event\n" +
      "/kitty add member {member name} to {event name} : add member to the event\n" +
      "/kitty {paied member name} paied {price} for {payment name} of {event name} : add payment\n" +
      "/kitty delete {payment name} of {event name} : delete payment\n" +
      "/kitty event {event name} : show summary of event payments\n"
    )

  robot.hear /^\/kitty events$/i, (msg) ->
    robot.http("https://chaus.herokuapp.com/apis/kitty/events")
      .get() (err, res, body) ->
        events = JSON.parse(body).items;
        list = events.map (event) ->
          return "#{event.name}"
        .join('\n')
        msg.reply("イベントのリストを表示し　マス\n#{list}")

  robot.hear /^\/kitty (make|add) event (.+)$/i, (msg) ->
    name = msg.match[2];
    robot.http("https://chaus.herokuapp.com/apis/kitty/events")
      .header('Content-Type', 'application/json')
      .post(JSON.stringify({
        name: name,
      })) (err, res, body) ->
        console.log(err, body);
        msg.reply("#{name} イベントを作成しま　シタ");

  robot.hear /^\/kitty add member (.+) to (.+)$/i, (msg) ->
    memberName = msg.match[1];
    eventName = msg.match[2];
    robot.http("https://chaus.herokuapp.com/apis/kitty/people")
      .header('Content-Type', 'application/json')
      .post(JSON.stringify({
        name: memberName,
      })) (err, res, body) ->
        robot.http("https://chaus.herokuapp.com/apis/kitty/people?name=#{memberName}")
          .get() (err, res, body) ->
            person = JSON.parse(body).items[0];
            robot.http("https://chaus.herokuapp.com/apis/kitty/events?name=#{eventName}")
              .get() (err, res, body) ->
                event = JSON.parse(body).items[0];
                robot.http("https://chaus.herokuapp.com/apis/kitty/members")
                  .header('Content-Type', 'application/json')
                  .post(JSON.stringify({
                    event: event.id,
                    person: person.id
                  })) (err, res, body) ->
                    msg.reply "#{memberName}を#{eventName}に　追加しました　デス";

  robot.hear /^\/kitty (.+) paied (.+) for (.+) of (.+)$/i, (msg) ->
    memberName = msg.match[1];
    amount = msg.match[2];
    paymentName = msg.match[3];
    eventName = msg.match[4];
    robot.http("https://chaus.herokuapp.com/apis/kitty/people?name=#{memberName}")
      .get() (err, res, body) ->
        person = JSON.parse(body).items[0];
        robot.http("https://chaus.herokuapp.com/apis/kitty/events?name=#{eventName}")
          .get() (err, res, body) ->
            event = JSON.parse(body).items[0];
            robot.http("https://chaus.herokuapp.com/apis/kitty/members?event=#{event.id}&person=#{person.id}")
              .get() (err, res, body) ->
                member = JSON.parse(body).items[0];
                robot.http("https://chaus.herokuapp.com/apis/kitty/payments")
                  .header('Content-Type', 'application/json')
                  .post(JSON.stringify({
                    person: person.id,
                    event: event.id,
                    amount: amount,
                    name: paymentName
                  })) (err, res, body) ->
                    msg.reply "#{memberName}が　#{amount}円 を #{paymentName}のために #{eventName}で　払いました　デス";

  robot.hear /^\/kitty delete (.+) payment of (.+)$/i, (msg) ->
    paymentName = msg.match[3];
    eventName = msg.match[4];
    robot.http("https://chaus.herokuapp.com/apis/kitty/events?name=#{eventName}")
      .get() (err, res, body) ->
        event = JSON.parse(body).items[0];
        robot.http("https://chaus.herokuapp.com/apis/kitty/payments?event=#{event.id}&name=#{paymentName}")
          .get() (err, res, body) ->
            payment = JSON.parse(body).items[0];
            robot.http("https://chaus.herokuapp.com/apis/kitty/payments/#{payment.id}")
              .header('Content-Type', 'application/json')
              .delete() (err, res, body) ->
                msg.reply "#{paymentName}を削除しました　デス";

  robot.hear /^\/kitty event (.+)$/i, (msg) ->
    eventName = msg.match[1];
    robot.http("https://chaus.herokuapp.com/apis/kitty/events?name=#{eventName}")
      .get() (err, res, body) ->
        event = JSON.parse(body).items[0];
        robot.http("https://chaus.herokuapp.com/apis/kitty/members?event=#{event.id}")
          .get() (err, res, body) ->
            members = JSON.parse(body).items;
            robot.http("https://chaus.herokuapp.com/apis/kitty/payments?event=#{event.id}")
              .get() (err, res, body) ->
                liquidFund = {};
                members.map (from) ->
                  liquidFund[from.person.id] = {};
                  members.map (to) ->
                    if from.person.id != to.person.id
                      liquidFund[from.person.id][to.person.id] = 0;
                payments = JSON.parse(body).items;
                total = 0;
                payments.map (payment) ->
                  costPerPerson = Math.ceil(payment.amount / members.length);
                  members.map (member) ->
                    if payment.person.id != member.person.id
                      liquidFund[member.person.id][payment.person.id] = costPerPerson;
                  total += payment.amount

                liquidMessages = [];
                Object.keys(liquidFund).map (from) ->
                  Object.keys(liquidFund[from]).map (to) ->
                    if liquidFund[from][to] > liquidFund[to][from]
                      liquidMessages.push("#{from} は #{to} に #{liquidFund[from][to] - liquidFund[to][from]}　払ってくだ　サイ")

                msg.reply "合計 #{total}円　デス";
                msg.reply "一人当たり #{total / members.length}円　デス";
                msg.reply "#{liquidMessages.join("\n")}"
