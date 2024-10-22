const emailRegex = /^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$/;
const contactNumberRegex = /^(02|03|04|07|08)\d{8}$/;
const stateRegex = /^(NSW|VIC|QLD|WA|SA|TAS|ACT|NT)$/;
const postcodeRegex = /^\d{4}$/; // Added for postcode validation
const pdfSignature = [0x25, 0x50, 0x44, 0x46]; // Magic number for PDFs

function isBase64PDF(base64Data) {
  // Decode the base64 data to a byte array and remove prefix, if present
  const base64String = base64Data.split(",")[1] || base64Data;

  // Decode base64 to a byte array using Buffer in Node.js
  const byteArray = Buffer.from(base64String, "base64");

  // Check the first four bytes for the PDF file signature
  for (let i = 0; i < pdfSignature.length; i++) {
    if (byteArray[i] !== pdfSignature[i]) {
      return false;
    }
  }

  return true;
}

const validateRegexField = (value, regex, fieldName) => {
  if (!regex.test(value)) {
    return `Invalid ${fieldName}`;
  }
  return null;
};

// Local validation functions
const validateFirstName = (firstName) => {
  if (!firstName) {
    return "First Name is required.";
  }
  if (firstName.length > 50) {
    return "First Name should not exceed 50 characters.";
  }
  return validateRegexField(firstName, /^[a-zA-Z]+$/, "First Name");
};

const validateLastName = (lastName) => {
  if (!lastName) {
    return "Last Name is required.";
  }
  if (lastName.length > 50) {
    return "Last Name should not exceed 50 characters.";
  }
  return validateRegexField(lastName, /^[a-zA-Z]+$/, "Last Name");
};

const validateDateOfBirth = (dob) => {
  if (!dob) {
    return "Date of Birth is required.";
  }

  const [day, month, year] = dob.split("-").map(Number);
  const date = new Date(year, month - 1, day);
  const now = new Date();
  const minDate = new Date(1900, 0, 1);

  // Check if the date is valid
  if (
    date.getFullYear() !== year ||
    date.getMonth() !== month - 1 ||
    date.getDate() !== day
  ) {
    return "Invalid date of birth.";
  }

  if (date >= now) {
    return "Date of Birth cannot be in the future.";
  }

  if (date < minDate) {
    return "Date of Birth cannot be earlier than January 1, 1900.";
  }

  return null;
};

const validateEmail = (email) => {
  if (!email) {
    return "Email Address is required.";
  }
  return validateRegexField(email, emailRegex, "Email Address");
};

const validatePhoneNumber = (phone) => {
  if (!phone) {
    return "Phone Number is required.";
  }
  return validateRegexField(phone, contactNumberRegex, "Phone Number");
};

const validateStreetAddress = (streetAddress) => {
  if (!streetAddress) {
    return "Street Address is required.";
  }
  return null;
};

const validateSuburb = (suburb) => {
  if (!suburb) {
    return "Suburb is required.";
  }
  return null;
};

const validateState = (state) => {
  if (!state) {
    return "State/Territory is required.";
  }
  return validateRegexField(state, stateRegex, "State/Territory");
};

const validatePostcode = (postcode) => {
  if (!postcode) {
    return "Postcode is required.";
  }
  return validateRegexField(postcode, postcodeRegex, "Postcode");
};

// This validation just confirms that a boolean was provided in the object
const validateIsMinor = (isMinor) => {
  if (isMinor !== true && isMinor !== false) {
    return "Minor status is required.";
  }
  return null;
};

const validateGuardianName = (guardianName, isMinor) => {
  if (!isMinor) {
    return null;
  }
  if (!guardianName) {
    return "Guardian's Name is required.";
  }
  return validateRegexField(guardianName, /^[a-zA-Z\s]+$/, "Guardian's Name");
};

const validateGuardianPhoneNumber = (guardianPhone, isMinor) => {
  if (!isMinor) {
    return null;
  }
  if (!guardianPhone) {
    return "Guardian's Phone Number is required.";
  }
  return validateRegexField(
    guardianPhone,
    contactNumberRegex,
    "Guardian's Phone Number",
  );
};

const validateStudyGroup = (studyGroup) => {
  if (!studyGroup) {
    return "Please select a study group.";
  }
  return null;
};

const validateStudyInterest = (studyInterest) => {
  if (!studyInterest) {
    return "Please select your area of interest in the study.";
  }
  return null;
};

