import {
    Controller,
    Get,
    Post,
    Body,
    Param,
    Delete,
    Put,
    Query,
    HttpCode,
    HttpStatus,
} from '@nestjs/common';
import { TopChartsService } from 'src/topchart/top-chart.service';
import { CreateTopChartDto } from 'src/users/dto/create-top-chart.dto';
import { UpdateTopChartDto } from 'src/users/dto/update-top-chart.dto';

@Controller('top-charts')
export class TopChartsController {
    constructor(private readonly topChartsService: TopChartsService) {}

    @Post()
    async create(@Body() createTopChartDto: CreateTopChartDto) {
        return await this.topChartsService.create(createTopChartDto);
    }

    @Get()
    async findAll() {
        return await this.topChartsService.findAll();
    }

    @Get(':productName') // Changed from ':id' to ':productName'
    async findOne(@Param('productName') productName: string) { // Changed from id to productName
        return await this.topChartsService.findOneByProductName(productName);
    }

    @Put(':productName') // Changed from ':id' to ':productName'
    async update(
        @Param('productName') productName: string, // Changed from id to productName
        @Body() updateTopChartDto: UpdateTopChartDto,
    ) {
        return await this.topChartsService.updateByProductName(productName, updateTopChartDto);
    }

    @Delete(':productName') // Changed from ':id' to ':productName'
    async remove(@Param('productName') productName: string) { // Changed from id to productName
        return await this.topChartsService.removeByProductName(productName);
    }

    @Get('filter/category')
    async filterByCategory(@Query('category') category: string) {
        return await this.topChartsService.filterByCategory(category);
    }
}