# opencv-metal-pipeline

WIP

- Gets camera output through `AVFoundation`
- Converts camera output to `cv::Mat` for processing
- Copies `cv::Mat` to a `MTLTexture`
- Displays output texture using a simple Metal pipeline
