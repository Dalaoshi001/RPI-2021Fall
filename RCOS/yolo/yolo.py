import torch
import cv2

# Model
model = torch.hub.load('ultralytics/yolov5', 'yolov5s')  # or yolov5m, yolov5l, yolov5x, custom

# Images
img = 'C:/Users/Yihang Wang/Desktop/RPI/2021 Fall/CS1/yuban1.jpg'  # or file, Path, PIL, OpenCV, numpy, list
#cap = cv2.VideoCapture('C:/Users/Yihang Wang/Desktop/RPI/2021 Fall/CS1/1.mkv')
# Inference

#cap.open('C:/Users/Yihang Wang/Desktop/RPI/2021 Fall/CS1/1.mkv')
# print(cap.isOpened()) 
# while(cap.isOpened()):
#     ret, frame = cap.read()
#     if ret is not True:
#         break
#     results = model(frame)
#     results.print()
#     c = cv2.waitKey(1)
#     if c == 27:
#         break

results = model(img)
results.show()

# Results
#results.print()  # or .show(), .save(), .crop(), .pandas(), etc.
    #results.show()
#results.save()


# import cv2 as cv
# import numpy as np
# from openvino.inference_engine import IENetwork, IECore

# weight_pb = "D:/projects/opencv_tutorial/data/models/face_detector/opencv_face_detector_uint8.pb";
# config_text = "D:/projects/opencv_tutorial/data/models/face_detector/opencv_face_detector.pbtxt";

# model_xml = "emotions-recognition-retail-0003.xml"
# model_bin = "emotions-recognition-retail-0003.bin"

# labels = ['neutral', 'happy', 'sad', 'surprise', 'anger']
# emotion_labels = ["neutral","anger","disdain","disgust","fear","happy","sad","surprise"]

# emotion_net = IENetwork(model=model_xml, weights=model_bin)
# ie = IECore()
# versions = ie.get_versions("CPU")
# input_blob = next(iter(emotion_net.inputs))
# n, c, h, w = emotion_net.inputs[input_blob].shape
# print(emotion_net.inputs[input_blob].shape)
# output_info = emotion_net.outputs[next(iter(emotion_net.outputs.keys()))]
# output_info.precision = "FP32"
# exec_net = ie.load_network(network=emotion_net, device_name="CPU")
# root_dir = "D:/facedb/emotion_dataset/"
# def emotion_detect(frame):
#     net = cv.dnn.readNetFromTensorflow(weight_pb, config=config_text)
#     h, w, c = frame.shape
#     blobImage = cv.dnn.blobFromImage(frame, 1.0, (300, 300), (104.0, 177.0, 123.0), False, False);
#     net.setInput(blobImage)
#     cvOut = net.forward()

#     # 绘制检测矩形
#     for detection in cvOut[0,0,:,:]:
#         score = float(detection[2])
#         if score > 0.5:
#             left = detection[3]*w
#             top = detection[4]*h
#             right = detection[5]*w
#             bottom = detection[6]*h

#             # roi and detect landmark
#             y1 = np.int32(top) if np.int32(top) > 0 else 0
#             y2 = np.int32(bottom) if np.int32(bottom) < h else h-1
#             x1 = np.int32(left) if np.int32(left) > 0 else 0
#             x2 = np.int32(right) if np.int32(right) < w else w-1
#             roi = frame[y1:y2,x1:x2,:]
#             image = cv.resize(roi, (64, 64))
#             image = image.transpose((2, 0, 1))  # Change data layout from HWC to CHW
#             res = exec_net.infer(inputs={input_blob: [image]})
#             prob_emotion = res['prob_emotion']
#             probs = np.reshape(prob_emotion, (5))
#             txt = labels[np.argmax(probs)]
#             cv.putText(frame, txt, (np.int32(left), np.int32(top)), cv.FONT_HERSHEY_SIMPLEX, 1.0, (255, 0, 0), 2)
#             cv.rectangle(frame, (np.int32(left), np.int32(top)),
#                          (np.int32(right), np.int32(bottom)), (0, 0, 255), 2, 8, 0)
# if __name__ == "__main__":
#     capture = cv.VideoCapture("C:/Users/Yihang Wang/Desktop/RPI/2021 Fall/CS1/1.mkv")
#     while True:
#         ret, frame = capture.read()
#         if ret is not True:
#             break
#         emotion_detect(frame)
#         cv2.imshow("emtion-detect-demo", frame)
#         c = cv2.waitKey(1)
#         if c == 27:
#             break