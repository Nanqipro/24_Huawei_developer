import RecordItem from '../bean/RecordItem'
import DateUtil from '../utils/DateUtil'
import MediaUtil from '../utils/MediaUtil'
import ItemModel from '../model/RecordItemModel'
import Logger from '../utils/Logger'
import router from '@ohos.router';
import { picker } from '@kit.CoreFileKit';
import { photoAccessHelper } from '@kit.MediaLibraryKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { dataSharePredicates } from '@kit.ArkData';
import KeepService from '../service/KeepService'
import { http } from '@kit.NetworkKit';
import { image } from '@kit.ImageKit';
import resourceManager from '@ohos.resourceManager'
import PermissionsUtil from '../utils/PermissionsUtil'
import { Permissions } from '@kit.AbilityKit';
import fs from '@ohos.file.fs';
import { DetectionResult } from '../viewmodel/resultViemModel'

@Preview
@CustomDialog
@Component
export default struct TaskAddDialog {

  @StorageProp('data') data: number = DateUtil.beginTimeOfDay(new Date())
  @Prop itemId: number
  @State recordItem: RecordItem = ItemModel.getById(this.itemId)
  @State pixelMap: image.PixelMap  | undefined = undefined
  @State uriTemp: string = ''
  private permissions: Array<Permissions> = ['ohos.permission.WRITE_IMAGEVIDEO','ohos.permission.READ_IMAGEVIDEO']
  private imageUri: string = ''

  controller: CustomDialogController
  mediaController: MediaUtil = new MediaUtil()

  // 点击后开始检测
  onConfirm() {
    // Logger.debug('检测任务id'+ this.itemId)
    // // 将记录想添加到数据库并返回到主页面
    // KeepService.insert(this.itemId)
    //   .then(() => {
    //     router.replaceUrl({ url: 'pages/MainIndex' })
    //     this.controller.close()
    // })
    this.requestHttpPost()
      .then((detectionResult) => {
        let imageUri = this.imageUri
        Logger.debug('检测itemId：' + this.itemId)
        // Logger.debug('检测结果：' + detectionResult)
        Logger.debug('图片位置：' + imageUri)
        // 将图片位置和检测结果存储到全局
        return KeepService.insert(this.itemId, detectionResult, imageUri)
      })
      .then(() => {
        router.replaceUrl({ url: 'pages/MainIndex' });
        this.controller.close();
      })
      .catch((err: Error) => {
        Logger.error('发生错误: ' + err.message);
      });
  }

  async aboutToAppear(): Promise<void> {
    PermissionsUtil.checkPermissions(this.permissions)
  }

  // 打包 PixelMap 为 jpg 格式
  async packingPixelMap2Jpg(pixelMap: PixelMap): Promise<ArrayBuffer> {
    const imagePackerApi = image.createImagePacker();
    const packOpts: image.PackingOption = { format: "image/jpeg", quality: 98 };
    let imageBuffer: ArrayBuffer = new ArrayBuffer(1);
    try {
      // 图片压缩或重新打包
      imageBuffer = await imagePackerApi.packing(pixelMap, packOpts);
    } catch (err) {
      console.error(`Invoke packingPixelMap2Jpg failed, err: ${JSON.stringify(err)}`);
    }
    return imageBuffer;
  }

  // 在rawfile读取图片
  async getPixelMapByImage():Promise<image.PixelMap>{
    const context : Context = getContext(this);
    // 获取resourceManager资源管理器
    const resourceMgr : resourceManager.ResourceManager = context.resourceManager;
    let rawFileDescriptor = await resourceMgr.getRawFd('detectImg.jpg')
    const imageSource : image.ImageSource = image.createImageSource(rawFileDescriptor);
    let decodingOptions : image.DecodingOptions = {
      editable: true,
      desiredPixelFormat: 3,
    }
    // 创建pixelMap并进行简单的旋转和缩放
    const pixelMap:image.PixelMap = await imageSource.createPixelMap(decodingOptions)
    this.pixelMap =  pixelMap
    return pixelMap;
  }


