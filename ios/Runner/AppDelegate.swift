import UIKit
import Flutter
import AVFoundation
import MediaPlayer

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
    
    var audioPlayer : AVQueuePlayer?
    var playerObserver : Any?
    var currentAudioRate : Float = 1.0
    var strURL : String = ""
    var isBuffering : Bool = true //Changes
    var isPlayingButton : Bool = false //Changes
    let volumeView = MPVolumeView(frame: CGRect.zero)
    var currentDeviceVolume : Double = 0.5
    var strTitle : String = ""
    let commandCenter = MPRemoteCommandCenter.shared()
    let playingInfoCenter = MPNowPlayingInfoCenter.default()
    
    
    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
        ) -> Bool {
        
        //Flutter Method and Result
        let controller : FlutterViewController = window?.rootViewController as! FlutterViewController
        let flutterChannel : FlutterMethodChannel = FlutterMethodChannel(name: "flutter.native.audio.bridge", binaryMessenger: controller as! FlutterBinaryMessenger)
        //Flutter Bridge Method Calls
        flutterChannel.setMethodCallHandler { (methodCall, methodResult) in
            
            let dictArguments = methodCall.arguments as? Dictionary<String,Any> ?? [:]
            
            switch methodCall.method{
            case "startPlayer":
                if self.strURL != ""{
                    if self.strURL == dictArguments["url"] as? String ?? ""{
                        self.audioPlayer?.play()
                        self.isPlayingButton = true //Changes
                    }
                    else{
                        let strAudio = dictArguments["url"] as? String ?? ""
                        self.strURL = strAudio
                        let strTitle = dictArguments["title"] as? String ?? ""
                        self.strTitle = strTitle
                        let strDescription = dictArguments["desc"] as? String ?? ""
                        self.startPlayer(audioPath: strAudio, audioTitle: strTitle, audioDescription: strDescription)
                        self.isPlayingButton = true //Changes
                    }
                }else{
                    let strAudio = dictArguments["url"] as? String ?? ""
                    self.strURL = strAudio
                    let strTitle = dictArguments["title"] as? String ?? ""
                    self.strTitle = strTitle
                    let strDescription = dictArguments["desc"] as? String ?? ""
                    self.startPlayer(audioPath: strAudio, audioTitle: strTitle, audioDescription: strDescription)
                    self.isPlayingButton = true //Changes
                }
                break;
            case "pausePlayer":
                self.isPlayingButton = false //Changes
                self.audioPlayer?.pause()
                break;
            case "getBuffering": //Changes
                methodResult(self.isBuffering) //Changes
                break;
            case "seekTo":
                let time = dictArguments["milisecond"] as? Double ?? 0.0
                self.seekTo(time: time/1000)
                break;
            case "setSeekBarMaxProgress":
                methodResult(self.getDuration())
                break;
            case "setSeekBarProgress":
                self.isPlayingPlayer()
                let currentTime = Double(self.getPlayerCurrentTime() ?? 0)
                print("\n\n\n\nCurrent Time Playing Is : ",currentTime,"\n\n\n\n\n\n")
                methodResult(currentTime)
                break;
            case "setPlayingState":
                methodResult(self.isPlayingButton)
                break;
            case "speedXPlayer":
                let speed = dictArguments["speedValue"] as? String ?? "1.0x"
                self.changeAudioSpeed(speed: speed)
                break;
            case "getVolumeProgress":
                methodResult(self.currentDeviceVolume)
                break;
            case "getMaxVolume":
                methodResult(1.0)
                break;
            case "setVolume":
                let time = dictArguments["volume"] as? Double ?? 0.0
                self.setVolumeLevel(Float(Double(time)))
                break;
            default:
                break;
            }
        }
        
        GeneratedPluginRegistrant.register(with: self)
        
        addVolumeView(controller : controller)
        currentDeviceVolume = Double(AVAudioSession.sharedInstance().outputVolume)
        NotificationCenter.default.addObserver(self, selector: #selector(volumeDidChange(notification:)), name: NSNotification.Name(rawValue: "AVSystemController_SystemVolumeDidChangeNotification"), object: nil)
        
        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }
}


