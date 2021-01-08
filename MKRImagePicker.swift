import Foundation
import Photos
import UIKit

/**
 This Class manages all of your imagePicker permissions and delegates.
 
 - Author:
 Manoj Kumar Rana
 
 - Copyright:
 Zapbuild Technologies Pvt Ltd
 
 - Date:
 06/01/20
 
 - Version:
 1.3
 */
class MKRImagePicker:NSObject {
    //MARK:- Properties
    var imageDelegate:MKRImagePickerDelegate?
    var imagePicker:UIImagePickerController = UIImagePickerController()
    var sourceType          : [UIImagePickerController.SourceType] = []
    var allowsEditing       : Bool = false
    
    //MARK:- Initialization
    private func initialize() {
        imagePicker.delegate = self
        imagePicker.allowsEditing = self.allowsEditing
    }
    /**
     This Method manages your ImagePickerViewController.
     
     This method checks your imagePicker Sourcetype array entered by you and decides weather to open the actionsheet or directly check for the authorization status.
     
     # Parameters
     
     * viewController: Pass the controller class where you want to check for the authorization status.
     * iPadSourceView: Pass a sourceView for iPad on which you want to present the ActionSheet.
     
     # Must Assign
     Please assign some values to the sourcetype array before calling this method.
     ```
     mkrImagePicker.sourceType = [.camera,.photolibrary]
     ```
     */
    func presentOn(viewController:UIViewController,
                   iPadSourceView:UIView = UIView(),
                   showVideos: Bool = false
                   ) {
        initialize()
        if self.sourceType.count > 1 {
            let actionSheet = createActionSheet(Controller: viewController)
            if UIDevice.current.userInterfaceIdiom == .pad {
                actionSheet.popoverPresentationController?.sourceView = iPadSourceView
                actionSheet.popoverPresentationController?.sourceRect = CGRect(x: iPadSourceView.bounds.midX, y: iPadSourceView.bounds.midY, width: 0, height: 0)
            }
            viewController.present(actionSheet, animated: false)
        } else if self.sourceType.count > 0{
            switch self.sourceType[0]{
            case .camera:
                checkCameraPermission(controller: viewController)
            case .photoLibrary:
                if showVideos {imagePicker.mediaTypes = ["public.movie"]}
                else {imagePicker.mediaTypes = ["public.image"]}
                checkPhotoLibraryPermission(controller: viewController)
            case .savedPhotosAlbum:
                checkSavedPhotoAlbumPermission(controller: viewController)
            default:
                break
            }
        } else {
            let alertController = UIAlertController(title: "Alert!", message: "Please select a sourceType for ImagePicker", preferredStyle: .alert)
            
            let defaultAction = UIAlertAction(title: "OK", style: .default, handler: nil)
            alertController.addAction(defaultAction)
            
            viewController.present(alertController, animated: true, completion: nil)
        }
    }
    
    //MARK:- Check Authorised Permissions
    //Checking PhotoLibraryPermission
    private func checkPhotoLibraryPermission(controller:UIViewController) {
        let status = PHPhotoLibrary.authorizationStatus()
        switch status {
        case .authorized:
            openImagePickerHandler(sourceType: .photoLibrary, controller: controller)
        case .limited:
            openImagePickerHandler(sourceType: .photoLibrary, controller: controller)
        case .denied, .restricted:
            self.showDeniedAlert(title: "Permission Denied", message: "Please grant photo library permissions in Settings to continue using this service", controller: controller)
            
        case .notDetermined:
            PHPhotoLibrary.requestAuthorization { (status) in
                if status.rawValue == 3{
                    self.openImagePickerHandler(sourceType: .photoLibrary, controller: controller)
                } else {
                    self.showDeniedAlert(title: "Permission Denied", message: "Please grant photo library permissions in Settings to continue using this service", controller: controller)
                }
            }
        default:
            break
        }
    }
    
    private func checkSavedPhotoAlbumPermission(controller:UIViewController) {
        let status = PHPhotoLibrary.authorizationStatus()
        switch status {
        case .authorized:
            openImagePickerHandler(sourceType: .savedPhotosAlbum, controller: controller)
        case .limited:
            openImagePickerHandler(sourceType: .savedPhotosAlbum, controller: controller)
        case .denied, .restricted :
            self.showDeniedAlert(title: "Permission Denied", message: "Please grant photo library permissions in Settings to continue using this service", controller: controller)
        case .notDetermined:
            PHPhotoLibrary.requestAuthorization { status in
                if status.rawValue == 3 {
                    self.openImagePickerHandler(sourceType: .photoLibrary, controller: controller)
                } else {
                    self.showDeniedAlert(title: "Permission Denied", message: "Please grant photo library permissions in Settings to continue using this service", controller: controller)
                }
            }
        default:
            break
        }
    }
    
