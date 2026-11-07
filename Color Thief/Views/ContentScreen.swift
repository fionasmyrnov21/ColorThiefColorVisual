import SwiftUI
import WebKit

struct ContentScreen: View {
    @ObservedObject var model: ContentViewModel
    let openGame: () -> Void

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            ContentFrame(model: model).ignoresSafeArea(.container, edges: .all)
            if model.loading.showsInitialCover {
                Color.black.ignoresSafeArea()
                ReservedRegionContent {
                    ProgressView().progressViewStyle(.circular).tint(.white)
                        .frame(maxWidth: .infinity, maxHeight: .infinity).accessibilityLabel("Loading")
                }
            } else if model.loading.showsInitialError {
                Color.black.ignoresSafeArea()
                ReservedRegionContent {
                    ScrollView {
                        VStack(spacing: 24) {
                            Text("Unable to open this page").font(.title2).multilineTextAlignment(.center)
                            Text("Check your connection and try again.").font(.body).multilineTextAlignment(.center)
                            Button("Retry") { model.retry() }.buttonStyle(.borderedProminent).tint(.white).foregroundStyle(.black)
                            Button("Open game", action: openGame).frame(minHeight: 44)
                        }.foregroundStyle(.white).padding(24).frame(maxWidth: .infinity)
                    }
                }
            }
        }
        .alert("Page could not be opened", isPresented: Binding(get: { model.loading.showsNavigationError }, set: { if !$0 { model.dismissFailure() } })) {
            Button("OK", role: .cancel) { model.dismissFailure() }
        } message: { Text("Check your connection and try the link again.") }
    }
}

private struct ContentFrame: UIViewRepresentable {
    @ObservedObject var model: ContentViewModel

    func makeCoordinator() -> Coordinator { Coordinator(model: model) }

    func makeUIView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        configuration.websiteDataStore = ContentSession.shared.dataStore
        let contentView = WKWebView(frame: .zero, configuration: configuration)
        contentView.scrollView.contentInsetAdjustmentBehavior = .never
        contentView.scrollView.contentInset = .zero
        contentView.scrollView.automaticallyAdjustsScrollIndicatorInsets = false
        contentView.scrollView.verticalScrollIndicatorInsets = .zero
        contentView.scrollView.horizontalScrollIndicatorInsets = .zero
        contentView.allowsBackForwardNavigationGestures = true
        contentView.isOpaque = false
        contentView.backgroundColor = .black
        contentView.scrollView.backgroundColor = .black
        contentView.navigationDelegate = context.coordinator
        contentView.uiDelegate = context.coordinator
        return contentView
    }

    func updateUIView(_ contentView: WKWebView, context: Context) {
        context.coordinator.load(contentView, attempt: model.attempt)
    }

    static func dismantleUIView(_ contentView: WKWebView, coordinator: Coordinator) {
        coordinator.stop()
        Task { await ContentSession.shared.capture() }
    }

    @MainActor
    final class Coordinator: NSObject, WKNavigationDelegate, WKUIDelegate {
        let model: ContentViewModel
        var tracker = ContentRequestTracker()
        private var loadingTask: Task<Void, Never>?

        init(model: ContentViewModel) { self.model = model }

        func load(_ contentView: WKWebView, attempt: Int) {
            guard tracker.shouldLoad(attempt: attempt) else { return }
            loadingTask?.cancel()
            loadingTask = Task { @MainActor [weak contentView] in
                await ContentSession.shared.prepare()
                guard !Task.isCancelled, let contentView, let destination = URL(string: model.address) else { return }
                contentView.load(RequestPolicy.fresh(URLRequest(url: destination)))
            }
        }

        func stop() { loadingTask?.cancel() }

        func webView(_ contentView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            guard navigationAction.targetFrame?.isMainFrame != false else { decisionHandler(.allow); return }
            Task { @MainActor [weak contentView] in
                guard let contentView else { decisionHandler(.cancel); return }
                let types: Set<String> = [
                    WKWebsiteDataTypeDiskCache,
                    WKWebsiteDataTypeMemoryCache,
                    WKWebsiteDataTypeOfflineWebApplicationCache,
                    WKWebsiteDataTypeFetchCache
                ]
                await withCheckedContinuation { continuation in
                    contentView.configuration.websiteDataStore.removeData(ofTypes: types, modifiedSince: .distantPast) {
                        continuation.resume()
                    }
                }
                decisionHandler(.allow)
            }
        }

        func webView(_ contentView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) { model.begin() }

        func webView(_ contentView: WKWebView, didFinish navigation: WKNavigation!) {
            model.complete(address: contentView.url?.absoluteString)
            Task { await ContentSession.shared.capture() }
        }

        func webView(_ contentView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) { report(error) }

        func webView(_ contentView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) { report(error) }

        func webViewWebContentProcessDidTerminate(_ contentView: WKWebView) { model.fail() }

        func webView(_ contentView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
            if navigationAction.targetFrame == nil {
                contentView.load(RequestPolicy.fresh(navigationAction.request))
            }
            return nil
        }

        private func report(_ error: Error) {
            let failure = error as NSError
            model.fail(cancelled: failure.domain == NSURLErrorDomain && failure.code == NSURLErrorCancelled)
        }
    }
}

final class ContentPageController: UIHostingController<ContentScreen> {
    let model: ContentViewModel
    private(set) var hasAppeared = false
    private let onAppearance: () -> Void

    init(model: ContentViewModel, onAppearance: @escaping () -> Void, openGame: @escaping () -> Void) {
        self.model = model
        self.onAppearance = onAppearance
        super.init(rootView: ContentScreen(model: model, openGame: openGame))
        if #available(iOS 16.4, *) { safeAreaRegions = .keyboard }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError() }

    override var prefersStatusBarHidden: Bool { true }
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask { .allButUpsideDown }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        hasAppeared = true
        onAppearance()
    }
}

struct StartupLoadingView: View {
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            ReservedRegionContent {
                ProgressView().progressViewStyle(.circular).tint(.white).frame(maxWidth: .infinity, maxHeight: .infinity).accessibilityLabel("Loading")
            }
        }
    }
}

final class StartupLoadingController: UIHostingController<StartupLoadingView> {
    init() { super.init(rootView: StartupLoadingView()) }
    required init?(coder: NSCoder) { super.init(coder: coder, rootView: StartupLoadingView()) }
    override var prefersStatusBarHidden: Bool { true }
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask { .allButUpsideDown }
}
