//
//  NavigatorView.swift
//  APIZenMac
//
//  Created by Jaseem V V on 10/12/25.
//

import SwiftUI
import CoreData
import AZData
import AZCommon

// Ignore tiny delta changes to avoid per-frame churn.
private let offsetEpsilon: CGFloat = 0.5

/// Left pane of the main window. Displays projects list for the selected workspace. Displays requests for if a project is selected.
struct NavigatorView: View {
    let workspaceId: String
    private let db: CoreDataService = CoreDataService.shared

    @Environment(\.managedObjectContext) private var moc

    @State private var projects: [EProject] = []
    @State private var requests: [ERequest] = []

    @State private var pane: Pane = .project
    @State private var selectedProject: EProject? = nil
    @State private var isPushing: Bool = true

    enum Pane {
        case project
        case request
    }

    var onSelectRequest: ((ERequest) -> Void)?

    var body: some View {
        VStack(spacing: 0) {
            header
                .padding(.horizontal, 8)
                .frame(height: 44)
                .background(.ultraThinMaterial)
                .overlay(Divider(), alignment: .bottom)

            ZStack {
                if pane == .project {
                    ProjectsListView(projects: projects, onSelect: { proj in
                        // prepare data, then push
                        selectedProject = proj
                        loadRequests(for: proj)
                        isPushing = true
                        withAnimation {
                            pane = .request
                        }
                    }, selectedProject: $selectedProject)
                    .transition(listTransition)
                }

                if pane == .request, let sel = selectedProject {
                    RequestsListView(project: sel, requests: requests, onSelect: { req in
                        onSelectRequest?(req)
                    })
                    .transition(listTransition)
                }
            }
            .animation(.default, value: pane)  // When pane changes, animate with the transition associated with the view.
            .animation(.default, value: isPushing)  // When isPushing changes, animate with the transition associated with the view.
        }
        .onAppear {
            loadProjects()
        }
    }

    private var listTransition: AnyTransition {
        if isPushing {
            // When pushing, projects is removed to the left (and requests will insert from right)
            // List moves from right to left.
            return .asymmetric(
                insertion: .move(edge: .trailing).combined(with: .opacity),
                removal:   .move(edge: .leading).combined(with: .opacity)
            )
        } else {
            // When popping, projects is inserted from the left.
            // List moves from left to right. Back button press animation.
            return .asymmetric(
                insertion: .move(edge: .leading).combined(with: .opacity),
                removal:   .move(edge: .trailing).combined(with: .opacity)
            )
        }
    }
    
    // MARK: - Header
    /// List header which shows Projects or project name with a back button.
    private var header: some View {
        HStack {
            if pane == .request {
                Button {
                    isPushing = false
                    withAnimation {
                        pane = .project
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "chevron.left")
                        Text(headerTitle)
                    }
                    .padding(.horizontal, 4)  // Gives enough room for click by expanding the button area. It's not visible unless we apply a border to it.
                    .padding(.vertical, 6)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .help("Back")
//                .overlay(
//                    RoundedRectangle(cornerRadius: 4)
//                        .stroke(Color.red.opacity(0.5), style: StrokeStyle(lineWidth: 1, dash: [4]))
//                )
            } else {
                Text(headerTitle)
                    .font(.headline)
                    .lineLimit(1)
                    .padding(.leading, 4)
            }
            
            Spacer()
        }
    }

    private var headerTitle: String {
        switch pane {
        case .project:
            return "Projects"
        case .request:
            if let p = selectedProject {
                return p.getName()
            }
            return "Requests"
        }
    }

    // MARK: - Data loading
    private func loadProjects() {  // TODO: use FRC. This can be moved to ProjectsListView with workspace id.
        projects = self.db.getProjects(wsId: workspaceId, ctx: moc)
    }

    private func loadRequests(for project: EProject) {
        requests = db.getRequests(projectId: project.getId(), ctx: moc)
    }
}

/// PreferenceKey to pass each row's top position up the view tree.
///
/// RowTopPreference is a PreferenceKey implementation that we can use together with GeometryReader to report per-row geometry (for example, each row’s minY) up the SwiftUI view tree so a parent view can decide which row is at the top.
///
/// PreferenceKey is a SwiftUI primitive to pass values up the view tree from children to ancestors. Children write into a preference (via .preference(...)) and ancestors read them with .onPreferenceChange or .background(GeometryReader...) — it’s the opposite direction of normal @State/@Binding.
struct RowTopPreference: PreferenceKey {
    typealias Value = [NSManagedObjectID: CGFloat]
    static var defaultValue: Value = [:]

    static func reduce(value: inout Value, nextValue: () -> Value) {
        value.merge(nextValue(), uniquingKeysWith: { $1 })
    }
}

