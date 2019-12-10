//
//  BottomDrawer.swift
//  GPS Log
//
//  Created by Stuart Rankin on 12/9/19.
//  Copyright © 2019 Stuart Rankin. All rights reserved.
//

import Foundation
import UIKit
import OfficeUIFabric

extension ViewController
{
    /// Display view settings in a bottom Fabric UI drawer.
    /// - Parameter Sender: The button that was pressed to show the settings.
    /// - Parameter FromBase: The bottom coordinate of where to start the drawer.
    func DisplayViewDrawer(_ Sender: UIButton, FromBase: CGFloat = -1)
    {
        if DrawerControls.count == 0
        {
            AddDrawerControl(Title: "Map View", Action: #selector(SetAppleMapView))
            AddDrawerControl(Title: "Table View", Action: #selector(SetTableView))
            AddDrawerControl(Title: "Session List", Action: #selector(ViewSessions))
            AddDrawerControl(Title: "Close", Action: #selector(CloseDrawer))
        }
        PresentDrawer(SourceView: Sender, PresentationOrigin: FromBase, PresentationDirection: .up,
                      ContentView: ContainerForDrawer(), ResizingBehavior: .dismissOrExpand,
                      DismissHandler: ResetBottomBar)
    }
    
    /// Reset the bottom toolbar - called everytime the drawer is dismissed.
    func ResetBottomBar()
    {
        ShowingViewView = false
        self.EnableButton(self.StartButton)
        self.EnableButton(self.MarkLocationButton)
        self.EnableButton(self.SettingsButton)
    }
    
    /// Present the drawer.
    /// - Note: If both `SourceView` and `BarButtonItem` are nil, a fatal error is generated. Either one must be specified.
    /// - Parameter SourceView: The source view. Either this or the `BarButtonItem` is required.
    /// - Parameter PresentationOrigin: The origin of where the presentation will start (eg, enlarge from). Defaults to -1 (top of
    ///                                 the screen).
    /// - Parameter PresentationDirection: Which way the drawer will grow.
    /// - Parameter PresentationStyle: The style of the drawer. Defaults to `.automatic`.
    /// - Parameter PresentationOffset: Offset value of the presentation from the `PresentationOrigin`. Defaults to 0.
    /// - Parameter PresentationBackground: Drawer background. Defaults to `.black`.
    /// - Parameter ContentController: The content controller to display in the presention. If nil, `ContentView' will be used.
    ///                                Defaults to nil.
    /// - Parameter ContentView: The view to display in the presentation. If nil, `ContentController` will be used. Defaults to nil.
    /// - Parameter ResizingBehavior: How resizing behaves. Defaults to `.none`.
    /// - Parameter Animated: Animated resizing flag. Defaults to true.
    /// - Parameter DismissHandler: Optional handler called when the drawer is dismissed. Handler takes no parameters and returns
    ///                             a `Void`. Defaults to nil.
    func PresentDrawer(SourceView: UIView? = nil, BarButtonItem: UIBarButtonItem? = nil, PresentationOrigin: CGFloat = -1,
                       PresentationDirection: MSDrawerPresentationDirection, PresentationStyle: MSDrawerPresentationStyle = .automatic,
                       PresentationOffset: CGFloat = 0, PresentationBackground: MSDrawerPresentationBackground = .black,
                       ContentController: UIViewController? = nil, ContentView: UIView? = nil,
                       ResizingBehavior: MSDrawerResizingBehavior = .none, Animated: Bool = true,
                       DismissHandler: (() -> Void)? = nil)
    {
        var Controller: MSDrawerController!
        if let Source = SourceView
        {
            Controller = MSDrawerController(sourceView: Source, sourceRect: Source.bounds, presentationOrigin: PresentationOrigin,
                                            presentationDirection: PresentationDirection)
        }
        else
            if let BarButton = BarButtonItem
            {
                Controller = MSDrawerController(barButtonItem: BarButton, presentationOrigin: PresentationOrigin,
                                                presentationDirection: PresentationDirection)
            }
            else
            {
                fatalError("Drawers require either a source view or a button bar.")
        }
        
        if let CloseHandler = DismissHandler
        {
            Controller.onDismiss = CloseHandler
        }
        Controller.presentationStyle = PresentationStyle
        Controller.presentationOffset = PresentationOffset
        Controller.presentationBackground = PresentationBackground
        Controller.resizingBehavior = ResizingBehavior
        
        if let Content = ContentView
        {
            Controller.preferredContentSize.width = 360
            Controller.contentView = Content
        }
        else
        {
            Controller.contentController = ContentController
        }
        present(Controller, animated: Animated)
    }
    
    /// Adds a button control to the drawer.
    /// - Parameter Title: Title of the button.
    /// - Action: Action to execute when the user presses the button.
    func AddDrawerControl(Title: String, Action: Selector)
    {
        let Button = CreateButton(Title: Title, Action: Action)
        DrawerControls.append(Button)
    }
    
    /// Returns a container for the drawer. For vertical-oriented containers.
    /// - Parameter CanExpand: Not currently used.
    /// - Returns: View for the drawer.
    func ContainerForDrawer(CanExpand: Bool = true) -> UIView
    {
        let Container = CreateVerticalContainer()
        for View in DrawerControls
        {
            Container.addArrangedSubview(View)
        }
        return Container
    }
    
    /// Creates a vertical container.
    /// - Returns: `UIStackView` oriented vertically.
    func CreateVerticalContainer() -> UIStackView
    {
        let Container = UIStackView(frame: .zero)
        Container.axis = .vertical
        Container.layoutMargins = UIEdgeInsets(top: 16.0, left: 16.0, bottom: 16.0, right: 16.0)
        Container.isLayoutMarginsRelativeArrangement = true
        Container.spacing = 16.0
        return Container
    }
    
    /// Create an MSButton.
    /// - Parameter Title: Text of the button.
    /// - Parameter Action: The action to execute when the user presses the button.
    /// - Returns: `MSButton` instance.
    func CreateButton(Title: String, Action: Selector) -> MSButton
    {
        let Button = MSButton()
        Button.titleLabel?.lineBreakMode = .byTruncatingTail
        Button.setTitle(Title, for: .normal)
        Button.addTarget(self, action: Action, for: .touchUpInside)
        return Button
    }
    
    // MARK: - Button action handlers
    
    /// Close the drawer.
    @objc func CloseDrawer()
    {
        dismiss(animated: true)
    }
    
    /// Display the Apple map view.
    @objc func SetAppleMapView()
    {
        HandleMapSelected()
        dismiss(animated: true)
    }
    
    /// Display the table view.
    @objc func SetTableView()
    {
        HandleTableSelected()
        dismiss(animated: true)
    }
    
    /// Show list of saved sessions.
    @objc func ViewSessions()
    {
        dismiss(animated: true)
        let Storyboard = UIStoryboard(name: "Main", bundle: nil)
        let VC = Storyboard.instantiateViewController(identifier: "SessionsNavigator") as SessionsNavigator
        VC.Main = self
        present(VC, animated: true)
    }
}

class DrawerControlDescription
{
    init(ButtonTitle: String, Action: Selector)
    {
        _ControlType = .Button
        Title = ButtonTitle
        self.Action = Action
    }
    
    init(BooleanTitle: String, Action: Selector, DefaultValue: Bool)
    {
        _ControlType = .Boolean
        DefaultBool = DefaultValue
        Title = BooleanTitle
        self.Action = Action
    }
    
    init(Titles: [String], Actions: [Selector])
    {
        _ControlType = .Multiselection
        self.Titles = Titles
        self.Actions = Actions
    }
    
    private var _Titles: [String] = []
    public var Titles: [String]
    {
        get
        {
            return _Titles
        }
        set
        {
            _Titles = newValue
        }
    }
    
    public var Title: String
    {
        get
        {
            return _Titles.first!
        }
        set
        {
            _Titles.append(newValue)
        }
    }
    
    private var _Actions: [Selector] = []
    public var Actions: [Selector]
    {
        get
        {
            return _Actions
        }
        set
        {
            _Actions = newValue
        }
    }
    
    public var Action: Selector
    {
        get
        {
            return _Actions.first!
        }
        set
        {
            _Actions.append(newValue)
        }
    }
    
    private var _ControlType: DrawerControlTypes = .Button
    public var ControlType: DrawerControlTypes
    {
        get
        {
            return _ControlType
        }
        set
        {
            _ControlType = newValue
        }
    }
    
    private var _DefaultBool: Bool = false
    public var DefaultBool: Bool
    {
        get
        {
            return _DefaultBool
        }
        set
        {
            _DefaultBool = newValue
        }
    }
}

enum DrawerControlTypes
{
    case Multiselection
    case Boolean
    case Button
}
