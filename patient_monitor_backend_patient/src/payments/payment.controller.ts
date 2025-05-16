import { Controller, Post, Body } from '@nestjs/common';
import { PaymentsService } from 'src/payments/payment.service';

@Controller('payments/stripe')
export class PaymentsController {
  constructor(private readonly paymentsService: PaymentsService) {}

  // Endpoint to initiate the payment (create PaymentIntent)
  @Post('initiate')
  async initiatePayment(@Body() body: { amount: number; currency: string }) {
    const { amount, currency } = body;

    try {
      // Call the PaymentsService to create a PaymentIntent
      const paymentData = await this.paymentsService.createPaymentIntent(amount, currency);

      // Return both clientSecret and paymentIntentId to the client
      return {
        status: 'success',
        data: paymentData,  // Contains both clientSecret and paymentIntentId
      };
    } catch (error) {
      return {
        status: 'error',
        message: error.message,
      };
    }
  }

  // Endpoint to verify the payment
  @Post('verify')
  async verifyPayment(@Body() body: { paymentIntentId: string }) {
    const { paymentIntentId } = body;

    try {
      // Call the PaymentsService to verify the payment
      const verificationResult = await this.paymentsService.verifyPayment(paymentIntentId);

      // Return the status of the payment (success or pending)
      return {
        status: 'success',
        data: verificationResult, // Contains payment status and details
      };
    } catch (error) {
      return {
        status: 'error',
        message: error.message,
      };
    }
  }
}
