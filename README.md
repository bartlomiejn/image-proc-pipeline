# opencv-metal-pipeline

- Retrieval of camera output through `AVFoundation`
- Convertion of camera output to input `cv::Mat` for processing
- Convertion of processed `cv::Mat` to `MTLTexture`
- Rendering of processed texture using a simple Metal pipeline in real time