/// We use a PreferenceKey because SwiftUI’s layout system only provides a reliable, well-defined way for child views to send geometry information up to their ancestors. Children (like the GeometryReader inside the list) shouldn’t directly mutate parent state during layout — doing that leads to reentrancy bugs, multiple updates per frame, and broken layout.
///
/// PreferenceKey is the safe, built-in mechanism for “child → parent” communication during layout.
///
/// PreferenceKey makes this safe: children publish values while layout is happening; SwiftUI collects/merges them and then delivers a single aggregated value to the parent (via .onPreferenceChange) at the right time.
///
/// It allows:
///   - many children to send values,
///   - the ancestor to receive a single merged value,
///   - the system to schedule delivery at a safe time in the render/layout cycle.
///
/// Using @State might "work" but it fires many times during a scroll and can cause multiple updates per frame. It will spam state updates and slow the UI. It will cause jitter. PreferenceKey does the same reporting but in a controlled, aggregated way.
private struct ScrollOffsetKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) { value = nextValue() }
}

/// Helper NSViewRepresentable to set NSScrollView's content offset
/// MacScrollViewOffsetSetter is an NSViewRepresentable helper whose job is to find the underlying AppKit NSScrollView SwiftUI created and set its content origin (i.e. programmatically scroll to a pixel offset) and tweak properties (elasticity, insets).
/// Use it when you need pixel-perfect programmatic scrolling or need to fix AppKit behaviour that SwiftUI doesn’t expose.
/// NSViewRepresentable lets us drop a tiny NSView inside the hierarchy and traverse the superview chain to find the NSScrollView SwiftUI created. Returns a zero sized NSView.
private struct MacScrollViewOffsetSetter: NSViewRepresentable {
    let offsetToSet: CGFloat?

    func makeNSView(context: Context) -> NSView { NSView() }

    func updateNSView(_ nsView: NSView, context: Context) {
        guard let offset = offsetToSet else { return }

        DispatchQueue.main.async {
            var v: NSView? = nsView
            while let current = v {
                if let scroll = current as? NSScrollView {  // Walks up the `nsView.superview` chain until it finds an `NSScrollView`.
                    scroll.verticalScrollElasticity = .allowed  // Allow bounce at top and bottom
                    scroll.horizontalScrollElasticity = .none  // Without this, if we navigate to requests list and back to projects list, horizontal list bounce appears. We should have top and bottom boucing only for the project list.
                    scroll.contentInsets = NSEdgeInsetsZero

                    // Now set the content origin (treat offset as distance from top)
                    let newOrigin = NSPoint(x: 0, y: offset)
                    scroll.contentView.scroll(to: newOrigin)  // set the scroll origin
                    scroll.reflectScrolledClipView(scroll.contentView)
                    break
                }
                v = current.superview
            }
        }
    }
}

/**
 
 Projects list view that preserves scroll offset when navigating back from requests view.
 
 How the scroll offset is preserved in the project list and how it works.
 
 The 3 key parts are:

 1. **A tiny invisible tool that *reads* how far you’ve scrolled**
 2. **A tiny invisible tool that *sets* the scroll position when you return**
 3. **A small piece of logic that decides *when* to read and when to restore**

 That’s really all that is happening — the rest is just SwiftUI ceremony.

 ---

 ## 1. The “scroll offset reader”

 *(the GeometryReader + PreferenceKey part)*

 ### What problem does it solve?

 SwiftUI’s `ScrollView` does **not give us** the current scroll position.
 So to remember the scroll position, we need a way to **measure how far down** the user has scrolled.

 ### How it works

 * We place one tiny invisible `GeometryReader` at the **top** of the scrollable content.
 * As we scroll, the content moves up/down.
 * The `GeometryReader` reports **how far that top edge has moved** from the original starting point.
 * This value is stored in a simple variable: `savedOffset`.

 ### What is a `PreferenceKey`?

 A `PreferenceKey` is just SwiftUI’s mechanism for children to **send values upward** in the view tree.
 A `PreferenceKey` is just a mailbox.
 The `GeometryReader` writes the value, and the parent view reads it.

 ### What does RowTopPreference / ScrollOffsetKey actually do?

 It is simply a named container that says:

 > “Whenever a child view sends me a number (the scroll offset), I’ll pass it to the parent.”

 Nothing more.

 ---

 ## 2. The “scroll offset setter”

 *(the MacScrollViewOffsetSetter NSViewRepresentable)*

 ### What problem does it solve?

 SwiftUI **can’t programmatically set scroll position** on macOS.
 You cannot write:

 ```swift
 scrollView.scrollTo(y: 200)
 ```

 Because SwiftUI does not expose the underlying `NSScrollView`.

 ### How this fixer works

 * We insert a tiny invisible AppKit `NSView` inside the SwiftUI view hierarchy. Only this NSView can navigate the super view hierarchy and find the NSScrollView and ask it to scroll to the offset.
 * Once inserted, we walk up the parent hierarchy until we find the real `NSScrollView` that SwiftUI created behind the scenes.
 * When we find it, we ask it to:

 > “Scroll to this exact Y position.”

 ### Why AppKit?

 Because only AppKit (`NSScrollView`) knows how to:

 * move the scroll content (`scroll(to:)`)
 * control bounce (`verticalScrollElasticity`)
 * stop horizontal bounce (`horizontalScrollElasticity = .none`)

 SwiftUI offers **no control** here.

 So this little helper gives us the superpowers SwiftUI is missing.

 ---

 ## 3. The “restore logic”

 *(the small bit of state and timing)*

 To restore the scroll offset correctly, two things must happen:

 ### a. Save the scroll position before navigating away

 When the user scrolls, the GeometryReader reports a new “how far down” value.

 We save the latest value:

 ```swift
 savedOffset = someNewValue
 ```

 ### b. Restore the position when navigating back

 When the Project List view appears again:

 1. SwiftUI builds the view
 2. AppKit creates the NSScrollView
 3. Our offset setter finds it
 4. We tell it: “scroll to savedOffset”

 This happens only **once**, right after the view appears.

 That’s why you see the list restored exactly where you left it.

 ---
 
 ##  Summary in pure plain English

 ### When you scroll:

 An invisible sensor at the top of the list measures how far you’ve scrolled and stores the number.

 ### When you navigate away:

 Nothing special happens — you just leave the screen, but the stored number remains.

 ### When you come back:

 Another invisible tool finds the underlying macOS scroll view and says:

 > “Scroll to the point where the user previously stopped.”

 SwiftUI itself cannot do this.
 Those two tiny helpers allow us to “tap into” AppKit to make scroll restoration possible.

 */
