import dotenv from 'dotenv';
import ssm from '@aws-sdk/client-ssm';
import { createRequire } from 'module';
import SimplifyInflector from '@graphile-contrib/pg-simplify-inflector';
import ManyToManyPlugin from '@graphile-contrib/pg-many-to-many';

dotenv.config();

async function getSsmParam(paramName) {
    if (paramName == null) {
        return null;
    }
    const ssmParams = {
        Name: paramName,
        WithDecryption: true,
    };
    try {
        return (await ssm.getParameter(ssmParams).promise())?.Parameter?.Value;
    } catch (err) {
        return null;
    }
}

const { env } = process;
const require = createRequire(import.meta.url);

const dbUrl = env.DB_URL ?? await getSsmParam(env.DB_SECRET_NAME);
const dbAdminUrl = env.DB_ADMIN_URL;
const { TagsFilePlugin } = require('postgraphile/plugins');

export const pgConfig = dbUrl;
export const schemas = (env.SCHEMAS ?? 'public').split(/\s*[,;]\s*/);
export const options = (serverless) => ({
    allowExplain: !serverless,
    appendPlugins: [
        ManyToManyPlugin,
        SimplifyInflector,
        TagsFilePlugin,
    ],
    disableQueryLog: serverless,
    dynamicJson: true,
    enableQueryBatching: true,
    enhanceGraphiql: !serverless,
    exportGqlSchemaPath: serverless ? undefined : env.GQL_SCHEMA_PATH,
    extendedErrors: ["hint", "detail", "errcode"],
    graphiql: !serverless,
    graphiqlRoute: '/',
    ignoreIndexes: false,
    ignoreRBAC: false,
    legacyRelations: "omit",
    ownerConnectionString: dbAdminUrl,
    readCache: serverless ? undefined : env.SCHEMA_CACHE_FILE,
    retryOnInitFail: !serverless,
    setofFunctionsContainNulls: false,
    showErrorStack: "json",
    watchPg: !serverless,
});
export const port = parseInt(env.PORT, 10) || 3000;
