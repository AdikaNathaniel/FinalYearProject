import { Injectable } from '@nestjs/common';
import Stripe from 'stripe';
import * as dotenv from 'dotenv';

dotenv.config();

// Initialize Stripe with your secret key from environment variables
const stripe = new Stripe(process.env.STRIPE_SECRET_KEY, { apiVersion: '2025-01-27.acacia' });

@Injectable()
export class PaymentsService {
  // Create a payment intent for processing the payment
  async createPaymentIntent(amount: number, currency: string) {
    try {
      // Create a PaymentIntent in Stripe (amount is in the smallest currency unit, e.g., cents)
      const paymentIntent = await stripe.paymentIntents.create({
        amount: amount * 100, // Convert to cents (for USD, 50 dollars = 5000 cents)
        currency,
        payment_method_types: ['card'], // Supports card payments
      });

      // Return both clientSecret and paymentIntentId so you can use them in frontend and backend
      return {
        clientSecret: paymentIntent.client_secret,  // Secret needed for frontend to complete payment
        paymentIntentId: paymentIntent.id,          // Payment intent ID to verify the payment later
      };
    } catch (error) {
      // Throw an error if there is an issue during payment intent creation
      throw new Error(`Stripe error: ${error.message}`);
    }
  }

  // Verify the payment status using the payment intent ID
  async verifyPayment(paymentIntentId: string) {
    try {
      // Retrieve the payment intent details from Stripe using the payment intent ID
      const paymentIntent = await stripe.paymentIntents.retrieve(paymentIntentId);

      // Check if the payment status is 'succeeded' (successful payment)
      if (paymentIntent.status === 'succeeded') {
        return { status: 'success', paymentIntent }; // Payment succeeded
      } else {
        return { status: 'pending', paymentIntent }; // Payment is still pending
      }
    } catch (error) {
      // Throw an error if there is an issue retrieving the payment intent
      throw new Error(`Stripe verification error: ${error.message}`);
    }
  }
}
