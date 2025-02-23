
import Foundation

enum DiffListChangeType {
    case singleRevison
    case compareRevision
}

final class DiffListChangeViewModel: DiffListGroupViewModel {
    
    let type: DiffListChangeType
    let heading: String
    private(set) var headingAttributedString: NSAttributedString
    let items: [DiffListChangeItemViewModel]
    var theme: Theme {
        didSet {
            borderColor = DiffListChangeViewModel.calculateBorderColor(type: type, theme: theme)
            let headingColor = DiffListChangeViewModel.calculateHeadingColor(type: type, theme: theme)
            headingAttributedString = DiffListChangeViewModel.calculateHeadingAttributedString(headingColor: headingColor, text: heading, traitCollection: traitCollection)
            
            for item in items {
                item.theme = theme
            }
        }
    }
    var traitCollection: UITraitCollection {
        didSet {
            for item in items {
                item.traitCollection = traitCollection
            }
            
            innerPadding = DiffListChangeViewModel.calculateInnerPadding(traitCollection: traitCollection)
            let headingColor = DiffListChangeViewModel.calculateHeadingColor(type: type, theme: theme)
            headingAttributedString = DiffListChangeViewModel.calculateHeadingAttributedString(headingColor: headingColor, text: heading, traitCollection: traitCollection)
        }
    }
    
    private var availableWidth: CGFloat {
        return width - innerPadding.leading - innerPadding.trailing - stackViewPadding.leading - stackViewPadding.trailing
    }
    
    private var _width: CGFloat
    var width: CGFloat {
        get {
            return _width
        }
        set {
            _width = newValue
            height = DiffListChangeViewModel.calculateHeight(items: items, availableWidth: availableWidth, innerPadding: innerPadding, headingAttributedString: headingAttributedString, headingPadding: headingPadding, stackViewPadding: stackViewPadding)
        }
    }
    
    private(set) var borderColor: UIColor
    private(set) var height: CGFloat = 0
    private(set) var innerPadding: NSDirectionalEdgeInsets
    private(set) var headingPadding: NSDirectionalEdgeInsets
    private(set) var stackViewPadding: NSDirectionalEdgeInsets
    
    let innerViewClipsToBounds: Bool
    
    init(type: DiffListChangeType, diffItems: [DiffItem], theme: Theme, width: CGFloat, traitCollection: UITraitCollection, groupedMoveIndexes: [String: Int], moveDistances: [String: MoveDistance], sectionInfo: [SectionInfo]?, semanticContentAttribute: UISemanticContentAttribute) {
        
        self.type = type
        self.theme = theme
        self._width = width
        self.traitCollection = traitCollection
        self.innerViewClipsToBounds = type == .compareRevision
        
        switch type {
        case .compareRevision:
            self.heading = DiffListChangeViewModel.calculateHeadingsFromLineNumbers(diffItems: diffItems)
        case .singleRevison:
            if let sectionInfo = sectionInfo, !sectionInfo.isEmpty {
                self.heading = DiffListChangeViewModel.calculateHeadingsFromSectionInfo(diffItems: diffItems, sectionInfo: sectionInfo)
            } else {
                self.heading = DiffListChangeViewModel.calculateHeadingsFromLineNumbers(diffItems: diffItems)
            }
            
        }
        
        var itemViewModels: [DiffListChangeItemViewModel] = []
        for (index, diffItem) in diffItems.enumerated() {
            
            //passing in next middle item to avoid double-space calculations for moved items
            let nextItem: DiffItem? = diffItems[safeIndex: index + 1]
            let changeItemViewModel = DiffListChangeItemViewModel(item: diffItem, traitCollection: traitCollection, theme: theme, type: type, diffItemType: diffItem.type, groupedMoveIndexes: groupedMoveIndexes, moveDistances: moveDistances, nextMiddleItem: nextItem, semanticContentAttribute: semanticContentAttribute)
            itemViewModels.append(changeItemViewModel)
        }
        
        self.items = itemViewModels
        
        borderColor = DiffListChangeViewModel.calculateBorderColor(type: type, theme: theme)
        innerPadding = DiffListChangeViewModel.calculateInnerPadding(traitCollection: traitCollection)
        headingPadding = DiffListChangeViewModel.calculateHeadingPadding(type: type)
        
        let headingColor = DiffListChangeViewModel.calculateHeadingColor(type: type, theme: theme)
        headingAttributedString = DiffListChangeViewModel.calculateHeadingAttributedString(headingColor: headingColor, text: heading, traitCollection: traitCollection)
        stackViewPadding = DiffListChangeViewModel.calculateStackViewPadding(type: type, items: items)
        
        height = DiffListChangeViewModel.calculateHeight(items: items, availableWidth: availableWidth, innerPadding: innerPadding, headingAttributedString: headingAttributedString, headingPadding: headingPadding, stackViewPadding: stackViewPadding)
    }
    
    private static func calculateHeadingsFromSectionInfo(diffItems: [DiffItem], sectionInfo: [SectionInfo]) -> String {
  
        for item in diffItems {
            if let sectionInfoIndex = item.sectionInfoIndex,
                let sectionInfo = sectionInfo[safeIndex: sectionInfoIndex] {
                return sectionInfo.title
            }
        }
        
        return "Unknown Section" //tonitodo: need business logic for this situation (intro change, delete line, move source, anything that doesn't have a section in to version)
    }
    