const validateHealthConditions = (healthConditions) => {
  if (healthConditions && healthConditions.length > 500) {
    return "Health conditions should not exceed 500 characters.";
  }
  return null;
};

// This validation just confirms that a boolean was provided in the object
const validateContactConsent = (contactConsent) => {
  if (contactConsent !== true && contactConsent !== false) {
    return "Contact Consent is required.";
  }
  return null;
};

// This validation just confirms that a boolean was provided in the object
const validateMediaConsent = (mediaConsent) => {
  if (mediaConsent !== true && mediaConsent !== false) {
    return "Media Consent is required.";
  }
  return null;
};

// Scanned document object validations
const validateScannedForm = (scannedForm) => {
  if (!scannedForm) {
    return "Scanned Form is required.";
  }
  if (!isBase64PDF(scannedForm)) {
    return "Form must be PDF document.";
  }
  return null;
};

const validateScannedFormFileName = (fileName) => {
  if (!fileName || fileName.trim() === "") {
    return "Scanned document file name is required.";
  }
  return null;
};

// Admin object validations
const validateAdminId = (adminId) => {
  if (!adminId || adminId.trim() === "") {
    return "Admin id is required.";
  }
  return null;
};

const validateAdminName = (adminName) => {
  if (!adminName || adminName.trim() === "") {
    return "Admin first name is required.";
  }
  return null;
};

const validateAdminFamilyName = (adminFamilyName) => {
  if (!adminFamilyName || adminFamilyName.trim() === "") {
    return "Admin family name is required.";
  }
  return null;
};

export const handler = async (event) => {
  try {
    // if (!event.payload || !event.payload.formData || !event.payload.scannedForm || !event.payload.admin) {
    if (!event.formData || !event.scannedForm || !event.admin) {
      console.error("Error: Malformed JSON object");
      return {
        status: "failure",
        errors: "Malformed JSON object",
      };
    }

    // Create timestamp for operation
    const timeStamp = new Date();

    // Parse the form data from the event
    const formData = event.formData;
    const scannedForm = event.scannedForm;
    const admin = event.admin;
    const errors = {};

    // Array of validation functions and their corresponding field names
    const formDataValidations = [
      { field: "firstName", validate: validateFirstName },
      { field: "lastName", validate: validateLastName },
      { field: "dateOfBirth", validate: validateDateOfBirth },
      { field: "email", validate: validateEmail },
      { field: "contactNumber", validate: validatePhoneNumber },
      { field: "streetAddress", validate: validateStreetAddress },
      { field: "suburb", validate: validateSuburb },
      { field: "state", validate: validateState },
      { field: "postcode", validate: validatePostcode },
      { field: "isMinor", validate: validateIsMinor },
      // These two fields are dependant on the minor status
      {
        field: "guardianName",
        validate: (value) => validateGuardianName(value, formData.isMinor),
      },
      {
        field: "guardianPhone",
        validate: (value) =>
          validateGuardianPhoneNumber(value, formData.isMinor),
      },
      { field: "studyGroup", validate: validateStudyGroup },
      { field: "studyInterest", validate: validateStudyInterest },
      { field: "healthConditions", validate: validateHealthConditions },
      { field: "contactConsent", validate: validateContactConsent },
      { field: "mediaConsent", validate: validateMediaConsent },
    ];

    const formValidations = [
      { field: "base64Data", validate: validateScannedForm },
      { field: "fileName", validate: validateScannedFormFileName },
    ];

    // These validations will check that these fields are non-empty
    const adminValidations = [
      { field: "id", validate: validateAdminId },
      { field: "name", validate: validateAdminName },
      { field: "familyName", validate: validateAdminFamilyName },
    ];

    // Iterate through validations
    for (const { field, validate } of formDataValidations) {
      const error = validate(formData[field]);
      if (error) {
        // Collect form errors in an array
        errors[field] = error;
      }
    }

    for (const { field, validate } of adminValidations) {
      const error = validate(admin[field]);
      if (error) {
        // Collect admin object errors in an array
        errors[field] = error;
      }
    }

    // If there are validation errors, return them
    if (Object.keys(errors).length > 0) {
      return {
        status: "failure",
        errors: errors,
      };
    }

    // If all fields are valid
    return {
      status: "success",
      message: "All fields are valid",
      timeStamp: timeStamp,
    };
  } catch (error) {
    console.error("Error:", error);
    // Non-validation related error
    return {
      status: "error",
      message: "Internal server error",
    };
  }
};

module.exports = { handler };
