import UIKit
import WebKit

/// 远程壳：全屏 WKWebView 直接加载服务器前端。
/// 改服务器地址 → 只改 Info.plist 的 XXJHomeURL（或本文件兜底常量），不用动别处。
final class WebViewController: UIViewController {

    private var webView: WKWebView!
    private var homeURL: URL!
    private var errorView: UIView?

    private let bgColor = UIColor(red: 11.0/255.0, green: 13.0/255.0, blue: 14.0/255.0, alpha: 1.0)
    private let goldColor = UIColor(red: 216.0/255.0, green: 180.0/255.0, blue: 90.0/255.0, alpha: 1.0)

    override var prefersStatusBarHidden: Bool { true }
    override var preferredStatusBarStyle: UIStatusBarStyle { .lightContent }

    override func viewDidLoad() {
        super.viewDidLoad()

        let raw = (Bundle.main.object(forInfoDictionaryKey: "XXJHomeURL") as? String)
            ?? "http://134.175.237.206:3000"
        homeURL = URL(string: raw) ?? URL(string: "http://134.175.237.206:3000")!

        view.backgroundColor = bgColor

        let config = WKWebViewConfiguration()
        config.allowsInlineMediaPlayback = true
        config.mediaTypesRequiringUserActionForPlayback = []
        config.preferences.javaScriptCanOpenWindowsAutomatically = true
        if #available(iOS 14.0, *) {
            let prefs = WKWebpagePreferences()
            prefs.allowsContentJavaScript = true
            config.defaultWebpagePreferences = prefs
        }

        webView = WKWebView(frame: view.bounds, configuration: config)
        webView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        webView.navigationDelegate = self
        webView.uiDelegate = self
        webView.allowsBackForwardNavigationGestures = true
        webView.scrollView.bounces = false
        webView.scrollView.contentInsetAdjustmentBehavior = .never
        webView.isOpaque = false
        webView.backgroundColor = bgColor
        webView.scrollView.backgroundColor = bgColor

        // 用 iPhone Safari 的 UA（服务端若按 UA 分支可命中），尾部加 App 标识便于排查
        webView.customUserAgent = "Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) "
            + "AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Mobile/15E148 Safari/604.1 XXJApp"

        view.addSubview(webView)
        webView.load(URLRequest(url: homeURL))
    }

    // MARK: - 断网 / 服务器不可达兜底

    private func showError() {
        guard errorView == nil else { return }
        let box = UIView(frame: view.bounds)
        box.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        box.backgroundColor = bgColor

        let title = UILabel()
        title.text = "连接不上服务器"
        title.textColor = goldColor
        title.font = UIFont.boldSystemFont(ofSize: 20)
        title.textAlignment = .center

        let sub = UILabel()
        sub.text = "请检查网络后重试\n（服务器：\(homeURL.host ?? "")）"
        sub.textColor = UIColor(white: 0.75, alpha: 1)
        sub.font = UIFont.systemFont(ofSize: 14)
        sub.numberOfLines = 0
        sub.textAlignment = .center

        let btn = UIButton(type: .system)
        btn.setTitle("重新加载", for: .normal)
        btn.setTitleColor(bgColor, for: .normal)
        btn.titleLabel?.font = UIFont.boldSystemFont(ofSize: 17)
        btn.backgroundColor = goldColor
        btn.layer.cornerRadius = 10
        btn.addTarget(self, action: #selector(retryLoad), for: .touchUpInside)

        let stack = UIStackView(arrangedSubviews: [title, sub, btn])
        stack.axis = .vertical
        stack.spacing = 16
        stack.alignment = .center
        stack.translatesAutoresizingMaskIntoConstraints = false
        box.addSubview(stack)

        NSLayoutConstraint.activate([
            stack.centerXAnchor.constraint(equalTo: box.centerXAnchor),
            stack.centerYAnchor.constraint(equalTo: box.centerYAnchor),
            stack.leadingAnchor.constraint(greaterThanOrEqualTo: box.leadingAnchor, constant: 32),
            stack.trailingAnchor.constraint(lessThanOrEqualTo: box.trailingAnchor, constant: -32),
            btn.widthAnchor.constraint(equalToConstant: 180),
            btn.heightAnchor.constraint(equalToConstant: 44),
        ])

        view.addSubview(box)
        errorView = box
    }

    private func hideError() {
        errorView?.removeFromSuperview()
        errorView = nil
    }

    @objc private func retryLoad() {
        hideError()
        webView.load(URLRequest(url: homeURL))
    }
}

// MARK: - WKNavigationDelegate

extension WebViewController: WKNavigationDelegate {

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        hideError()
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        if (error as NSError).code != NSURLErrorCancelled { showError() }
    }

    func webView(_ webView: WKWebView,
                 didFailProvisionalNavigation navigation: WKNavigation!,
                 withError error: Error) {
        if (error as NSError).code != NSURLErrorCancelled { showError() }
    }
}

// MARK: - WKUIDelegate（target=_blank 在同窗口打开）

extension WebViewController: WKUIDelegate {

    func webView(_ webView: WKWebView,
                 createWebViewWith configuration: WKWebViewConfiguration,
                 for navigationAction: WKNavigationAction,
                 windowFeatures: WKWindowFeatures) -> WKWebView? {
        if navigationAction.targetFrame == nil, let url = navigationAction.request.url {
            webView.load(URLRequest(url: url))
        }
        return nil
    }
}
