import { Module } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';
import { EmergencyController } from './emergency.controller';
import { EmergencyService } from './emergency.service';
import { Contact, ContactSchema } from 'src/shared/schema/contact.schema';
import { HttpModules } from 'src/shared/http/http.module';
// import { ConfigModule } from '../shared/config/config.module';
// import { HttpService } from '../shared/http/http.service';

@Module({
  imports: [
    MongooseModule.forFeature([{ name: Contact.name, schema: ContactSchema }]),
    HttpModules,
    
  ],
  controllers: [EmergencyController],
  providers: [EmergencyService],
})
export class EmergencyModule {}