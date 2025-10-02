import { Injectable, NotFoundException, BadRequestException } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model, Types } from 'mongoose';
import { RiskAssessment } from 'src/shared/schema/risk-assessment.schema';
import { PredictRiskDto } from 'src/users/dto/predict-risk.dto';
import { RiskResultDto } from 'src/users/dto/risk-result.dto';

@Injectable()
export class AnaemiaRiskService {
  // Updated feature weights (as specified)
  private readonly weights = {
    excessiveVomiting: 1,
    diarrhea: 1,
    historyHeavyMenstrualFlow: 6,
    infections: 3,
    chronicDisease: 3,
    familyHistory: 3,
    bmiLow: 2, // encoded as 1 if BMI < 18.5, else 0
    shortInterpregnancyInterval: 4,
    multiplePregnancy: 4,
    age35OrLess: 1, // encoded as 1 if age <= 35, else 0
    poverty: 2,
    lackOfAccessHealthcare: 1,
    education: 2,
  };

  // Risk thresholds (normalized percentage)
  private readonly thresholds = {
    lowLt: 45.0,   // <45% = Low
    mildLt: 55.0,  // 45–<55% = Mild
    modLt: 70.0,   // 55–<70% = Moderate
    // >=70% = High
  };

  constructor(
    @InjectModel(RiskAssessment.name)
    private readonly riskAssessmentModel: Model<RiskAssessment>,
  ) {}

  private computeBmi(weightKg: number, heightInput: number): number {
    // If height > 3, interpret as centimeters and convert to meters
    const heightM = heightInput > 3 ? heightInput / 100 : heightInput;
    if (heightM <= 0) {
      throw new BadRequestException('Height must be positive.');
    }
    return weightKg / (heightM ** 2);
  }

  private categorizeRisk(scorePct: number): string {
    if (scorePct < this.thresholds.lowLt) {
      return 'Low';
    } else if (scorePct < this.thresholds.mildLt) {
      return 'Mild';
    } else if (scorePct < this.thresholds.modLt) {
      return 'Moderate';
    } else {
      return 'High';
    }
  }

  private validatePatientId(patientId: string): void {
    if (!patientId || patientId.trim() === '') {
      throw new BadRequestException('Patient ID is required');
    }
  }

  async predictRisk(predictRiskDto: PredictRiskDto): Promise<RiskResultDto> {
    // Validate patient ID
    this.validatePatientId(predictRiskDto.patientId);

    // Check if this patient already has a recent assessment
    await this.checkForRecentAssessment(predictRiskDto.patientId);

    // Calculate BMI and encode flags
    const bmiValue = this.computeBmi(predictRiskDto.weight, predictRiskDto.height);
    const bmiFlag = bmiValue < 18.5 ? 1 : 0;
    const ageFlag = predictRiskDto.age <= 35 ? 1 : 0;

    // Prepare feature values
    const featureValues = {
      excessiveVomiting: predictRiskDto.excessiveVomiting ? 1 : 0,
      diarrhea: predictRiskDto.diarrhea ? 1 : 0,
      historyHeavyMenstrualFlow: predictRiskDto.historyHeavyMenstrualFlow ? 1 : 0,
      infections: predictRiskDto.infections ? 1 : 0,
      chronicDisease: predictRiskDto.chronicDisease ? 1 : 0,
      familyHistory: predictRiskDto.familyHistory ? 1 : 0,
      bmiLow: bmiFlag,
      shortInterpregnancyInterval: predictRiskDto.shortInterpregnancyInterval ? 1 : 0,
      multiplePregnancy: predictRiskDto.multiplePregnancy ? 1 : 0,
      age35OrLess: ageFlag,
      poverty: predictRiskDto.poverty ? 1 : 0,
      lackOfAccessHealthcare: predictRiskDto.lackOfAccessHealthcare ? 1 : 0,
      education: predictRiskDto.education ? 1 : 0,
    };

    // Calculate total possible weight
    const totalWeight = Object.values(this.weights).reduce((sum, weight) => sum + weight, 0);
    const unitPct = 100.0 / totalWeight;

    // Calculate raw weighted sum and percentage
    let rawWeighted = 0;
    const featureContributions = {};

    for (const [feature, weight] of Object.entries(this.weights)) {
      const value = featureValues[feature];
      const contribution = value * weight;
      rawWeighted += contribution;
      featureContributions[feature] = {
        input: value,
        weight: weight,
        contribution: contribution * unitPct
      };
    }

    const scorePct = (rawWeighted / totalWeight) * 100.0;
    const riskClass = this.categorizeRisk(scorePct);

    // Save to database with feature contributions
    const riskAssessment = new this.riskAssessmentModel({
      patientId: predictRiskDto.patientId,
      ...featureValues,
      bmiValue,
      calculatedRisk: scorePct,
      riskClass,
      featureContributions, // Store feature contributions
      rawScore: rawWeighted, // Store raw score
      encodedAge: ageFlag, // Store encoded age
      createdAt: new Date(),
    });

    try {
      await riskAssessment.save();
    } catch (error) {
      throw new BadRequestException(`Failed to save risk assessment: ${error.message}`);
    }

    // Return result
    return {
      patientId: predictRiskDto.patientId,
      probability: scorePct,
      riskClass,
      rawScore: rawWeighted,
      featureContributions,
      bmiValue,
      encodedAge: ageFlag,
    };
  }

