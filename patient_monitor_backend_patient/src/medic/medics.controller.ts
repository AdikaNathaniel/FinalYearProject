import {
  Controller,
  Get,
  Post,
  Put,
  Delete,
  Body,
  Param,
  UseInterceptors,
  UploadedFile,
  ParseFilePipe,
  MaxFileSizeValidator,
  FileTypeValidator,
} from '@nestjs/common';
import { FileInterceptor } from '@nestjs/platform-express';
import { MedicsService } from './medics.service';
import { CreateMedicDto } from 'src/users/dto/create-medic.dto';
import { UpdateMedicDto } from 'src/users/dto/update-medic.dto';
import { Medic } from 'src/shared/schema/medic.schema';
import { diskStorage } from 'multer';
import { extname } from 'path';

@Controller('medics')
export class MedicsController {
  constructor(private readonly medicsService: MedicsService) {}

  @Post()
  @UseInterceptors(
    FileInterceptor('profilePhoto', {
      storage: diskStorage({
        destination: './uploads/profile-photos',
        filename: (req, file, callback) => {
          const uniqueSuffix = Date.now() + '-' + Math.round(Math.random() * 1e9);
          const ext = extname(file.originalname);
          const filename = `${uniqueSuffix}${ext}`;
          callback(null, filename);
        },
      }),
    }),
  )
  async create(
    @Body() createMedicDto: CreateMedicDto,
    @UploadedFile(
      new ParseFilePipe({
        validators: [
          new MaxFileSizeValidator({ maxSize: 1024 * 1024 * 5 }), // 5MB
          // new FileTypeValidator({ fileType: '.(png|jpeg|jpg)' }),
        ],
        fileIsRequired: false,
      }),
    )
    file: Express.Multer.File,
  ): Promise<Medic> {
    let dtoToSave = createMedicDto;
    if (file) {
      dtoToSave = { ...createMedicDto, profilePhoto: `/profile-photos/${file.filename}` };
    }
    return this.medicsService.create(dtoToSave);
  }

  @Get()
  async findAll(): Promise<Medic[]> {
    return this.medicsService.findAll();
  }

  @Get(':fullName')
  async findOne(@Param('fullName') fullName: string): Promise<Medic> {
    return this.medicsService.findOne(fullName);
  }

  @Put(':fullName')
  @UseInterceptors(
    FileInterceptor('profilePhoto', {
      storage: diskStorage({
        destination: './uploads/profile-photos',
        filename: (req, file, callback) => {
          const uniqueSuffix = Date.now() + '-' + Math.round(Math.random() * 1e9);
          const ext = extname(file.originalname);
          const filename = `${uniqueSuffix}${ext}`;
          callback(null, filename);
        },
      }),
    }),
  )
  async update(
    @Param('fullName') fullName: string,
    @Body() updateMedicDto: UpdateMedicDto,
    @UploadedFile(
      new ParseFilePipe({
        validators: [
          new MaxFileSizeValidator({ maxSize: 1024 * 1024 * 5 }), // 5MB
          new FileTypeValidator({ fileType: '.(png|jpeg|jpg)' }),
        ],
        fileIsRequired: false,
      }),
    )
    file: Express.Multer.File,
  ): Promise<Medic> {
    let dtoToUpdate = updateMedicDto;
    if (file) {
      dtoToUpdate = { ...updateMedicDto, profilePhoto: `/profile-photos/${file.filename}` };
    }
    return this.medicsService.update(fullName, dtoToUpdate);
  }

  @Delete(':fullName')
  async remove(@Param('fullName') fullName: string): Promise<Medic> {
    return this.medicsService.remove(fullName);
  }
}