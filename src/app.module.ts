import { Module } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';
import { AppController } from './app.controller';
import { AppService } from './app.service';
import config from 'config';
import { UsersModule } from './users/users.module';
// import { ElasticsearchConfigModule } from './products/elastic.module';
import { OrderModule } from './orders/orders.module';
import { PaymentsModule } from './payments/payments.module';
import { StripeModule } from './payments/stripe.module';
import { TopChartsModule } from 'src/topchart/top-chart.module';
import { FavoriteModule } from 'src/favorite/favorite.module';
import { TrackingModule } from 'src/tracking/tracking.module';

import { MQService } from 'src/delivery/mq.service';
// Import ChatModule and Chat schema
import { Chat, ChatSchema } from 'src/shared/schema/chat.schema';
import { ChatModule } from './chat/chat.module';
// Import EmailModule and NotificationModule
import { EmailModule } from 'src/email/email.module'; // Adjust the path as necessary
import { NotificationModule } from 'src/notification/notification.module'; // Adjust the path as necessary

@Module({
  imports: [
    MongooseModule.forRoot(config.get('mongoDbUrl'), {
      w: 1,
      retryWrites: true,
      maxPoolSize: 10,
    }),
    UsersModule,
    // ElasticsearchConfigModule,
    OrderModule,
    PaymentsModule,
    StripeModule,
    TopChartsModule,
    FavoriteModule,
    TrackingModule,
    ChatModule, // Add ChatModule here
    MongooseModule.forFeature([{ name: Chat.name, schema: ChatSchema }]), // Add Chat Schema if needed
    EmailModule, // Add EmailModule here
    NotificationModule, // Add NotificationModule here
  ],
  controllers: [AppController], // Add DeliveryController
  providers: [AppService, MQService], // Add DeliveryService and MQService
})
export class AppModule {}
