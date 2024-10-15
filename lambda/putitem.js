const { DynamoDBClient } = require("@aws-sdk/client-dynamodb");
const {
  DynamoDBDocumentClient,
  BatchWriteCommand,
} = require("@aws-sdk/lib-dynamodb");
const { v4: uuidv4 } = require("uuid");
const crypto = require("crypto");

// Core hashing logic
const hashData = (data) => {
  const salt = crypto.randomBytes(16).toString("hex");
  const hash = crypto.createHash("sha256");
  hash.update(JSON.stringify(data) + salt);
  return {
    formHash: hash.digest("hex"),
    saltKey: salt,
  };
};

const client = new DynamoDBClient({ region: "ap-southeast-2" });
const ddbDocClient = DynamoDBDocumentClient.from(client);
const tableName = process.env.PARTICIPANT_CONSENT_TABLE;

const putFormItemHandler = async (event) => {
  try {
    if (event.httpMethod !== "POST") {
      return {
        statusCode: 405,
        headers: {
          "Access-Control-Allow-Origin": "http://scfu-frontend.s3-website-ap-southeast-2.amazonaws.com",
          "Access-Control-Allow-Methods": "POST,OPTIONS",
          "Access-Control-Allow-Headers":
            "Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token",
          "Access-Control-Allow-Credentials": "true",
        },
        body: JSON.stringify({
          message: `Method not allowed: ${event.httpMethod}`,
        }),
      };
    }

    if (!tableName) {
      return {
        statusCode: 500,
        headers: {
          "Access-Control-Allow-Origin": "http://scfu-frontend.s3-website-ap-southeast-2.amazonaws.com",
          "Access-Control-Allow-Methods": "POST,OPTIONS",
          "Access-Control-Allow-Headers":
            "Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token",
          "Access-Control-Allow-Credentials": "true",
        },
        body: JSON.stringify({
          message: "Table name is not defined in environment variables",
        }),
      };
    }

    const body = JSON.parse(event.body);
    const consentForm = body.consentForm;
    const admin = body.admin;

    if (!consentForm || !admin || !admin.adminName) {
      return {
        statusCode: 400,
        headers: {
          "Access-Control-Allow-Origin": "http://scfu-frontend.s3-website-ap-southeast-2.amazonaws.com",
          "Access-Control-Allow-Methods": "POST,OPTIONS",
          "Access-Control-Allow-Headers":
            "Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token",
          "Access-Control-Allow-Credentials": "true",
        },
        body: JSON.stringify({
          message: "consentForm and admin with adminName are required.",
        }),
      };
    }

    const id = uuidv4();
    const hashMap = hashData(consentForm);

    const items = [
      {
        id: id,
        version: 0,
        hashMap: { formHash: hashMap.formHash, saltKey: hashMap.saltKey },
        consentForm: consentForm,
        admin: admin,
        latestVersion: 1,
      },
      {
        id: id,
        version: 1,
        hashMap: { formHash: hashMap.formHash, saltKey: hashMap.saltKey },
        consentForm: consentForm,
        admin: admin,
      },
    ];

    const params = {
      RequestItems: {
        [tableName]: items.map((item) => ({
          PutRequest: { Item: item },
        })),
      },
    };

    await ddbDocClient.send(new BatchWriteCommand(params));

    return {
      statusCode: 200,
      headers: {
        "Access-Control-Allow-Origin": "http://scfu-frontend.s3-website-ap-southeast-2.amazonaws.com",
        "Access-Control-Allow-Methods": "POST,OPTIONS",
        "Access-Control-Allow-Headers":
          "Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token",
        "Access-Control-Allow-Credentials": "true",
      },
      body: JSON.stringify({ message: "Successfully written to table" }),
    };
  } catch (error) {
    console.error("Error:", error); // Log the error

    return {
      statusCode: 500,
      headers: {
        "Access-Control-Allow-Origin": "http://scfu-frontend.s3-website-ap-southeast-2.amazonaws.com",
        "Access-Control-Allow-Methods": "POST,OPTIONS",
        "Access-Control-Allow-Headers":
          "Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token",
        "Access-Control-Allow-Credentials": "true",
      },
      body: JSON.stringify({
        message: "Internal Server Error",
        error: error.message, // Optionally include the error message
      }),
    };
  }
};

module.exports = { putFormItemHandler };
