// import RecordVO from '../viewmodel/RecordVO'
// import RecordItem from '../bean/RecordItem'
// import { common } from '@kit.AbilityKit'
// import router from '@ohos.router'
// import { fileUri } from '@kit.CoreFileKit'
// import { componentSnapshot } from '@kit.ArkUI'
// import { image } from '@kit.ImageKit'
// import fs from '@ohos.file.fs'
// import { ImageItemView } from '../view/ImageItemView'
//
//
// const CONTEXT: common.UIAbilityContext = getContext(this) as common.UIAbilityContext;
// const NODE_CONTAINER_ID = 'root';
//
// @Entry
// @Component
// export default struct ResultDialog {
//   @State record: RecordVO = new RecordVO(0, 0, 0, new RecordItem(0, '', '','', ''))
//   private img: ImageBitmap = new ImageBitmap("")
//   private settings: RenderingContextSettings = new RenderingContextSettings(true)
//   private context: CanvasRenderingContext2D = new CanvasRenderingContext2D(this.settings)
//   private matrix: Matrix2D = new Matrix2D()
//   private pattern: CanvasPattern | null = null
//   @State imageUrl: string = ''
//   @State filePath: string = '';
//   @State showImage: boolean = false
//   @State imageUri: string = ''
//   @State isEnableSwipe: boolean = true
//   @Provide bgc: Color = Color.White;
//   @State detectionText: string = '';
//   private thisDetectionId: string = '';
//
//   onPageShow(): void {
//     const params = router.getParams() as Map<string, RecordVO>;
//     if (params) {
//       this.record = params['record']
//       this.imageUrl = fileUri.getUriFromPath(this.record.imageUri!!)
//       this.img = new ImageBitmap(this.imageUrl)
//       if (this.record.detectionResultData?.detection_classes &&
//         this.record.detectionResultData?.detection_scores &&
//         this.record.detectionResultData?.detection_boxes) {
//
//         this.thisDetectionId = this.record.id.toString()
//         const detectionClasses = this.record.detectionResultData.detection_classes;
//         const detectionScores = this.record.detectionResultData.detection_scores;
//         const detectionBoxes = this.record.detectionResultData.detection_boxes;
//
//         this.detectionText = detectionClasses.map((cls, index) => {
//           const score = detectionScores[index]?.toFixed(2);
//           const box = detectionBoxes[index];
//           const boxText = box
//             ? `位置: ${box.map(coord => coord.toFixed(2)).join(', ')}`
//             : '位置: 未知';
//
//           return ` ${index + 1}: 缺陷类别：${cls} 置信度：${score}                     ${boxText}`;
//         }).join('\n');
//       }
//     }
//   }
//
//   build() {
//     Stack() {
//       Column() {
//         Row() {
//           Blank(10)
//           Button() {
//             Text('x')
//               .fontSize(15)
//               .fontColor(Color.White)
//               .fontWeight(800)
//           }
//           .width(20)
//           .height(20)
//           .backgroundColor(Color.Red)
//           .padding({ bottom: 5 })
//           .onClick(() => {
//             router.back()
//           })
//         }
//         .width('95%')
//         .justifyContent(FlexAlign.End)
//
//
//         if (this.record.detectionResult && this.imageUrl.length > 0 && this.record.detectionResultData) {
//           Column() {
//             Text() {
//               Span('检测id:' + this.thisDetectionId + '的')
//               Span($r('app.string.defect_number'))
//               Span(this.record.detectionResultData.detection_classes.length.toString())
//                 .fontColor(Color.Red)
//               Span($r('app.string.Danwei'))
//             }
//             .fontSize(20)
//             .fontWeight(600)
//             .opacity(0.8)
//           }
//           .width('95%')
//           .height(28)
//           .borderRadius(15)
//           .backgroundColor($r('app.color.light_gray'))
//
//           Column() {
//             Text('详细检测结果:')
//               .fontSize(20)
//               .fontWeight(600)
//               .margin({ top: 5 })
//             Text(this.detectionText)
//               .fontSize(16)
//               .fontWeight(600)
//               .margin({ top: 5, left: 25 })
//           }
//           .width('100%')
//           .backgroundColor($r('app.color.light_gray'))
//           .borderRadius(15)
//           .margin({ top: 5 })
//
//
//           Canvas(this.context)
//             .id(NODE_CONTAINER_ID)
//             .width(this.img.width / 2)
//             .height(this.img.height / 2)
//             .onReady(() => {
//               this.context.imageSmoothingEnabled = false
//               this.pattern = this.context.createPattern(this.img, 'no-repeat')
//               this.matrix.scaleY = 0.5
//               this.matrix.scaleX = 0.5
//               if (this.pattern) {
//                 this.context.fillStyle = this.pattern
//                 this.pattern.setTransform(this.matrix)
//               }
//               this.context.fillRect(0, 0, this.img.width / 2, this.img.height / 2)
//               this.record.detectionResultData?.detection_boxes.forEach((value: number[], index) => {
//                 let temp = value
//                 this.context.lineWidth = 1
//                 this.context.strokeStyle = Color.Red
//                 let y = this.pxConvert(temp[0])
//                 let x = this.pxConvert(temp[1])
//                 let h = this.pxConvert(temp[2]) - y
//                 let w = this.pxConvert(temp[3]) - x
//
//                 this.context.strokeRect(x, y, w, h)
//                 // this.context.stroke()
//                 this.context.save()
//                 this.context.fillStyle = '#007dff'
//                 this.context.textAlign = 'start'
//                 this.context.font = '30px'
//                 if (this.record.detectionResultData != null) {
//                   let text =
//                     this.record.detectionResultData.detection_classes[index] + " " +
//                     this.record.detectionResultData.detection_scores[index].toFixed(2)
//                   this.context.fillText(text, x, y)
//                 }
//               })
//             })
//             .margin({ top: 10 })
//             .onClick(() => {
//               componentSnapshot.get(NODE_CONTAINER_ID, async (error: Error, pixelMap: image.PixelMap) => {
//                 if (pixelMap !== null) {
//                   // 图片写入文件
//                   this.filePath = await this.packToFile(getContext(), pixelMap);
//                   this.imageUri = this.filePath
//                   // logger.info(TAG, `Images saved using the packToFile method are located in : ${this.filePath}`);
//                   this.showImage = true
//                 }
//               })
//
//             })
//         }
//
//
//       }.height('100%')
//
//       if (this.showImage) {
//         ImageItemView({ imageUri: this.imageUri, isEnableSwipe: this.isEnableSwipe })
//           .width("100%")
//           .height("100%")
//           .borderRadius(5)
//         Text("关闭")
//           .width('100%')
//           .onClick(() => {
//             this.showImage = false
//           }).align(Alignment.TopEnd)
//       }
//
//     }
//     .alignContent(Alignment.TopStart)
//     .height('100%')
//     .padding(12)
//   }
//
//   async packToFile(context: Context, pixelMap: PixelMap): Promise<string> {
//     // 创建图像编码ImagePacker对象
//     const imagePackerApi = image.createImagePacker();
//     // 设置编码输出流和编码参数。format为图像的编码格式；quality为图像质量，范围从0-100，100为最佳质量
//     const options: image.PackingOption = { format: 'image/jpeg', quality: 100 };
//     // 图片写入的沙箱路径
//     const filePath: string = `${context.filesDir}/${getTimeStr()}.jpg`;
//     // const phAccessHelper = photoAccessHelper.getPhotoAccessHelper(CONTEXT);
//     // const uri = await phAccessHelper.createAsset(photoAccessHelper.PhotoType.IMAGE, 'png');
//
//     const file: fs.File = await fs.open(filePath, fs.OpenMode.CREATE | fs.OpenMode.READ_WRITE);
//     // 使用packToFile直接将pixelMap写入文件
//     await imagePackerApi.packToFile(pixelMap, file.fd, options);
//     fs.closeSync(file);
//     return filePath;
//   }
//   pxConvert(value: number): number {
//     return (px2vp(value)) / 2
//   }
// }
//
// function getTimeStr(): string {
//   const now: Date = new Date();
//   const year: number = now.getFullYear();
//   const month: number = now.getMonth() + 1;
//   const day: number = now.getDate();
//   const hours: number = now.getHours();
//   const minutes: number = now.getMinutes();
//   const seconds: number = now.getSeconds();
//   return `${year}${month}${day}_${hours}${minutes}${seconds}`;
// }
//

