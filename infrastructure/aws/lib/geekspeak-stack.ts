import * as path from 'path';
import * as cdk from '@aws-cdk/core';
import * as ec2 from '@aws-cdk/aws-ec2';
import * as lambda from '@aws-cdk/aws-lambda';
import * as rds from '@aws-cdk/aws-rds';
import { CognitoToApiGatewayToLambda } from '@aws-solutions-constructs/aws-cognito-apigateway-lambda';
import { LambdaToS3 } from '@aws-solutions-constructs/aws-lambda-s3';
import { LambdaToSsmstringparameter } from '@aws-solutions-constructs/aws-lambda-ssmstringparameter';

// eslint-disable-next-line import/prefer-default-export
export class GeekspeakStack extends cdk.Stack {
    constructor(scope: cdk.Construct, id: string, props?: cdk.StackProps) {
        super(scope, id, props);

        const vpc = new ec2.Vpc(this, 'Vpc', {
            cidr: '10.66.0.0/16',
            subnetConfiguration: [
                {
                    cidrMask: 28,
                    name: 'rds',
                    subnetType: ec2.SubnetType.ISOLATED,
                },
            ],
        });

        const db = new rds.DatabaseInstance(this, 'RdsInstance', {
            engine: rds.DatabaseInstanceEngine.postgres({
                version: rds.PostgresEngineVersion.VER_13_3,
            }),
            databaseName: 'geekspeak',
            vpc,
        });

        // const auroraDb = new rds.ServerlessCluster(this, 'GsDb', {
        //     engine: rds.DatabaseClusterEngine.AURORA_POSTGRESQL,
        //     parameterGroup: rds.ParameterGroup.fromParameterGroupName(this, 'RdsParameterGroup', 'default.aurora-postgresql10'),
        //     defaultDatabaseName: 'geekspeak',
        //     vpc,
        //     scaling: {
        //         autoPause: cdk.Duration.minutes(90),
        //     },
        // });

        const postgraphile = new lambda.DockerImageFunction(this, 'Graphql', {
            code: lambda.DockerImageCode.fromImageAsset(path.join(__dirname, '..', 'graphql')),
            vpc,
        });

        db.grantConnect(postgraphile);

        const cognitoConstruct = new CognitoToApiGatewayToLambda(this, 'CognitoGraphql', {
            existingLambdaObj: postgraphile,
            apiGatewayProps: {
                defaultCorsPreflightOptions: {
                    allowOrigins: ['admin.geekspeak.org'],
                },
                domainName: {
                    certificate: null, // TODO: add cert
                    domainName: 'api.geekspeak.org',
                },
                failOnWarnings: true,
                minimumCompressionSize: 0,
                proxy: true,
                vpc,
            },
            cognitoUserPoolProps: {
            },
        });
        // Mandatory to call this method to Apply the Cognito Authorizers on all API methods
        cognitoConstruct.addAuthorizers();

        const ssmParams = new LambdaToSsmstringparameter(this, 'GraphqlSsm', {

        });

        const lambdaS3 = new LambdaToS3(this, 'GraphqlS3', {
            existingLambdaObj: postgraphile,
            bucketProps: {

            },
        });

    }
}
