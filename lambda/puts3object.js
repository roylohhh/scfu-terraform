const { S3Client, PutObjectCommand } = require("@aws-sdk/client-s3");
const { PDFDocument, rgb } = require("pdf-lib");
const { v4: uuidv4 } = require("uuid");

// Initialize the S3 Client
const client = new S3Client({
  region: "ap-southeast-2",
});

// Consent form bucket
const BUCKET_NAME = process.env.S3_BUCKET_NAME;

if (!BUCKET_NAME) {
  throw new Error('S3 bucket name is not defined in environment variables');
}

exports.handler = async (event) => {
  try {
    if (!event.scannedForm || !event.admin) {
      console.error("Error: Malformed JSON object");
      return {
        status: "failure",
        errors: "Malformed JSON object",
      };
    }

    const scannedForm = event.scannedForm;
    const admin = event.admin;
    const timestamp = event.timeStamp;

    const { base64Data, fileName } = scannedForm;

    if (!base64Data || !fileName) {
      throw new Error("Missing required parameters: base64Data, fileName");
    }

    // Generate unique name for the original document
    const originalDocumentName = `${uuidv4()}_${fileName}`;

    // Convert base64 to binary
    const existingPdfBytes = Buffer.from(base64Data, "base64");

    // Upload parameters for the original document
    const originalDocumentUploadParams = {
      Bucket: BUCKET_NAME,
      Key: originalDocumentName,
      Body: Buffer.from(existingPdfBytes),
      ContentType: "application/pdf",
      ChecksumAlgorithm: "SHA256",
    };

    // Create the PutObjectCommand for the original document
    const firstDocumentUploadCommand = new PutObjectCommand(
      originalDocumentUploadParams
    );

    // Upload to S3
    const firstDocumentUploadResult = await client.send(
      firstDocumentUploadCommand
    );

    // Get SHA-256 checksum of the first uploaded document
    const firstDocumentChecksum = firstDocumentUploadResult.ChecksumSHA256;

    // Load the PDF with pdf-lib
    const pdfDoc = await PDFDocument.load(existingPdfBytes);

    // Construct watermark string
    const watermarkText =
      `${admin.name} ${admin.familyName}\t(${admin.id})\n${firstDocumentChecksum}`;

    // Add watermark to each page
    const pages = pdfDoc.getPages();
    for (const page of pages) {
      const { width, height } = page.getSize();
      page.drawText(watermarkText, {
        x: 10,
        y: height - 20,
        size: 12,
        opacity: 0.7,
        color: rgb(0.0, 0.694, 0.863), // CSIRO Colour
      });
    }

    // Save the modified PDF
    const modifiedPdfBytes = await pdfDoc.save();

    const watermarkedDocumentName = `${uuidv4()}_${fileName}`;

    // Upload parameters for the watermarked document
    const params = {
      Bucket: BUCKET_NAME,
      Key: watermarkedDocumentName,
      Body: Buffer.from(modifiedPdfBytes),
      ContentType: "application/pdf",
      ChecksumAlgorithm: "SHA256",
    };

    // Create the PutObjectCommand
    const command = new PutObjectCommand(params);

    // Upload to S3
    const uploadResult = await client.send(command);

    // Get SHA-256 checksum of the watermarked document
    const watermarkedDocumentChecksum = uploadResult.ChecksumSHA256;

    return {
      status: "success",
      message: "File uploaded successfully with watermark!",
      data: uploadResult,
      // Original and Watermarked documents key and checksum
      originalS3ObjectKey: originalDocumentName,
      originalS3Hash: firstDocumentChecksum,
      watermarkedS3ObjectKey: watermarkedDocumentName,
      watermarkedS3Hash: watermarkedDocumentChecksum,
    };
  } catch (error) {
    return {
      status: "failure",
      message: "Document upload failed",
    };
  }
};
