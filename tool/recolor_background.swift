// Recolours the background of a portrait while leaving the person untouched.
// Used once to move the paywall photo's orange backdrop onto our palette:
//   swift tool/recolor_background.swift original.jpg assets/images/paywall.jpg -28 0.55 0.09
// usage: swift tool/recolor_background.swift <in.jpg> <out.jpg> <hueDegrees> <saturation> <brightness> [mask.png]
//    or: swift tool/recolor_background.swift <in.jpg> <out.jpg> tint <RRGGBB> <brightness>
//        (tints a busy backdrop one soft colour, e.g. the waist photo:
//         tint F6DCE2 0.1)
import CoreImage
import CoreImage.CIFilterBuiltins
import Foundation
import Vision
import AppKit

let args = CommandLine.arguments
let input = URL(fileURLWithPath: args[1])
let output = URL(fileURLWithPath: args[2])
let tintHex = args[3] == "tint" ? args[4] : nil
let hue = (Double(args[3]) ?? -40) * .pi / 180
let saturation = Double(args[4]) ?? 0.8  // ignored in tint mode
let brightness = Double(args[5]) ?? 0.03

let image = CIImage(contentsOf: input)!
let request = VNGeneratePersonSegmentationRequest()
request.qualityLevel = .accurate
request.outputPixelFormat = kCVPixelFormatType_OneComponent8
try VNImageRequestHandler(ciImage: image).perform([request])
let maskBuffer = request.results!.first!.pixelBuffer

// Scale the mask to the photo and soften its edge so hair and fabric blend.
var mask = CIImage(cvPixelBuffer: maskBuffer)
mask = mask.transformed(by: CGAffineTransform(
  scaleX: image.extent.width / mask.extent.width,
  y: image.extent.height / mask.extent.height))
let blur = CIFilter.gaussianBlur()
blur.inputImage = mask.clampedToExtent()
blur.radius = 2.5
mask = blur.outputImage!.cropped(to: image.extent)

// The background: same light and shadow, new colour.
let hueFilter = CIFilter.hueAdjust()
hueFilter.inputImage = image
hueFilter.angle = Float(hue)
let controls = CIFilter.colorControls()
controls.inputImage = hueFilter.outputImage
controls.saturation = Float(saturation)
controls.brightness = Float(brightness)
var background = controls.outputImage!
if let tintHex, let rgb = Int(tintHex, radix: 16) {
  // One soft colour, keeping the backdrop's light and shadow.
  let mono = CIFilter.colorMonochrome()
  mono.inputImage = image
  mono.color = CIColor(
    red: CGFloat((rgb >> 16) & 0xFF) / 255,
    green: CGFloat((rgb >> 8) & 0xFF) / 255,
    blue: CGFloat(rgb & 0xFF) / 255)
  mono.intensity = 1
  let lift = CIFilter.colorControls()
  lift.inputImage = mono.outputImage
  lift.brightness = Float(brightness)
  lift.contrast = 0.85
  background = lift.outputImage!
}

let blend = CIFilter.blendWithMask()
blend.inputImage = image          // person, untouched
blend.backgroundImage = background
blend.maskImage = mask
let result = blend.outputImage!.cropped(to: image.extent)

let context = CIContext()
let colorSpace = CGColorSpace(name: CGColorSpace.sRGB)!
try context.writeJPEGRepresentation(of: result, to: output, colorSpace: colorSpace,
  options: [kCGImageDestinationLossyCompressionQuality as CIImageRepresentationOption: 0.85])
if args.count > 6 {
  try context.writePNGRepresentation(of: mask, to: URL(fileURLWithPath: args[6]), format: .L8, colorSpace: CGColorSpace(name: CGColorSpace.linearGray)!)
}
print("done \(Int(image.extent.width))x\(Int(image.extent.height))")
