import { Injectable } from '@nestjs/common';
import { CreateReportDto } from 'src/users/dto/create-report.dto';
import axios from 'axios';

@Injectable()
export class ReportService {
  async generateReport(createReportDto: CreateReportDto): Promise<any> {
    const inputText = `Vitals: Body Temperature: ${createReportDto.body_temperature}, Heart Rate: ${createReportDto.heart_rate}, Oxygen Saturation: ${createReportDto.oxygen_saturation}, Blood Pressure: ${createReportDto.blood_pressure}, Blood Glucose: ${createReportDto.blood_glucose}. Notes: ${createReportDto.notes || 'N/A'}. Drugs: ${createReportDto.drugs || 'N/A'}.`;
    
    try {
      const response = await axios.post(
        'https://api-inference.huggingface.co/models/facebook/bart-large-cnn',
        { inputs: inputText },
        {
          headers: {
            Authorization: `Bearer ${process.env.HUGGING_FACE_API_KEY}`,
          },
        },
      );
      // Handle the response more robustly
      let summary = null; 
      // Check if response.data is an array (common format for HF API)
      if (Array.isArray(response.data) && response.data.length > 0) {
        summary = response.data[0]?.summary_text;
      } else if (response.data?.summary_text) {
        // Direct object format
        summary = response.data.summary_text;
      } else if (typeof response.data === 'string') {
        // Sometimes it might return just the string
        summary = response.data;
      }

      // Create a proper response object that includes both the input data and summary
      return {
        success: true,
        data: {
          patientData: createReportDto,
          summary: summary || 'No summary generated',
        }
      };
    } catch (error) {
      console.error('Error generating report:', error);
      return {
        success: false,
        message: error.response?.data?.error || 'Failed to generate report. Please try again later.',
        data: {
          patientData: createReportDto,
          summary: null
        }
      };
    }
  }
}
