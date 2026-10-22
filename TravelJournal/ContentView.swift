import SwiftUI
import WebKit

struct ContentView: View {
    var body: some View {
        WebView()
    }
}

/// 手账数据保存在 Documents/journal.json（可在“文件”App → 我的 iPhone → 旅行手账 里看到）
enum Store {
    static var url: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("journal.json")
    }
    static func read() -> String? {
        try? String(contentsOf: url, encoding: .utf8)
    }
    static func write(_ s: String) {
        try? s.write(to: url, atomically: true, encoding: .utf8)
    }
}

struct WebView: UIViewRepresentable {
    func makeCoordinator() -> Coordinator { Coordinator() }

    func makeUIView(context: Context) -> WKWebView {
        let controller = WKUserContentController()
        controller.add(context.coordinator, name: "native")

        // 启动时把已保存的数据注入网页
        if let raw = Store.read(),
           let encoded = try? JSONEncoder().encode(raw),
           let literal = String(data: encoded, encoding: .utf8) {
            controller.addUserScript(WKUserScript(
                source: "window.__NATIVE_DATA=\(literal);",
                injectionTime: .atDocumentStart,
                forMainFrameOnly: true))
        }

        let config = WKWebViewConfiguration()
        config.userContentController = controller
        config.allowsInlineMediaPlayback = true

        let web = WKWebView(frame: .zero, configuration: config)
        web.isOpaque = false
        web.backgroundColor = .clear
        web.scrollView.backgroundColor = .clear
        web.scrollView.contentInsetAdjustmentBehavior = .never
        web.scrollView.bounces = false
        web.scrollView.isScrollEnabled = false
        web.allowsLinkPreview = false
        web.allowsBackForwardNavigationGestures = false

        if let html = Bundle.main.url(forResource: "journal", withExtension: "html") {
            web.loadFileURL(html, allowingReadAccessTo: html.deletingLastPathComponent())
        }
        return web
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {}

    final class Coordinator: NSObject, WKScriptMessageHandler {
        func userContentController(_ controller: WKUserContentController,
                                   didReceive message: WKScriptMessage) {
            guard let body = message.body as? [String: Any],
                  let action = body["a"] as? String,
                  let data = body["data"] as? String else { return }
            switch action {
            case "save":
                Store.write(data)
            case "export":
                share(data)
            default:
                break
            }
        }

        private func share(_ json: String) {
            let file = FileManager.default.temporaryDirectory
                .appendingPathComponent("travel-journal.json")
            try? json.write(to: file, atomically: true, encoding: .utf8)

            let scene = UIApplication.shared.connectedScenes
                .compactMap { $0 as? UIWindowScene }
                .first
            guard let window = scene?.windows.first(where: { $0.isKeyWindow }) ?? scene?.windows.first,
                  var top = window.rootViewController else { return }
            while let presented = top.presentedViewController { top = presented }

            let sheet = UIActivityViewController(activityItems: [file], applicationActivities: nil)
            sheet.popoverPresentationController?.sourceView = top.view
            sheet.popoverPresentationController?.sourceRect =
                CGRect(x: top.view.bounds.midX, y: top.view.bounds.midY, width: 1, height: 1)
            top.present(sheet, animated: true)
        }
    }
}
