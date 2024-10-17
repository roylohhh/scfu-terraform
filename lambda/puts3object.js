import { S3Client, PutObjectCommand } from "@aws-sdk/client-s3";
import { PDFDocument, rgb, degrees } from "pdf-lib"; // Import pdf-lib
import { v4 as uuidv4 } from "uuid";

// Initialize the S3 Client
const client = new S3Client({
  region: "ap-southeast-2",
});

// Consent form bucket
const BUCKET_NAME = process.env.S3_BUCKET_NAME;

export const handler = async (event) => {
  try {
    return event;
    if (!event.formData || !event.scannedForm || !event.admin) {
      console.error("Error: Malformed JSON object");
      return {
        status: "failure",
        errors: "Malformed JSON object",
      };
    }

    const formData = event.formData;
    const scannedForm = event.scannedForm;
    const admin = event.admin;

    const { base64Data, fileName } = scannedForm;

    if (!base64Data || !fileName) {
      throw new Error("Missing required parameters: base64Data, fileName");
    }

    // Upload first document

    // Generate unique name for first document
    const originalDocumentName = `${uuidv4()}_${fileName}`;

    // Convert base64 to binary
    const existingPdfBytes = Buffer.from(base64Data, "base64");

    // Upload parameters
    const originalDocumentUploadParams = {
      Bucket: BUCKET_NAME,
      Key: originalDocumentName,
      Body: Buffer.from(existingPdfBytes),
      ContentType: "application/pdf",
      ChecksumAlgorithm: "SHA256",
    };

    // Create the PutObjectCommand for the first document
    const firstDocumentUploadCommand = new PutObjectCommand(
      originalDocumentUploadParams,
    );

    // Upload to S3
    const firstDocumentUploadResult = await client.send(
      firstDocumentUploadCommand,
    );

    // Get SHA-256 checksum of first uploaded document
    const firstDocumentChecksum = firstDocumentUploadResult.ChecksumSHA256;

    // Load the PDF with pdf-lib
    const pdfDoc = await PDFDocument.load(existingPdfBytes);

    const adminString =
      admin.name + " " + admin.familyName + "\t(" + admin.id + ")";
    const watermarkText = adminString + "\n" + firstDocumentChecksum;

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

    // Upload parameters
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

    // Get SHA-256 checksum of uploaded first document
    const watermarkedDocumentChecksum = uploadResult.ChecksumSHA256;

    return {
      statusCode: 200,
      body: JSON.stringify({
        message: "File uploaded successfully with watermark!",
        data: uploadResult,
        // Original and Watermarked documents key and checksum
        originalS3ObjectKey: originalDocumentName,
        originalS3Hash: firstDocumentChecksum,
        watermarkedS3ObjectKey: watermarkedDocumentName,
        watermarkedS3Hash: watermarkedDocumentChecksum,
      }),
    };

    // TODO replace return value with hash, new pdf, form data
    // TODO need to roll back in next function if something fails
  } catch (error) {
    console.error("Error:", error);
    return {
      status: "error",
      message: "Internal server error",
    };
  }
};
