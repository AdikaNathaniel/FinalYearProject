import { Injectable } from '@nestjs/common';
import * as nodemailer from 'nodemailer';

@Injectable()
export class EmailService {
  private transporter;

  // constructor() {
  //   this.transporter = nodemailer.createTransport({
  //     host: process.env.SMTP_HOST,
  //     port: parseInt(process.env.SMTP_PORT),
  //     secure: false,
  //     auth: {
  //       user: process.env.SMTP_USER,
  //       pass: process.env.SMTP_PASS,
  //     },
  //     connectionTimeout: 10000, // 10 seconds
  //     greetingTimeout: 10000, // 10 seconds
  //     socketTimeout: 10000,
  //   });
  // }



  constructor() {
  console.log("SMTP Configuration:", {
    host: process.env.SMTP_HOST,
    port: parseInt(process.env.SMTP_PORT),
    user: process.env.SMTP_USER,
    pass: process.env.SMTP_PASS ? "******" : "NOT SET", // Don't log the actual password
  });
  
  this.transporter = nodemailer.createTransport({
    host: process.env.SMTP_HOST,
    port: parseInt(process.env.SMTP_PORT),
    secure: true,
    auth: {
      user: process.env.SMTP_USER,
      pass: process.env.SMTP_PASS,
    },
    connectionTimeout: 10000,
    greetingTimeout: 10000,
    socketTimeout: 10000,
  });
}

  // async sendOTPEmail(email: string, otp: string) {
  //   const mailOptions = {
  //     from: process.env.SMTP_USER,
  //     to: email,
  //     subject: 'Your OTP Verification Code',
  //     html: `
  //       <h1>OTP Verification</h1>
  //       <p>Your OTP code is: <strong>${otp}</strong></p>
  //       <p>This code will expire in 10 minutes.</p>
  //     `,
  //   };

  //   try {
  //     await this.transporter.sendMail(mailOptions);
  //     return { success: true, message: 'OTP sent successfully' };
  //   } catch (error) {
  //     return { success: false, message: error.message };
  //   }
  // }



  async sendOTPEmail(email: string, otp: string) {
  const mailOptions = {
    from: process.env.SMTP_USER,
    to: email,
    subject: 'Your OTP Verification Code',
    html: `
      <h1>OTP Verification</h1>
      <p>Your OTP code is: <strong>${otp}</strong></p>
      <p>This code will expire in 10 minutes.</p>
    `,
  };
  
  try {
    console.log(`Attempting to send OTP email to ${email}`);
    const info = await this.transporter.sendMail(mailOptions);
    console.log(`Email sent successfully: ${info.messageId}`);
    return { success: true, message: 'OTP sent successfully', messageId: info.messageId };
  } catch (error) {
    console.error("Failed to send email:", error);
    return { success: false, message: error.message };
  }
}


  // In your email.service.ts, add this after creating the transporter
async onModuleInit() {
  try {
    console.log("Verifying email connection...");
    await this.transporter.verify();
    console.log("Email service is ready to send emails");
  } catch (error) {
    console.error("Failed to connect to email server:", error);
    // You might want to throw an error here to prevent the app from starting
  }
}



  async sendForgotPasswordEmail(email: string, newPassword: string) {
    const mailOptions = {
      from: process.env.SMTP_USER,
      to: email,
      subject: 'Your New Password',
      html: `
        <h1>Password Reset</h1>
        <p>Your new password is: <strong>${newPassword}</strong></p>
        <p>Please change your password on the settings Page after logging in.</p>
      `,
    };

    try {
      await this.transporter.sendMail(mailOptions);
      return { success: true, message: 'New password sent successfully' };
    } catch (error) {
      console.error('Email sending error:', error);
      return { success: false, message: error.message };
    }
  }
}