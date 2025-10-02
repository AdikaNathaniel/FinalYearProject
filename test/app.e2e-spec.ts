// filepath: /c:/Users/USER/Desktop/MultiVendorPlatform/digizone/test/app.e2e-spec.ts
import { Test, TestingModule } from '@nestjs/testing';
import { INestApplication } from '@nestjs/common';
import request from 'supertest';
import { AppModule } from './../src/app.module';

describe('AppController (e2e)', () => {
  let app: INestApplication;

  beforeEach(async () => {
    const moduleFixture: TestingModule = await Test.createTestingModule({
      imports: [AppModule],
    }).compile();

    app = moduleFixture.createNestApplication();
    await app.init();
  });

  it('/api/v1 (GET)', () => {
    return request(app.getHttpServer())
      .get('/api/v1')
      .set('X-CSRF-TOKEN', 'your-csrf-token-here') // Include CSRF token if required
      .expect(200)
      .expect('Hello World!');
  });

  it('/api/v1/test (GET)', () => {
    return request(app.getHttpServer())
      .get('/api/v1/test')
      .set('X-CSRF-TOKEN', 'your-csrf-token-here') // Include CSRF token if required
      .expect(200)
      .expect('Test endpoint');
  });
});