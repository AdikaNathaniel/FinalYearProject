import { Injectable, BadRequestException } from '@nestjs/common';
import Stripe from 'stripe';

@Injectable()
export class StripeService {
  private stripe: Stripe;

  constructor() {
    this.stripe = new Stripe('sk_test_51Ql8Us4GUh5P0VNW3tFukM02hwvCQFoaLXGFbN1Vrlqzqa2z2McmymCVcADCyAB74cJxVxGCy2hacOdABCuaGrRS00R32nWOIQ', {
      apiVersion: '2025-01-27.acacia', // Ensure to use the correct API version
    });
  }

  // Create a checkout session
  async createCheckoutSession(amount: number, email: string) {
    try {
      const session = await this.stripe.checkout.sessions.create({
        payment_method_types: ['card'],
        line_items: [
          {
            price_data: {
              currency: 'usd',
              product_data: {
                name: 'Product Name', // You can dynamically set this based on your product
              },
              unit_amount: amount, // Amount in cents (e.g., $10 would be 1000)
            },
            quantity: 1, // Quantity of the product
          },
        ],
        mode: 'payment',
        success_url: 'http://localhost:3100/api/v1/payment-success?session_id={CHECKOUT_SESSION_ID}',
        cancel_url: 'http://localhost:3000/api/v1/payment-cancelled',
        customer_email: email,
      });

      return session;
    } catch (error) {
      throw new BadRequestException('Error creating checkout session', error.message);
    }
  }

  // Create a Payment Intent
  async createPaymentIntent(amount: number, email: string) {
    try {
      const paymentIntent = await this.stripe.paymentIntents.create({
        amount, // Amount in cents
        currency: 'usd',
        payment_method_types: ['card'],
        receipt_email: email,
      });

      return paymentIntent;
    } catch (error) {
      throw new BadRequestException('Error creating payment intent', error.message);
    }
  }

  // Webhook handler for Stripe events
  async handleStripeWebhook(payload: any) {
    try {
      const sig = payload.headers['stripe-signature'];
      const event = this.stripe.webhooks.constructEvent(payload.body, sig, 'your_stripe_webhook_secret');

      // Handle the event
      switch (event.type) {
        case 'checkout.session.completed':
          // Handle successful payment, mark order as paid in your database
          const session = event.data.object;
          console.log(`Payment for session ${session.id} was successful!`);
          break;

        case 'payment_intent.succeeded':
          // Handle successful Payment Intent
          const paymentIntent = event.data.object;
          console.log(`PaymentIntent ${paymentIntent.id} succeeded!`);
          break;

        case 'payment_intent.payment_failed':
          // Handle failed Payment Intent
          console.log(`PaymentIntent failed: ${event.data.object.last_payment_error?.message}`);
          break;

        default:
          console.warn(`Unhandled event type: ${event.type}`);
      }

      return { received: true };
    } catch (error) {
      throw new BadRequestException('Error handling webhook', error.message);
    }
  }
}
