// interface DetectionResultJSON {
//   detection_classes: string[];
//   detection_boxes: number[][];
//   detection_scores: number[];
// }
//
// export class DetectionResult {
//   detection_classes: string[];
//   detection_boxes: number[][];
//   detection_scores: number[];
//
//   constructor(
//     detectionClasses: string[],
//     detectionBoxes: number[][],
//     detectionScores: number[]
//   ) {
//     this.detection_classes = detectionClasses;
//     this.detection_boxes = detectionBoxes;
//     this.detection_scores = detectionScores;
//   }
//
//   // 从 JSON 对象创建 DetectionResult 实例
//   static fromJson(json: DetectionResultJSON): DetectionResult {
//     return new DetectionResult(
//       json.detection_classes,
//       json.detection_boxes,
//       json.detection_scores
//     );
//   }
// }

interface DetectionResultJSON {
  detection_classes: number;
  detection_duration: number;
}

export class DetectionResult {
  detection_classes: number;
  detection_duration: number;

  constructor(
    detectionClasses: number,
    detectionDuration: number
  ) {
    this.detection_classes = detectionClasses;
    this.detection_duration = detectionDuration;
  }

  // 从 JSON 对象创建 DetectionResult 实例
  static fromJson(json: DetectionResultJSON): DetectionResult {
    return new DetectionResult(
      json.detection_classes,
      json.detection_duration,
    );
  }
}