const { DynamoDBClient } = require('@aws-sdk/client-dynamodb');
const { S3Client, DeleteObjectCommand } = require('@aws-sdk/client-s3');
const { DynamoDBDocumentClient, BatchWriteCommand } = require('@aws-sdk/lib-dynamodb');
const { v4: uuidv4 } = require('uuid');
const crypto = require('crypto');

// Consent form bucket
const BUCKET_NAME = "csiro-consent-forms";

// Initialize the S3 Client
const s3Client = new S3Client({
    region: "ap-southeast-2",
});

// Core hashing logic
const hashData = (data) => {
    const salt = crypto.randomBytes(16).toString('hex');
    const hash = crypto.createHash('sha256');
    hash.update(JSON.stringify(data) + salt);
    const hashedData = hash.digest('hex');

    return {
        formHash: hashedData,
        saltKey: salt
    };
};

// Function to handle rollback of uploaded files
const rollbackUpload = async (fileKeys) => {
    const bucketName = process.env.S3_BUCKET_NAME;

    if (!bucketName) {
        throw new Error('S3 bucket name is not defined in environment variables');
    }

    if (!fileKeys || fileKeys.length === 0) {
        console.log('No files to roll back.');
        return;
    }

    try {
        for (const key of fileKeys) {
            if (key) {
                const deleteParams = {
                    Bucket: bucketName,
                    Key: key
                };
                await s3Client.send(new DeleteObjectCommand(deleteParams));
                console.log(`Successfully rolled back (deleted) file with key: ${key}`);
            }
        }
    } catch (err) {
        console.error('Error rolling back files from S3:', err.message);
        throw new Error(`Failed to roll back files from S3: ${err.message}`);
    }
};

// DynamoDB client setup
const client = new DynamoDBClient({ region: 'ap-southeast-2' });
const ddbDocClient = DynamoDBDocumentClient.from(client);

// Get the DynamoDB table name from environment variables
const tableName = process.env.PARTICIPANT_CONSENT_TABLE;

const putFormItemHandler = async (event) => {
    try {
        if (!tableName) {
            throw new Error("Table name is not defined in environment variables");
        }

        const requiredFields = [
            'formData', 'admin', 'timeStamp',
            'originalS3ObjectKey', 'originalS3Hash',
            'watermarkedS3ObjectKey', 'watermarkedS3Hash'
        ];

        const missingFields = requiredFields.filter(field => !event[field]);

        if (missingFields.length > 0) {
            throw new Error(`Missing required fields: ${missingFields.join(', ')}.`);
        }

        const { formData, admin, timeStamp, s3Map } = event;
        const hashMap = hashData(formData);

        if (!hashMap || !hashMap.formHash || !hashMap.saltKey) {
            throw new Error('hashMap with formHash and saltKey is required.');
        }

        const id = uuidv4();

        const items = [
            {
                id,
                version: 0,
                hashMap: {
                    formHash: hashMap.formHash,
                    saltKey: hashMap.saltKey
                },
                consentForm: formData,
                admin,
                timeStamp,
                latestVersion: 1
            },
            {
                id,
                version: 1,
                hashMap: {
                    formHash: hashMap.formHash,
                    saltKey: hashMap.saltKey
                },
                consentForm: formData,
                admin,
                timeStamp
            }
        ];

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

        await ddbDocClient.send(new BatchWriteCommand(params));

        return {
            status: "success",
            message: 'Form submitted successfully'
        };
    } catch (err) {
        console.error("Error occurred:", err.message);

        const fileKeys = [event.originalS3ObjectKey, event.watermarkedS3ObjectKey];
        await rollbackUpload(fileKeys);

        return {
            status: "failure",
            message: err.message
        };
    }
};

module.exports = { putFormItemHandler };
