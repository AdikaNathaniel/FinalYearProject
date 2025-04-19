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

      const chartingData = JSON.parse(response.text);
      const charts = await this.generateCharts(patient, chartingData);

      return {
        success: true,
        message: 'Charting insights generated successfully',
        result: {
          insights: chartingData.insights,
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

  private async generateCharts(patient: any, chartingData: any) {
    const charts = [];
    
    for (const chartType of chartingData.chartTypes) {
      switch (chartType.toLowerCase()) {
        case 'line':
          charts.push(await this.generateLineChart(patient));
          break;
        case 'bar':
          charts.push(await this.generateBarChart(patient));
          break;
        case 'scatter':
          charts.push(await this.generateScatterPlot(patient));
          break;
        case 'pie':
          charts.push(await this.generatePieChart(patient));
          break;
      }
    }
    
    return charts;
  }

  private async generateLineChart(patient: any) {
    return {
      type: 'line',
      data: {
        labels: ['Week 1', 'Current Week', 'Projected Week 40'],
        datasets: [
          {
            label: 'Systolic BP',
            data: [110, patient.systolic_bp_mmHg, 125],
            borderColor: 'rgb(255, 99, 132)',
          },
          {
            label: 'Diastolic BP',
            data: [70, patient.diastolic_bp_mmHg, 75],
            borderColor: 'rgb(54, 162, 235)',
          },
        ],
      },
      options: {
        responsive: true,
        plugins: {
          title: {
            display: true,
            text: 'Blood Pressure Trend',
          },
        },
      },
    };
  }

  private async generateBarChart(patient: any) {
    return {
      type: 'bar',
      data: {
        labels: ['Glucose', 'Oxygen Sat', 'Heart Rate'],
        datasets: [
          {
            label: 'Patient',
            data: [
              patient.blood_glucose_mg_dL,
              patient.oxygen_saturation_percent,
              patient.heart_rate_bpm,
            ],
            backgroundColor: 'rgba(75, 192, 192, 0.6)',
          },
          {
            label: 'Normal Range Max',
            data: [140, 100, 90],
            backgroundColor: 'rgba(255, 99, 132, 0.6)',
          },
          {
            label: 'Normal Range Min',
            data: [70, 95, 70],
            backgroundColor: 'rgba(54, 162, 235, 0.6)',
          },
        ],
      },
      options: {
        responsive: true,
        plugins: {
          title: {
            display: true,
            text: 'Patient Metrics vs Normal Ranges',
          },
        },
      },
    };
  }

  private async generateScatterPlot(patient: any) {
    return {
      type: 'scatter',
      data: {
        datasets: [
          {
            label: 'Patient',
            data: [{
              x: patient.bmi,
              y: patient.systolic_bp_mmHg,
            }],
            backgroundColor: 'rgb(255, 99, 132)',
            pointRadius: 10,
          },
          {
            label: 'Normal Range',
            data: Array.from({ length: 20 }, () => ({
              x: 18 + Math.random() * 12,
              y: 100 + Math.random() * 20,
            })),
            backgroundColor: 'rgba(54, 162, 235, 0.6)',
          },
        ],
      },
      options: {
        responsive: true,
        plugins: {
          title: {
            display: true,
            text: 'BMI vs Blood Pressure',
          },
        },
        scales: {
          x: {
            title: {
              display: true,
              text: 'BMI',
            },
          },
          y: {
            title: {
              display: true,
              text: 'Systolic BP (mmHg)',
            },
          },
        },
      },
    };
  }

  private async generatePieChart(patient: any) {
    return {
      type: 'pie',
      data: {
        labels: ['Anemia Risk', 'Diabetes Risk', 'Preeclampsia Risk', 'Normal'],
        datasets: [
          {
            data: [
              patient.past_history_anemia ? 30 : 5,
              patient.past_history_diabetes ? 30 : 5,
              patient.past_history_preeclampsia ? 30 : 5,
              35,
            ],
            backgroundColor: [
              'rgba(255, 99, 132, 0.6)',
              'rgba(54, 162, 235, 0.6)',
              'rgba(255, 206, 86, 0.6)',
              'rgba(75, 192, 192, 0.6)',
            ],
          },
        ],
      },
      options: {
        responsive: true,
        plugins: {
          title: {
            display: true,
            text: 'Risk Factor Distribution',
          },
        },
      },
    };
  }
}