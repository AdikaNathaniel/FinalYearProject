import { Injectable } from '@nestjs/common';
import { parse } from 'csv-parse/sync';
import * as fs from 'fs';
import * as path from 'path';
import { LLMChain } from 'langchain/chains';
import { OpenAI } from 'langchain/llms/openai';
import { PromptTemplate } from 'langchain/prompts';

@Injectable()
export class HealthAnalyticsService {
  private patientData: any[] = [];
  private llm: OpenAI;
  private summaryChain: LLMChain;
  private queryChain: LLMChain;
  private diagnosticChain: LLMChain;
  private alertChain: LLMChain;
  private chartingChain: LLMChain;
 


  constructor() {
    this.loadData();
    this.initializeLangChain();
  }

  private loadData() {
    const csvFilePath = path.join(__dirname, '../../src/health-analytics/pregnancy_health_data_with_history.csv');
    const fileContent = fs.readFileSync(csvFilePath, 'utf8');
    this.patientData = parse(fileContent, {
      columns: true,
      skip_empty_lines: true,
    });
  }

  private initializeLangChain() {
    this.llm = new OpenAI({
      temperature: 0.3,
      modelName: 'gpt-4o',
      openAIApiKey: this.OPENAI_API_KEY,
    });

    // Initialize all chains
    this.summaryChain = new LLMChain({
      llm: this.llm,
      prompt: PromptTemplate.fromTemplate(`
        You are a medical assistant analyzing pregnancy health data. 
        Generate a concise summary for patient {patientName} with the following data:
        {patientData}
        
        Focus on key health indicators and potential risks.
      `),
    });

    this.queryChain = new LLMChain({
      llm: this.llm,
      prompt: PromptTemplate.fromTemplate(`
        You are a medical query system. Answer the doctor's question about patient records.
        Question: {question}
        Patient Data: {patientData}
        
        Provide a detailed, clinically relevant response.
      `),
    });

    this.diagnosticChain = new LLMChain({
      llm: this.llm,
      prompt: PromptTemplate.fromTemplate(`
        Explain the following diagnostic prediction in human-readable terms:
        Prediction: {prediction}
        Patient Data: {patientData}
        
        Include possible causes, risk factors, and recommended next steps.
      `),
    });

    this.alertChain = new LLMChain({
      llm: this.llm,
      prompt: PromptTemplate.fromTemplate(`
        Translate this medical alert into meaningful context:
        Alert: {alert}
        Patient Data: {patientData}
        
        Provide clinical significance, potential causes, and suggested actions.
      `),
    });

    this.chartingChain = new LLMChain({
      llm: this.llm,
      prompt: PromptTemplate.fromTemplate(`
        Analyze this patient data and suggest appropriate visualizations:
        {patientData}
        
        Return a JSON object with:
        - chartTypes: array of suggested chart types
        - dataPoints: relevant data points to visualize
        - insights: key insights to highlight
      `),
    });
  }

  // 1. Patient Summary Generator
  async generatePatientSummary(patientName: string) {
    try {
      const patient = this.patientData.find(p => p.patient_name === patientName);
      if (!patient) {
        return {
          success: false,
          message: 'Patient not found',
          result: null,
        };
      }
      
      const response = await this.summaryChain.call({
        patientName,
        patientData: JSON.stringify(patient),
      });

      return {
        success: true,
        message: 'Patient summary generated successfully',
        result: response.text,
      };
    } catch (error) {
      return {
        success: false,
        message: error.message,
        result: null,
      };
    }
  }


  // 2. Conversational Record Queries
  async queryPatientRecords(patientName: string, question: string) {
    try {
      const patient = this.patientData.find(p => p.patient_name === patientName);
      if (!patient) {
        return {
          success: false,
          message: 'Patient not found',
          result: null,
        };
      }
      
      const response = await this.queryChain.call({
        question,
        patientData: JSON.stringify(patient),
      });

      return {
        success: true,
        message: 'Query response generated successfully',
        result: response.text,
      };
    } catch (error) {
      return {
        success: false,
        message: error.message,
        result: null,
      };
    }
  }