  private async checkForRecentAssessment(patientId: string): Promise<void> {
    // Check if patient has an assessment in the last 24 hours
    const twentyFourHoursAgo = new Date(Date.now() - 24 * 60 * 60 * 1000);
    
    const recentAssessment = await this.riskAssessmentModel.findOne({
      patientId: patientId,
      createdAt: { $gte: twentyFourHoursAgo }
    });

    if (recentAssessment) {
      throw new BadRequestException(
        `Patient already has a risk assessment from ${recentAssessment.createdAt.toLocaleString()}. Please wait 24 hours before creating a new assessment.`
      );
    }
  }

  async getRiskAssessments(): Promise<any[]> {
    const assessments = await this.riskAssessmentModel.find().exec();
    return assessments.map(assessment => this.formatAssessmentResponse(assessment));
  }

  async getRiskAssessmentsByPatientId(patientId: string): Promise<any[]> {
    this.validatePatientId(patientId);
    const assessments = await this.riskAssessmentModel
      .find({ patientId: patientId })
      .sort({ createdAt: -1 })
      .exec();
    
    return assessments.map(assessment => this.formatAssessmentResponse(assessment));
  }

  async getLatestRiskAssessmentByPatientId(patientId: string): Promise<any> {
    this.validatePatientId(patientId);
    const assessment = await this.riskAssessmentModel
      .findOne({ patientId: patientId })
      .sort({ createdAt: -1 })
      .exec();
    
    return assessment ? this.formatAssessmentResponse(assessment) : null;
  }

  async getRiskAssessmentById(assessmentId: string): Promise<any> {
    if (!Types.ObjectId.isValid(assessmentId)) {
      throw new BadRequestException('Invalid assessment ID format');
    }

    const assessment = await this.riskAssessmentModel.findById(assessmentId).exec();
    
    if (!assessment) {
      throw new NotFoundException(`Risk assessment with ID ${assessmentId} not found`);
    }

    return this.formatAssessmentResponse(assessment);
  }

  private formatAssessmentResponse(assessment: any): any {
    return {
      patientId: assessment.patientId,
      probability: assessment.calculatedRisk,
      riskClass: assessment.riskClass,
      rawScore: assessment.rawScore,
      featureContributions: assessment.featureContributions,
      bmiValue: assessment.bmiValue,
      encodedAge: assessment.encodedAge,
      createdAt: assessment.createdAt,
      // Include all feature values for completeness
      excessiveVomiting: assessment.excessiveVomiting,
      diarrhea: assessment.diarrhea,
      historyHeavyMenstrualFlow: assessment.historyHeavyMenstrualFlow,
      infections: assessment.infections,
      chronicDisease: assessment.chronicDisease,
      familyHistory: assessment.familyHistory,
      bmiLow: assessment.bmiLow,
      shortInterpregnancyInterval: assessment.shortInterpregnancyInterval,
      multiplePregnancy: assessment.multiplePregnancy,
      age35OrLess: assessment.age35OrLess,
      poverty: assessment.poverty,
      lackOfAccessHealthcare: assessment.lackOfAccessHealthcare,
      education: assessment.education
    };
  }

  async deleteRiskAssessment(assessmentId: string): Promise<void> {
    if (!Types.ObjectId.isValid(assessmentId)) {
      throw new BadRequestException('Invalid assessment ID format');
    }

    const result = await this.riskAssessmentModel.deleteOne({ _id: assessmentId }).exec();
    
    if (result.deletedCount === 0) {
      throw new NotFoundException(`Risk assessment with ID ${assessmentId} not found`);
    }
  }

