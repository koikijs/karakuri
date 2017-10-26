# coffeelint: disable=max_line_length
_ = require 'lodash'
moment = require 'moment'
moment.locale 'ja'
cron = require('cron').CronJob

liquid = (payPerPerson, messages) ->
  if payPerPerson.length > 1
    from = _.minBy(payPerPerson, 'amount')
    to = _.maxBy(payPerPerson, 'amount')
    messages.push "#{from.person} は #{to.person} に #{from.amount * -1}円　払ってくだ　サイ"
    to.amount += from.amount
    return liquid(_.reject(payPerPerson, { person: from.person }), messages)
  else
    return messages

module.exports = (robot) ->

  robot.respond /kitty help$/i, (msg) ->
    msg.reply(
      "@karakuri events : show all events\n" +
      "@karakuri make event {event name} : make new event\n" +
      "@karakuri add member {member name} to {event name} : add member to the event\n" +
      "@karakuri {paid member name} paid {price} for {payment name} of {event name} : add payment\n" +
      "@karakuri delete {payment name} of {event name} : delete payment\n" +
      "@karakuri event {event name} : show summary of event payments\n"
    )

  robot.respond /events$/i, (msg) ->
    robot.http("https://chaus.herokuapp.com/apis/kitty/events")
      .get() (err, res, body) ->
        events = JSON.parse(body).items;
        list = events.map (event) ->
          return "#{event.name}"
        .join('\n')
        msg.reply("イベントのリストを表示し　マス\n#{list}")

  robot.respond /(make|add) event (.+)$/i, (msg) ->
    name = msg.match[2];
    robot.http("https://chaus.herokuapp.com/apis/kitty/events")
      .header('Content-Type', 'application/json')
      .post(JSON.stringify({
        name: name,
      })) (err, res, body) ->
        console.log(err, body);
        msg.reply("#{name} イベントを作成しま　シタ");

  robot.respond /add member (.+) to (.+)$/i, (msg) ->
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

  robot.respond /(.+) paid (.+) for (.+) of (.+)$/i, (msg) ->
    memberName = msg.match[1];
    amount = msg.match[2].replace(/(,|円)/g, '');
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

  robot.respond /delete (.+) payment of (.+)$/i, (msg) ->
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

  robot.respond /event (.+)$/i, (msg) ->
    eventName = msg.match[1];
    robot.http("https://chaus.herokuapp.com/apis/kitty/events?name=#{eventName}")
      .get() (err, res, body) ->
        event = JSON.parse(body).items[0];
        robot.http("https://chaus.herokuapp.com/apis/kitty/members?event=#{event.id}")
          .get() (err, res, body) ->
            members = JSON.parse(body).items;
            robot.http("https://chaus.herokuapp.com/apis/kitty/payments?event=#{event.id}")
              .get() (err, res, body) ->
                payments = JSON.parse(body).items;

                # calculate cost per person, total amount
                total = 0;
                paymentMessages = [];
                payPerPerson = [];
                members.forEach (member) ->
                  payPerPerson.push({ person: member.person.id, amount: 0 })

                payments.forEach (payment) ->
                  paymentMessages.push("#{payment.name} (#{payment.amount}円) paid by #{payment.person.id}");
                  _.find(payPerPerson, { person: payment.person.id }).amount += payment.amount
                  total += payment.amount

                # calculate avarage cost
                averageCost = Math.ceil(total / members.length)

                # re-calculate, how much need to pay in each person
                members.forEach (member) ->
                  _.find(payPerPerson, { person: member.person.id}).amount -= averageCost

                # calculate liquid
                liquidMessages = [];
                liquidMessages = liquid(payPerPerson, []);

                msg.reply "#{paymentMessages.join("\n")}\n\n" +
                          "合計 #{total}円　デス\n" +
                          "一人当たり #{averageCost}円　デス\n\n" +
                          "#{liquidMessages.join("\n")}"