//MARK:- Flutter Function
extension AppDelegate{
    
    func startPlayer(audioPath: String?, audioTitle: String?, audioDescription: String?){
        if audioPlayer != nil{
            audioPlayer = nil
        }
        if let strAudio = audioPath{
            if let audioURL = URL(string: strAudio){
                let avPlayerItem = AVPlayerItem(url: audioURL)
                audioPlayer = AVQueuePlayer(items: [avPlayerItem])
                audioPlayer?.actionAtItemEnd = .advance
                NotificationCenter.default.addObserver(self, selector: #selector(playerFinishPlaying(note:)), name: .AVPlayerItemDidPlayToEndTime, object: audioPlayer?.currentItem)
                audioPlayer?.play()
                observingTimeChanges()
                setToBackGround(isPlaying: true, dictMusicData: ["title":audioTitle ?? ""])
                setBackgroundControls()
                audioSession()
            }else{
                //Audio String Not Converted To URL
            }
        }else{
            //AudioPath Is nil
        }
    }
    
    func seekTo(time : Double){
        if audioPlayer?.currentItem?.status == AVPlayerItem.Status.readyToPlay{ }else {  return }
        
        let currentTime = CMTimeGetSeconds(audioPlayer?.currentItem?.currentTime() ?? CMTime.zero)
        guard let timeScale = audioPlayer?.currentItem?.asset.duration.timescale else { return }
        let exactTime = CMTime(seconds: time, preferredTimescale: timeScale)
        
        audioPlayer?.currentItem?.seek(to: exactTime, toleranceBefore: CMTime.zero, toleranceAfter: CMTime.zero, completionHandler: { (isSeek) in
            if isSeek{
                print("\n\n\nSeeked To Time : ",currentTime,"\n\n\n")
                self.audioPlayer?.play()
                self.audioPlayer?.rate = self.currentAudioRate
            }
        })
    } //Seek
    
    func getDuration() -> Double{
        let totalTime = audioPlayer?.currentItem?.duration ?? CMTime.zero
        
        print("\n\n\n\n\n\n\n\n\nPlaying Current Item Is \(audioPlayer?.currentItem)\n\n\n\n\n\n\n\n")
        
        
        if CMTimeGetSeconds(totalTime).isNaN{
            return 0.0
        }else{
            return CMTimeGetSeconds(totalTime)*1000
        }
    } //Get Total Duration
    
    //Get Current Player Time
    func getPlayerCurrentTime() -> Int?{
        guard let currentTime = audioPlayer?.currentItem?.currentTime() else {
            return nil
        }
        
        if CMTimeGetSeconds(currentTime).isNaN || CMTimeGetSeconds(currentTime).isInfinite{
            print(CMTimeGetSeconds(currentTime))
            return nil
        }else{
            return Int(CMTimeGetSeconds(currentTime)) * 1000
        }
    } //Current Player Time
    
    func changeAudioSpeed(speed: String?){
        if var audioRate = speed{
            _ = String(audioRate.removeLast())
            audioPlayer?.rate = Float(audioRate) ?? 0.0
            currentAudioRate = Float(audioRate) ?? 0.0
        }else{
            //Speed is Nil
        }
    } //Speed Change
    
    //Set Device Volume
    func setVolumeLevel(_ volumeLevel: Float) {
        guard let slider = volumeView.subviews.compactMap({ $0 as? UISlider }).first else {
            return
        }
        slider.value = volumeLevel
        currentDeviceVolume = Double(volumeLevel)
    }
}


//MARK:- Observers
extension AppDelegate {
    
    //Notification For Audio Finished
    @objc func playerFinishPlaying(note : NSNotification){//Audio End
        print("\n\n > > > > > > > > Audio Finished > > > > > > > > \n\n")
        audioPlayer?.seek(to: CMTime.zero)
        strURL = ""
        audioPlayer?.pause()
        self.isPlayingButton = false
        setToBackGround(isPlaying: false, dictMusicData: ["title":""])
        if playerObserver != nil{
            NotificationCenter.default.removeObserver(Notification.Name.AVPlayerItemDidPlayToEndTime)
            playerObserver = nil
        }
    }
    