  // 3. Diagnostic Explanation (XAI)
  async explainDiagnostic(patientName: string, prediction: string) {
    try {
      const patient = this.patientData.find(p => p.patient_name === patientName);
      if (!patient) {
        return {
          success: false,
          message: 'Patient not found',
          result: null,
        };
      }
      
      const response = await this.diagnosticChain.call({
        prediction,
        patientData: JSON.stringify(patient),
      });

      return {
        success: true,
        message: 'Diagnostic explanation generated successfully',
        result: response.text,
      };
    } catch (error) {
      return {
        success: false,
        message: error.message,
        result: null,
      };
    }
  }

  // 4. Alert Explanation Generator
  async explainAlert(patientName: string, alert: string) {
    try {
      const patient = this.patientData.find(p => p.patient_name === patientName);
      if (!patient) {
        return {
          success: false,
          message: 'Patient not found',
          result: null,
        };
      }
      
      const response = await this.alertChain.call({
        alert,
        patientData: JSON.stringify(patient),
      });

      return {
        success: true,
        message: 'Alert explanation generated successfully',
        result: response.text,
      };
    } catch (error) {
      return {
        success: false,
        message: error.message,
        result: null,
      };
    }
  }

  async getPatientsWithAbnormalVitals() {
    try {
      // Define normal threshold ranges for vital signs
      const normalThresholds = {
        body_temperature_c: { min: 36.1, max: 37.5 },
        systolic_bp_mmHg: { min: 90, max: 140 },
        diastolic_bp_mmHg: { min: 60, max: 90 },
        blood_glucose_mg_dL: { min: 70, max: 140 },
        oxygen_saturation_percent: { min: 95, max: 100 },
        heart_rate_bpm: { min: 60, max: 100 },
        protein_urine_scale: { min: 0, max: 2 }, // Above 2 might indicate issues
        bmi: { min: 18.5, max: 30 }
      };
  
      // Array to store patients with abnormal vitals
      const patientsWithAbnormalVitals = [];
  
      // Iterate through each patient in the CSV data
      for (const patient of this.patientData) {
        const abnormalVitals: Record<string, any> = {};
        let hasAbnormalVitals = false;
  
        // Check each vital sign against normal thresholds
        for (const [vital, range] of Object.entries(normalThresholds)) {
          if (patient[vital] < range.min || patient[vital] > range.max) {
            abnormalVitals[vital] = {
              value: patient[vital],
              normal_range: range,
              status: patient[vital] < range.min ? 'below normal' : 'above normal'
            };
            hasAbnormalVitals = true;
          }
        }
  
        // Check high-risk medical history
        if (patient.past_history_anemia === 1) {
          abnormalVitals['past_history_anemia'] = { value: true, status: 'risk factor' };
          hasAbnormalVitals = true;
        }
        
        if (patient.past_history_diabetes === 1) {
          abnormalVitals['past_history_diabetes'] = { value: true, status: 'risk factor' };
          hasAbnormalVitals = true;
        }
        
        if (patient.past_history_preeclampsia === 1) {
          abnormalVitals['past_history_preeclampsia'] = { value: true, status: 'risk factor' };
          hasAbnormalVitals = true;
        }
  
        // If patient has abnormal vitals, add to the result array
        if (hasAbnormalVitals) {
          patientsWithAbnormalVitals.push({
            patient_name: patient.patient_name,
            gestational_week: patient.gestational_week,
            abnormal_vitals: abnormalVitals
          });
        }
      }
  
      return {
        success: true,
        message: 'Patients with abnormal vitals identified successfully',
        result: patientsWithAbnormalVitals
      };
    } catch (error) {
      return {
        success: false,
        message: error.message,
        result: null
      };
    }
  }

  // 5. Multilingual Support
  async translateMedicalText(text: string, targetLanguage: string) {
    try {
      const prompt = PromptTemplate.fromTemplate(`
        Translate this medical text to {targetLanguage}:
        {text}
        
        Maintain all medical terminology accuracy.
      `);
      const chain = new LLMChain({ llm: this.llm, prompt });

      const response = await chain.call({ text, targetLanguage });

      return {
        success: true,
        message: 'Translation successful',
        result: response.text,
      };
    } catch (error) {
      return {
        success: false,
        message: error.message,
        result: null,
      };
    }
  }

