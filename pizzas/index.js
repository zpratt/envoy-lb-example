import Fastify from 'fastify'

const app = Fastify();

function getPizzas(req, reply) {
    reply.send([
        {id: 1, crust: 'thin', cheese: 'mozarella', sauce: 'tomato', name: 'cheese'},
    ]);
}

function healthCheck(req, reply) {
    reply.send({status: 'ok'});
}

function main() {
    app.get('/pizzas', getPizzas);
    app.get('/health', healthCheck);

    app.listen({port: 3000, host: '0.0.0.0'}, (err, address) => {
        if (err) {
        console.error(err)
        process.exit(1)
        }
        console.log(`Server listening at ${address}`)
    });

    process.on('SIGINT', async () => {
        await app.close();
    });
}

main();
