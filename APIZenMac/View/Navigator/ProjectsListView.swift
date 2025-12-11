//
//  ProjectsListView.swift
//  APIZenMac
//
//  Created by Jaseem V V on 11/12/25.
//

import SwiftUI
import CoreData
import AZData
import AZCommon

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
    /// Selected workspace id
    let workspaceId: String
    /// We need to invoke the parent view function so that the navigator can navigate to request view on selecting a project.
    let onSelect: (EProject) -> Void
    @Binding var selectedProject: EProject?
    var searchText: String = ""
    
    @State private var projects: [EProject] = []
    @State private var dataManager: CoreDataManager<EProject>?
    @State private var sortField: ProjectSortField = .manual
    
    // Maintain scroll offset
    @State private var savedTopId: NSManagedObjectID? = nil
    @State private var topPositions: [NSManagedObjectID: CGFloat] = [:]
    
    /// The scroll offset
    @State private var savedOffset: CGFloat? = nil
    @State private var shouldRestore: Bool = false
    
    @Environment(\.managedObjectContext) private var moc
    
    // Ignore tiny delta changes in scroll offset to avoid per-frame churn.
    private let offsetEpsilon: CGFloat = 0.5
    private var sortAscending: Bool = true
    private let db = CoreDataService.shared
    private let projectsCacheName: String = "projects-cache"
    
    enum ProjectSortField: String, CaseIterable, Codable, Equatable {
        case manual
        case name
        case created
    }
    
    // Explicit init with only the required params is required because we have many properties and default init becomes internal.
    init(workspaceId: String, onSelect: @escaping (EProject) -> Void, selectedProject: Binding<EProject?>, searchText: String) {
        Log.debug("proj list view: ws id: \(workspaceId)")
        self.workspaceId = workspaceId
        self.onSelect = onSelect
        self._selectedProject = selectedProject
        self.searchText = searchText
    }

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
            /*
             Overlay GeometryReader at top to read offset without taking layout space - to the outside padding.
             
             overlay lets us put a GeometryReader on top of the scroll content so it can measure the scroll position without affecting layout.
             - It is not for drawing.
             - It is not for adding UI.
             - It is simply a way to attach an invisible measuring tool to the scrolling content.
             
             We need a place to attach a GeometryReader that:
             1. Moves together with the scroll content,
             2. Does NOT take up space,
             3. Does NOT interfere with layout,
             4. Can read its position inside the scrolling coordinate space.
             
             A normal child view always takes up space and changes the layout.
             A background view measures layout before scroll metrics are updated.
             
             But an overlay sits on top. It doesn’t push content, doesn’t shift anything, and scrolls with the content.
             
             GeometryReader gives us the position of the overlay view inside the scroll's coordinate space. Because the overlay moves exactly with the scrolling content, its minY becomes the perfect representation of the scroll offset.
             
             Example:
             
             At top of the list → minY == 0
             Scrolled down 100 px → minY == -100
             
             So we invert it: `value: -geo.frame(...).minY`
             
             Now offset = 100 means “scrolled down 100 points”.
             
             .preference(key:value:) - sends the number up to the parent safely.
             
             .allowsHitTesting(false) - So the overlay doesn’t block clicks on your list rows.
             
             */
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
        // Here we get the offset set by the child view which is the VStack. And saves it in the `savedOffset` variable.
        .onPreferenceChange(ScrollOffsetKey.self) { value in
            // Clamp to >= 0 if we treat offset as distance from top
            let newValue = max(0, value)
            
            // Don't spam state updates for tiny changes (and avoid "multiple updates per frame")
            if let prev = savedOffset, abs(prev - newValue) < offsetEpsilon {
                return
            }

            // Schedule the state write to next runloop tick to avoid same-frame multi-updates
            DispatchQueue.main.async {
                savedOffset = newValue
            }
        }
        .overlay(content: {
            Group {
                if shouldRestore, let offset = savedOffset {
                    // This view is inserted in the overlay when shouldRestore is set and has an offset. Once this view is inserted, the updateNSView lifecycle method is invoked by SwiftUI which will make the list to scroll.
                    // When shouldRestore or this condition is false, we should not add this. So if it is already added, SwiftUI removes it. This happens after a scroll where we reset the flag.
                    MacScrollViewOffsetSetter(offsetToSet: offset).frame(width: 0, height: 0)
                }
            }
        })
        .onAppear {
            self.initDataManager()
            guard let _ = savedOffset, !shouldRestore else { return }
            DispatchQueue.main.async {
                shouldRestore = true  // Scroll the list if needed on appear.
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { shouldRestore = false }  // This should have scrolled. Disable the flag.
            }
        }
        .onChange(of: workspaceId) { oldId, newId in
            if oldId != newId {
                Log.debug("proj list: workspace id changed: \(newId)")
                self.initDataManager()  // re-init data maanger with new predicate for workspaceId to update project listing
            }
        }
        .onChange(of: sortField, { _, _ in
            self.initDataManager()  // re-init data manager with new sort descriptor to update the list ordering
        })
        .onChange(of: sortAscending, { _, _ in
            self.initDataManager()  // re-init data manager with new sort descriptor to update the list ordering
        })
        .onChange(of: searchText, { _, _ in
            self.initDataManager()
        })
    }
    
    /// The query is cached. So multiple searches of the same parameters would not be that costly.
    func initDataManager() {
        Log.debug("proj list view: init data manager")
        let fr = EProject.fetchRequest()
        fr.sortDescriptors = self.getSortDescriptors()
        if searchText.isNotEmpty {
            // fr.predicate = NSPredicate(format: "(name CONTAINS[cd] %@) OR (desc CONTAINS[cd] %@)", searchText, searchText)  // c: case-insensitive; d: diacritic-insensitive
        } else {
            fr.predicate = NSPredicate(format: "workspace.id == %@ AND name != %@ AND markForDelete == %hdd", workspaceId, "", false)
        }
        fr.fetchBatchSize = 50
        if let dm = self.dataManager { dm.clearCache() }  // clear previous cache if already initialized before.
        dataManager = CoreDataManager(fetchRequest: fr, ctx: moc, cacheName: self.projectsCacheName, onChange: { projects in
            withAnimation {
                self.projects = projects
            }
        })
    }
    
    private func getSortDescriptors() -> [NSSortDescriptor] {
        let sortDescriptor: NSSortDescriptor
        switch sortField {
        case .manual:
            sortDescriptor = NSSortDescriptor(keyPath: \EProject.order, ascending: sortAscending)
        case .name:
            sortDescriptor = NSSortDescriptor(keyPath: \EProject.name, ascending: sortAscending)
        case .created:
            sortDescriptor = NSSortDescriptor(keyPath: \EProject.created, ascending: sortAscending)
        }
        return [sortDescriptor]
    }
}

// MARK: - Scroll offset helpers

/// PreferenceKey to pass each row's top position up the view tree.
///
/// RowTopPreference is a PreferenceKey implementation that we can use together with GeometryReader to report per-row geometry (for example, each row’s minY) up the SwiftUI view tree so a parent view can decide which row is at the top.
///
/// PreferenceKey is a SwiftUI primitive to pass values up the view tree from children to ancestors. Children write into a preference (via .preference(...)) and ancestors read them with .onPreferenceChange or .background(GeometryReader...) — it’s the opposite direction of normal @State/@Binding.
struct RowTopPreference: PreferenceKey {  // This should not be private. Preserving scroll offset is not working when private.
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