  //展示相册第一张图片
  async showFirstPhoto() {
    let context = getContext(this);
    let phAccessHelper = photoAccessHelper.getPhotoAccessHelper(context);
    console.info('getAssets');
    let predicates: dataSharePredicates.DataSharePredicates = new dataSharePredicates.DataSharePredicates();
    let fetchOptions: photoAccessHelper.FetchOptions = {
      fetchColumns: [],
      predicates: predicates
    };
    phAccessHelper.getAssets(fetchOptions, async (err, fetchResult) => {
      if (fetchResult !== undefined) {
        console.info('fetchResult success');
        let photoAsset: photoAccessHelper.PhotoAsset = await fetchResult.getFirstObject();
        this.uriTemp = photoAsset.uri
        if (photoAsset !== undefined) {
          console.info('photoAsset.displayName : ' + photoAsset.displayName);
        }
      } else {
        console.error(`fetchResult fail with error: ${err.code}, ${err.message}`);
      }
    });
  }

  // 读取图片并写入相册
  async WritePhoto() {
    console.info('createAssetDemo');
    let context = getContext(this);
    let phAccessHelper = photoAccessHelper.getPhotoAccessHelper(context);
    let photoType: photoAccessHelper.PhotoType = photoAccessHelper.PhotoType.IMAGE;
    let extension:string = 'jpg';
    let options: photoAccessHelper.CreateOptions = {
      title: 'testPhoto'
    }
    let uri = await phAccessHelper.createAsset(photoType, extension, options);
    // 使用uri打开文件，可以持续写入内容，写入过程不受时间限制
    let file = await fs.open(uri, fs.OpenMode.READ_WRITE | fs.OpenMode.CREATE);
    try {
      const imageBuffer = await this.packingPixelMap2Jpg(this.pixelMap as image.PixelMap)

      // 写到媒体库文件中
      await fs.write(file.fd, imageBuffer);
      await fs.close(file.fd);
      AlertDialog.show({message:'已保存至相册!'});
      Logger.debug('已保存至相册')
    }
    catch (err) {
      console.error("error is "+ JSON.stringify(err))
    }
  }

  // pickPhoto选择图片
  selectImage(): Promise<string> {
    return new Promise((resolve, reject) => {
      let photoViewPicker = new picker.PhotoViewPicker();
      let photoSelectOption = new picker.PhotoSelectOptions();
      photoSelectOption.MIMEType = picker.PhotoViewMIMETypes.IMAGE_TYPE;
      photoViewPicker.select(photoSelectOption).then((photoSelectResult) => {
        Logger.debug("图片选择结果:" + photoSelectResult);
        let uri = photoSelectResult.photoUris[0];
        Logger.debug("图片uri:" + uri);
        resolve(uri);
      }).catch((err: BusinessError) => {
        Logger.debug('Invoke photoViewPicker.select failed, code is' + err.code + 'message is' + err.message);
        reject(err);
      });
    });
}

