import PerfectHTTP
import PerfectHTTPServer
import PerfectWebSockets

var routers = Routes()

routers.add(getATRoutes())

do {
    try HTTPServer.launch(
        .server(name: "AT Service", port: 8181, routes: routers)
    )
} catch {
    fatalError("\(error)") // fatal error launching one of the servers
}
