import Foundation
#if canImport(FoundationXML)
import FoundationXML
#endif
#if canImport(Compression)
import Compression
#endif

/// Programme du guide TV.
public struct Programme: Codable, Hashable, Sendable, Identifiable {
    public var channel: String
    public var start: Date
    public var stop: Date
    public var title: String
    public var desc: String?

    public var id: String { "\(channel)|\(start.timeIntervalSince1970)" }

    public init(channel: String, start: Date, stop: Date, title: String, desc: String? = nil) {
        self.channel = channel
        self.start = start
        self.stop = stop
        self.title = title
        self.desc = desc
    }

    /// Avancement entre 0 et 1 à l'instant donné.
    public func progress(at date: Date = Date()) -> Double {
        let total = stop.timeIntervalSince(start)
        guard total > 0 else { return 0 }
        return min(max(date.timeIntervalSince(start) / total, 0), 1)
    }
}

/// Index du guide TV par chaîne.
public struct EPGIndex: Sendable {
    private var byChannel: [String: [Programme]] = [:]

    public init(programmes: [Programme] = []) {
        merge(programmes)
    }

    public var isEmpty: Bool { byChannel.isEmpty }
    public var channelCount: Int { byChannel.count }

    public mutating func merge(_ programmes: [Programme]) {
        for p in programmes {
            byChannel[Self.key(p.channel), default: []].append(p)
        }
        for key in byChannel.keys {
            byChannel[key]!.sort { $0.start < $1.start }
        }
    }

    static func key(_ channel: String) -> String { channel.lowercased().trimmingCharacters(in: .whitespaces) }

    public func programmes(for channel: String?) -> [Programme] {
        guard let channel else { return [] }
        return byChannel[Self.key(channel)] ?? []
    }

    public func current(for channel: String?, at date: Date = Date()) -> Programme? {
        programmes(for: channel).first { $0.start <= date && date < $0.stop }
    }

    public func upcoming(for channel: String?, after date: Date = Date(), limit: Int = 6) -> [Programme] {
        Array(programmes(for: channel).filter { $0.start > date }.prefix(limit))
    }
}

/// Analyseur XMLTV (guide TV), en flux, avec filtrage sur une fenêtre de temps pour limiter la mémoire.
public final class XMLTVParser: NSObject, XMLParserDelegate {

    private var window: DateInterval?
    private var programmes: [Programme] = []

    private var currentChannel: String?
    private var currentStart: Date?
    private var currentStop: Date?
    private var currentTitle = ""
    private var currentDesc = ""
    private var textBuffer = ""
    private var inProgramme = false
    private var element: String?

    /// Analyse un document XMLTV (gère aussi le .gz sur les plateformes Apple).
    public static func parse(data: Data, window: DateInterval? = XMLTVParser.defaultWindow()) -> [Programme] {
        var payload = data
        if Gzip.isGzip(data), let inflated = Gzip.decompress(data) { payload = inflated }
        let delegate = XMLTVParser()
        delegate.window = window
        let parser = XMLParser(data: payload)
        parser.delegate = delegate
        parser.parse()
        return delegate.programmes
    }

    /// Fenêtre par défaut : de 6 h en arrière à 48 h en avant.
    public static func defaultWindow(now: Date = Date()) -> DateInterval {
        DateInterval(start: now.addingTimeInterval(-6 * 3600), end: now.addingTimeInterval(48 * 3600))
    }

    public func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?,
                       qualifiedName qName: String?, attributes attributeDict: [String: String] = [:]) {
        if elementName == "programme" {
            inProgramme = true
            currentChannel = attributeDict["channel"]
            currentStart = attributeDict["start"].flatMap(XMLTVDate.parse)
            currentStop = attributeDict["stop"].flatMap(XMLTVDate.parse)
            currentTitle = ""
            currentDesc = ""
        } else if inProgramme {
            element = elementName
            textBuffer = ""
        }
    }

    public func parser(_ parser: XMLParser, foundCharacters string: String) {
        if inProgramme, element != nil { textBuffer += string }
    }

    public func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        if elementName == "programme" {
            inProgramme = false
            guard let channel = currentChannel, let start = currentStart else { return }
            let stop = currentStop ?? start.addingTimeInterval(3600)
            if let window, stop < window.start || start > window.end { return }
            let title = currentTitle.trimmingCharacters(in: .whitespacesAndNewlines)
            let desc = currentDesc.trimmingCharacters(in: .whitespacesAndNewlines)
            programmes.append(Programme(channel: channel, start: start, stop: stop,
                                        title: title.isEmpty ? "Sans titre" : title,
                                        desc: desc.isEmpty ? nil : desc))
        } else if inProgramme, let el = element, el == elementName {
            // On garde le premier titre / la première description (souvent plusieurs langues).
            if el == "title", currentTitle.isEmpty { currentTitle = textBuffer }
            if el == "desc", currentDesc.isEmpty { currentDesc = textBuffer }
            element = nil
        }
    }
}