  async updateRiskAssessment(assessmentId: string, updateData: Partial<RiskAssessment>): Promise<RiskAssessment> {
    if (!Types.ObjectId.isValid(assessmentId)) {
      throw new BadRequestException('Invalid assessment ID format');
    }

    // Prevent updating patient ID and calculated fields
    const { patientId, calculatedRisk, riskClass, createdAt, featureContributions, rawScore, ...allowedUpdates } = updateData;

    const updatedAssessment = await this.riskAssessmentModel
      .findByIdAndUpdate(
        assessmentId,
        { ...allowedUpdates, updatedAt: new Date() },
        { new: true, runValidators: true }
      )
      .exec();

    if (!updatedAssessment) {
      throw new NotFoundException(`Risk assessment with ID ${assessmentId} not found`);
    }

    return updatedAssessment;
  }

  


  async getAssessmentStatistics(patientId?: string): Promise<any> {
  const matchStage = patientId ? { patientId: patientId } : {};

  const stats = await this.riskAssessmentModel.aggregate([
    { $match: matchStage },
    {
      $group: {
        _id: null,
        totalAssessments: { $sum: 1 },

        // Counts per risk category
        lowRiskCount: { $sum: { $cond: [{ $eq: ['$riskClass', 'Low'] }, 1, 0] } },
        mildRiskCount: { $sum: { $cond: [{ $eq: ['$riskClass', 'Mild'] }, 1, 0] } },
        moderateRiskCount: { $sum: { $cond: [{ $eq: ['$riskClass', 'Moderate'] }, 1, 0] } },
        highRiskCount: { $sum: { $cond: [{ $eq: ['$riskClass', 'High'] }, 1, 0] } },

        // Average score
        averageRiskScore: { $avg: '$calculatedRisk' },

        // Std deviation for spread
        riskStdDev: { $stdDevPop: '$calculatedRisk' },

        // Extremes & trend
        maxRisk: { $max: '$calculatedRisk' },
        minRisk: { $min: '$calculatedRisk' },
        latestAssessment: { $max: '$createdAt' },
        earliestAssessment: { $min: '$createdAt' }
      }
    }
  ]);

  if (stats.length === 0) {
    return {
      stats: {
        totalAssessments: 0,
        lowRiskCount: 0,
        mildRiskCount: 0,
        moderateRiskCount: 0,
        highRiskCount: 0,
        averageRiskScore: 0,
        riskStdDev: 0,
        maxRisk: null,
        minRisk: null,
        latestAssessment: null,
        earliestAssessment: null
      },
      interpretations: []
    };
  }

  const result = stats[0];

  // Compute variance manually
  const riskVariance = Math.pow(result.riskStdDev ?? 0, 2);
  result.riskVariance = riskVariance;

  // ---- Interpretations ----
  const interpretations: string[] = [];

  interpretations.push(
    `There have been ${result.totalAssessments} total assessments recorded. This gives a sense of how much data is available for analysis.`
  );

  interpretations.push(
    `Risk distribution shows: Low (${result.lowRiskCount}), Mild (${result.mildRiskCount}), Moderate (${result.moderateRiskCount}), High (${result.highRiskCount}). This indicates which categories are most common.`
  );

  interpretations.push(
    `The average risk score is ${result.averageRiskScore.toFixed(2)}, which provides a central tendency of patient risk levels.`
  );

  interpretations.push(
    `The variance is ${riskVariance.toFixed(2)} and the standard deviation is ${result.riskStdDev?.toFixed(
      2
    )}. This shows how widely risk scores are spread around the mean — higher values mean more variability in risk.`
  );

  // interpretations.push(
  //   `The highest observed risk score is ${result.maxRisk} and the lowest is ${result.minRisk}. This range highlights the best and worst cases recorded.`
  // );

  interpretations.push(
  `The highest observed risk score is ${result.maxRisk.toFixed(2)} and the lowest is ${result.minRisk.toFixed(2)}. This range highlights the best and worst cases recorded.`
);


  // interpretations.push(
  //   `The earliest assessment was on ${result.earliestAssessment} and the latest on ${result.latestAssessment}. This helps establish a timeline of patient monitoring.`
  // );

  // Push earliest and latest assessment in readable 12-hour format
interpretations.push(
  `The earliest assessment was on ${new Date(result.earliestAssessment).toLocaleDateString('en-US', { year: 'numeric', month: 'short', day: 'numeric' })} at ${new Date(result.earliestAssessment).toLocaleTimeString('en-US', { hour: 'numeric', minute: '2-digit', second: '2-digit', hour12: true })} and the latest on ${new Date(result.latestAssessment).toLocaleDateString('en-US', { year: 'numeric', month: 'short', day: 'numeric' })} at ${new Date(result.latestAssessment).toLocaleTimeString('en-US', { hour: 'numeric', minute: '2-digit', second: '2-digit', hour12: true })}. This helps establish a timeline of patient monitoring.`
);

  return {
    stats: result,
    interpretations
  };
}

}