import Foundation

final class BufferReader {
    private var length = 0
    private var payload = Data()
    private var handler: ([String: Any]) -> Void
    private var isValid: Bool { length == payload.count }

    init(handler: @escaping ([String: Any]) -> Void) {
        self.handler = handler
    }

    func read(_ data: Data) {
        if length == 0 {
            let length = Int(data.prefix(4).withUnsafeBytes { $0.load(as: Int32.self) })
            let payload = data.dropFirst(4)

            if payload.count == length {
                handle(payload)
                reset()
                return
            }

            if payload.count < length {
                self.length = length
                self.payload = payload
                return
            }

            handle(payload.prefix(length))
            reset()

            let remaining = payload.dropFirst(length)
            if !remaining.isEmpty {
                read(Data(remaining))
            }
        } else {
            if length == payload.count + data.count {
                handle(payload + data)
                reset()
                return
            }

            if payload.count + data.count < length {
                payload += data
                return
            }

            handle(payload + data.prefix(length - payload.count))
            reset()

            let remaining = payload.dropFirst(length - payload.count)
            if !remaining.isEmpty {
                read(Data(remaining))
            }
        }
    }

    private func handle(_ data: Data) {
        guard let request = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] else {
            return
        }
        handler(request)
    }

    private func reset() {
        length = 0
        payload = Data()
    }
}
