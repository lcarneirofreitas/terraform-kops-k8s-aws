
const amqp = require('amqplib');
const uuid = require('uuid/v4');

const host = process.env.HOST || 'amqp:guest:guest@rabbitmq.default.svc.cluster.local:5672';
const queue = process.env.QUEUE;
const replyTo = process.env.REPLY_TO;
const id = process.env.ID;
const wait = process.env.WAIT_TIME || 1000;

amqp.connect(host)
  .then(conn => conn.createChannel())
  .then(ch => {

    ch.assertQueue(replyTo, { durable: true });
    ch.assertQueue(queue, { durable: true });

    ch.consume(replyTo, (msg) => {

      console.log(`[${id} RESPONSE] Reponse CONSUMED: ${msg.content.toString()}`);

    }, { noAck: true });


    let count = 0;
    let correlationId;
    setInterval(() => {

      count++;
      correlationId = uuid();

      console.log(`[${id} PRODUCE] Message PRODUCED: ${count}`);
      ch.sendToQueue(queue, new Buffer(`{ "counter": "${id}-${count}" }`), {
        replyTo,
        correlationId
      }, { noAck: true });
    }, wait);

  })
  .catch(err => console.log(err));


