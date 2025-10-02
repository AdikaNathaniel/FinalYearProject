import { Injectable, PipeTransform } from '@nestjs/common';

@Injectable()
export class NormalizeVitalsPipe implements PipeTransform {
  transform(value: any) {
    return {
      glucose: value.glucose ?? value.g,
      systolicBP: value.systolicBP ?? value.s,
      diastolicBP: value.diastolicBP ?? value.d,
      heartRate: value.heartRate ?? value.h,
      spo2: value.spo2 ?? value.sp,
      skinTemp: value.skinTemp ?? value.sk,
      bodyTemp: value.bodyTemp ?? value.b,
      accelX: value.accelX ?? value.aclX,
      accelY: value.accelY ?? value.aclY,
      accelZ: value.accelZ ?? value.aclZ,
      gyroX: value.gyroX ?? value.gyX,
      gyroY: value.gyroY ?? value.gyY,
      gyroZ: value.gyroZ ?? value.gyZ,
      proteinLevel: value.proteinLevel ?? value.p, // optional
    };
  }
}
