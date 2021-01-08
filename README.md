# MKRImagePicker
Pick an image or video in super easy way, no need to handle any permissions, it will handle all of them autometically. Just Copy the file and do the following actions.
# Usage

    //MARK:- Private Properties
    private lazy var imagePicker: MKRImagePicker = {
        let imagePicker = MKRImagePicker()
        imagePicker.sourceType = [.camera,.photoLibrary]
        imagePicker.imageDelegate = self
        return imagePicker
    }()
    
    @IBAction func editImageButtonTapped(_ sender: UIButton) {
        imagePicker.presentOn(viewController: self)
    }
    
    //MARK:- ImagePicker Delegates
    extension SomeController:MKRImagePickerDelegate{
    
    func imageSelectionSuccessful(selectedImage: UIImage) {
        userProfilePicture.image = selectedImage
        isProfileChanged = true
    }
    
    func imageSelectionCancelled() {}
    }
