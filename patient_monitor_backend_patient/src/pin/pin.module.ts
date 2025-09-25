
import { Module } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';
import { PinController } from './pin.controller';
import { PinService } from './pin.service';
import { Pin, PinSchema } from 'src/shared/schema/pin.schema';
import { AntenatalVisitSmsService } from 'src/visit/antenatal-visit-sms.service';
import { HttpModule } from '@nestjs/axios';
import { SmsModule } from 'src/sms/sms.module';
import { SmsRecord, SmsRecordSchema } from 'src/shared/schema/sms-record.schema';

@Module({
  imports: [
    MongooseModule.forFeature([
      { name: Pin.name, schema: PinSchema },
      { name: SmsRecord.name, schema: SmsRecordSchema }
    ]),
    HttpModule,
    SmsModule
  ],
  controllers: [PinController],
  providers: [PinService, AntenatalVisitSmsService],
  exports: [PinService],
})
export class PinModule {}