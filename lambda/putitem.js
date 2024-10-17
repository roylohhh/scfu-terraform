import { DynamoDBClient } from "@aws-sdk/client-dynamodb";
import { S3Client, DeleteObjectCommand } from "@aws-sdk/client-s3";
import {
  DynamoDBDocumentClient,
  BatchWriteCommand,
} from "@aws-sdk/lib-dynamodb";
import { v4 as uuidv4 } from "uuid";
import crypto from "crypto";

// Consent form bucket
const BUCKET_NAME = "csiro-consent-forms";

// Initialize the S3 Client
const s3Client = new S3Client({
  region: "ap-southeast-2",
});

// Core hashing logic
const hashData = (data) => {
  // Generate a random 16-byte salt
  const salt = crypto.randomBytes(16).toString("hex");

  // Create a hash of the data with the salt
  const hash = crypto.createHash("sha256");
  hash.update(JSON.stringify(data) + salt);
  const hashedData = hash.digest("hex");

  return {
    formHash: hashedData,
    saltKey: salt,
  };
};

// Function to handle rollback of uploaded files
const rollbackUpload = async (fileKeys) => {
  const bucketName = process.env.S3_BUCKET_NAME;

  if (!bucketName) {
    throw new Error("S3 bucket name is not defined in environment variables");
  }

  // Check if there are any file keys to delete
  if (!fileKeys || fileKeys.length === 0) {
    console.log("No files to roll back.");
    return;
  }

  try {
    // Iterate over each file key and delete the associated object from S3
    for (const key of fileKeys) {
      if (key) {
        const deleteParams = {
          Bucket: bucketName,
          Key: key,
        };

        // Call S3 to delete the object
        await s3Client.send(new DeleteObjectCommand(deleteParams));
        console.log(`Successfully rolled back (deleted) file with key: ${key}`);
      }
    }
  } catch (err) {
    console.error("Error rolling back files from S3:", err.message);
    throw new Error(`Failed to roll back files from S3: ${err.message}`);
  }
};

// DynamoDB client setup
const client = new DynamoDBClient({ region: "ap-southeast-2" });
const ddbDocClient = DynamoDBDocumentClient.from(client);

// Get the DynamoDB table name from environment variables
const tableName = process.env.PARTICIPANT_CONSENT_TABLE;

export const putFormItemHandler = async (event) => {
  try {
    if (!tableName) {
      throw new Error("Table name is not defined in environment variables");
    }

    // Check if any required fields are missing
    const requiredFields = [
      "formData",
      "admin",
      "timeStamp",
      "originalS3ObjectKey",
      "originalS3Hash",
      "watermarkedS3ObjectKey",
      "watermarkedS3Hash",
    ];

    const missingFields = requiredFields.filter((field) => !event[field]);

    if (missingFields.length > 0) {
      throw new Error(`Missing required fields: ${missingFields.join(", ")}.`);
    }

    const { formData, admin, timeStamp, s3Map } = event;

    // Generate hash of the formData
    const hashMap = hashData(formData);

    // Validate required fields in hashMap
    if (!hashMap || !hashMap.formHash || !hashMap.saltKey) {
      throw new Error("hashMap with formHash and saltKey is required.");
    }

    // Map event data to be written to DynamoDB
    const id = uuidv4();

    const items = [
      {
        id: id,
        version: 0,
        hashMap: {
          formHash: hashMap.formHash,
          saltKey: hashMap.saltKey,
        },
        consentForm: formData,
        admin: admin,
        timeStamp: timeStamp,
        latestVersion: 1,
      },
      {
        id: id,
        version: 1,
        hashMap: {
          formHash: hashMap.formHash,
          saltKey: hashMap.saltKey,
        },
        consentForm: formData,
        admin: admin,
        timeStamp: timeStamp,
      },
    ];

    // If s3Map is provided, add it to each item
    if (s3Map && s3Map.s3Hash && s3Map.s3ObjectKey) {
      items.forEach((item) => {
        item.s3Map = {
          s3Hash: s3Map.s3Hash,
          s3ObjectKey: s3Map.s3ObjectKey,
        };
      });
    }

    // Prepare BatchWriteCommand parameters for DynamoDB
    const params = {
      RequestItems: {
        [tableName]: items.map((item) => ({
          PutRequest: {
            Item: item,
          },
        })),
      },
    };

    // Write to DynamoDB
    await ddbDocClient.send(new BatchWriteCommand(params));

    // Success response
    return {
      status: "success",
      message: "Form submitted successfully",
    };
  } catch (err) {
    console.error("Error occurred:", err.message);

    // Call rollbackUpload function to delete any uploaded files from S3
    const fileKeys = [event.originalS3ObjectKey, event.watermarkedS3ObjectKey];
    await rollbackUpload(fileKeys);

    // Failure response
    return {
      status: "failure",
      message: err.message,
    };
  }
};
