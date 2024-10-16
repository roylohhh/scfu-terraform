const esbuild = require("esbuild");
const path = require("path");

async function buildLambda() {
  const functions = [
    {
      entry: path.join(__dirname, "putitem.js"),   // Correct path for putitem.js
      outfile: path.join(__dirname, "build", "putitem.js"),  // Output to build folder
    },
    {
      entry: path.join(__dirname, "puts3object.js"),  // Correct path for puts3object.js
      outfile: path.join(__dirname, "build", "puts3object.js"),  // Output to build folder
    },
    {
      entry: path.join(__dirname, "validateform.js"), // Correct path for validateform.js
      outfile: path.join(__dirname, "build", "validateform.js"), // Output to build folder
    }
  ];

  for (const func of functions) {
    await esbuild.build({
      entryPoints: [func.entry],
      bundle: true,
      platform: "node",
      target: "node20",
      external: [
        "@aws-sdk/client-s3",       // Exclude AWS SDK modules
        "@aws-sdk/lib-dynamodb",    // Exclude DynamoDB module
        "@aws-sdk/client-dynamodb"  // Exclude DynamoDB client
      ],
      outfile: func.outfile,
      minify: true,
    });
    console.log(`Built: ${func.entry} -> ${func.outfile}`);
  }
}

buildLambda().catch(() => process.exit(1));