  // 6. Copilot for Notes & Charting
  async generateChartingInsights(patientName: string) {
    try {
      const patient = this.patientData.find(p => p.patient_name === patientName);
      if (!patient) {
        return {
          success: false,
          message: 'Patient not found',
          result: null,
        };
      }
  
      const response = await this.chartingChain.call({
        patientData: JSON.stringify(patient),
      });
  
      // Enhanced robust JSON parsing
      let chartingData;
      try {
        // First attempt: direct parsing
        chartingData = JSON.parse(response.text);
      } catch (parseError) {
        try {
          // Second attempt: Handle if response.text itself is a stringified object
          if (typeof response.text === 'string') {
            // Check if the response starts with common non-JSON characters
            let cleanedText = response.text;
            
            // Remove any leading non-JSON characters (like backticks, j, etc.)
            cleanedText = cleanedText.replace(/^[^{[\"]*/g, '');
            
            // Remove any trailing non-JSON characters
            cleanedText = cleanedText.replace(/[^}\]"]*$/g, '');
            
            // Try parsing the cleaned text
            chartingData = JSON.parse(cleanedText);
          } else {
            // If response.text is not a string, use a default object
            chartingData = { insights: [] };
          }
        } catch (secondError) {
          // If all parsing attempts fail, use a default object
          console.error('Failed to parse response:', secondError);
          chartingData = { insights: [] };
        }
      }
  
      const charts = [];
  
      // Blood Pressure Trend
      charts.push({
        id: 'bp_trend',
        title: 'Blood Pressure Trend',
        type: 'line',
        labels: ['Week 1', `Week ${patient.gestational_week}`, 'Week 40'],
        datasets: [
          {
            label: 'Systolic BP',
            data: [110, patient.systolic_bp_mmHg, 125],
            color: '#FF6384',
          },
          {
            label: 'Diastolic BP',
            data: [70, patient.diastolic_bp_mmHg, 75],
            color: '#36A2EB',
          },
        ],
      });
  
      // Weight Gain During Pregnancy
      charts.push({
        id: 'weight_progression',
        title: 'Weight Gain During Pregnancy',
        type: 'line',
        labels: ['Week 1', `Week ${patient.gestational_week}`, 'Week 40'],
        datasets: [
          {
            label: 'Weight (kg)',
            data: [55, patient.weight_kg, 65],
            color: '#9966FF',
          },
        ],
      });
  
      // Patient Metrics vs Normal Ranges
      charts.push({
        id: 'metric_ranges',
        title: 'Patient Metrics vs Normal Ranges',
        type: 'bar',
        labels: ['Glucose', 'Oxygen Sat', 'Heart Rate'],
        datasets: [
          {
            label: 'Patient',
            data: [
              patient.blood_glucose_mg_dL,
              patient.oxygen_saturation_percent,
              patient.heart_rate_bpm,
            ],
            color: '#4BC0C0',
          },
          {
            label: 'Normal Range Max',
            data: [140, 100, 90],
            color: '#FF6384',
          },
          {
            label: 'Normal Range Min',
            data: [70, 95, 70],
            color: '#36A2EB',
          },
        ],
      });
  
      // Urine Protein Level
      charts.push({
        id: 'urine_protein',
        title: 'Urine Protein Level',
        type: 'bar',
        labels: ['Protein (Urine)'],
        datasets: [
          {
            label: 'Measured Value',
            data: [patient.protein_urine_scale],
            color: '#FF9F40',
          },
          {
            label: 'Normal Threshold',
            data: [3],
            color: '#C9CBCE',
          },
        ],
      });
  
      // BMI vs Blood Pressure
      charts.push({
        id: 'bmi_vs_bp',
        title: 'BMI vs Blood Pressure',
        type: 'scatter',
        datasets: [
          {
            label: 'Patient',
            data: [{ x: patient.bmi, y: patient.systolic_bp_mmHg }],
            color: '#FF6384',
          },
          {
            label: 'Normal Range',
            data: Array.from({ length: 20 }, () => ({
              x: 18 + Math.random() * 12,
              y: 100 + Math.random() * 20,
            })),
            color: '#36A2EB',
          },
        ],
        xLabel: 'BMI',
        yLabel: 'Systolic BP (mmHg)',
      });
  
      // Body Temperature vs Heart Rate
      charts.push({
        id: 'temp_vs_hr',
        title: 'Body Temperature vs Heart Rate',
        type: 'scatter',
        datasets: [
          {
            label: 'Patient',
            data: [{ x: patient.body_temperature_c, y: patient.heart_rate_bpm }],
            color: '#FFCE56',
          },
          {
            label: 'Normal Range',
            data: Array.from({ length: 20 }, () => ({
              x: 36 + Math.random() * 1.5,
              y: 70 + Math.random() * 30,
            })),
            color: '#9966FF',
          },
        ],
        xLabel: 'Temperature (°C)',
        yLabel: 'Heart Rate (bpm)',
      });
  
      // Risk Factor Distribution
      charts.push({
        id: 'risk_pie',
        title: 'Risk Factor Distribution',
        type: 'pie',
        labels: ['Anemia Risk', 'Diabetes Risk', 'Preeclampsia Risk', 'Normal'],
        datasets: [
          {
            data: [
              patient.past_history_anemia ? 30 : 5,
              patient.past_history_diabetes ? 30 : 5,
              patient.past_history_preeclampsia ? 30 : 5,
              35,
            ],
            color: ['#FF6384', '#36A2EB', '#FFCE56', '#4BC0C0'],
          },
        ],
      });
  
      // Heart Rate Trend
      charts.push({
        id: 'heart_rate_trend',
        title: 'Heart Rate Trend',
        type: 'line',
        labels: ['Week 1', `Week ${patient.gestational_week}`, 'Week 40'],
        datasets: [
          {
            label: 'Heart Rate (bpm)',
            data: [75, patient.heart_rate_bpm, 80],
            color: '#FF9F40',
          },
        ],
      });
  
      // Glucose Level Trend
      charts.push({
        id: 'glucose_trend',
        title: 'Glucose Level Trend',
        type: 'line',
        labels: ['Week 1', `Week ${patient.gestational_week}`, 'Week 40'],
        datasets: [
          {
            label: 'Blood Glucose (mg/dL)',
            data: [90, patient.blood_glucose_mg_dL, 100],
            color: '#4BC0C0',
          },
        ],
      });
  
      // Oxygen Saturation Trend
      charts.push({
        id: 'oxygen_saturation_trend',
        title: 'Oxygen Saturation Trend',
        type: 'line',
        labels: ['Week 1', `Week ${patient.gestational_week}`, 'Week 40'],
        datasets: [
          {
            label: 'Oxygen Saturation (%)',
            data: [98, patient.oxygen_saturation_percent, 99],
            color: '#36A2EB',
          },
        ],
      });
  
      // Weight vs Gestational Week
      charts.push({
        id: 'weight_vs_gestational_week',
        title: 'Weight vs Gestational Week',
        type: 'scatter',
        datasets: [
          {
            label: 'Patient',
            data: [{ x: patient.gestational_week, y: patient.weight_kg }],
            color: '#FFCE56',
          },
        ],
        xLabel: 'Gestational Week',
        yLabel: 'Weight (kg)',
      });
  
      // Protein Level Trend
      charts.push({
        id: 'protein_level_trend',
        title: 'Protein Level Trend',
        type: 'line',
        labels: ['Week 1', `Week ${patient.gestational_week}`, 'Week 40'],
        datasets: [
          {
            label: 'Protein Level',
            data: [1, patient.protein_urine_scale, 3],
            color: '#9966FF',
          },
        ],
      });
  
      // Temperature Trend
      charts.push({
        id: 'temperature_trend',
        title: 'Body Temperature Trend',
        type: 'line',
        labels: ['Week 1', `Week ${patient.gestational_week}`, 'Week 40'],
        datasets: [
          {
            label: 'Body Temperature (°C)',
            data: [36.5, patient.body_temperature_c, 37],
            color: '#FF6384',
          },
        ],
      });
  
      // Risk Factor Analysis
      charts.push({
        id: 'risk_factor_analysis',
        title: 'Overall Risk Factor Analysis',
        type: 'bar',
        labels: ['Anemia', 'Diabetes', 'Preeclampsia'],
        datasets: [
          {
            label: 'Risk Level',
            data: [
              patient.past_history_anemia ? 1 : 0,
              patient.past_history_diabetes ? 1 : 0,
              patient.past_history_preeclampsia ? 1 : 0,
            ],
            color: '#FF9F40',
          },
        ],
      });
  
      // Overall Health Score
      charts.push({
        id: 'overall_health_score',
        title: 'Overall Health Score',
        type: 'radar',
        labels: ['Blood Pressure', 'Heart Rate', 'Glucose', 'Weight', 'Oxygen'],
        datasets: [
          {
            label: 'Patient Score',
            data: [
              patient.systolic_bp_mmHg / 120,
              patient.heart_rate_bpm / 100,
              patient.blood_glucose_mg_dL / 140,
              patient.weight_kg / 90,
              patient.oxygen_saturation_percent / 100,
            ],
            color: '#4BC0C0',
          },
        ],
      });
  
      // Gestational Week Distribution
      charts.push({
        id: 'gestational_week_distribution',
        title: 'Gestational Week Distribution',
        type: 'bar',
        labels: ['1-12 Weeks', '13-24 Weeks', '25-36 Weeks', '37-40 Weeks'],
        datasets: [
          {
            label: 'Patient',
            data: [
              patient.gestational_week <= 12 ? 1 : 0,
              patient.gestational_week <= 24 && patient.gestational_week > 12 ? 1 : 0,
              patient.gestational_week <= 36 && patient.gestational_week > 24 ? 1 : 0,
              patient.gestational_week > 36 ? 1 : 0,
            ],
            color: '#36A2EB',
          },
        ],
      });
  
      return {
        success: true,
        message: 'Charting insights generated successfully',
        result: {
          insights: chartingData.insights || [],
          charts,
        },
      };
    } catch (error) {
      return {
        success: false,
        message: error.message,
        result: null,
      };
    }
  } 



  // Add this function to your health-analytics.service.ts file
async getPatientVitals(patientName: string) {
  try {
    const patient = this.patientData.find(p => p.patient_name === patientName);
    
    if (!patient) {
      return {
        success: false,
        message: 'Patient not found',
        result: null,
      };
    }
    
    // Extract the vital signs and medical history
    const vitals = {
      personal_info: {
        patient_name: patient.patient_name,
        gestational_week: patient.gestational_week,
        height_cm: patient.height_cm,
        weight_kg: patient.weight_kg,
        bmi: patient.bmi
      },
      vital_signs: {
        body_temperature_c: patient.body_temperature_c,
        systolic_bp_mmHg: patient.systolic_bp_mmHg,
        diastolic_bp_mmHg: patient.diastolic_bp_mmHg,
        blood_glucose_mg_dL: patient.blood_glucose_mg_dL,
        oxygen_saturation_percent: patient.oxygen_saturation_percent,
        heart_rate_bpm: patient.heart_rate_bpm,
        protein_urine_scale: patient.protein_urine_scale
      },
      medical_history: {
        past_history_anemia: patient.past_history_anemia === 1 ? 1 : 0,
        past_history_diabetes: patient.past_history_diabetes === 1 ? 1 : 0,
        past_history_preeclampsia: patient.past_history_preeclampsia === 1 ? 1 : 0
      }
    };
    
    return {
      success: true,
      message: 'Patient vitals retrieved successfully',
      result: vitals
    };
  } catch (error) {
    return {
      success: false,
      message: error.message,
      result: null
    };
  }
}

}