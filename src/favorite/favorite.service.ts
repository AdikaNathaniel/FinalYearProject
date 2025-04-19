import { Injectable, Inject } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model } from 'mongoose';
import { Favorite } from 'src/shared/schema/favorite.schema';
import { CreateFavoriteDto } from 'src/users/dto/create-favorite.dto';
import { UpdateFavoriteDto } from 'src/users/dto/update-favorite.dto';

@Injectable()
export class FavoriteService {
    constructor(
        @InjectModel(Favorite.name) private readonly FavoriteModel: Model<Favorite>,
    ) {}

    async create(createFavoriteDto: CreateFavoriteDto) {
        try {
            const createdFavorite = new this.FavoriteModel(createFavoriteDto);
            await createdFavorite.save();

            return {
                success: true,
                message: 'Favorite created successfully',
                result: createdFavorite,
            };
        } catch (error) {
            throw error;
        }
    }

    async findAll() {
        try {
            const Favorite = await this.FavoriteModel.find().exec();

            return {
                success: true,
                message: 'Favorite retrieved successfully',
                result: Favorite,
            };
        } catch (error) {
            throw error;
        }
    }

    async findOneByProductName(productName: string) { // Changed from findOne to findOneByProductName
        try {
            const product = await this.FavoriteModel.findOne({ productName }).exec(); // Changed to findOne by productName
            if (!product) {
                return {
                    success: false,
                    message: 'Product not found',
                    result: null,
                };
            }

            return {
                success: true,
                message: 'Favorite retrieved successfully',
                result: product,
            };
        } catch (error) {
            throw error;
        }
    }

    async updateByProductName(productName: string, updateFavoriteDto: UpdateFavoriteDto) { // Changed from update to updateByProductName
        try {
            const updatedProduct = await this.FavoriteModel.findOneAndUpdate(
                { productName },
                updateFavoriteDto,
                { new: true },
            );

            if (!updatedProduct) {
                return {
                    success: false,
                    message: 'Product not found',
                    result: null,
                };
            }

            return {
                success: true,
                message: 'Product updated successfully',
                result: updatedProduct,
            };
        } catch (error) {
            throw error;
        }
    }

    async removeByProductName(productName: string) { // Changed from remove to removeByProductName
        try {
            const deletedProduct = await this.FavoriteModel.findOneAndDelete({ productName }); // Changed to findOneAndDelete by productName

            if (!deletedProduct) {
                return {
                    success: false,
                    message: 'Product not found',
                    result: null,
                };
            }

            return {
                success: true,
                message: 'Product deleted successfully',
                result: deletedProduct,
            };
        } catch (error) {
            throw error;
        }
    }

    async filterByCategory(category: string) {
        try {
            const products = await this.FavoriteModel.find({ category }).exec();

            return {
                success: true,
                message: 'Products filtered by category successfully',
                result: products,
            };
        } catch (error) {
            throw error;
        }
    }
}