import { Body, Controller, Get, Patch, Post } from '@nestjs/common';
import { HeltecLiveVitalsService } from './heltec-live-vitals.service';
import { CreateHeltecLiveVitalsDto } from 'src/users/dto/create-heltec-live-vitals.dto';
import { NormalizeVitalsPipe } from './normalize-vitals.pipe';

@Controller('heltec-live-vitals')
export class HeltecLiveVitalsController {
  constructor(private readonly heltecVitalsService: HeltecLiveVitalsService) {}

  // @Post()
  // create(@Body() dto: CreateHeltecLiveVitalsDto) {
  //   return this.heltecVitalsService.createVitals(dto);
  // }

   @Post()
  async create(@Body(NormalizeVitalsPipe) data) {
    return this.heltecVitalsService.createVitals(data);
  }



  @Get('latest')
  getLatest() {
    return this.heltecVitalsService.getLatestVitals();
  }

  @Patch('latest/protein-level')
  updateProteinLevel(@Body('proteinLevel') proteinLevel: number) {
    return this.heltecVitalsService.updateLatestProteinLevel(proteinLevel);
  }
  

  @Get()
  getAll() {
    return this.heltecVitalsService.getAllVitals();
  }

}

// Reverted to old