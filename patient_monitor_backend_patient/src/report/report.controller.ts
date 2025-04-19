import { Body, Controller, Post } from '@nestjs/common';
import { ReportService } from './report.service';
import { CreateReportDto } from 'src/users/dto/create-report.dto';

@Controller('reports')
export class ReportController {
  constructor(private readonly reportService: ReportService) {}

  @Post()
  async generateReport(@Body() createReportDto: CreateReportDto) {
    return this.reportService.generateReport(createReportDto);
  }
}
