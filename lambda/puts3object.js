const { S3Client, PutObjectCommand } = require("@aws-sdk/client-s3");
const { PDFDocument, rgb, degrees } = require("pdf-lib");

const client = new S3Client({ region: "ap-southeast-2" });
const BUCKET_NAME = process.env.S3_BUCKET_NAME;

exports.handler = async (event) => {
  try {
    const body = JSON.parse(event.body);
    const { base64Data, fileName } = body;

    if (!base64Data || !fileName) {
      throw new Error("Missing required parameters: base64Data, fileName");
    }

    // Load the existing PDF bytes
    const existingPdfBytes = Buffer.from(base64Data, "base64");
    const pdfDoc = await PDFDocument.load(existingPdfBytes);

    // Add watermark to each page of the PDF
    const pages = pdfDoc.getPages();
    for (const page of pages) {
      const { width, height } = page.getSize(); // width and height are scoped here
      console.log(
        `Applying watermark on page: width=${width}, height=${height}`,
      );
      page.drawText("testmark", {
        x: width / 4,
        y: height / 2,
        size: 50,
        opacity: 0.5,
        rotate: degrees(45),
        color: rgb(0.75, 0.75, 0.75),
      });
    }

    // Save the modified PDF with the watermark
    const modifiedPdfBytes = await pdfDoc.save();
    console.log(`Modified PDF size: ${modifiedPdfBytes.length} bytes`);

    // Upload the modified PDF to S3
    const params = {
      Bucket: BUCKET_NAME,
      Key: fileName,
      Body: Buffer.from(modifiedPdfBytes),
      ContentType: "application/pdf",
    };

    const command = new PutObjectCommand(params);
    const uploadResult = await client.send(command);
    const checksum = uploadResult.ETag;

    // Return success response
    return {
      statusCode: 200,
      headers: {
        "Access-Control-Allow-Origin": "*",
        "Access-Control-Allow-Methods": "POST,OPTIONS",
        "Access-Control-Allow-Headers":
          "Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token",
        "Access-Control-Allow-Credentials": "true",
      },
      body: JSON.stringify({
        message: "Consent form uploaded successfully with watermark",
        data: uploadResult,
        s3ObjectKey: fileName,
        s3Hash: checksum,
      }),
    };
  } catch (error) {
    console.error("Error during processing:", error);
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
        message: "Consent form upload failed",
        error: error.message,
      }),
    };
  }
};
