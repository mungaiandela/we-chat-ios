//
//  Ex+ViewController.swift
//  wechat
//
//  Created by Martin Mungai on 19/03/2018.
//  Copyright © 2018 Martin Mungai. All rights reserved.
//
import TwilioVideo

//MARK: TVIVideoViewDelegate
extension ViewController: TVIVideoViewDelegate {
    func videoView(_ view: TVIVideoView, videoDimensionsDidChange dimensions: CMVideoDimensions) {
        self.view.setNeedsLayout()
    }
}

//MARK: UITextFieldDelegate
extension ViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.connectButtonTapped(sender: textField)
        return true
    }
}

//MARK: TVIRoomDelegate
extension ViewController: TVIRoomDelegate {
    func didConnect(to room: TVIRoom) {
        logSuccessMessage(messageText: "Connected to \(room.name)")
        if room.remoteParticipants.count > 0 {
            self.remoteParticipant = room.remoteParticipants[0]
            self.remoteParticipant?.delegate = self
        }
    }
    
    func room(_ room: TVIRoom, didDisconnectWithError error: Error?) {
        logWarningMessage(messageText: "Disconnected from \(room.name)")
        self.cleanupRemoteParticipant()
        self.room = nil
    }
    
    func room(_ room: TVIRoom, didFailToConnectWithError error: Error) {
        logDangerMessage(messageText: "Failed to connect to room")
        self.room = nil
    }
    
    func room(_ room: TVIRoom, participantDidConnect participant: TVIRemoteParticipant) {
        if self.remoteParticipant == nil {
            self.remoteParticipant = participant
            self.remoteParticipant?.delegate = self
        }
        
        logSuccessMessage(messageText: "Participant connected")
    }
    
    func room(_ room: TVIRoom, participantDidDisconnect participant: TVIRemoteParticipant) {
        if self.remoteParticipant == participant {
            cleanupRemoteParticipant()
        }
        
        logWarningMessage(messageText: "Participant disconnected")
    }
}

//MARK: TVIRemoteParticipantDelegate
extension ViewController: TVIRemoteParticipantDelegate {
    
    func subscribed(to videoTrack: TVIRemoteVideoTrack,
                    publication: TVIRemoteVideoTrackPublication,
                    for participant: TVIRemoteParticipant) {
        
        // We are subscribed to the remote Participant's audio Track. We will start receiving the
        // remote Participant's video frames now.
        
        if self.remoteParticipant == participant {
            if let renderer = TVIVideoView(frame: remoteView.frame, delegate: self, renderingType: .openGLES) {
                videoTrack.addRenderer(renderer)
                renderer.contentMode = .scaleAspectFit
                renderer.tag = 140069
                self.remoteView.addSubview(renderer)
            }
            else {
                print("********No video added*******")
            }
        }
    }
    
    func unsubscribed(from videoTrack: TVIRemoteVideoTrack,
                      publication: TVIRemoteVideoTrackPublication,
                      for participant: TVIRemoteParticipant) {

        // We are unsubscribed from the remote Participant's video Track. We will no longer receive the
        // remote Participant's video.

        if (self.remoteParticipant == participant) {
            self.remoteView?.subviews.forEach({
                if $0.tag == 140069 {
                    $0.removeFromSuperview()
                }
            })
        }
    }
}

//MARK: UITapGestureRecognizer
extension ViewController: UIGestureRecognizerDelegate {
    
}


