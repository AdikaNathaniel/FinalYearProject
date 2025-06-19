import { Injectable, Inject } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model } from 'mongoose';
import { TopChart } from 'src/shared/schema/top-chart.schema';
import { CreateTopChartDto } from 'src/users/dto/create-top-chart.dto';
import { UpdateTopChartDto } from 'src/users/dto/update-top-chart.dto';

@Injectable()
export class TopChartsService {
    constructor(
        @InjectModel(TopChart.name) private readonly topChartModel: Model<TopChart>,
    ) {}

    async create(createTopChartDto: CreateTopChartDto) {
        try {
            const createdTopChart = new this.topChartModel(createTopChartDto);
            await createdTopChart.save();

            return {
                success: true,
                message: 'Product created successfully',
                result: createdTopChart,
            };
        } catch (error) {
            throw error;
        }
    }

    async findAll() {
        try {
            const topCharts = await this.topChartModel.find().exec();

            return {
                success: true,
                message: 'Products retrieved successfully',
                result: topCharts,
            };
        } catch (error) {
            throw error;
        }
    }

    async findOneByProductName(productName: string) { // Changed from findOne to findOneByProductName
        try {
            const product = await this.topChartModel.findOne({ productName }).exec(); // Changed to findOne by productName
            if (!product) {
                return {
                    success: false,
                    message: 'Product not found',
                    result: null,
                };
            }

            return {
                success: true,
                message: 'Product retrieved successfully',
                result: product,
            };
        } catch (error) {
            throw error;
        }
    }

    async updateByProductName(productName: string, updateTopChartDto: UpdateTopChartDto) { // Changed from update to updateByProductName
        try {
            const updatedProduct = await this.topChartModel.findOneAndUpdate(
                { productName },
                updateTopChartDto,
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
            const deletedProduct = await this.topChartModel.findOneAndDelete({ productName }); // Changed to findOneAndDelete by productName

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
            const products = await this.topChartModel.find({ category }).exec();

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