    @objc func volumeDidChange(notification: NSNotification) {
        let volume = notification.userInfo!["AVSystemController_AudioVolumeNotificationParameter"] as? Float ?? 1.0
        currentDeviceVolume = Double(volume)
    }
    
    @objc func audioSessionInterrupted(){
        print("\n\n\n > > > > > Error Audio Session Interrupted ","\n\n\n")
    }
    
    @objc func handleRouteChange(notification: Notification) {
        print("\n\n\n > > > > > Audio Route Changed ","\n\n\n")
        guard let userInfo = notification.userInfo,
            let reasonValue = userInfo[AVAudioSessionRouteChangeReasonKey] as? UInt,
            let reason = AVAudioSession.RouteChangeReason(rawValue:reasonValue) else {
                return
        }
        
        let ports : [AVAudioSession.Port] = [.airPlay,.builtInMic,.bluetoothA2DP,.bluetoothHFP,.builtInReceiver,.bluetoothLE,.builtInReceiver,.headphones,.headsetMic]
        switch reason {
        case .newDeviceAvailable: //Get Notification When Device Connect
            let session = AVAudioSession.sharedInstance()
            for output in session.currentRoute.outputs where ports.contains(where: {$0 == output.portType}) {
                //                try AVAudioSession.sharedInstance().overrideOutputAudioPort(AVAudioSession.PortOverride.speaker)
                //                headphonesConnected = true
                break
            }
        case .oldDeviceUnavailable:  //Get Notification When Device Disconnect
            if let previousRoute =
                userInfo[AVAudioSessionRouteChangePreviousRouteKey] as? AVAudioSessionRouteDescription {
                for output in previousRoute.outputs where ports.contains(where: {$0 == output.portType}) {
                    //                    headphonesConnected = false
                    
                    //Check Player State
                    
                    break
                }
            }
        default: ()
        }
    }
    
    @objc func audioSessionInterrupted(notification: Notification){
        guard let userInfo = notification.userInfo,
            let typeValue = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt,
            let type = AVAudioSession.InterruptionType(rawValue: typeValue) else {
                return
        }
        switch type {
            
        case .began:
            // Interruption began, take appropriate actions
            break
        case .ended:
            if let optionsValue = userInfo[AVAudioSessionInterruptionOptionKey] as? UInt {
                let options = AVAudioSession.InterruptionOptions(rawValue: optionsValue)
                if options.contains(.shouldResume) {
                    // Interruption Ended - playback should resume
                } else {
                    // Interruption Ended - playback should NOT resume
                }
            }
            break
        @unknown default:
            break
        }
        
        
    }
    
