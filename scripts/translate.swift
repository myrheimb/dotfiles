import Foundation
import NaturalLanguage
import Translation

let arguments = CommandLine.arguments.dropFirst()
let text =
  arguments.isEmpty
  ? String(decoding: FileHandle.standardInput.readDataToEndOfFile(), as: UTF8.self)
  : arguments.joined(separator: " ")

guard let detected = NLLanguageRecognizer.dominantLanguage(for: text) else {
  FileHandle.standardError.write(Data("translate: could not detect the language\n".utf8))
  exit(1)
}

let source = Locale.Language(identifier: detected.rawValue)
let target = Locale.Language(identifier: detected == .english ? "ja" : "en")

do {
  let session = TranslationSession(
    installedSource: source, target: target, preferredStrategy: .highFidelity)
  print(try await session.translate(text).targetText)
} catch {
  let pair = "\(source.minimalIdentifier) → \(target.minimalIdentifier)"
  FileHandle.standardError.write(Data("translate: \(pair): \(error.localizedDescription)\n".utf8))
  exit(1)
}