//GPT4o
import RecordVO from '../viewmodel/RecordVO'
import RecordItem from '../bean/RecordItem'
import { common } from '@kit.AbilityKit'
import router from '@ohos.router'
import { fileUri } from '@kit.CoreFileKit'
import { componentSnapshot } from '@kit.ArkUI'
import { image } from '@kit.ImageKit'
import fs from '@ohos.file.fs'
import { ImageItemView } from '../view/ImageItemView'

const CONTEXT: common.UIAbilityContext = getContext(this) as common.UIAbilityContext;
const NODE_CONTAINER_ID = 'root';

@Entry
@Component
export default struct ResultDialog {
  @State record: RecordVO = new RecordVO(0, 0, 0, new RecordItem(0, '', $r('app.media.pcbIcon'), ''))
  private img: ImageBitmap = new ImageBitmap("")
  private settings: RenderingContextSettings = new RenderingContextSettings(true)
  private context: CanvasRenderingContext2D = new CanvasRenderingContext2D(this.settings)
  private matrix: Matrix2D = new Matrix2D()
  private pattern: CanvasPattern | null = null
  @State imageUrl: string = ''
  @State filePath: string = '';
  @State showImage: boolean = false
  @State imageUri: string = ''
  @State isEnableSwipe: boolean = true
  @Provide bgc: Color = Color.White;
  @State detectionText: string = '';
  private thisDetectionId: string = '';

