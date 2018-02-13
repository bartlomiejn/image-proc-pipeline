# barcode-detection
Barcode scanner for iOS

- Gets the video output from the camera through `AVFoundation`
- Retrieves the approximate contours for the barcode
- Retrieves the rotated bounding box of the contours and draws it on the image
- Converts the mat buffer back to `UIImage` and displays result on screen using an `UIImageView`

Works fairly bad for now and in only certain lightning conditions.
