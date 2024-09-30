import RecordItem from '../bean/RecordItem'

const TaskItem: RecordItem[] = [
  new RecordItem(0,'电子产品', $r('app.media.pcbIcon'),'检测种类：PCB、IC和显示屏等','缺陷种类：0.Mouse_bite 1.Open_circuit \n .Short 3.Spur 4.Spurious_copper'),
  new RecordItem(1,'机械零部件', $r('app.media.gearIcon'),'检测种类：齿轮、轴承等零部件','缺陷种类：0.表面缺陷检测 1.焊缝检测 \n2.形状畸变检测 3.磨损检测'),
  new RecordItem(2,'食品与饮料', $r('app.media.foodIcon'), '检测种类：水果和食品包装等','0.水果表皮瑕疵检测 1.食品包装封口 \n2.标签信息检测'),
  new RecordItem(3,'纺织品', $r('app.media.clothIcon'),'检测种类：布料和编制品等','缺陷种类：0.服装是色差检测 \n1.布料表面缺陷检测 2.服装尺寸检测'),
  new RecordItem(4,'建筑材料', $r('app.media.brickIcon'),'检测种类：瓷砖、砖块、管道和钢筋等','缺陷种类：0.管道表面质量检测 \n1.瓷砖、砖块裂纹缺角检测'),

]

class ItemModel {
  getById(id: number){
    return TaskItem[id]
  }

  list(): RecordItem[] {
    return TaskItem
  }
}

let itemModel = new ItemModel()
export default itemModel as ItemModel
