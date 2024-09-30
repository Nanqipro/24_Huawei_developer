import RecordItemModel from '../model/RecordItemModel';
import RecordItem from '../bean/RecordItem';
import { DetectionResult } from './resultViemModel';

export default class RecordVO {
  //记录ID
  id: number;
  //检测任务ID
  detectId: number;
  //检测任务创建日期
  createTime: number;
  //检测任务信息
  recordItem: RecordItem
  // 检测结果
  detectionResult?: string;
  // 检测图片位置
  imageUri?: string;
  detectionResultData: DetectionResult = new DetectionResult([],[],[])

  constructor(
    id: number | undefined,
    detectId: number,
    createTime: number,
    recordItem: RecordItem,
    detectionResult?: string,
    imageUri?: string
  ) {
    this.id = id ?? 0;
    this.detectId = detectId;
    this.createTime = createTime;
    this.recordItem = RecordItemModel.getById(this.detectId);
    this.detectionResult = detectionResult;
    this.imageUri = imageUri;
  }
}