// Synthesizes the app's sound effects as 16-bit mono WAV files.
// Usage: swift scripts/render-sounds.swift <output-dir>
import Foundation

let sampleRate = 44_100.0

guard CommandLine.arguments.count == 2 else {
    print("Usage: swift scripts/render-sounds.swift <output-dir>")
    exit(1)
}
let outputDirectory = URL(fileURLWithPath: CommandLine.arguments[1])
try FileManager.default.createDirectory(at: outputDirectory, withIntermediateDirectories: true)

/// One note: a frequency, when it starts, how long it rings, and its tone.
struct Note {
    var frequency: Double
    var start: Double
    var duration: Double
    var volume = 0.5
    /// Relative strength of the 2nd and 3rd harmonics. More makes it brighter or buzzier.
    var harmonics: (Double, Double) = (0.3, 0.1)
}

func frequency(_ name: String) -> Double {
    let semitones = ["C": -9, "D": -7, "E": -5, "F": -4, "G": -2, "A": 0, "B": 2]
    let letter = String(name.prefix(1))
    let isSharp = name.contains("#")
    let isFlat = name.dropFirst().contains("b")
    let octave = Int(String(name.last!))!
    let offset = semitones[letter]! + (isSharp ? 1 : 0) - (isFlat ? 1 : 0) + (octave - 4) * 12
    return 440 * pow(2, Double(offset) / 12)
}

/// Mixes notes with a quick attack and an exponential decay, so they sound plucked rather than beeped.
func render(_ notes: [Note], length: Double) -> [Int16] {
    let count = Int(length * sampleRate)
    var samples = [Double](repeating: 0, count: count)
    for note in notes {
        let first = Int(note.start * sampleRate)
        let last = min(count, first + Int(note.duration * sampleRate))
        for index in first..<last {
            let t = Double(index - first) / sampleRate
            let attack = min(1, t / 0.008)
            let decay = exp(-t * 5 / note.duration)
            let phase = 2 * Double.pi * note.frequency * t
            let tone = sin(phase) + note.harmonics.0 * sin(2 * phase) + note.harmonics.1 * sin(3 * phase)
            samples[index] += note.volume * attack * decay * tone
        }
    }
    let peak = samples.map(abs).max() ?? 1
    let gain = peak > 0 ? 0.8 / peak : 0
    return samples.map { Int16(($0 * gain * Double(Int16.max)).rounded()) }
}

func wav(_ samples: [Int16]) -> Data {
    var data = Data()
    func append<T: FixedWidthInteger>(_ value: T) {
        withUnsafeBytes(of: value.littleEndian) { data.append(contentsOf: $0) }
    }
    let byteCount = UInt32(samples.count * 2)
    data.append(contentsOf: Array("RIFF".utf8)); append(36 + byteCount)
    data.append(contentsOf: Array("WAVE".utf8))
    data.append(contentsOf: Array("fmt ".utf8)); append(UInt32(16)); append(UInt16(1)); append(UInt16(1))
    append(UInt32(sampleRate)); append(UInt32(sampleRate * 2)); append(UInt16(2)); append(UInt16(16))
    data.append(contentsOf: Array("data".utf8)); append(byteCount)
    for sample in samples { append(sample) }
    return data
}

let sounds: [String: (notes: [Note], length: Double)] = [
    // Two low, buzzy pulses.
    "times-up": ([
        Note(frequency: frequency("A2"), start: 0, duration: 0.22, volume: 0.6, harmonics: (0.7, 0.5)),
        Note(frequency: frequency("A2"), start: 0.28, duration: 0.32, volume: 0.6, harmonics: (0.7, 0.5)),
    ], 0.7),
    // A bright major arpeggio that lands on a chord.
    "crew-wins": ([
        Note(frequency: frequency("C5"), start: 0, duration: 0.5),
        Note(frequency: frequency("E5"), start: 0.09, duration: 0.5),
        Note(frequency: frequency("G5"), start: 0.18, duration: 0.6),
        Note(frequency: frequency("C6"), start: 0.27, duration: 0.9, volume: 0.45),
        Note(frequency: frequency("G5"), start: 0.27, duration: 0.9, volume: 0.25),
    ], 1.3),
    // A sly, falling minor phrase.
    "imposters-win": ([
        Note(frequency: frequency("E4"), start: 0, duration: 0.3, harmonics: (0.5, 0.3)),
        Note(frequency: frequency("C4"), start: 0.16, duration: 0.3, harmonics: (0.5, 0.3)),
        Note(frequency: frequency("A3"), start: 0.32, duration: 0.45, harmonics: (0.5, 0.3)),
        Note(frequency: frequency("Eb3"), start: 0.5, duration: 0.9, volume: 0.45, harmonics: (0.5, 0.3)),
    ], 1.4),
]

for (name, sound) in sounds.sorted(by: { $0.key < $1.key }) {
    let url = outputDirectory.appending(path: "\(name).wav")
    try wav(render(sound.notes, length: sound.length)).write(to: url)
    print("Wrote \(url.path)")
}
