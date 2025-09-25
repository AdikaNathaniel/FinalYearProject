import { Injectable } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model } from 'mongoose';
import { PreeclampsiaVitals } from 'src/shared/schema/preeclampsia-vitals.schema';
import { CreatePreeclampsiaVitalsDto } from 'src/users/dto/create-preeclampsia-vitals.dto';
import { UpdatePreeclampsiaVitalsDto } from 'src/users/dto/update-preeclampsia-vitals.dto';
import { PreeclampsiaVitalsResponseDto } from 'src/users/dto/preeclampsia-vitals-response.dto';

@Injectable()
export class PreeclampsiaVitalsService {
  constructor(
    @InjectModel(PreeclampsiaVitals.name) 
    private preeclampsiaVitalsModel: Model<PreeclampsiaVitals>
  ) {}

  private calculateMAP(systolicBP: number, diastolicBP: number): number {
    return (systolicBP + 2 * diastolicBP) / 3;
  }

  private determineStatus(map: number, proteinUrine: number): string {
    if (proteinUrine < 2) {
      return 'no_preeclampsia';
    } else if (map >= 130) {
      return 'severe preeclampsia';
    } else if (map >= 125 && map <= 129) {
      return 'moderate preeclampsia';
    } else if (map >= 114 && map <= 124) {
      return 'mild preeclampsia';
    } else {
      return 'no_preeclampsia';
    }
  }

  async create(
    createPreeclampsiaVitalsDto: CreatePreeclampsiaVitalsDto
  ): Promise<PreeclampsiaVitalsResponseDto> {
    const map = this.calculateMAP(
      createPreeclampsiaVitalsDto.systolicBP,
      createPreeclampsiaVitalsDto.diastolicBP,
    );
    const status = this.determineStatus(map, createPreeclampsiaVitalsDto.proteinUrine);

    const createdPreeclampsiaVitals = new this.preeclampsiaVitalsModel({
      ...createPreeclampsiaVitalsDto,
      map,
      status,
    });

    const savedPreeclampsiaVitals = await createdPreeclampsiaVitals.save();
    return this.mapToResponseDto(savedPreeclampsiaVitals);
  }

  async findAll(): Promise<PreeclampsiaVitalsResponseDto[]> {
    const preeclampsiaVitals = await this.preeclampsiaVitalsModel.find().exec();
    return preeclampsiaVitals.map(this.mapToResponseDto);
  }

  async findByPatientId(patientId: string): Promise<PreeclampsiaVitalsResponseDto[]> {
    const preeclampsiaVitals = await this.preeclampsiaVitalsModel.find({ patientId }).exec();
    return preeclampsiaVitals.map(this.mapToResponseDto);
  }

  async update(
    patientId: string,
    updatePreeclampsiaVitalsDto: UpdatePreeclampsiaVitalsDto,
  ): Promise<PreeclampsiaVitalsResponseDto> {
    let updateFields: any = { ...updatePreeclampsiaVitalsDto };

    // Recalculate MAP and status if BP values are updated
    if (updatePreeclampsiaVitalsDto.systolicBP || updatePreeclampsiaVitalsDto.diastolicBP) {
      const existing = await this.preeclampsiaVitalsModel.findOne({ patientId }).exec();
      const systolicBP = updatePreeclampsiaVitalsDto.systolicBP || existing.systolicBP;
      const diastolicBP = updatePreeclampsiaVitalsDto.diastolicBP || existing.diastolicBP;
      const proteinUrine = updatePreeclampsiaVitalsDto.proteinUrine || existing.proteinUrine;

      updateFields.map = this.calculateMAP(systolicBP, diastolicBP);
      updateFields.status = this.determineStatus(updateFields.map, proteinUrine);
    } else if (updatePreeclampsiaVitalsDto.proteinUrine) {
      const existing = await this.preeclampsiaVitalsModel.findOne({ patientId }).exec();
      updateFields.status = this.determineStatus(
        existing.map,
        updatePreeclampsiaVitalsDto.proteinUrine,
      );
    }

    const updatedPreeclampsiaVitals = await this.preeclampsiaVitalsModel
      .findOneAndUpdate({ patientId }, updateFields, { new: true })
      .exec();

    return this.mapToResponseDto(updatedPreeclampsiaVitals);
  }

  async deleteByPatientId(patientId: string): Promise<void> {
    await this.preeclampsiaVitalsModel.deleteMany({ patientId }).exec();
  }

  private mapToResponseDto(
    preeclampsiaVitals: PreeclampsiaVitals
  ): PreeclampsiaVitalsResponseDto {
    return {
      patientId: preeclampsiaVitals.patientId,
      systolicBP: preeclampsiaVitals.systolicBP,
      diastolicBP: preeclampsiaVitals.diastolicBP,
      proteinUrine: preeclampsiaVitals.proteinUrine,
      map: preeclampsiaVitals.map,
      status: preeclampsiaVitals.status,
      createdAt: preeclampsiaVitals.createdAt,
      updatedAt: preeclampsiaVitals.updatedAt,
    };
  }
}