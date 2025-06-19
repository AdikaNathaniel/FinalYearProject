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
  HttpException,
  HttpStatus,
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
          new MaxFileSizeValidator({ maxSize: 1024 * 1024 * 5 }) // 5MB
          // new FileTypeValidator({ fileType: '.(png|jpeg|jpg)' }),
        ],
        fileIsRequired: false,
      }),
    )
    file?: Express.Multer.File,
  ): Promise<Medic> {
    try {
      let dtoToSave = {...createMedicDto};
      
      // Parse consultation hours if sent as a string
      if (typeof dtoToSave.consultationHours === 'string') {
        try {
          dtoToSave.consultationHours = JSON.parse(dtoToSave.consultationHours as string);
        } catch (e) {
          console.warn('Failed to parse consultationHours as JSON', e);
        }
      }
      
      // Parse languages spoken if sent as a string
      if (typeof dtoToSave.languagesSpoken === 'string') {
        try {
          dtoToSave.languagesSpoken = JSON.parse(dtoToSave.languagesSpoken as string);
        } catch (e) {
          // If not valid JSON, try to split by comma
          dtoToSave.languagesSpoken = (dtoToSave.languagesSpoken as string)
            .split(',')
            .map(lang => lang.trim())
            .filter(lang => lang);
        }
      }
      
      if (file) {
        dtoToSave.profilePhoto = `/profile-photos/${file.filename}`;
      }
      
      return this.medicsService.create(dtoToSave);
    } catch (error) {
      throw new HttpException(
        `Failed to create medic: ${error.message}`,
        HttpStatus.BAD_REQUEST,
      );
    }
  }

  @Get()
  async findAll(): Promise<{ medics: Medic[] }> {
    try {
      const medics = await this.medicsService.findAll();
      return { medics };
    } catch (error) {
      throw new HttpException(
        `Failed to retrieve medics: ${error.message}`,
        HttpStatus.INTERNAL_SERVER_ERROR,
      );
    }
  }

  @Get(':identifier')
  async findOne(@Param('identifier') identifier: string): Promise<Medic | { medic: Medic | null; similarResults?: Medic[] }> {
    try {
      // Check if the identifier is a MongoDB ObjectId
      const isValidId = /^[0-9a-fA-F]{24}$/.test(identifier);
      
      let medic: Medic;
      if (isValidId) {
        medic = await this.medicsService.findById(identifier);
      } else {
        // If not an ID, treat as fullName (decoding URI components)
        const decodedName = decodeURIComponent(identifier);
        medic = await this.medicsService.findOne(decodedName);
      }
      
      if (!medic) {
        // If exact match fails, find similar results
        const similarResults = await this.medicsService.findSimilar(decodeURIComponent(identifier));
        
        if (similarResults && similarResults.length > 0) {
          // Return the first match as the primary result with others as similar
          return {
            medic: similarResults[0],
            similarResults: similarResults.length > 1 ? similarResults.slice(1) : []
          };
        }
        
        throw new HttpException(
          `Medic with identifier "${identifier}" not found. Please check the name spelling.`, 
          HttpStatus.NOT_FOUND
        );
      }
      
      return medic;
    } catch (error) {
      if (error instanceof HttpException) {
        throw error;
      }
      throw new HttpException(
        `Failed to retrieve medic: ${error.message}`,
        HttpStatus.INTERNAL_SERVER_ERROR,
      );
    }
  }
  
  @Get('search/:query')
  async search(@Param('query') query: string): Promise<Medic[]> {
    try {
      const decodedQuery = decodeURIComponent(query);
      return this.medicsService.findSimilar(decodedQuery);
    } catch (error) {
      throw new HttpException(
        `Failed to search medics: ${error.message}`,
        HttpStatus.INTERNAL_SERVER_ERROR,
      );
    }
  }

  @Put(':identifier')
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
    @Param('identifier') identifier: string,
    @Body() updateMedicDto: UpdateMedicDto,
    @UploadedFile(
      new ParseFilePipe({
        validators: [
          new MaxFileSizeValidator({ maxSize: 1024 * 1024 * 5 })
          // new FileTypeValidator({ fileType: '.(png|jpeg|jpg)' }),
        ],
        fileIsRequired: false,
      }),
    )
    file?: Express.Multer.File,
  ): Promise<Medic> {
    try {
      // Check if the identifier is a MongoDB ObjectId
      const isValidId = /^[0-9a-fA-F]{24}$/.test(identifier);
      
      let existingMedic: Medic;
      if (isValidId) {
        existingMedic = await this.medicsService.findById(identifier);
      } else {
        // If not an ID, treat as fullName (decoding URI components)
        const decodedName = decodeURIComponent(identifier);
        existingMedic = await this.medicsService.findOne(decodedName);
      }
      
      if (!existingMedic) {
        throw new HttpException(
          `Medic with identifier "${identifier}" not found`, 
          HttpStatus.NOT_FOUND
        );
      }

      let dtoToUpdate = {...updateMedicDto};
      
      // Parse consultation hours if sent as a string
      if (typeof dtoToUpdate.consultationHours === 'string') {
        try {
          dtoToUpdate.consultationHours = JSON.parse(dtoToUpdate.consultationHours as string);
        } catch (e) {
          console.warn('Failed to parse consultationHours as JSON', e);
        }
      }
      
      // Parse languages spoken if sent as a string
      if (typeof dtoToUpdate.languagesSpoken === 'string') {
        try {
          dtoToUpdate.languagesSpoken = JSON.parse(dtoToUpdate.languagesSpoken as string);
        } catch (e) {
          // If not valid JSON, try to split by comma
          dtoToUpdate.languagesSpoken = (dtoToUpdate.languagesSpoken as string)
            .split(',')
            .map(lang => lang.trim())
            .filter(lang => lang);
        }
      }
      
      if (file) {
        dtoToUpdate.profilePhoto = `/profile-photos/${file.filename}`;
      }
      
      const updatedMedic = await this.medicsService.update(existingMedic.fullName, dtoToUpdate);
      return updatedMedic;
    } catch (error) {
      if (error instanceof HttpException) {
        throw error;
      }
      throw new HttpException(
        `Failed to update medic: ${error.message}`,
        HttpStatus.INTERNAL_SERVER_ERROR,
      );
    }
  }

 

  @Delete(':identifier')
async remove(@Param('identifier') identifier: string): Promise<Medic> {
  try {
    // Check if the identifier is a MongoDB ObjectId
    const isValidId = /^[0-9a-fA-F]{24}$/.test(identifier);
    
    let deletedMedic: Medic;
    if (isValidId) {
      deletedMedic = await this.medicsService.removeById(identifier);
    } else {
      // If not an ID, treat as fullName (decoding URI components)
      const decodedName = decodeURIComponent(identifier);
      deletedMedic = await this.medicsService.remove(decodedName);
    }
    
    if (!deletedMedic) {
      throw new HttpException(
        `Medic with identifier "${identifier}" not found`, 
        HttpStatus.NOT_FOUND
      );
    }
    
    return deletedMedic;
  } catch (error) {
    if (error instanceof HttpException) {
      throw error;
    }
    throw new HttpException(
      `Failed to delete medic: ${error.message}`,
      HttpStatus.INTERNAL_SERVER_ERROR,
    );
  }
}
}