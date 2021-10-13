import koa from 'koa';
import serverless from 'serverless-http';
import { createServer } from 'http';
import { postgraphile } from 'postgraphile';
import { pgConfig, schemas, options, port } from './config.mjs';

const SERVERLESS = import.meta.url !== `file://${process.argv[1]}`;

const app = new koa();
const middleware = postgraphile(pgConfig, schemas, options(SERVERLESS));
app.use(middleware);

// eslint-disable-next-line import/prefer-default-export
export const handler = serverless(app);

// Invoked from the command line, not loaded as a module/lambda
if (!SERVERLESS) {
    const server = createServer(app.callback());
    server.listen(port, () => {
        const address = server.address();
        if (typeof address !== 'string') {
            const href = `http://localhost:${address.port}${options.graphiqlRoute ?? '/graphiql'}`;
            console.log(`PostGraphiQL available at ${href} 🚀`);
        } else {
            console.log(`PostGraphile listening on ${address} 🚀`);
        }
    });
}
