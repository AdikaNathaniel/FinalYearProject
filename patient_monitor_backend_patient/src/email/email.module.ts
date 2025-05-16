import { Module } from '@nestjs/common';
import { EmailService } from './email.service'; // Adjust the path as necessary

@Module({
  providers: [EmailService],
  exports: [EmailService], // Ensure EmailService is exported
})
export class EmailModule {}