    func observingTimeChanges() {
        if playerObserver != nil{
            playerObserver = nil
        }else{
            let time = CMTimeMake(value: 1, timescale: 1) // 1/1 seconds
            playerObserver = audioPlayer?.addPeriodicTimeObserver(forInterval: time, queue: DispatchQueue.main, using: { (currentPlayerTime) in //Get CurrentTime Of Player
                self.setToBackGround(isPlaying: true, dictMusicData: [:])
                self.checkAudioPlayback()
            })
        }
    } //For Observing the playing Time
    
}

//Extra Function Used For Call
extension AppDelegate{
    func checkAudioPlayback(){
        
        if self.audioPlayer?.currentItem?.status == AVPlayerItem.Status.readyToPlay {
            let playbackLikelyToKeepUp = self.audioPlayer?.currentItem?.isPlaybackLikelyToKeepUp
            let playbackBufferFull = self.audioPlayer?.currentItem?.isPlaybackBufferFull
            let playbackBufferEmpty = self.audioPlayer?.currentItem?.isPlaybackBufferEmpty
            
            if playbackLikelyToKeepUp ?? false {
                self.isBuffering = false
            }else if playbackBufferEmpty ?? true{
                self.isBuffering = true
            }else if playbackBufferFull ?? false{
                self.isBuffering = false
            }
        }
    }
    
    
    func isPlayingPlayer(){
        // print(audioPlayer.rate,"\n")
        if audioPlayer?.rate != nil || audioPlayer?.rate != 0.0{
            // self.isBuffering = false //Changes
        }else{
            //   self.isBuffering = true //Changes
        }
    }
    
    
    //Start The Audio Session
    func audioSession(){
        NotificationCenter.default.addObserver(self, selector: #selector(audioSessionInterrupted(notification:)), name: AVAudioSession.interruptionNotification, object: AVAudioSession.sharedInstance())
        do{
            
            let avPlayerSession = AVAudioSession.sharedInstance()
            
            try avPlayerSession.setCategory(AVAudioSession.Category.playback)
            try avPlayerSession.setCategory(.playback, options: .allowBluetooth)
            if #available(iOS 10.0, *) {
                try avPlayerSession.setCategory(.playback, options: .allowAirPlay)
            } else {
                // Fallback on earlier versions
            }
            if #available(iOS 10.0, *) {
                try avPlayerSession.setCategory(.playback, options: .allowBluetoothA2DP)
            } else {
                // Fallback on earlier versions
            }
            try avPlayerSession.overrideOutputAudioPort(AVAudioSession.PortOverride.speaker)
            NotificationCenter.default.addObserver(self, selector: #selector(handleRouteChange(notification:)), name: AVAudioSession.routeChangeNotification, object: nil)
            let _ = try AVAudioSession.sharedInstance().setActive(true)
            
        }catch let error as NSError {
            print("\n\n\n > > > > > Error during Audio Session \n",error.localizedDescription,"\nReason",error.localizedFailureReason ?? "Nil","\n\n\n")
        }
    }
    
    //Add VolumeView For Set The Volume For Device
    func addVolumeView(controller : UIViewController){
        controller.view.addSubview(volumeView)
        volumeView.isHidden = true
    }
    
}

//MARK:- Media Control Functions
extension AppDelegate{
    func setToBackGround(isPlaying : Bool,dictMusicData:Dictionary<String,Any>){
        if isPlaying{ //Music Is Playing
            print("\n\n\n\nAdded To BackGround>>>>>>>>>>>>\n\n\n\n")
            var nowPlayingInfo = [String : Any]()
            nowPlayingInfo[MPMediaItemPropertyTitle] = self.strTitle
            if let image = UIImage(named: "lockscreen") {
                if #available(iOS 10.0, *) {
                    nowPlayingInfo[MPMediaItemPropertyArtwork] =
                        MPMediaItemArtwork(boundsSize: image.size) { size in
                            return image
                    }
                } else {
                    // Fallback on earlier versions
                }
            }
            
            nowPlayingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = CMTimeGetSeconds(audioPlayer?.currentItem?.currentTime() ?? CMTime.zero)
            nowPlayingInfo[MPMediaItemPropertyPlaybackDuration] = CMTimeGetSeconds(audioPlayer?.currentItem?.duration ?? CMTime.zero)
            nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackRate] = audioPlayer?.rate
            // Set the metadata
            playingInfoCenter.nowPlayingInfo = nowPlayingInfo
        }else{ //Music Is Not Playing
            var nowPlayingInfo = [String : Any]()
            do{
                try AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
            }catch{
                print("Error In Inactive Session Of Audio",error.localizedDescription)
            }
            nowPlayingInfo[MPMediaItemPropertyTitle] = "Music"
            playingInfoCenter.nowPlayingInfo = [:]//nowPlayingInfo
        }
        
    } //Background Notification
    
    func setBackgroundControls(){
        let pauseCommand = commandCenter.pauseCommand
        let playCommand = commandCenter.playCommand
        playCommand.addTarget(self, action: #selector(playPauseNotification(event:)))
        pauseCommand.addTarget(self, action: #selector(playPauseNotification(event:)))
    } //Background Button Action
    
    @objc func playPauseNotification(event : MPSkipIntervalCommandEvent){
        if audioPlayer?.timeControlStatus == AVPlayer.TimeControlStatus.playing{
            print("Setting Player To Pause")
            audioPlayer?.pause()
            self.isPlayingButton = false
        }else{
            print("Setting Player To Play")
            audioPlayer?.play()
            self.isPlayingButton = true
        }
    }
}

