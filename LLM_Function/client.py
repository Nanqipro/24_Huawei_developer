# import sounddevice as sd
# from scipy.io.wavfile import write
# import requests
# import os
# from playsound import playsound
#
# def record_audio(filename, duration=5, fs=16000):
#     """录制音频并保存为 WAV 文件。"""
#     print(f"开始录制 {duration} 秒的音频...")
#     recording = sd.rec(int(duration * fs), samplerate=fs, channels=1, dtype='int16')
#     sd.wait()  # 等待录音结束
#     write(filename, fs, recording)  # 保存为 WAV 文件
#     print(f"录音完成，音频已保存为 {filename}")
#
# def upload_audio_to_server(file_path):
#     url = "http://192.168.1.72:8001/process_audio"  # 将此替换为您的服务器 URL
#     files = {'audio': open(file_path, 'rb')}
#     try:
#         response = requests.post(url, files=files)
#         if response.status_code == 200:
#             print("文件上传成功，正在处理...")
#             return response.content  # 接收处理后的音频数据
#         else:
#             print(f"文件上传失败: {response.status_code}")
#             return None
#     except Exception as e:
#         print(f"上传文件时出错: {e}")
#         return None
#
# def play_audio(file_path):
#     """播放音频文件。"""
#     try:
#         print(f"正在播放音频: {file_path}")
#         playsound(file_path)
#     except Exception as e:
#         print(f"播放音频时出错: {e}")
#
# if __name__ == "__main__":
#     # 步骤 1：录制音频
#     recorded_audio_file = "recorded_audio.wav"
#     record_audio(recorded_audio_file, duration=5)  # 可根据需要调整持续时间
#
#     # 步骤 2：上传音频并接收处理后的音频
#     response_audio_data = upload_audio_to_server(recorded_audio_file)
#     if response_audio_data:
#         # 保存接收到的音频数据
#         response_audio_file = "response_audio.wav"
#         with open(response_audio_file, 'wb') as f:
#             f.write(response_audio_data)
#         print("已从服务器接收处理后的音频。")
#
#         # 步骤 3：播放接收到的音频
#         play_audio(response_audio_file)
#     else:
#         print("未能接收到处理后的音频。")


import sounddevice as sd
from scipy.io.wavfile import write
import requests
import os
from playsound import playsound
from sshtunnel import SSHTunnelForwarder

def record_audio(filename, duration=5, fs=16000):
    """录制音频并保存为 WAV 文件。"""
    print(f"开始录制 {duration} 秒的音频...")
    recording = sd.rec(int(duration * fs), samplerate=fs, channels=1, dtype='int16')
    sd.wait()  # 等待录音结束
    write(filename, fs, recording)  # 保存为 WAV 文件
    print(f"录音完成，音频已保存为 {filename}")

def upload_audio_to_server_through_ssh(file_path):
    # SSH 连接信息
    jump_host = '222.204.6.193'
    jump_user = 'YZH'
    jump_password = 'YZH@good114'  # 使用密码认证
    jump_port = 8087

    # 远程服务器的 SSH 连接信息
    remote_server_ip = '192.168.1.72'
    remote_port = 22  # 远程服务器的 SSH 端口

    # 使用 sshtunnel 创建 SSH 隧道
    with SSHTunnelForwarder(
        (jump_host, jump_port),
        ssh_username=jump_user,
        ssh_password=jump_password,
        remote_bind_address=(remote_server_ip, 8001),  # 服务器上的 Flask 监听端口
        local_bind_address=('0.0.0.0', 5000)  # 本地绑定端口
    ) as tunnel:
        print("SSH 隧道已建立，开始连接服务器...")

        # 上传音频文件到通过隧道建立的服务器端口
        url = f"http://127.0.0.1:{tunnel.local_bind_port}/process_audio"
        files = {'audio': open(file_path, 'rb')}

        try:
            response = requests.post(url, files=files)
            if response.status_code == 200:
                print("文件上传成功，正在处理...")
                return response.content  # 接收处理后的音频数据
            else:
                print(f"文件上传失败: {response.status_code}")
                return None
        except Exception as e:
            print(f"上传文件时出错: {e}")
            return None

def play_audio(file_path):
    """播放音频文件。"""
    try:
        print(f"正在播放音频: {file_path}")
        playsound(file_path)
    except Exception as e:
        print(f"播放音频时出错: {e}")

if __name__ == "__main__":
    # 步骤 1：录制音频
    recorded_audio_file = "recorded_audio.wav"
    record_audio(recorded_audio_file, duration=5)  # 可根据需要调整持续时间

    # 步骤 2：通过 SSH 隧道上传音频并接收处理后的音频
    response_audio_data = upload_audio_to_server_through_ssh(recorded_audio_file)
    if response_audio_data:
        # 保存接收到的音频数据
        response_audio_file = "response_audio.wav"
        with open(response_audio_file, 'wb') as f:
            f.write(response_audio_data)
        print("已从服务器接收处理后的音频。")

        # 步骤 3：播放接收到的音频
        play_audio(response_audio_file)
    else:
        print("未能接收到处理后的音频。")
