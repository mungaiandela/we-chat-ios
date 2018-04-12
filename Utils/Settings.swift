//
//  Settings.swift
//  wechat
//
//  Created by Martin Mungai on 20/03/2018.
//  Copyright © 2018 Martin Mungai. All rights reserved.
//

import TwilioVideo

class Settings: NSObject {
    
    let supportedAudioCodecs = [TVIAudioCodec.ISAC,
                                TVIAudioCodec.opus,
                                TVIAudioCodec.PCMA,
                                TVIAudioCodec.PCMU,
                                TVIAudioCodec.G722]
    
    let supportedVideoCodecs = [TVIVideoCodec.VP8,
                                TVIVideoCodec.H264,
                                TVIVideoCodec.VP9]
    
    var audioCodec: TVIAudioCodec?
    var videoCodec: TVIVideoCodec?
    
    var maxAudioBitrate = UInt()
    var maxVideoBitrate = UInt()
    
    func getEncodingParameters() -> TVIEncodingParameters?  {
        if maxAudioBitrate == 0 && maxVideoBitrate == 0 {
            return nil;
        } else {
            return TVIEncodingParameters(audioBitrate: maxAudioBitrate,
                                         videoBitrate: maxVideoBitrate)
        }
    }
    
    private override init() {
        // Can't initialize a singleton
    }
    
    // MARK: Shared Instance
    static let shared = Settings()
}
