import { Injectable, OnModuleInit } from '@nestjs/common';
import * as admin from 'firebase-admin';

@Injectable()
export class MessagingService implements OnModuleInit {
  private readonly token: string = 'YOUR_FCM_TOKEN'; // Replace with your FCM token

  constructor() {
    const serviceAccount = require('C:\\Users\\ACER\\Desktop\\SES\\L400-SEM1\\FIRST_SEM\\FinalYearProject\\Code\\patient_monitor_backend_patient\\service-account-file.json');

    admin.initializeApp({
      credential: admin.credential.cert(serviceAccount),
    });
  }

  onModuleInit() {
    this.startSendingNotifications();
  }

  private startSendingNotifications() {
    setInterval(async () => {
      const title = 'Automated Notification';
      const body = 'This notification is sent every 30 seconds.';
      await this.sendPushNotification(this.token, title, body);
    }, 30000); // 30 seconds
  }

  async sendPushNotification(token: string, title: string, body: string) {
    const message = {
      notification: {
        title: title,
        body: body,
      },
      token: token,
    };

    try {
      const response = await admin.messaging().send(message);
      console.log('Successfully sent message:', response);
      return response;
    } catch (error) {
      console.error('Error sending message:', error);
      throw new Error('Notification not sent');
    }
  }
}