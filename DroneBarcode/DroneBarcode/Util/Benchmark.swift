//
//  Benchmark.swift
//  DroneBarcode
//
//  Created by nick on 10/22/18.
//  Copyright © 2018 Tom Kocik. All rights reserved.
//

import Foundation

public class Benchmark {
    
    private var start = UInt64(0)
    private var end = UInt64(0)
    
    init(){}
    
    func startBenchmark() {
        self.start = mach_absolute_time()
    }
    
    func endBenchmark() {
        self.end = mach_absolute_time()
    }
    
    func getTimeNano() -> UInt64 {
        return self.end - self.start
    }
    
    /// Saves the list of times you have accumulated from numerous benchmarks to a file
    static func saveTimesToDataFile(_ times: [UInt64], file fileName: String) {
        var times_str = ""
        for time in times {
            times_str += String(format: "%lld,", time)
        }
        if let dir = NSSearchPathForDirectoriesInDomains(FileManager.SearchPathDirectory.documentDirectory, .allDomainsMask, true).first {
            let path = dir + "/" + fileName
            print("Saving to " + path)
            do {
                try times_str.write(toFile: path, atomically: false, encoding: .utf8)
                print("Wrote to file.")
            } catch {
                print("Could not save!")
            }
        } else {
            print("Could not get directory!")
        }
//        let fm = FileManager.default
//        let outfile = fm.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent(fileName)
//        if let handle = try? FileHandle(forWritingTo: outfile) {
//            handle.seekToEndOfFile()
//            // Write a comma separated list of values.
//            for time in times {
//                handle.write(String(format: "%lld, ", time).data(using: .utf8)!)
//            }
//            handle.closeFile()
//        }
    }
}
