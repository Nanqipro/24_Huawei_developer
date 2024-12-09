import speech_recognition as sr
from openai import OpenAI
# coding: utf-8



def getcontent(str):
    client = OpenAI(
        api_key="sk-f450512199a14efabd485d87680463b6",  # 注意: 不要在公开场合分享你的API Key
        base_url="https://dashscope.aliyuncs.com/compatible-mode/v1",
    )

    completion = client.chat.completions.create(
        model="qwen-plus",
        messages=[
            {'role': 'system', 'content': 'You are a helpful assistant.'},
            {'role': 'user', 'content': str}
        ],
    )

    # 直接访问choices列表中的第一个元素的message内容
    if completion.choices:
        first_choice = completion.choices[0]
        if hasattr(first_choice, 'message') and hasattr(first_choice.message, 'content'):
            print("Content:", first_choice.message.content)
            return  first_choice.message.content
            # getaud(first_choice.message.content)
    else:
        print("No choices returned from the API.")

while True:
    # 初始化识别器
    r = sr.Recognizer()
    str = ""
    # 使用默认麦克风作为音频来源
    with sr.Microphone() as source:
        print("请说些什么吧...")
        audio = r.listen(source)

        try:
            # 使用Google Web Speech API进行识别
            print("Google Speech Recognition thinks you said:")
            text = r.recognize_google(audio, language='zh-CN')  # 根据需要设置语言
            print(text)
            str = getcontent(text)
        except sr.UnknownValueError:
            print("Google Speech Recognition could not understand audio")
        except sr.RequestError as e:
            print(f"Could not request results from Google Speech Recognition service; {e}")


    import yy
    import base64
    import pygame  # 用于播放MP3
    from huaweicloudsdkcore.auth.credentials import BasicCredentials
    from huaweicloudsdksis.v1.region.sis_region import SisRegion
    from huaweicloudsdkcore.exceptions import exceptions
    from huaweicloudsdksis.v1 import *
    from playsound import playsound
    yy.getaud(str)