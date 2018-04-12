//
//  ViewController.swift
//  wechat
//
//  Created by Martin Mungai on 15/03/2018.
//  Copyright © 2018 Martin Mungai. All rights reserved.
//

import UIKit
import NotificationBannerSwift
import TwilioVideo

class ViewController: UIViewController {
    
    // MARK: View Controller Members
    
    // Configure access token manually for testing
    private var accessToken = "TWILIO_ACCESS_TOKEN"
    
    // Configure localhost URL to fetch token from
    private var tokenURL = "https://videochat-app.herokuapp.com/"
    
    // Video SDK Components
    internal var room: TVIRoom?
    private var camera: TVICameraCapturer?
    private var localVideoTrack: TVILocalVideoTrack?
    private var localAudioTrack: TVILocalAudioTrack?
    internal var remoteParticipant: TVIRemoteParticipant?
    
    
    // Mark: UI Element Outlets and handles
    
    @IBOutlet weak var roomTextField: UITextField!
    @IBOutlet weak var previewView: TVIVideoView!
    @IBOutlet weak var disconnectButton: UIImageView!
    @IBOutlet weak var remoteView: TVIVideoView!
    @IBOutlet weak var micButton: UIImageView!
    
    // MARK: Overriden public methods
    
    public override func viewDidLoad() {
        
        super.viewDidLoad()
        
        if PlatformUtils.isSimulator {
            self.previewView.removeFromSuperview()
        }
        
        self.roomTextField.autocapitalizationType = .none
        self.roomTextField.delegate = self
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(ViewController.dismissKeyboard))
        self.view.addGestureRecognizer(tap)
        
        disconnect()
        toggleMic()
    }
    
    public override func viewDidAppear(_ animated: Bool) {
        self.startPreview()
    }
    
    // MARK: Icons used as buttons
    
    internal func disconnect() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(ViewController.disconnectButtonTapped))
        tap.delegate = self
        self.disconnectButton.addGestureRecognizer(tap)
        self.disconnectButton.isUserInteractionEnabled = true
    }
    
    internal func toggleMic() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(ViewController.toggleMicTapped))
        tap.delegate = self
        self.micButton.addGestureRecognizer(tap)
        self.micButton.isUserInteractionEnabled = true
    }
    
    @objc internal func connectButtonTapped(sender: AnyObject) {
        // Configure access token either from server or manually
        // If default access token wasn't changed, try fetching from server
        
        if accessToken == "TWILIO_ACCESS_TOKEN" {
            do {
                accessToken = try TokenUtils.fetchToken(url: tokenURL)
            } catch {
                let message = "Failed to fetch access token"
                logWarningMessage(messageText: message)
                return
            }
            
            // Prepare local media which we will share with Room Participants.
            self.prepareLocalMedia()
            
            // Preparing the connect options with the access token that we fetched
            
            let connectOptions = TVIConnectOptions(token: accessToken) { (builder) in
                
                // Use the local media that we prepared earlier.
                builder.audioTracks = self.localAudioTrack != nil ? [self.localAudioTrack!] : [TVILocalAudioTrack]()
                builder.videoTracks = self.localVideoTrack != nil ? [self.localVideoTrack!] : [TVILocalVideoTrack]()
                
                // Use preferred audio codec
                if let preferredAudioCodec = Settings.shared.audioCodec {
                    builder.preferredAudioCodecs = [preferredAudioCodec.rawValue]
                }
                
                // Use preferred video codec
                if let preferredVideoCodec = Settings.shared.audioCodec {
                    builder.preferredVideoCodecs = [preferredVideoCodec.rawValue]
                }
                
                // Use preferred encoding parameters
                if let encodingParameters = Settings.shared.getEncodingParameters() {
                    builder.encodingParameters = encodingParameters
                }
                
                // If you pass an empty room name the client will create one for you
                builder.roomName = self.roomTextField.text
            }
        
            // Connect to the room using provided options
            
            room = TwilioVideo.connect(with: connectOptions, delegate: self)
            
            logWarningMessage(messageText: "Attempting to connect to \(String(describing: self.roomTextField.text!))")
            self.dismissKeyboard()
        }
    }
    
    // MARK: Private instance methods
    
    internal func startPreview() {
        
        if PlatformUtils.isSimulator { return }
        
        //Show local camera preview in previewView
        
        camera = TVICameraCapturer(source: .frontCamera)
        
        localVideoTrack = TVILocalVideoTrack(capturer: camera!)
        
        let renderer = TVIVideoView(frame: previewView.bounds)
        
        if localVideoTrack == nil {
            logWarningMessage(messageText: "Failed to create video track")
        } else {
            // Add renderer to video track for local preview
            localVideoTrack!.addRenderer(renderer)
            previewView.addSubview(renderer)
            logSuccessMessage(messageText: "Video track created")
            // Flip camera on tap
            let tap = UITapGestureRecognizer(target: self, action: #selector(ViewController.flipCamera))
            self.previewView.addGestureRecognizer(tap)
            
        }
    }
    
    private func prepareLocalMedia() {
        
        if localAudioTrack == nil {
            localAudioTrack = TVILocalAudioTrack(options: nil, enabled: true, name: "Microphone")
            if localAudioTrack == nil {
                logWarningMessage(messageText: "Failed to create audio track")
            }
        }
    }
    
    @objc private func flipCamera() {
        
        if self.camera?.source == .frontCamera {
            self.camera?.selectSource(.backCameraWide)
        } else {
            self.camera?.selectSource(.frontCamera)
        }
    }
    
    @objc private func dismissKeyboard() {
        if self.roomTextField.isFirstResponder {
            self.roomTextField.resignFirstResponder()
        }
    }
    
    internal func cleanupRemoteParticipant() {
        if self.remoteParticipant != nil && (self.remoteParticipant?.videoTracks.count)! > 0 {
            let remoteVideoTrack = self.remoteParticipant?.remoteVideoTracks[0].remoteTrack
            remoteVideoTrack?.removeRenderer(self.remoteView!)
            self.remoteView?.removeFromSuperview()
            self.remoteView = nil
        }
        
        self.remoteParticipant = nil
    }
    
    
    
    internal func logWarningMessage(messageText: String) {
        
        let banner = NotificationBanner(title: messageText, style: .warning)
        banner.show(on: self)
        banner.dismiss()
    }
    
    internal func logSuccessMessage(messageText: String) {
        
        let banner = NotificationBanner(title: messageText, style: .success)
        banner.show(on: self)
        banner.dismiss()
    }
    
    internal func logDangerMessage(messageText: String) {
        let banner = NotificationBanner(title: messageText, style: .danger)
        banner.show(on: self)
        banner.dismiss()
    }
    
    @objc internal func disconnectButtonTapped() {
        
        guard let room = self.room
            else { return }
        room.disconnect()
        logWarningMessage(messageText: "Attempting to disconnect from room \(room.name)")
    }
    
    @objc internal func toggleMicTapped() {
        if self.localAudioTrack != nil {
            if self.localAudioTrack?.isEnabled == true {
                self.localAudioTrack?.isEnabled = false
                logSuccessMessage(messageText: "Mute")
            } else {
                self.localAudioTrack?.isEnabled = true
                self.logWarningMessage(messageText: "Unmute")
            }
        }
    }
}



