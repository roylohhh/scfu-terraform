const { DynamoDBClient } = require('@aws-sdk/client-dynamodb');
const { DynamoDBDocumentClient, PutCommand, BatchWriteCommand } = require('@aws-sdk/lib-dynamodb');
const { v4: uuidv4 } = require('uuid');
const crypto = require('crypto');

// Core hashing logic
const hashData = (data) => {
    // Generate a random 16-byte salt
    const salt = crypto.randomBytes(16).toString('hex');

    // Create a hash of the data with the salt
    const hash = crypto.createHash('sha256');
    hash.update(JSON.stringify(data) + salt);
    const hashedData = hash.digest('hex');

    const response = {
        formHash: hashedData,
        saltKey: salt
    };

    return response;
};

// DynamoDB putFormItem event
const client = new DynamoDBClient({
    region: 'ap-southeast-2',
});

const ddbDocClient = DynamoDBDocumentClient.from(client);

// Get the DynamoDB table name from environment variables
const tableName = process.env.PARTICIPANT_CONSENT_TABLE;

const putFormItemHandler = async (event) => {

    if (event.httpMethod !== 'POST') {
        throw new Error(`postMethod only accepts POST method, you tried: ${event.httpMethod} method.`);
    }

    if (!tableName) {
        throw new Error("Table name is not defined in environment variables");
    }

    // Get hashMap, consentForm, and optional s3Map from the body of the request
    const body = JSON.parse(event.body);

    // Log the size of the consent form for diagnostic purposes
    console.log(`Size of consentForm: ${JSON.stringify(body.consentForm).length} bytes`);

    // Map event data to be written to DynamoDb table
    const id = uuidv4();
    const consentForm = body.consentForm;

    // Timing log for the hashing operation
    const startHashing = Date.now();
    const hashMap = hashData(consentForm);
    console.log(`Hashing took: ${Date.now() - startHashing} ms`);

    const s3Map = body.s3Map;
    const admin = body.admin;

    // Validate required fields
    if (!hashMap || !hashMap.formHash || !hashMap.saltKey) {
        throw new Error('hashMap with formHash and saltKey is required.');
    }
    if (!consentForm) {
        throw new Error('consentForm is required.');
    }
    if (!admin || !admin.adminName) {
        throw new Error('admin with adminName required.');
    }

    const items = [
        {
            // Version 0 Item - represents the latest version for this item
            id: id,
            version: 0,
            hashMap: { 
                formHash: hashMap.formHash,
                saltKey: hashMap.saltKey
            },
            consentForm: consentForm,
            admin: admin,
            latestVersion: 1
        },
        {
              // Version 1 Item - represents the first version for this item to be created
            id: id,
            version: 1,
            hashMap: {
                formHash: hashMap.formHash,
                saltKey: hashMap.saltKey
            },
            consentForm: consentForm,
            admin: admin
        }
    ];

    // Add optional s3Map attribute if provided
    if (s3Map && s3Map.s3Hash && s3Map.s3ObjectKey) {
        items.forEach(item => {
            item.s3Map = {
                s3Hash: s3Map.s3Hash,
                s3ObjectKey: s3Map.s3ObjectKey
            };
        });
    }

    const params = {
        RequestItems: {
            [tableName]: items.map(item => ({
                PutRequest: {
                    Item: item
                }
            }))
        }
    };

    try {
        // Timing log for DynamoDB BatchWriteCommand
        const startWrite = Date.now();
        await ddbDocClient.send(new BatchWriteCommand(params));
        console.log(`DynamoDB BatchWrite took: ${Date.now() - startWrite} ms`);
    } catch (err) {
        console.log("Error", err.stack);
    }

    const response = {
        statusCode: 200,
        body: JSON.stringify(body)
    };

    // All log statements are written to CloudWatch
    console.info(`response from: ${event.path} statusCode: ${response.statusCode} body: ${response.body}`);
    return response;
};

module.exports = { putFormItemHandler };