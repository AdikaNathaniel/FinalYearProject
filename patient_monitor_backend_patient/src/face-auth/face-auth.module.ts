import { Module } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';
import { FaceAuthController } from './face-auth.controller';
import { FaceAuthService } from './face-auth.service';
import { FaceAuth, FaceAuthSchema } from 'src/shared/schema/face-auth.schema';

@Module({
  imports: [
    MongooseModule.forFeature([{ name: FaceAuth.name, schema: FaceAuthSchema }]),
  ],
  controllers: [FaceAuthController],
  providers: [FaceAuthService],
  exports: [FaceAuthService],
})
export class FaceAuthModule {}