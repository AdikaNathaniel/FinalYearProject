import { Controller, Post, Body, Req, Res, Get, Query } from '@nestjs/common';
import { StripeService } from './stripe.service';
import { Request, Response } from 'express';

@Controller('stripe')
export class StripeController {
  constructor(private readonly stripeService: StripeService) {}

  // Create a checkout session
  @Post('create-checkout-session')
  async createCheckoutSession(
    @Body() body: { amount: number; email: string },
    @Res() res: Response,
  ) {
    try {
      const { amount, email } = body;

      // Call Stripe service to create checkout session
      const session = await this.stripeService.createCheckoutSession(amount, email);

      // Return the session URL to the frontend
      return res.json({ url: session.url });
    } catch (error) {
      return res.status(500).json({ error: 'Payment session creation failed' });
    }
  }

  // Create a Payment Intent (for manual payments)
  @Post('payment-intent')
  async createPaymentIntent(@Body() body: { amount: number; email: string }, @Res() res: Response) {
    try {
      const { amount, email } = body;

      // Call Stripe service to create a payment intent
      const paymentIntent = await this.stripeService.createPaymentIntent(amount, email);

      return res.json(paymentIntent);
    } catch (error) {
      return res.status(500).json({ error: 'Payment intent creation failed' });
    }
  }

  // Handle Stripe webhook (for payment success notification)
  @Post('webhook')
  async handleWebhook(@Req() req: Request, @Res() res: Response) {
    try {
      const payload = req.body;
      await this.stripeService.handleStripeWebhook(payload);
      return res.status(200).send({ message: 'Webhook received successfully' });
    } catch (error) {
      return res.status(400).json({ error: 'Error handling webhook' });
    }
  }

  // Handle payment success
  @Get('payment-success')
  async paymentSuccess(@Query('session_id') sessionId: string, @Res() res: Response) {
    console.log(`Payment successful! Session ID: ${sessionId}`);

    return res.json({ message: 'Payment successful!', session_id: sessionId });
  }

  // Handle payment cancellation
  @Get('payment-cancelled')
  async paymentCancelled(@Res() res: Response) {
    console.log('Payment was cancelled');

    return res.json({ message: 'Payment was cancelled' });
  }
}