  requestHttpPost(): Promise<DetectionResult> {
  return new Promise((resolve, reject) => {
    let uri = '';
    let photoViewPicker = new picker.PhotoViewPicker();
    let photoSelectOption = new picker.PhotoSelectOptions();
    photoSelectOption.MIMEType = picker.PhotoViewMIMETypes.IMAGE_TYPE;
    photoViewPicker.select(photoSelectOption).then((photoSelectResult) => {
      Logger.debug("图片选择结果:" + photoSelectResult);
      uri = photoSelectResult.photoUris[0];
      Logger.debug("图片uri:" + uri);
      try {
        let resultPhoto = fs.openSync(uri, fs.OpenMode.READ_ONLY);
        // let resultName = resultPhoto.name;
        let fileTemp = fs.openSync(getContext().filesDir + resultPhoto.name, fs.OpenMode.READ_WRITE | fs.OpenMode.CREATE);
        let imageUri = fileTemp.path;
        this.imageUri = imageUri
        fs.copyFileSync(resultPhoto.fd, fileTemp.fd);
        fs.closeSync(resultPhoto);
        fs.closeSync(fileTemp);
        const httpRequest = http.createHttp();
        httpRequest.request('https://infer-modelarts-cn-southwest-2.myhuaweicloud.com/v1/infers/0b1e4db5-ead9-4fd3-b0b3-3c97f11be574', {
          method: http.RequestMethod.POST,
          header: {
            'content-Type': 'multipart/form-data',
            'Connection': 'keep-alive',
            'X-Auth-Token': 'MIIOMwYJKoZIhvcNAQcCoIIOJDCCDiACAQExDTALBglghkgBZQMEAgEwggxFBgkqhkiG9w0BBwGgggw2BIIMMnsidG9rZW4iOnsiZXhwaXJlc19hdCI6IjIwMjQtMDktMDhUMTE6MTc6NDAuODg1MDAwWiIsIm1ldGhvZHMiOlsicGFzc3dvcmQiXSwiY2F0YWxvZyI6W10sInJvbGVzIjpbeyJuYW1lIjoidGVfYWRtaW4iLCJpZCI6IjAifSx7Im5hbWUiOiJ0ZV9hZ2VuY3kiLCJpZCI6IjAifSx7Im5hbWUiOiJvcF9nYXRlZF9jc2JzX3JlcF9hY2NlbGVyYXRpb24iLCJpZCI6IjAifSx7Im5hbWUiOiJvcF9nYXRlZF9lY3NfZGlza0FjYyIsImlkIjoiMCJ9LHsibmFtZSI6Im9wX2dhdGVkX2Rzc19tb250aCIsImlkIjoiMCJ9LHsibmFtZSI6Im9wX2dhdGVkX29ic19kZWVwX2FyY2hpdmUiLCJpZCI6IjAifSx7Im5hbWUiOiJvcF9nYXRlZF9hX2NuLXNvdXRoLTRjIiwiaWQiOiIwIn0seyJuYW1lIjoib3BfZ2F0ZWRfZGVjX21vbnRoX3VzZXIiLCJpZCI6IjAifSx7Im5hbWUiOiJvcF9nYXRlZF9jYnJfc2VsbG91dCIsImlkIjoiMCJ9LHsibmFtZSI6Im9wX2dhdGVkX2Vjc19vbGRfcmVvdXJjZSIsImlkIjoiMCJ9LHsibmFtZSI6Im9wX2dhdGVkX3Bhbmd1IiwiaWQiOiIwIn0seyJuYW1lIjoib3BfZ2F0ZWRfd2VsaW5rYnJpZGdlX2VuZHBvaW50X2J1eSIsImlkIjoiMCJ9LHsibmFtZSI6Im9wX2dhdGVkX2Nicl9maWxlIiwiaWQiOiIwIn0seyJuYW1lIjoib3BfZ2F0ZWRfZG1zLXJvY2tldG1xNS1iYXNpYyIsImlkIjoiMCJ9LHsibmFtZSI6Im9wX2dhdGVkX2Rtcy1rYWZrYTMiLCJpZCI6IjAifSx7Im5hbWUiOiJvcF9nYXRlZF9lZGdlc2VjX29idCIsImlkIjoiMCJ9LHsibmFtZSI6Im9wX2dhdGVkX29ic19kZWNfbW9udGgiLCJpZCI6IjAifSx7Im5hbWUiOiJvcF9nYXRlZF9jc2JzX3Jlc3RvcmUiLCJpZCI6IjAifSx7Im5hbWUiOiJvcF9nYXRlZF9pZG1lX21ibV9mb3VuZGF0aW9uIiwiaWQiOiIwIn0seyJuYW1lIjoib3BfZ2F0ZWRfZWNzX2M2YSIsImlkIjoiMCJ9LHsibmFtZSI6Im9wX3BjX3ZlbmRvcl9zdWJ1c2VyIiwiaWQiOiIwIn0seyJuYW1lIjoib3BfZ2F0ZWRfbXVsdGlfYmluZCIsImlkIjoiMCJ9LHsibmFtZSI6Im9wX2dhdGVkX3Ntbl9jYWxsbm90aWZ5IiwiaWQiOiIwIn0seyJuYW1lIjoib3BfZ2F0ZWRfYV9hcC1zb3V0aGVhc3QtM2QiLCJpZCI6IjAifSx7Im5hbWUiOiJvcF9nYXRlZF9jc2JzX3Byb2dyZXNzYmFyIiwiaWQiOiIwIn0seyJuYW1lIjoib3BfZ2F0ZWRfY2VzX3Jlc291cmNlZ3JvdXBfdGFnIiwiaWQiOiIwIn0seyJuYW1lIjoib3BfZ2F0ZWRfZWNzX29mZmxpbmVfYWM3IiwiaWQiOiIwIn0seyJuYW1lIjoib3BfZ2F0ZWRfZXZzX3JldHlwZSIsImlkIjoiMCJ9LHsibmFtZSI6Im9wX2dhdGVkX2tvb21hcCIsImlkIjoiMCJ9LHsibmFtZSI6Im9wX2dhdGVkX2V2c19lc3NkMiIsImlkIjoiMCJ9LHsibmFtZSI6Im9wX2dhdGVkX2Rtcy1hbXFwLWJhc2ljIiwiaWQiOiIwIn0seyJuYW1lIjoib3BfZ2F0ZWRfZXZzX3Bvb2xfY2EiLCJpZCI6IjAifSx7Im5hbWUiOiJvcF9nYXRlZF9hX2NuLXNvdXRod2VzdC0yYiIsImlkIjoiMCJ9LHsibmFtZSI6Im9wX2dhdGVkX2h3Y3BoIiwiaWQiOiIwIn0seyJuYW1lIjoib3BfZ2F0ZWRfZWNzX29mZmxpbmVfZGlza180IiwiaWQiOiIwIn0seyJuYW1lIjoib3BfZ2F0ZWRfaHdkZXYiLCJpZCI6IjAifSx7Im5hbWUiOiJvcF9nYXRlZF9zbW5fd2VsaW5rcmVkIiwiaWQiOiIwIn0seyJuYW1lIjoib3BfZ2F0ZWRfY2NlX2F1dG9waWxvdCIsImlkIjoiMCJ9LHsibmFtZSI6Im9wX2dhdGVkX2h2X3ZlbmRvciIsImlkIjoiMCJ9LHsibmFtZSI6Im9wX2dhdGVkX2FfY24tbm9ydGgtNGUiLCJpZCI6IjAifSx7Im5hbWUiOiJvcF9nYXRlZF9hX2NuLW5vcnRoLTRkIiwiaWQiOiIwIn0seyJuYW1lIjoib3BfZ2F0ZWRfZWNzX2hlY3NfeCIsImlkIjoiMCJ9LHsibmFtZSI6Im9wX2dhdGVkX2Vjc19hYzciLCJpZCI6IjAifSx7Im5hbWUiOiJvcF9nYXRlZF9lcHMiLCJpZCI6IjAifSx7Im5hbWUiOiJvcF9nYXRlZF9jc2JzX3Jlc3RvcmVfYWxsIiwiaWQiOiIwIn0seyJuYW1lIjoib3BfZ2F0ZWRfYV9jbi1ub3J0aC00ZiIsImlkIjoiMCJ9LHsibmFtZSI6Im9wX2dhdGVkX29jdG9wdXMiLCJpZCI6IjAifSx7Im5hbWUiOiJvcF9nYXRlZF9vcF9nYXRlZF9yb3VuZHRhYmxlIiwiaWQiOiIwIn0seyJuYW1lIjoib3BfZ2F0ZWRfZXZzX2V4dCIsImlkIjoiMCJ9LHsibmFtZSI6Im9wX2dhdGVkX3Bmc19kZWVwX2FyY2hpdmUiLCJpZCI6IjAifSx7Im5hbWUiOiJvcF9nYXRlZF9hX2FwLXNvdXRoZWFzdC0xZSIsImlkIjoiMCJ9LHsibmFtZSI6Im9wX2dhdGVkX2FfcnUtbW9zY293LTFiIiwiaWQiOiIwIn0seyJuYW1lIjoib3BfZ2F0ZWRfYV9hcC1zb3V0aGVhc3QtMWQiLCJpZCI6IjAifSx7Im5hbWUiOiJvcF9nYXRlZF9hcHBzdGFnZSIsImlkIjoiMCJ9LHsibmFtZSI6Im9wX2dhdGVkX2FfYXAtc291dGhlYXN0LTFmIiwiaWQiOiIwIn0seyJuYW1lIjoib3BfZ2F0ZWRfc21uX2FwcGxpY2F0aW9uIiwiaWQiOiIwIn0seyJuYW1lIjoib3BfZ2F0ZWRfZXZzX2NvbGQiLCJpZCI6IjAifSx7Im5hbWUiOiJvcF9nYXRlZF9yZHNfY2EiLCJpZCI6IjAifSx7Im5hbWUiOiJvcF9nYXRlZF9lY3NfZ3B1X2c1ciIsImlkIjoiMCJ9LHsibmFtZSI6Im9wX2dhdGVkX29wX2dhdGVkX21lc3NhZ2VvdmVyNWciLCJpZCI6IjAifSx7Im5hbWUiOiJvcF9nYXRlZF9lY3NfcmkiLCJpZCI6IjAifSx7Im5hbWUiOiJvcF9nYXRlZF9hX3J1LW5vcnRod2VzdC0yYyIsImlkIjoiMCJ9LHsibmFtZSI6Im9wX2dhdGVkX2llZl9wbGF0aW51bSIsImlkIjoiMCJ9XSwicHJvamVjdCI6eyJkb21haW4iOnsibmFtZSI6Ik5DVS1Eb25nWXVDb25nIiwiaWQiOiJkMzlkZGJlNzcxZmM0OTVmOTM2ZTY5YmI2YjBmZjM5YyJ9LCJuYW1lIjoiY24tc291dGh3ZXN0LTIiLCJpZCI6ImVlODQzYjU0OTQzNjQwNzdhZDMwN2FmODgxMTMyMWE4In0sImlzc3VlZF9hdCI6IjIwMjQtMDktMDdUMTE6MTc6NDAuODg1MDAwWiIsInVzZXIiOnsiZG9tYWluIjp7Im5hbWUiOiJOQ1UtRG9uZ1l1Q29uZyIsImlkIjoiZDM5ZGRiZTc3MWZjNDk1ZjkzNmU2OWJiNmIwZmYzOWMifSwibmFtZSI6Ik5DVS1Eb25nWXVDb25nIiwicGFzc3dvcmRfZXhwaXJlc19hdCI6IiIsImlkIjoiZDBhMTk2YmMyZTk0NGE0NTljNzg0NzUwMzc0ZTVmMzYifX19MYIBwTCCAb0CAQEwgZcwgYkxCzAJBgNVBAYTAkNOMRIwEAYDVQQIDAlHdWFuZ0RvbmcxETAPBgNVBAcMCFNoZW5aaGVuMS4wLAYDVQQKDCVIdWF3ZWkgU29mdHdhcmUgVGVjaG5vbG9naWVzIENvLiwgTHRkMQ4wDAYDVQQLDAVDbG91ZDETMBEGA1UEAwwKY2EuaWFtLnBraQIJANyzK10QYWoQMAsGCWCGSAFlAwQCATANBgkqhkiG9w0BAQEFAASCAQBOwvVZIrvCuNPPVk-pthKYdMlO521y+rj+EdlkLq61fIeC-KyN43dW6cVF417NuDDOpqIzWr0oRKq+1hHcfELUgqLBFOhDVYzZThHs6E46xTsg0fItQdLb95kDK+znYBbv-kQKV2YPn-3EIvc4j3fIN4y+Ekh7T8ylFIEd9BkIYRFjAjBTiLv+-E-+Cq6cDbewTZXXMtlov8m9cXO4O2AsUr4VHaJCGm5bWs4asgKZUAuj2EW9ufWbTQPvwCg0kdza24yFByhvt7Rkwqea2B4eNOBRkyC9cJt4DT-HeVS2GQkwtJZ+qzaNUMBXGeroa3PGE9juQjPyocNnk7OnYq2R'
          },
          expectDataType: http.HttpDataType.STRING,
          multiFormDataList: [{
            name: 'file',
            contentType: 'image/jpg',
            filePath: imageUri
          }],
        }, (err: BusinessError, data: http.HttpResponse) => {
          Logger.debug('test:上传结束');
          if (!err) {
            if (typeof data.result == 'string') {
              Logger.debug('返回值为' + data.result);
              Logger.debug('返回调用代码:' + data.responseCode );
              let detectionResult: DetectionResult = JSON.parse(data.result) as DetectionResult;
              Logger.debug('返回错误类型结果:' + detectionResult.detection_classes);
              Logger.debug('返回错误位置结果:' + detectionResult.detection_boxes);
              Logger.debug('返回置信度结果:' + detectionResult.detection_scores);
              resolve(detectionResult);
            } else {
              reject('Unexpected data format');
            }
          } else {
            Logger.error('返回错误原因:' + JSON.stringify(err));
            reject(err);
          }
          httpRequest.destroy();
        });
      } catch (err) {
        Logger.debug('请求上传失败' + JSON.stringify(err));
        reject(err);
      }
    }).catch((err: BusinessError) => {
      Logger.debug('Invoke photoViewPicker.select failed, code is' + err.code + ' message is' + err.message);
      reject(err);
    });
  });
}

