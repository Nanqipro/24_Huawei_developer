import cv2
import time
import requests
import json
import collections
import threading


def getToken():
    url = "https://iam.cn-north-4.myhuaweicloud.com/v3/auth/tokens"
    body = {
        "auth": {
            "identity": {
                "methods": [
                    "password"
                ],
                "password": {
                    "user": {
                        "domain": {
                            "name": "hid_eb2gnxs55yqdnn_"
                        },
                        "name": "Czq",
                        "password": "darling.czq2002"
                    }
                }
            },
            "scope": {
                "project": {
                    "name": "cn-north-4"
                }
            }
        }
    }

    headers = {
        'Content-Type': 'application/json'
    }
    response = requests.post(url, data=json.dumps(body), headers=headers)
    token = response.headers["X-Subject-Token"]
    return token

def save_video_from_frames(frames, output_file="temp_video.mp4"):
    if not frames:
        return None

    height, width, layers = frames[0].shape
    fourcc = cv2.VideoWriter_fourcc(*'mp4v')
    out = cv2.VideoWriter(output_file, fourcc, 30.0, (width, height))

    for frame in frames:
        out.write(frame)

    out.release()
    return output_file


def upload_video_and_get_result(file_path):
    url = "https://015c2ea02afc4cf0afbd3935a760adab.apig.cn-north-4.huaweicloudapis.com/v1/infers/d8700113-5c4a-4ee7-b987-18e87ea6062b"
    token = getToken()
    headers = {
        'X-Auth-Token': token
    }
    files = {
        'input_video': open(file_path, 'rb')
    }
    response = requests.post(url, headers=headers, files=files)
    return response.json()


# 异步处理视频保存和分析
def async_save_and_analyze(frames, warning_flag):
    output_file = save_video_from_frames(frames)
    result = upload_video_and_get_result(output_file)
    category = result.get("result", {}).get("category", None)
    if category == 3:
        warning_flag[0] = True  # 设置标志位表示需要显示警告
    else:
        warning_flag[0] = False  # 如果没有检测到违规行为，清除警告


def main():
    cap = cv2.VideoCapture(0)

    if not cap.isOpened():
        print("Error opening video stream or file")
        return

    frame_queue = collections.deque(maxlen=150)  # 存储最近5秒的帧，假设帧率是30fps (5秒 * 30 = 150帧)
    warning_flag = [False]  # 用于指示是否显示警告
    start_time = time.time()

    while True:
        ret, frame = cap.read()
        if ret:
            if warning_flag[0]:
                cv2.putText(frame, "Warning: do not use phone", (50, 50), cv2.FONT_HERSHEY_SIMPLEX, 1, (0, 0, 255), 2)
            # elif warning_flag[0]:
            #     cv2.putText(frame, "Warning: do not look away", (50, 50), cv2.FONT_HERSHEY_SIMPLEX, 1, (0, 0, 255), 2)
            cv2.imshow('Live Stream', frame)
            frame_queue.append(frame)

            if cv2.waitKey(1) & 0xFF == ord('q'):
                break

        current_time = time.time()
        elapsed_time = current_time - start_time

        # 每秒进行一次分析
        if elapsed_time >= 1:
            if len(frame_queue) == 150:  # 确保队列中有完整的5秒帧数据
                # 启动一个新线程进行异步保存和分析
                threading.Thread(target=async_save_and_analyze, args=(list(frame_queue), warning_flag)).start()
            start_time = current_time  # 重置时间

    cap.release()
    cv2.destroyAllWindows()


if __name__ == "__main__":
    main()
