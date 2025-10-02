import { Injectable } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
// import { Client, Databases } from 'appwrite';
import { Client, Databases } from 'node-appwrite';

@Injectable()
export class AppwriteService {
  private client: Client;
  private databases: Databases;

  constructor(private configService: ConfigService) {
    // Initialize the Appwrite client
    // this.client = new Client()
    //   .setEndpoint('https://cloud.appwrite.io/v1')
    //   .setProject('682d4f730001443567d3')
    //   // Add API key for server-side authentication
    //   .setKey(this.configService.get('APPWRITE_API_KEY') || 'standard_2c0de3d3aa7f16786fa56f019725a06fdcd126da275a0259c93cb309587556d8e0ea0325526a26e63161056713f19277b88e2303d3b7721ec5152290348df5bea1b6e64b672168b2a3889e5b420b680392077019438dadea723a7430b7ac8120019574971426fade2ac73f1e9629c76e2715b74c85b22504f843d6ca3b6b676e');
      


    // In your AppwriteService constructor
this.client = new Client()
  .setEndpoint('https://cloud.appwrite.io/v1')
  .setProject('682d4f730001443567d3');
  this.client.setKey('standard_2c0de3d3aa7f16786fa56f019725a06fdcd126da275a0259c93cb309587556d8e0ea0325526a26e63161056713f19277b88e2303d3b7721ec5152290348df5bea1b6e64b672168b2a3889e5b420b680392077019438dadea723a7430b7ac8120019574971426fade2ac73f1e9629c76e2715b74c85b22504f843d6ca3b6b676e');
  
    this.databases = new Databases(this.client);
  }

  async getDatabase() {
    return this.databases;
  }


  async healthCheck() {
  try {
    // Check connection by listing documents
    await this.databases.listDocuments('682d4fed000729da9e0d', '682d50ac001b5276d5aa');
    return true;
  } catch (error) {
    console.error('Appwrite connection error:', {
      message: error.message,
      code: error.code,
      type: error.type,
      response: error.response
    });
    return false;
  }
}
}