  // pickPhotoBtn() {
  //   try {
  //     let uris: Array<string> = [];
  //     let PhotoSelectOptions = new picker.PhotoSelectOptions();
  //     PhotoSelectOptions.MIMEType = picker.PhotoViewMIMETypes.IMAGE_TYPE;
  //     PhotoSelectOptions.maxSelectNumber = 1;
  //     let photoPicker = new picker.PhotoViewPicker();
  //     photoPicker.select(PhotoSelectOptions).then((PhotoSelectResult: picker.PhotoSelectResult) => {
  //       console.info('photoPicker.select successfully, PhotoSelectResult uri: ' + JSON.stringify(PhotoSelectResult));
  //       uris = PhotoSelectResult.photoUris;
  //       let phAccessHelper = photoAccessHelper.getPhotoAccessHelper(context);
  //       let predicates: dataSharePredicates.DataSharePredicates = new dataSharePredicates.DataSharePredicates();
  //       // 配置查询条件，使用PhotoViewPicker选择图片返回的uri进行查询
  //       predicates.equalTo('uri', uris[0]);
  //       let fetchOptions: photoAccessHelper.FetchOptions = {
  //         fetchColumns: [],
  //         predicates: predicates
  //       };
  //       phAccessHelper.getAssets(fetchOptions, async (err, fetchResult) => {
  //         if (fetchResult !== undefined) {
  //           console.info('fetchResult success');
  //           let photoAsset: photoAccessHelper.PhotoAsset = await fetchResult.getFirstObject();
  //           if (photoAsset !== undefined) {
  //             // 获取缩略图
  //             photoAsset.getThumbnail((err, pixelMap) => {
  //               if (err == undefined) {
  //                 console.info('getThumbnail successful ' + JSON.stringify(pixelMap));
  //               } else {
  //                 console.error('getThumbnail fail', err);
  //               }
  //             });
  //             console.info('photoAsset.displayName : ' + photoAsset.displayName);
  //           }
  //         } else {
  //           console.error(`fetchResult fail with error: ${err.code}, ${err.message}`);
  //         }
  //       });
  //     }).catch((err: BusinessError) => {
  //       console.error('photoPicker.select failed with err: ' + JSON.stringify(err));
  //     });
  //   } catch (error) {
  //     let err: BusinessError = error as BusinessError;
  //     console.error('photoPicker failed with err: ' + JSON.stringify(err));
  //   }
  // }

