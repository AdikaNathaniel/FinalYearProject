import { 
  Controller, 
  Get, 
  Post, 
  Body, 
  Patch, 
  Param, 
  Delete, 
  Query,
  UsePipes,
  ValidationPipe,
  Req
} from '@nestjs/common';
import { VitalsHealthDataService } from './vitals-health-data.service';
import { CreateVitalsHealthDataDto } from 'src/users/dto/create-vitals-health-data.dto';
import { UpdateVitalsHealthDataDto } from 'src/users/dto/update-vitals-health-data.dto';
import { ApiTags, ApiOperation, ApiResponse, ApiQuery } from '@nestjs/swagger';
import { InputMethod } from 'src/shared/schema/vitals-health-data.schema';

@ApiTags('vitals-health-data')
@Controller('vitals-health-data')
@UsePipes(new ValidationPipe({ whitelist: true, transform: true }))
export class VitalsHealthDataController {
  constructor(private readonly vitalsHealthDataService: VitalsHealthDataService) {}

  @Post()
  @ApiOperation({ summary: 'Create a new vitals health data record' })
  @ApiResponse({ status: 201, description: 'Vitals health data record created successfully' })
  @ApiResponse({ status: 400, description: 'Bad request' })
  create(@Body() createVitalsHealthDataDto: CreateVitalsHealthDataDto, @Req() req: any) {
    const userId = req.user?.id || createVitalsHealthDataDto.userId || 'temp-user-id';
    return this.vitalsHealthDataService.create(createVitalsHealthDataDto, userId);
  }

  @Get()
  @ApiOperation({ summary: 'Get vitals health data records (all patients or specific user)' })
  @ApiQuery({ name: 'userId', required: false, type: String })
  @ApiQuery({ name: 'page', required: false, type: Number })
  @ApiQuery({ name: 'limit', required: false, type: Number })
  @ApiQuery({ name: 'startDate', required: false, type: Date })
  @ApiQuery({ name: 'endDate', required: false, type: Date })
  @ApiResponse({ status: 200, description: 'List of vitals health data records' })
  findAll(
    @Query('userId') userId?: string,
    @Query('page') page: number = 1,
    @Query('limit') limit: number = 10,
    @Query('startDate') startDate?: Date,
    @Query('endDate') endDate?: Date,
  ) {
    return this.vitalsHealthDataService.findAll(userId, page, limit, startDate, endDate);
  }

  @Get('latest')
  @ApiOperation({ summary: 'Get the latest vitals health data record for a user' })
  @ApiQuery({ name: 'userId', required: true, type: String })
  @ApiResponse({ status: 200, description: 'Latest vitals health data record' })
  @ApiResponse({ status: 404, description: 'No vitals health data records found' })
  findLatest(@Query('userId') userId: string) {
    return this.vitalsHealthDataService.getLatestVitalsHealthData(userId);
  }

  @Get('method/:method')
  @ApiOperation({ summary: 'Get vitals health data records by input method' })
  @ApiQuery({ name: 'userId', required: true, type: String })
  @ApiQuery({ name: 'page', required: false, type: Number })
  @ApiQuery({ name: 'limit', required: false, type: Number })
  @ApiResponse({ status: 200, description: 'List of vitals health data records by method' })
  findByMethod(
    @Param('method') method: InputMethod,
    @Query('userId') userId: string,
    @Query('page') page: number = 1,
    @Query('limit') limit: number = 10,
  ) {
    return this.vitalsHealthDataService.getVitalsHealthDataByMethod(userId, method, page, limit);
  }

  @Get(':id')
  @ApiOperation({ summary: 'Get a specific vitals health data record' })
  @ApiResponse({ status: 200, description: 'Vitals health data record details' })
  @ApiResponse({ status: 404, description: 'Vitals health data record not found' })
  findOne(@Param('id') id: string, @Query('userId') userId?: string) {
    return this.vitalsHealthDataService.findOne(id, userId);
  }

  @Patch(':id')
  @ApiOperation({ summary: 'Update a vitals health data record' })
  @ApiResponse({ status: 200, description: 'Vitals health data record updated' })
  @ApiResponse({ status: 404, description: 'Vitals health data record not found' })
  update(
    @Param('id') id: string, 
    @Body() updateVitalsHealthDataDto: UpdateVitalsHealthDataDto,
    @Query('userId') userId?: string,
  ) {
    return this.vitalsHealthDataService.update(id, updateVitalsHealthDataDto, userId);
  }

  @Delete(':id')
  @ApiOperation({ summary: 'Delete a vitals health data record' })
  @ApiResponse({ status: 200, description: 'Vitals health data record deleted' })
  @ApiResponse({ status: 404, description: 'Vitals health data record not found' })
  remove(@Param('id') id: string, @Query('userId') userId?: string) {
    return this.vitalsHealthDataService.remove(id, userId);
  }
}
