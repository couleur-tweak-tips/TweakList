function HEVCCheck {

    if ((cmd /c .mp4) -eq '.mp4=WMP11.AssocFile.MP4'){ # If default video player for .mp4 is Movies & TV
        
        if(Test-Path "Registry::HKEY_CLASSES_ROOT\ms-windows-store"){
            "Opening HEVC extension in Windows Store.."
            Start-Process ms-windows-store://pdp/?ProductId=9n4wgh0z6vhq
        }
    }
}