  // async handleImageUpload() {
  //   try {
  //     let uri = await this.selectImage(); // 这是你选择图片的函数
  //
  //     // 上传图片，返回JSON字符串
  //     // 通过类型断言将解析后的JSON字符串转换为DetectionResultJSON类型
  //     let resultJson: string = await this.uploadImage(uri);
  //     let detectionResult: DetectionResultJSON = RecordResult.fromJson(resultJson);
  //
  //     // 现在你可以使用 detectionResult 对象来访问检测结果
  //     Logger.debug('Detection Classes:', detectionResult.detectionClasses);
  //     Logger.debug('Detection Boxes:', detectionResult.detectionBoxes);
  //     Logger.debug('Detection Scores:', detectionResult.detectionScores);
  //   } catch (error) {
  //     Logger.debug('处理图片上传失败:', error);
  //   }
  // }

build() {
    Column() {
      Row() {
        Text(DateUtil.formatDate(this.data))
          .fontSize(20)
          .fontWeight(600)
          .margin({top: 5, left: 5})
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
          this.controller.close()
        })
      }
      .width('95%')
      .justifyContent(FlexAlign.End)


      Column({ space: 10 }) {
        Button() {
          Text('拍摄')
            .fontSize(18)
            .fontWeight(600)
        }
        .width('80%')
        .height(50)
        .backgroundColor("#ffd0d0d0")
        .onClick(() => {
        })

        Button() {
          Text('本地读取检测并写入图片')
            .fontSize(18)
            .fontWeight(600)
        }
        .width('80%')
        .height(50) // 50
        .backgroundColor("#ffd0d0d0")
        .onClick(() => {
          // const result: DetectionResult = callModelArtsAPI()
          // this.pickPhotoBtn()
          // this.onConfirm()
          this.getPixelMapByImage()
          this.WritePhoto()
        })

        // Button() {
        //   Text('检测图片写入')
        //     .fontSize(18)
        //     .fontWeight(600)
        // }
        // .width('80%')
        // .height(50) // 50
        // .backgroundColor("#ffd0d0d0")
        // .onClick(() => {
        //   // const result: DetectionResult = callModelArtsAPI()
        //   // this.pickPhotoBtn()
        // })

        Button() {
          Text('从相册选择')
            .fontSize(18)
            .fontWeight(600)
        }
        .width('80%')
        .height(50)
        .backgroundColor("#ffd0d0d0")
        .onClick(() => {
         this.onConfirm()
        })

        Button() {
          Text('取消')
            .fontSize(18)
            .fontWeight(600)
        }
        .width('80%')
        .height(50)
        .backgroundColor("#ffd0d0d0")
        .onClick(() => {
          this.controller.close()
        })

        // Column() {
        //   Button('待检测图片预览')
        //     .onClick(() => {
        //
        //     })
        //   Image(this.pixelMap)
        //     .width(300)
        //     .height(300)
        //   Button('开始检测')
        //     .onClick(() => {
        //       this.onConfirm()
        //     })
        // }
      }
      .width('95%')
      .height('37%')
      .alignItems(HorizontalAlign.Center)
    }
  }
}