  onPageShow(): void {
    const params: Map<string, RecordVO> = router.getParams() as Map<string, RecordVO>;
    if (params) {
      this.record = params['record']
      this.imageUrl = fileUri.getUriFromPath(this.record.imageUri!)
      this.img = new ImageBitmap(this.imageUrl)
      if (this.record.detectionResultData?.detection_classes) {
        this.thisDetectionId = this.record.id.toString();
        const detectionClasses = this.record.detectionResultData.detection_classes;

        this.detectionText = detectionClasses.toString(); // 直接转换为字符串显示
      }
    }
  }

  build() {
    Stack() {
      Column() {
        Row() {
          Blank(10)
          Button() {
            Text('x')
              .fontSize(15)
              .fontColor(Color.White)
              .fontWeight(800)
          }
          .width(20)
          .height(20)
          .backgroundColor(Color.Red)
          .padding({ bottom: 5 })
          .onClick(() => {
            router.back()
          })
        }
        .width('95%')
        .justifyContent(FlexAlign.End)

        if (this.record.detectionResult && this.imageUrl.length > 0 && this.record.detectionResultData) {
          Column() {
            Text() {
              Span('检测id:' + this.thisDetectionId + '的')
              Span($r('app.string.defect_number'))
              Span(this.record.detectionResultData.detection_classes.toString())
                .fontColor(Color.Red)
              Span($r('app.string.Danwei'))
            }
            .fontSize(20)
            .fontWeight(600)
            .opacity(0.8)
          }
          .width('95%')
          .height(28)
          .borderRadius(15)
          .backgroundColor($r('app.color.light_gray'))

          Column() {
            Text('详细检测结果:')
              .fontSize(20)
              .fontWeight(600)
              .margin({ top: 5 })
            Text(this.detectionText)
              .fontSize(16)
              .fontWeight(600)
              .margin({ top: 5, left: 25 })
          }
          .width('100%')
          .backgroundColor($r('app.color.light_gray'))
          .borderRadius(15)
          .margin({ top: 5 })

          Canvas(this.context)
            .id(NODE_CONTAINER_ID)
            .width(this.img.width / 2)
            .height(this.img.height / 2)
            .onReady(() => {
              this.context.imageSmoothingEnabled = false
              this.pattern = this.context.createPattern(this.img, 'no-repeat')
              this.matrix.scaleY = 0.5
              this.matrix.scaleX = 0.5
              if (this.pattern) {
                this.context.fillStyle = this.pattern
                this.pattern.setTransform(this.matrix)
              }
              this.context.fillRect(0, 0, this.img.width / 2, this.img.height / 2)
            })
            .margin({ top: 10 })
            .onClick(() => {
              componentSnapshot.get(NODE_CONTAINER_ID, async (error: Error, pixelMap: image.PixelMap) => {
                if (pixelMap !== null) {
                  // 图片写入文件
                  this.filePath = await this.packToFile(getContext(), pixelMap);
                  this.imageUri = this.filePath
                  this.showImage = true
                }
              })
            })
        }
      }.height('100%')

      if (this.showImage) {
        ImageItemView({ imageUri: this.imageUri, isEnableSwipe: this.isEnableSwipe })
          .width("100%")
          .height("100%")
          .borderRadius(5)
        Text("关闭")
          .width('100%')
          .onClick(() => {
            this.showImage = false
          }).align(Alignment.TopEnd)
      }
    }
    .alignContent(Alignment.TopStart)
    .height('100%')
    .padding(12)
  }

