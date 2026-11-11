#if os(macOS)
import Foundation
import ImposterHost
import ImposterKit

var ports = PortPair.defaults
let arguments = CommandLine.arguments
if let index = arguments.firstIndex(of: "--port"), index + 1 < arguments.count, let http = UInt16(arguments[index + 1]), http < UInt16.max {
    ports = [PortPair(http: http, ws: http + 1)]
}

let controller = try HostController(
    hostName: "Host",
    library: try WordLibrary.bundled(),
    allowsRemoteHostCommands: true,
    ports: ports
)
controller.autoplaysHostSeat = true
await controller.startListening()

if let message = controller.errorMessage {
    print("Could not start: \(message)")
    exit(1)
}
if let http = controller.httpPort {
    print("Imposter dev host running.")
    print("Open locally: http://localhost:\(http)/")
    if let url = controller.joinURL { print("Join URL:     \(url.absoluteString)") }
    print("Add ?dev=1 to drive host commands from a browser tab. Ctrl-C to stop.")
}
try await Task.sleep(for: .seconds(Double(Int32.max)))
#else
print("imposter-host-dev only runs on macOS.")
#endif
