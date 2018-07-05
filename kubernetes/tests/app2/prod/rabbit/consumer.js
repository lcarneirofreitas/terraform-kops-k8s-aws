
const amqp = require('amqplib');

const host = process.env.HOST || 'amqp:guest:guest@rabbitmq.default.svc.cluster.local:5672';
const queue = process.env.QUEUE;
const id = process.env.ID;
const wait = process.env.WAIT_TIME || 1000;

debugger;

amqp.connect(host)
  .then(conn => conn.createChannel())
  .then(ch => {

    ch.assertQueue(queue, { durable: true });
    ch.consume(queue, (msg) => {

      let parsed = JSON.parse(msg.content.toString());
      console.log(`[${id} CONSUME] Message CONSUMED : ${parsed.counter}`);

      setTimeout(() => {

        console.log(`[${id} RESPONSE] Reponse PRODUCED: ${parsed.counter}`);
        ch.sendToQueue(msg.properties.replyTo, new Buffer(`{ status: "ok", responder: "${id}", counter: ${parsed.counter}}`),
          {
            correlationId: msg.properties.correlationId
          });

      }, { noAck: true });

    }, wait);
  })
  .catch(err => console.log(err));


