//
//  ContentView.swift
//  Murmur
//
//  Created by Jerome Paulos on 12/13/22.
//

import SwiftUI

struct ContentView: View {
    @State private var output = ""
    @State private var isRunning = false
    @State private var task = Process()
    @State private var progress = 0.0
    
    struct Line {
        var text: String;
        var startSeconds: Int;
        var endSeconds: Int;

        static func fromString(_ string: String) -> [Line] {
            var result: [Line] = []
            let pattern = /\[(?<startHours>\d\d):(?<startMinutes>\d\d\.\d\d\d) --> (?<endHours>\d\d):(?<endMinutes>\d\d\.\d\d\d)\]  (?<text>.*)/;

            string.matches(of: pattern).forEach { match in
                let startHours = Int(match.startHours)!
                let endHours = Int(match.endHours)!
                
                let startSeconds: Float = Float(startHours*60*60) + Float(match.startMinutes)!
                let endSeconds: Float = Float(endHours*60*60) + Float(match.endMinutes)!

                result.append(Line(
                    text: String(match.text),
                    startSeconds: Int(startSeconds),
                    endSeconds: Int(endSeconds)
                ))
            }

            return result
        }
    }

    var body: some View {
        VStack {
            HStack {
                Button {
                    output = ""
                    isRunning = true
                    progress = 0

                    task = Process()
                    task.currentDirectoryURL = URL(filePath: "/Users/jerome/Downloads/whisper")
                    
                    // task.executableURL = URL(filePath: "/usr/local/bin/whisper")
                    // task.arguments = ["emery-emery.mp3", "--fp16=False", "--model=tiny", "--language=English"]
                    
                    task.executableURL = URL(filePath: "/bin/zsh")
                    task.arguments = ["-c", "export PATH=\"/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:/Library/Apple/usr/bin\"; export PYTHONUNBUFFERED=1; /usr/local/bin/whisper emery-emery.mp3 --fp16=False --model=tiny --language=English"]
                    // task.arguments = ["-c", "echo \"[00:00.000 --> 00:02.600]  Hello, I'm Emory Emory.\""]

                    task.terminationHandler = { process in
                        isRunning = process.isRunning
                    }

                    let pipe = Pipe()
                    task.standardOutput = pipe
                    task.standardError = pipe
                    let outHandle = pipe.fileHandleForReading
                    
                    outHandle.readabilityHandler = { pipe in
                        if let line = String(data: pipe.availableData, encoding: .utf8) {
                            let lines = Line.fromString(line)
                            
                            if let endSeconds = lines.last?.endSeconds {
                                progress = Double(endSeconds) / 57.0
                            }

                            output += " " + lines.map({$0.text}).joined(separator: " ")
                        } else {
                            output += "\nError decoding data: \(pipe.availableData)"
                        }
                    }

                    do {
                        try task.run()
                    } catch {
                        output += "\nError: \(error)"
                    }
                } label: {
                    Image(systemName: "waveform")
                    Text("Transcribe")
                }.disabled(isRunning)

                if isRunning {
                    Button("Cancel") { task.terminate() } // or .interrupt()
                    ProgressView(value: progress)
                        .progressViewStyle(.linear)
                        .tint(.accentColor)
                        .padding(.horizontal)
                } else {
                    Spacer()
                }
            }
            
            List {
                if output == "" {
                    Text("Your text will appear here")
                        .fontDesign(.serif)
                        .opacity(0.25)
                } else {
                    Text(output)
                        .fontDesign(.serif)
                        .textSelection(.enabled)
                }
            }
        }.padding()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
