import { onCall, HttpsError } from "firebase-functions/v2/https";
import * as logger from "firebase-functions/logger";
import * as admin from "firebase-admin";
import * as nodemailer from "nodemailer";

admin.initializeApp();

// Config mail transporter
const transporter = nodemailer.createTransport({
  service: "gmail",
  auth: {
    user: "quzkhanh@gmail.com",
    pass: "rjns vvft iivk wxni",
  },
});

export const requestPasswordResetOtp = onCall(async (request) => {
  const email = request.data.email;
  if (!email || typeof email !== "string") {
    throw new HttpsError("invalid-argument", "The function must be called with one argument 'email' containing the email address to reset.");
  }

  try {
    // Check if user exists first
    await admin.auth().getUserByEmail(email);

    // Generate 6 digit OTP
    const otp = Math.floor(100000 + Math.random() * 900000).toString();
    const expiresAt = Date.now() + 5 * 60 * 1000; // 5 minutes

    // Save to Firestore
    await admin.firestore().collection("password_reset_otps").doc(email).set({
      otp: otp,
      expiresAt: expiresAt,
    });

    // Send Email
    const mailOptions = {
      from: "Smart Garden <quzkhanh@gmail.com>",
      to: email,
      subject: "Your Smart Garden Password Reset OTP",
      text: `Your password reset code is: ${otp}. It will expire in 5 minutes.`,
      html: `<h2>Smart Garden Password Reset</h2><p>Your verification code is: <strong>${otp}</strong></p><p>This code will expire in 5 minutes.</p>`,
    };

    await transporter.sendMail(mailOptions);
    logger.info(`OTP sent to ${email}`);

    return { success: true };
  } catch (error: any) {
    logger.error("Error sending OTP", error);
    if (error.code === "auth/user-not-found") {
      throw new HttpsError("not-found", "User not found with this email.");
    }
    throw new HttpsError("internal", "Unable to send OTP at this time.");
  }
});

export const verifyOtpAndResetPassword = onCall(async (request) => {
  const { email, otp, newPassword } = request.data;
  
  if (!email || !otp || !newPassword) {
    throw new HttpsError("invalid-argument", "Missing required fields: email, otp, newPassword.");
  }

  if (newPassword.length < 6) {
    throw new HttpsError("invalid-argument", "Password must be at least 6 characters.");
  }

  try {
    const docRef = admin.firestore().collection("password_reset_otps").doc(email);
    const docSnap = await docRef.get();

    if (!docSnap.exists) {
      throw new HttpsError("not-found", "No pending password reset found for this email.");
    }

    const data = docSnap.data();
    if (data?.otp !== otp) {
      throw new HttpsError("unauthenticated", "Invalid OTP.");
    }

    if (Date.now() > data?.expiresAt) {
      await docRef.delete();
      throw new HttpsError("deadline-exceeded", "OTP has expired.");
    }

    // OTP is valid, get user and update password
    const user = await admin.auth().getUserByEmail(email);
    await admin.auth().updateUser(user.uid, { password: newPassword });

    // Clean up OTP
    await docRef.delete();
    
    logger.info(`Password successfully reset for ${email}`);
    
    return { success: true };
  } catch (error: any) {
    logger.error("Error resetting password", error);
    if (error instanceof HttpsError) {
      throw error;
    }
    throw new HttpsError("internal", "An error occurred while resetting the password.");
  }
});
