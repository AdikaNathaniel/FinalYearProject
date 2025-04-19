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
import { FavoriteService } from 'src/favorite/favorite.service';
import { CreateFavoriteDto } from 'src/users/dto/create-favorite.dto';
import { UpdateFavoriteDto } from 'src/users/dto/update-favorite.dto';

@Controller('favorite')
export class FavoriteController {
    constructor(private readonly FavoriteService: FavoriteService) {}

    @Post()
    async create(@Body() createFavoriteDto: CreateFavoriteDto) {
        return await this.FavoriteService.create(createFavoriteDto);
    }

    @Get()
    async findAll() {
        return await this.FavoriteService.findAll();
    }

    @Get(':productName') // Changed from ':id' to ':productName'
    async findOne(@Param('productName') productName: string) { // Changed from id to productName
        return await this.FavoriteService.findOneByProductName(productName);
    }

    @Put(':productName') // Changed from ':id' to ':productName'
    async update(
        @Param('productName') productName: string, // Changed from id to productName
        @Body() updateFavoriteDto: UpdateFavoriteDto,
    ) {
        return await this.FavoriteService.updateByProductName(productName, updateFavoriteDto);
    }

    @Delete(':productName') // Changed from ':id' to ':productName'
    async remove(@Param('productName') productName: string) { // Changed from id to productName
        return await this.FavoriteService.removeByProductName(productName);
    }

    @Get('filter/category')
    async filterByCategory(@Query('category') category: string) {
        return await this.FavoriteService.filterByCategory(category);
    }
}