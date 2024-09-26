const { S3Client, PutObjectCommand } = require('@aws-sdk/client-s3');
const { PDFDocument, rgb, degrees } = require('pdf-lib');

const client = new S3Client({ region: 'ap-southeast-2' });
// const BUCKET_NAME = 'csiro-consent-forms';
const BUCKET_NAME = process.env.S3_BUCKET_NAME;

exports.handler = async (event) => {
  try {
    const body = JSON.parse(event.body);
    const { base64Data, fileName } = body;

    if (!base64Data || !fileName) {
      throw new Error('Missing required parameters: base64Data, fileName');
    }

    const existingPdfBytes = Buffer.from(base64Data, 'base64');
    const pdfDoc = await PDFDocument.load(existingPdfBytes);

    const pages = pdfDoc.getPages();
    for (const page of pages) {
      const { width, height } = page.getSize();
      page.drawText('testmark', {
        x: width / 4,
        y: height / 2,
        size: 50,
        opacity: 0.5,
        rotate: degrees(45),
        color: rgb(0.75, 0.75, 0.75)
      });
    }

    const modifiedPdfBytes = await pdfDoc.save();

    const params = {
      Bucket: BUCKET_NAME,
      Key: fileName,
      Body: Buffer.from(modifiedPdfBytes),
      ContentType: 'application/pdf',
    };

    const command = new PutObjectCommand(params);
    const uploadResult = await client.send(command);
    const checksum = uploadResult.ETag;

    return {
      statusCode: 200,
      body: JSON.stringify({
        message: 'Consent form uploaded successfully with watermark',
        data: uploadResult,
        s3ObjectKey: fileName,
        s3Hash: checksum
      }),
    };
  } catch (error) {
    return {
      statusCode: 500,
      body: JSON.stringify({
        message: 'Consent form upload failed',
        error: error.message,
      }),
    };
  }
};
