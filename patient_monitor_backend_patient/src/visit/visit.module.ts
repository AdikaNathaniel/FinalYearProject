import { Module } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';
import { HttpModule } from '@nestjs/axios';
import { ScheduleModule } from '@nestjs/schedule';
import { PatientModule } from '../patient/patient.module';
import { SmsModule } from '../sms/sms.module';
import { VisitController } from './visit.controller';
import { VisitService } from './visit.service';
import { Visit, VisitSchema } from '../shared/schema/visit.schema';
import { Patient, PatientSchema } from '../shared/schema/patient.schema';
import { AntenatalVisitSmsService } from './antenatal-visit-sms.service';
import { SmsRecord, SmsRecordSchema } from '../shared/schema/sms-record.schema';

@Module({
  imports: [
    HttpModule,
    ScheduleModule,
    MongooseModule.forFeature([
      { name: Visit.name, schema: VisitSchema },
      { name: Patient.name, schema: PatientSchema },
      { name: SmsRecord.name, schema: SmsRecordSchema },
    ]),
    PatientModule,
    SmsModule,
  ],
  controllers: [VisitController],
  providers: [VisitService, AntenatalVisitSmsService],
})
export class VisitModule {}