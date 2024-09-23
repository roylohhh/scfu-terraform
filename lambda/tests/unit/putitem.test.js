const { putFormItemHandler } = require('../../putitem');
const { DynamoDBDocumentClient, BatchWriteCommand } = require('@aws-sdk/lib-dynamodb');
const { mockClient } = require('aws-sdk-client-mock');

// This includes all tests for putItemHandler() 
describe('Test putFormItem', function () { 
    const ddbMock = mockClient(DynamoDBDocumentClient);

    beforeEach(() => {
        ddbMock.reset();
    });

    // This test invokes putFormItemHandler() for a batch write and compares the result  
    it('should add multiple items to the table in a batch', async () => { 
        const returnedItems = [
            { id: 'id1', version: 0, consentForm: { name: "Michael Johnson", email: "michael.johnson@example.com", address: "789 Oak St, Lakeview, USA" }, HashMap: { formHash: "abc123", saltKey: "salt123" }, s3Map: { s3Hash: "z9y8x7w6v5u4t3s2r1q0", s3ObjectKey: "different-key-54321" }, admin: { adminName: "Admin User" }, latestVersion: 1 },
            { id: 'id2', version: 0, consentForm: { name: "Sarah Lee", email: "sarah.lee@example.com", address: "123 Birch St, Maple Town, USA" }, HashMap: { formHash: "def456", saltKey: "salt456" }, s3Map: { s3Hash: "y7w6v5u4t3s2r1q0z9x8", s3ObjectKey: "key-98765" }, admin: { adminName: "Admin User" }, latestVersion: 2 }
        ];

        // Return the specified value whenever the batch write command is called 
        ddbMock.on(BatchWriteCommand).resolves({
            UnprocessedItems: {}
        });

        const event = {
            httpMethod: 'POST',
            body: JSON.stringify({
                Items: returnedItems
            })
        };

        // Invoke putItemHandler() 
        const result = await putFormItemHandler(event);

        const expectedResult = {
            statusCode: 200,
            body: JSON.stringify({ message: 'Batch write successful', items: returnedItems })
        };

        // Compare the result with the expected result 
        expect(result).toEqual(expectedResult);
    });
});
