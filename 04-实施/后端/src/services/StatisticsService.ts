import { RecordModel } from '../models/RecordModel';
import { Record } from '../types';

export class StatisticsService {
  // 获取综合统计数据
  static getOverallStatistics() {
    // 获取所有记录
    const result = RecordModel.findAll({
      page: 1,
      page_size: 10000
    });
    
    const records = result.data;
    
    // 计算各种统计指标
    const totalRecords = records.length;
    
    // 按机房统计
    const datacenterStats = this.countByField(records, 'datacenter_name');
    
    // 按线缆类型统计
    const cableTypeStats = this.countByField(records, 'cable_type');
    
    // 按运营商统计
    const operatorStats = this.countByField(records, 'operator');
    
    // 标签齐全率统计
    const labelCompleteStats = this.calculateCompletionRate(records, 'label_complete');
    
    // 线路规范率统计
    const cableStandardStats = this.calculateCompletionRate(records, 'cable_standard');
    
    // 跳数分布统计
    const hopCountStats = this.calculateHopCountDistribution(records);
    
    return {
      totalRecords,
      datacenterStats,
      cableTypeStats,
      operatorStats,
      labelCompleteStats,
      cableStandardStats,
      hopCountStats,
      timestamp: new Date().toISOString()
    };
  }
  
  // 获取按机房的详细统计
  static getDatacenterStatistics() {
    // 获取所有记录
    const result = RecordModel.findAll({
      page: 1,
      page_size: 10000
    });
    
    const records = result.data;
    
    // 按机房分组
    const datacenterGroups = this.groupByField(records, 'datacenter_name');
    
    // 为每个机房生成统计数据
    const datacenterDetails = Object.entries(datacenterGroups).map(([datacenter, dcRecords]) => {
      // 按线缆类型统计
      const cableTypeStats = this.countByField(dcRecords, 'cable_type');
      
      // 按运营商统计
      const operatorStats = this.countByField(dcRecords, 'operator');
      
      // 标签齐全率
      const labelCompleteRate = this.calculateCompletionRate(dcRecords, 'label_complete');
      
      // 线路规范率
      const cableStandardRate = this.calculateCompletionRate(dcRecords, 'cable_standard');
      
      // 跳数分布
      const hopCountStats = this.calculateHopCountDistribution(dcRecords);
      
      return {
        datacenter,
        totalRecords: dcRecords.length,
        cableTypeStats,
        operatorStats,
        labelCompleteRate,
        cableStandardRate,
        hopCountStats
      };
    });
    
    return datacenterDetails;
  }
  
  // 按字段分组统计
  private static countByField(records: Record[], field: keyof Record) {
    const stats: Record<string, number> = {};
    
    records.forEach(record => {
      const value = record[field] as string || '未分类';
      stats[value] = (stats[value] || 0) + 1;
    });
    
    return stats;
  }
  
  // 按字段分组
  private static groupByField(records: Record[], field: keyof Record) {
    const groups: Record<string, Record[]> = {};
    
    records.forEach(record => {
      const value = record[field] as string || '未分类';
      if (!groups[value]) {
        groups[value] = [];
      }
      groups[value].push(record);
    });
    
    return groups;
  }
  
  // 计算完成率（0/1字段）
  private static calculateCompletionRate(records: Record[], field: keyof Record) {
    if (records.length === 0) {
      return {
        total: 0,
        completed: 0,
        rate: 0
      };
    }
    
    const total = records.length;
    const completed = records.filter(record => record[field] === 1).length;
    const rate = parseFloat(((completed / total) * 100).toFixed(2));
    
    return {
      total,
      completed,
      rate
    };
  }
  
  // 计算跳数分布
  private static calculateHopCountDistribution(records: Record[]) {
    const hopCounts: Record<string, number> = {};
    
    records.forEach(record => {
      let hopCount = 0;
      
      // 计算实际跳数
      if (record.hop1) hopCount++;
      if (record.hop2) hopCount++;
      if (record.hop3) hopCount++;
      if (record.hop4) hopCount++;
      if (record.hop5) hopCount++;
      
      const hopKey = `${hopCount}跳`;
      hopCounts[hopKey] = (hopCounts[hopKey] || 0) + 1;
    });
    
    return hopCounts;
  }
  
  // 获取导出的统计报表数据
  static getExportableStatistics() {
    const overallStats = this.getOverallStatistics();
    const datacenterDetails = this.getDatacenterStatistics();
    
    return {
      overall: overallStats,
      datacenters: datacenterDetails,
      exportDate: new Date().toISOString()
    };
  }
}