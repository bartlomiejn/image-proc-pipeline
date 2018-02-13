# barcode-detection
Barcode scanner for iOS

- Gets the video output from the camera through `AVFoundation`
- Retrieves the approximate contours for the barcode by getting the gradient magnitude from a Scharr operator and subsequent morphological operations, erosion & dilation
- Retrieves the rotated bounding box of the contours and draws it on the image
- Converts the mat buffer back to `UIImage` and displays result on screen using an `UIImageView` - which is awfully slow, but its the best I managed until now
