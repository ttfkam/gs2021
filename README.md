# Geek Speak

First things first. Either create a .pgpass file in your home directory or
edit the existing one to hold the following entry:

```
db:5432:*:postgres:demo
```

This allows the migration tool to update the local development database.

Second, make sure Docker is installed and running.

Third, run the following:

```sh
docker-compose up -d
```

## Database

[Sqitch](https://sqitch.org/docs/manual/sqitchtutorial/) migration files. To
install Sqitch locally:

```sh
docker pull sqitch/sqitch
sudo curl -L https://git.io/JJKCn -o /usr/local/bin/sqitch && sudo chmod +x /usr/local/bin/sqitch
```

You'll need this if you want to change the database structure.

## Infrastructure

### AWS

[AWS CDK](https://docs.aws.amazon.com/cdk/latest/guide/getting_started.html) implementation to deploy/update the Geek Speak AWS stack.

### GraphQL

[Postgraphile](https://www.graphile.org/postgraphile/) implementation that makes an existing database schema available through GraphQL.

This implementation allows for running as a server or deployed as an AWS Lambda behind API Gateway.

## UI

### Public

Public web site to be authored in [SvelteKit](https://kit.svelte.dev/docs), prerendered, and deployed to [AWS S3](https://aws.amazon.com/s3/).

### Admin

Admin web site to be authored in [SvelteKit](https://kit.svelte.dev/docs), deployed to [AWS S3](https://aws.amazon.com/s3/), and interact with the GraphQL layer.
