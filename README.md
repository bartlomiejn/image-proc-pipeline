# opencv-metal-pipeline

WIP

- Gets camera output through `AVFoundation`
- Converts camera output to `cv::Mat` for processing
- Converts `cv::Mat` to `MTLTexture`
- Renders processed texture using a simple Metal pipeline in real time
