import { Controller, Post, Get, Param, Res, UploadedFile, UseInterceptors } from '@nestjs/common';
import { FileInterceptor } from '@nestjs/platform-express';
import { CsvService } from './csv.service';
import { diskStorage } from 'multer';
import { extname } from 'path';
import { Response } from 'express';

@Controller('csv')
export class CsvController {
  constructor(private readonly csvService: CsvService) {}

  // ---- Upload Endpoint ----
  @Post('upload')
  @UseInterceptors(FileInterceptor('file', {
    storage: diskStorage({
      destination: './uploads',
      filename: (req, file, cb) => {
        const uniqueSuffix = Date.now() + '-' + Math.round(Math.random() * 1e9);
        cb(null, uniqueSuffix + extname(file.originalname));
      },
    }),
  }))
  async uploadFile(@UploadedFile() file: Express.Multer.File) {
    const created = await this.csvService.create({
      filename: file.filename,
      path: file.path,
      size: file.size,
      mimetype: file.mimetype,
    });
    return { id: created._id, message: 'Upload successful' };
  }

  // ---- Download Endpoint ----
//   @Get('download/:id')
//   async downloadFile(@Param('id') id: string, @Res() res: Response) {
//     const file = await this.csvService.findOne(id);
//     res.set({
//       'Content-Type': file.mimetype,
//       'Content-Disposition': `attachment; filename="${file.filename}"`,
//     });
//     const stream = await this.csvService.getFileStream(id);
//     stream.pipe(res);
//   }



  @Get('download/:id')
async downloadFile(@Param('id') id: string, @Res() res: Response) {
  const file = await this.csvService.findOne(id);

  res.setHeader('Content-Type', 'text/csv');
  res.setHeader(
    'Content-Disposition',
    `attachment; filename="${file.filename}"`,
  );

  const stream = await this.csvService.getFileStream(id);
  stream.pipe(res);
}


 @Get('latest-id')
  async getLatestId() {
    const latestId = await this.csvService.findLatestId();
    return {
      message: 'Latest CSV ID fetched successfully',
      success: true,
      result: { id: latestId },
    };
  }

  


@Get('all-ids')
async getAllIds() {
  const allIds = await this.csvService.findAllIds();
  return {
    message: 'All CSV IDs fetched successfully',
    success: true,
    result: allIds,
  };
}


}