struct ProjectsListView: View {
    let projects: [EProject]
    let onSelect: (EProject) -> Void
    @Binding var selectedProject: EProject?
    
    @State private var savedTopId: NSManagedObjectID? = nil
    @State private var topPositions: [NSManagedObjectID: CGFloat] = [:]
    @Environment(\.scenePhase) private var scenePhase
    
    /// The scroll offset
    @State private var savedOffset: CGFloat? = nil
    @State private var shouldRestore: Bool = false

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Safe top padding that doesn't affect scroll offset calculation
                Color.clear.frame(height: 12)
                // NOTE: No top padding here — avoid adding .padding() that affects top
                LazyVStack(alignment: .leading, spacing: 6) {
                    ForEach(projects) { project in
                        // List style does not show separator. This could be a distinction between projects and requests.
                        Button {
                            // allow preference system to settle then navigate
                            DispatchQueue.main.async {
                                onSelect(project)
                            }
                        } label: {
                            NameDescView(imageName: "project", name: project.getName(), desc: project.desc)
                                .padding(.vertical, 6)
                                .padding(.leading, 4)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .buttonStyle(.plain)
                        .id(project.objectID)
                    }
                }
                // horizontal padding only if you want — no top padding
                .padding(.horizontal, 8)
                // Safe bottom padding that doesn't affect scroll offset calculation
                Color.clear.frame(height: 12)
            }
            // Overlay GeometryReader at top to read offset without taking layout space - to the outside padding.
            .overlay(alignment: .top, content: {
                GeometryReader { proxy in
                    Color.clear
                        .preference(key: ScrollOffsetKey.self,
                                    value: -proxy.frame(in: .named("scroll")).minY)
                }
                .allowsHitTesting(false) // don't block clicks
            })
        }
        .coordinateSpace(.named("scroll"))
        .onPreferenceChange(ScrollOffsetKey.self) { value in
            // clamp to >= 0 if you treat offset as distance from top
            let newValue = max(0, value)
            
            // don't spam state updates for tiny changes (and avoid "multiple updates per frame")
            if let prev = savedOffset, abs(prev - newValue) < offsetEpsilon {
                return
            }

            // schedule the state write to next runloop tick to avoid same-frame multi-updates
            DispatchQueue.main.async {
                savedOffset = newValue
            }
        }
        .overlay(content: {
            Group {
                if shouldRestore, let offset = savedOffset {
                    MacScrollViewOffsetSetter(offsetToSet: offset).frame(width: 0, height: 0)
                }
            }
        })
        .onAppear {
            guard let _ = savedOffset, !shouldRestore else { return }
            DispatchQueue.main.async {
                shouldRestore = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { shouldRestore = false }
            }
        }
    }
}


// MARK: - Request List View
struct RequestsListView: View {
    let project: EProject
    let requests: [ERequest]
    let onSelect: (ERequest) -> Void

    var body: some View {
        List {
            ForEach(requests, id: \.objectID) { req in
                HStack {
                    Image(systemName: "doc.text")
                    Text(req.name ?? "No name")
                    Spacer()
                }
                .padding(.vertical, 6)
                .contentShape(Rectangle())
                .onTapGesture {
                    onSelect(req)
                }
            }
        }
        .listStyle(SidebarListStyle())
    }
}