  async packToFile(context: Context, pixelMap: PixelMap): Promise<string> {
    const imagePackerApi = image.createImagePacker();
    const options: image.PackingOption = { format: 'image/jpeg', quality: 100 };
    const filePath: string = `${context.filesDir}/${getTimeStr()}.jpg`;
    const file: fs.File = await fs.open(filePath, fs.OpenMode.CREATE | fs.OpenMode.READ_WRITE);
    await imagePackerApi.packToFile(pixelMap, file.fd, options);
    fs.closeSync(file);
    return filePath;
  }

  pxConvert(value: number): number {
    return (px2vp(value)) / 2;
  }
}

function getTimeStr(): string {
  const now: Date = new Date();
  const year: number = now.getFullYear();
  const month: number = now.getMonth() + 1;
  const day: number = now.getDate();
  const hours: number = now.getHours();
  const minutes: number = now.getMinutes();
  const seconds: number = now.getSeconds();
  return `${year}${month}${day}_${hours}${minutes}${seconds}`;
}

//GPTo1
// import RecordVO from '../viewmodel/RecordVO';
// import RecordItem from '../bean/RecordItem';
// import { common } from '@kit.AbilityKit';
// import router from '@ohos.router';
// import { fileUri } from '@kit.CoreFileKit';
// import { componentSnapshot } from '@kit.ArkUI';
// import { image } from '@kit.ImageKit';
// import fs from '@ohos.file.fs';
// import { ImageItemView } from '../view/ImageItemView';
// import { DetectionResult } from '../viewmodel/resultViemModel'; // Ensure correct import
//
// const CONTEXT: common.UIAbilityContext = getContext(this) as common.UIAbilityContext;
// const NODE_CONTAINER_ID = 'root';
//
// @Entry
// @Component
// export default struct ResultDialog {
//   @State record: RecordVO = new RecordVO(0, 0, 0, new RecordItem(0, '', '', '')); // Adjusted RecordItem constructor
//   private img: image.PixelMap | null = null; // Use explicit type and initialize as null
//   private settings: RenderingContextSettings = new RenderingContextSettings(true);
//   private context: CanvasRenderingContext2D = new CanvasRenderingContext2D(this.settings);
//   private matrix: Matrix2D = new Matrix2D();
//   private pattern: CanvasPattern | null = null;
//   @State imageUrl: string = '';
//   @State filePath: string = '';
//   @State showImage: boolean = false;
//   @State imageUri: string = '';
//   @State isEnableSwipe: boolean = true;
//   @Provide bgc: Color = Color.White;
//   @State detectionText: string = '';
//   private thisDetectionId: string = '';
//
//   onPageShow(): void {
//     const params = router.getParams() as { record: RecordVO }; // Specify the type of params
//     if (params && params.record) {
//       this.record = params.record;
//       if (this.record.imageUri) {
//         this.imageUrl = fileUri.getUriFromPath(this.record.imageUri);
//         // Load the image as PixelMap
//         image.createPixelMap(this.imageUrl).then((pixelMap: image.PixelMap) => {
//           this.img = pixelMap;
//         }).catch((err) => {
//           console.error('Failed to create PixelMap:', err);
//         });
//       }
//       if (this.record.detectionResultData) {
//         this.thisDetectionId = this.record.id.toString();
//         const detectionClass = this.record.detectionResultData.detection_classes;
//         const detectionDuration = this.record.detectionResultData.detection_duration;
//
//         // Since detection_classes is a number, adjust the text accordingly
//         this.detectionText = `检测类别：${detectionClass}, 检测持续时间：${detectionDuration}s`;
//       }
//     }
//   }
//
//   build() {
//     Stack() {
//       Column() {
//         Row() {
//           Blank(10)
//           Button() {
//             Text('x')
//               .fontSize(15)
//               .fontColor(Color.White)
//               .fontWeight(800)
//           }
//           .width(20)
//           .height(20)
//           .backgroundColor(Color.Red)
//           .padding({ bottom: 5 })
//           .onClick(() => {
//             router.back();
//           })
//         }
//         .width('95%')
//         .justifyContent(FlexAlign.End)
//
//         if (this.record.detectionResult && this.imageUrl.length > 0 && this.record.detectionResultData) {
//           Column() {
//             Text() {
//               Span('检测id:' + this.thisDetectionId + '的')
//               Span('检测结果')
//               Span('1') // Since detection_classes is a single number
//                 .fontColor(Color.Red)
//               Span('个')
//             }
//             .fontSize(20)
//             .fontWeight(600)
//             .opacity(0.8)
//           }
//           .width('95%')
//           .height(28)
//           .borderRadius(15)
//           .backgroundColor($r('app.color.light_gray'))
//
//           Column() {
//             Text('详细检测结果:')
//               .fontSize(20)
//               .fontWeight(600)
//               .margin({ top: 5 })
//             Text(this.detectionText)
//               .fontSize(16)
//               .fontWeight(600)
//               .margin({ top: 5, left: 25 })
//           }
//           .width('100%')
//           .backgroundColor($r('app.color.light_gray'))
//           .borderRadius(15)
//           .margin({ top: 5 })
//
//           if (this.img) {
//             Canvas(this.context)
//               .id(NODE_CONTAINER_ID)
//               .width(this.img.width / 2)
//               .height(this.img.height / 2)
//               .onReady(() => {
//                 if (!this.img) return;
//                 this.context.imageSmoothingEnabled = false;
//                 this.pattern = this.context.createPattern(this.img, 'no-repeat');
//                 this.matrix.scaleY = 0.5;
//                 this.matrix.scaleX = 0.5;
//                 if (this.pattern) {
//                   this.context.fillStyle = this.pattern;
//                   this.pattern.setTransform(this.matrix);
//                 }
//                 this.context.fillRect(0, 0, this.img.width / 2, this.img.height / 2);
//                 // Since we don't have detection_boxes, we skip drawing boxes
//               })
//               .margin({ top: 10 })
//               .onClick(() => {
//                 componentSnapshot.get(NODE_CONTAINER_ID, async (error: Error, pixelMap: image.PixelMap) => {
//                   if (pixelMap) {
//                     // Save the image to a file
//                     this.filePath = await this.packToFile(getContext(), pixelMap);
//                     this.imageUri = this.filePath;
//                     this.showImage = true;
//                   }
//                 });
//               })
//           }
//         }
//       }.height('100%')
//
//       if (this.showImage) {
//         ImageItemView({ imageUri: this.imageUri, isEnableSwipe: this.isEnableSwipe })
//           .width("100%")
//           .height("100%")
//           .borderRadius(5)
//         Text("关闭")
//           .width('100%')
//           .onClick(() => {
//             this.showImage = false;
//           })
//           .align(Alignment.TopEnd)
//       }
//
//     }
//     .alignContent(Alignment.TopStart)
//     .height('100%')
//     .padding(12)
//   }
//
//   async packToFile(context: Context, pixelMap: image.PixelMap): Promise<string> {
//     // Create an image packer
//     const imagePackerApi = image.createImagePacker();
//     // Set encoding options
//     const options: image.PackingOption = { format: 'image/jpeg', quality: 100 };
//     // File path to save the image
//     const filePath: string = `${context.filesDir}/${getTimeStr()}.jpg`;
//
//     const file: fs.File = await fs.open(filePath, fs.OpenMode.CREATE | fs.OpenMode.READ_WRITE);
//     // Write the pixelMap to file
//     await imagePackerApi.packToFile(pixelMap, file.fd, options);
//     fs.closeSync(file);
//     return filePath;
//   }
//
//   pxConvert(value: number): number {
//     // Assuming px2vp is defined elsewhere
//     return px2vp(value) / 2;
//   }
// }
//
// function getTimeStr(): string {
//   const now: Date = new Date();
//   const year: number = now.getFullYear();
//   const month: number = now.getMonth() + 1;
//   const day: number = now.getDate();
//   const hours: number = now.getHours();
//   const minutes: number = now.getMinutes();
//   const seconds: number = now.getSeconds();
//   return `${year}${month}${day}_${hours}${minutes}${seconds}`;
// }
