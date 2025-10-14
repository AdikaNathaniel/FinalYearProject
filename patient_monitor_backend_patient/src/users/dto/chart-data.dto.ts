// src/dto/chart-data.dto.ts
export class ChartDataDto {
  labels: string[];
  datasets: {
    label: string;
    data: number[];
    borderColor: string;
    backgroundColor: string;
    tension?: number;
    // fill: boolean;
  }[];
}
