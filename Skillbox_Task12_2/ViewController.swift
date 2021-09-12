import UIKit
import Vision

class ViewController: UIViewController {
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var resultLabel: UILabel!
    
    @IBAction func cameraButton(_ sender: Any) {
        createImagePicker(sourceType: .photoLibrary)
    }
    
    private lazy var classificationRequest: VNCoreMLRequest = {
        do {
            let model = try VNCoreMLModel(for: MyImageClassifier_1().model)
            let request = VNCoreMLRequest(model: model) { request, _ in
                if let classifications = request.results as? [VNClassificationObservation] {
                    let topClassifications = classifications.prefix(2).map {
                      (confidence: $0.confidence, identifier: $0.identifier)
                    }
                    DispatchQueue.main.async {
                        self.resultLabel.text = "Confidence: \(String(describing: topClassifications.first!.confidence))\nAnimal: \(String(describing: topClassifications.first!.identifier))"
                    }
                }
            }
            request.imageCropAndScaleOption = .centerCrop
            return request
        } catch {
            fatalError("\(error)")
        }
    }()
    
    override func viewDidLoad() { super.viewDidLoad() }
    
    func createImagePicker(sourceType: UIImagePickerController.SourceType) {
        
        let imagePickerController = UIImagePickerController()
        imagePickerController.sourceType = sourceType
        imagePickerController.allowsEditing = true
        imagePickerController.delegate = self
        present(imagePickerController, animated: false)
    }
    
    func classifyImage(image: UIImage) {
        
        guard let orientation = CGImagePropertyOrientation(
          rawValue: UInt32(image.imageOrientation.rawValue)) else { return }
        
        guard let ciImage = CIImage(image: image) else {
          fatalError("Unable to create \(CIImage.self) from \(image).")
        }
        
        DispatchQueue.global(qos: .userInitiated).async {
            let handler = VNImageRequestHandler(ciImage: ciImage, orientation: orientation)
            do {
                try handler.perform([self.classificationRequest])
            } catch {
                print("Failed to perform classification.\n\(error.localizedDescription)")
            }
        }
    }
}

extension ViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        
        picker.getPicture(pickerGetPicture: picker, infoGetPicture: info, imageViewGetPicture: imageView)
        let image = info[UIImagePickerController.InfoKey.originalImage] as! UIImage
        classifyImage(image: image)
    }
}

extension UIImagePickerController {
    
    func getPicture(pickerGetPicture: UIImagePickerController, infoGetPicture: [UIImagePickerController.InfoKey : Any], imageViewGetPicture: UIImageView) {
        
        guard let picture = infoGetPicture[.originalImage] as? UIImage else {
            print("Photo is not found")
            return
        }
        
        imageViewGetPicture.image = picture
        pickerGetPicture.dismiss(animated: true, completion: nil)
    }
}