/// Dates XMLTV : « 20261018203000 +0200 » (le décalage est facultatif, UTC par défaut).
public enum XMLTVDate {
    public static func parse(_ text: String) -> Date? {
        let parts = text.split(separator: " ", omittingEmptySubsequences: true)
        guard let stamp = parts.first, stamp.count >= 12 else { return nil }
        let digits = Array(stamp.utf8.prefix(14))
        func number(_ from: Int, _ length: Int) -> Int? {
            guard from + length <= digits.count else { return length == 2 && from == 12 ? 0 : nil }
            var value = 0
            for byte in digits[from..<(from + length)] {
                guard byte >= 48 && byte <= 57 else { return nil }
                value = value * 10 + Int(byte - 48)
            }
            return value
        }
        guard let year = number(0, 4), let month = number(4, 2), let day = number(6, 2),
              let hour = number(8, 2), let minute = number(10, 2) else { return nil }
        let second = number(12, 2) ?? 0

        var offset = 0
        if parts.count > 1 {
            let tz = Array(parts[1].utf8)
            if tz.count == 5, tz[0] == 43 || tz[0] == 45 {
                let h = Int(tz[1] - 48) * 10 + Int(tz[2] - 48)
                let m = Int(tz[3] - 48) * 10 + Int(tz[4] - 48)
                offset = (h * 3600 + m * 60) * (tz[0] == 45 ? -1 : 1)
            }
        }

        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let components = DateComponents(year: year, month: month, day: day, hour: hour, minute: minute, second: second)
        guard let utc = calendar.date(from: components) else { return nil }
        return utc.addingTimeInterval(TimeInterval(-offset))
    }
}

/// Décompression gzip (guides TV « .xml.gz »).
public enum Gzip {
    public static func isGzip(_ data: Data) -> Bool {
        data.count > 18 && data[data.startIndex] == 0x1f && data[data.startIndex + 1] == 0x8b
    }

    public static func decompress(_ data: Data) -> Data? {
        #if canImport(Compression)
        let bytes = [UInt8](data)
        guard bytes.count > 18, bytes[0] == 0x1f, bytes[1] == 0x8b, bytes[2] == 8 else { return nil }
        let flags = bytes[3]
        var index = 10
        if flags & 0x04 != 0 { // FEXTRA
            guard index + 2 <= bytes.count else { return nil }
            index += 2 + Int(bytes[index]) + Int(bytes[index + 1]) << 8
        }
        if flags & 0x08 != 0 { while index < bytes.count && bytes[index] != 0 { index += 1 }; index += 1 } // FNAME
        if flags & 0x10 != 0 { while index < bytes.count && bytes[index] != 0 { index += 1 }; index += 1 } // FCOMMENT
        if flags & 0x02 != 0 { index += 2 } // FHCRC
        guard index < bytes.count - 8 else { return nil }
        let deflated = Array(bytes[index..<(bytes.count - 8)])

        let bufferSize = 1 << 20
        let destination = UnsafeMutablePointer<UInt8>.allocate(capacity: bufferSize)
        defer { destination.deallocate() }
        let streamPointer = UnsafeMutablePointer<compression_stream>.allocate(capacity: 1)
        defer { streamPointer.deallocate() }
        guard compression_stream_init(streamPointer, COMPRESSION_STREAM_DECODE, COMPRESSION_ZLIB) == COMPRESSION_STATUS_OK else { return nil }
        defer { compression_stream_destroy(streamPointer) }

        var output = Data()
        let ok: Bool = deflated.withUnsafeBufferPointer { source -> Bool in
            guard let base = source.baseAddress else { return false }
            streamPointer.pointee.src_ptr = base
            streamPointer.pointee.src_size = source.count
            while true {
                streamPointer.pointee.dst_ptr = destination
                streamPointer.pointee.dst_size = bufferSize
                let status = compression_stream_process(streamPointer, Int32(COMPRESSION_STREAM_FINALIZE.rawValue))
                let produced = bufferSize - streamPointer.pointee.dst_size
                if produced > 0 { output.append(destination, count: produced) }
                switch status {
                case COMPRESSION_STATUS_OK: continue
                case COMPRESSION_STATUS_END: return true
                default: return false
                }
            }
        }
        return ok ? output : nil
        #else
        return nil
        #endif
    }
}

/// Chargement d'un guide TV distant.
public enum EPGLoader {
    public static func load(from url: URL, window: DateInterval = XMLTVParser.defaultWindow()) async throws -> [Programme] {
        let data = try await HTTP.get(url, timeout: 180)
        return XMLTVParser.parse(data: data, window: window)
    }
}