    private static func calculateHeadingsFromLineNumbers(diffItems: [DiffItem]) -> String {

        let lineNumbers = diffItems.compactMap { ($0.type != .deleteLine && $0.type != .moveSource) ? $0.lineNumber : nil }
        
        if let firstItemLineNumber = lineNumbers.first {
            
            let lastItemLineNumber = lineNumbers.last
            
            if diffItems.count == 1 || lastItemLineNumber == nil {
               return String.localizedStringWithFormat(CommonStrings.diffSingleLineFormat, firstItemLineNumber)
            } else if let lastItemLineNumber = lastItemLineNumber {
                return String.localizedStringWithFormat(CommonStrings.diffMultiLineFormat, firstItemLineNumber, lastItemLineNumber)
            } else {
                return ""
            }
            
        } else {
            return "" //tonitodo: optional would be better
        }
    }
    
    private static func calculateBorderColor(type: DiffListChangeType, theme: Theme) -> UIColor {
        switch type {
        case .compareRevision:
            return theme.colors.diffCompareAccent
        case .singleRevison:
            return theme.colors.paperBackground
        }
    }
    
    private static func calculateHeadingColor(type: DiffListChangeType, theme: Theme) -> UIColor {
        switch type {
        case .compareRevision:
            return theme.colors.diffCompareChangeHeading
        case .singleRevison:
            return theme.colors.secondaryText
        }
    }
    
    private static func calculateStackViewPadding(type: DiffListChangeType, items: [DiffListChangeItemViewModel]) -> NSDirectionalEdgeInsets {
        switch type {
        case .compareRevision:
            
            var top: CGFloat = 10
            var bottom: CGFloat = 10
            if let firstItemType = items.first?.diffItemType,
                let lastItemType = items.last?.diffItemType {
                
                if firstItemType == .moveDestination || firstItemType == .moveSource {
                    top = 0
                }
                
                if lastItemType == .moveDestination || lastItemType == .moveSource {
                    bottom = 0
                }
            }
            
            return NSDirectionalEdgeInsets(top: top, leading: 0, bottom: bottom, trailing: 0)
        case .singleRevison:
            return NSDirectionalEdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0)
        }
    }
    
    private static func calculateHeadingPadding(type: DiffListChangeType) -> NSDirectionalEdgeInsets {
        switch type {
        case .compareRevision:
            return NSDirectionalEdgeInsets(top: 10, leading: 7, bottom: 10, trailing: 7)
        case .singleRevison:
            return NSDirectionalEdgeInsets(top: 5, leading: 0, bottom: 10, trailing: 0)
        }
    }
    
    private static func calculateHeadingAttributedString(headingColor: UIColor, text: String, traitCollection: UITraitCollection) -> NSAttributedString {
        
        let font = UIFont.wmf_font(DynamicTextStyle.boldFootnote, compatibleWithTraitCollection: traitCollection)
        let attributes: [NSAttributedString.Key: Any] = [
            NSAttributedString.Key.font: font,
            NSAttributedString.Key.foregroundColor: headingColor
            ]
        return NSAttributedString(string: text, attributes: attributes)
    }
    
    private static func calculateHeight(items: [DiffListChangeItemViewModel], availableWidth: CGFloat, innerPadding: NSDirectionalEdgeInsets, headingAttributedString: NSAttributedString, headingPadding: NSDirectionalEdgeInsets, stackViewPadding: NSDirectionalEdgeInsets) -> CGFloat {

        var height: CGFloat = 0
        
        for item in items {
            let newHeight = ceil(item.textAttributedString.boundingRect(with: CGSize(width: availableWidth - item.textPadding.leading - item.textPadding.trailing, height: CGFloat.infinity), options: [.usesLineFragmentOrigin], context: nil).height)
            height += newHeight
            height += item.textPadding.top
            height += item.textPadding.bottom
        }
        
        //add heading height
        height += headingPadding.top
        height += headingPadding.bottom
        height += ceil(headingAttributedString.boundingRect(with: CGSize(width: availableWidth, height: CGFloat.infinity), options: [.usesLineFragmentOrigin], context: nil).height)
        
        height += innerPadding.top
        height += innerPadding.bottom
        height += stackViewPadding.top
        height += stackViewPadding.bottom
        
        return height
    }
    
    private static func calculateInnerPadding(traitCollection: UITraitCollection) -> NSDirectionalEdgeInsets {
        switch (traitCollection.horizontalSizeClass, traitCollection.verticalSizeClass) {
        case (.regular, .regular):
            return NSDirectionalEdgeInsets(top: 0, leading: 50, bottom: 0, trailing: 50)
        default:
            return NSDirectionalEdgeInsets(top: 0, leading: 15, bottom: 0, trailing: 15)
        }
    }
    
    func updateSize(width: CGFloat, traitCollection: UITraitCollection) {
        _width = width
        self.traitCollection = traitCollection
        
        height = DiffListChangeViewModel.calculateHeight(items: items, availableWidth: availableWidth, innerPadding: innerPadding, headingAttributedString: headingAttributedString, headingPadding: headingPadding, stackViewPadding: stackViewPadding)
    }
}