    //Checking Camera Permission
    private func checkCameraPermission(controller:UIViewController) {
        if AVCaptureDevice.authorizationStatus(for: .video) ==  .authorized {
            openImagePickerHandler(sourceType: .camera, controller: controller)
        } else  if AVCaptureDevice.authorizationStatus(for: .video) ==  .notDetermined {
            AVCaptureDevice.requestAccess(for: .video, completionHandler: { (granted) in
                if granted {
                    self.openImagePickerHandler(sourceType: .camera, controller: controller)
                } else {
                    self.showDeniedAlert(title: "Permission Denied", message: "Please grant camera permissions in Settings to continue using this service", controller: controller)
                }
            })
        } else {
            self.showDeniedAlert(title: "Permission Denied", message: "Please grant camera permissions in Settings to continue using this service", controller: controller)
        }
    }
    
    //MARK:- Private functions
    private func createActionSheet(Controller:UIViewController)->UIAlertController {
        let actionSheet = UIAlertController(title: "Choose Source Type", message: nil, preferredStyle: .actionSheet)
        for type in sourceType {
            switch type {
            case .camera:
                actionSheet.addAction(UIAlertAction(title: ButtonTitles.camera, style: .default){ (_) in
                    self.checkCameraPermission(controller: Controller)
                })
            case .photoLibrary:
                actionSheet.addAction(UIAlertAction(title: ButtonTitles.photos, style: .default){ (_) in
                    self.checkPhotoLibraryPermission(controller: Controller)
                })
            case .savedPhotosAlbum:
                actionSheet.addAction(UIAlertAction(title: ButtonTitles.savedPhotos, style: .default){ (_) in
                    self.checkSavedPhotoAlbumPermission(controller: Controller)
                })
            default:
                break
            }
        }
        
        actionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        return actionSheet
        
    }
    
    private func openImagePickerHandler(sourceType:UIImagePickerController.SourceType,controller:UIViewController){
        
        DispatchQueue.main.async {
            self.imagePicker.sourceType = sourceType
            self.imagePicker.allowsEditing = true
            controller.present(self.imagePicker, animated: true, completion: {
                self.imagePicker.navigationBar.topItem?.rightBarButtonItem?.isEnabled = true
            })
        }
        
    }
    
    private func openAppSettings(){
        if let url = URL(string:UIApplication.openSettingsURLString) {
            if UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
            }
        }
    }
    
    private func showDeniedAlert(title:String,message:String,controller:UIViewController) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: "Open Settings", style: .default, handler: { action in
            self.openAppSettings()
        }))
        alert.addAction(UIAlertAction(title: "Cancel", style: .default, handler: { action in
            controller.dismiss(animated: false, completion: nil)
        }))
        DispatchQueue.main.async {
            controller.present(alert, animated: true)
        }
    }
}

//MARK:- ImagePicker Delegates
extension MKRImagePicker:UIImagePickerControllerDelegate,UINavigationControllerDelegate{
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        imageDelegate?.imageSelectionCancelled()
        imagePicker.dismiss(animated: true, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let image = info[UIImagePickerController.InfoKey.editedImage] as? UIImage {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0, execute: { [weak self] in
                self?.imageDelegate?.imageSelectionSuccessful(selectedImage: image)
            })
            
        }
        else if let mediaURL = info[UIImagePickerController.InfoKey.mediaURL] as? URL {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0, execute: { [weak self] in
                self?.imageDelegate?.videoSelectionSuccessful(mediaURL: mediaURL)
            })
        }
        imagePicker.dismiss(animated: true, completion: nil)
    }
}

//MARK:- ImagePicker Protocol definition
protocol MKRImagePickerDelegate:class {
    func imageSelectionSuccessful(selectedImage:UIImage)
    func imageSelectionCancelled()
    func videoSelectionSuccessful(mediaURL: URL)
}
extension MKRImagePickerDelegate {
    func videoSelectionSuccessful(mediaURL: URL) {}
}

//MARK:- Button Titles
struct ButtonTitles {
    static let camera = "Camera"
    static let photos = "Photos"
    static let savedPhotos = "Saved Photo Album"
}
