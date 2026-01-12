import { RecordModel } from '../models/RecordModel';
import { Record as RecordType } from '../types';

export class StatisticsService {
  static getOverallStatistics() {
    const result = RecordModel.findAll({
      page: 1,
      page_size: 10000
    });
    
    const records = result.data;
    
    const totalRecords = records.length;
    
    const datacenterStats = this.countByField(records, 'datacenter_name');
    
    const cableTypeStats = this.countByField(records, 'cable_type');
    
    const operatorStats = this.countByField(records, 'operator');
    
    const labelCompleteStats = this.calculateCompletionRate(records, 'label_complete');
    
    const cableStandardStats = this.calculateCompletionRate(records, 'cable_standard');
    
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
  
  static getDatacenterStatistics() {
    // 获取所有记录
    const result = RecordModel.findAll({
      page: 1,
      page_size: 10000
    });
    
    const records = result.data;
    
    // 按机房分组
    const datacenterGroups = this.groupByField(records, 'datacenter_name');
    
    const datacenterDetails = Object.entries(datacenterGroups).map(([datacenter, dcRecords]) => {
      const cableTypeStats = this.countByField(dcRecords as RecordType[], 'cable_type');
      
      const operatorStats = this.countByField(dcRecords as RecordType[], 'operator');
      
      const labelCompleteRate = this.calculateCompletionRate(dcRecords as RecordType[], 'label_complete');
      
      const cableStandardRate = this.calculateCompletionRate(dcRecords as RecordType[], 'cable_standard');
      
      const hopCountStats = this.calculateHopCountDistribution(dcRecords as RecordType[]);
      
      return {
        datacenter,
        totalRecords: (dcRecords as RecordType[]).length,
        cableTypeStats,
        operatorStats,
        labelCompleteRate,
        cableStandardRate,
        hopCountStats
      };
    });
    
    return datacenterDetails;
  }
  
  private static countByField(records: RecordType[], field: keyof RecordType) {
    const stats: { [key: string]: number } = {};
    
    records.forEach(record => {
      const value = record[field] as string || '未分类';
      stats[value] = (stats[value] || 0) + 1;
    });
    
    return stats;
  }
  
  private static groupByField(records: RecordType[], field: keyof RecordType) {
    const groups: { [key: string]: RecordType[] } = {};
    
    records.forEach(record => {
      const value = record[field] as string || '未分类';
      if (!groups[value]) {
        groups[value] = [];
      }
      groups[value].push(record);
    });
    
    return groups;
  }
  
  private static calculateCompletionRate(records: RecordType[], field: keyof RecordType) {
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
  
  private static calculateHopCountDistribution(records: RecordType[]) {
    const hopCounts: { [key: string]: number } = {};
    
    records.forEach(record => {
      let hopCount = 0;
      
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

  static getJumpFiberStatistics() {
    const result = RecordModel.findAll({
      page: 1,
      page_size: 10000
    });
    
    const records = result.data;
    
    const datacenterGroups = this.groupByField(records, 'datacenter_name');
    
    const jumpFiberStats = Object.entries(datacenterGroups).map(([datacenter, dcRecords]) => {
      const dcRecordsTyped = dcRecords as RecordType[];
      const total = dcRecordsTyped.length;
      
      let inUse = 0;
      let removed = 0;
      
      dcRecordsTyped.forEach(record => {
        if (record.cable_standard === 1) {
          inUse++;
        } else if (record.cable_standard === 0) {
          removed++;
        }
      });
      
      const inUseRate = total > 0 ? parseFloat(((inUse / total) * 100).toFixed(2)) : 0;
      const removedRate = total > 0 ? parseFloat(((removed / total) * 100).toFixed(2)) : 0;
      
      return {
        datacenter,
        total,
        inUse,
        removed,
        inUseRate,
        removedRate
      };
    });
    
    return {
      datacenters: jumpFiberStats,
      total: jumpFiberStats.reduce((sum, stat) => sum + stat.total, 0),
      totalInUse: jumpFiberStats.reduce((sum, stat) => sum + stat.inUse, 0),
      totalRemoved: jumpFiberStats.reduce((sum, stat) => sum + stat.removed, 0),
      timestamp: new Date().toISOString()
    };
  }
}