import QtQuick 2.0
import Ubuntu.Components 1.3
import Ubuntu.Components.ListItems 1.3 as ListItem

Column {
    anchors {
        left: parent.left
        right: parent.right
    }
    spacing: units.gu(1)

    property string category
    property string categoryName

    objectName: "categoryGrid-" + category

    ListItem.Standard {
        id: header

        highlightWhenPressed: false
        showDivider: false
        text: categoryName
        visible: repeater.count > 0
    }

    Grid {
        property int itemWidth: units.gu(12)

        // The amount of whitespace, including column spacing
        property int space: parent.width - columns * itemWidth

        // The column spacing is 1/n of the left/right margins
        property int n: 4

        columnSpacing: space / ((2 * n) + (columns - 1))
        rowSpacing: units.gu(3)
        width: (columns * itemWidth) + columnSpacing * (columns - 1)
        anchors.horizontalCenter: parent.horizontalCenter
        columns: {
            var items = Math.floor(parent.width / itemWidth)
            var count = repeater.count
            return count < items ? count : items
        }

        Repeater {
            id: repeater

            model: pluginManager.itemModel(category)

            delegate: Loader {
                id: loader
                width: parent.itemWidth
                sourceComponent: model.item.entryComponent
                active: model.item.visible
                Connections {
                    ignoreUnknownSignals: true
                    target: loader.item
                    onClicked: {
                        var pageComponent = model.item.pageComponent
                        if (pageComponent) {
                            pageStack.push(model.item.pageComponent,
                                           { plugin: model.item, pluginManager: pluginManager })
                        }
                    }
                }
            }
        }
    }
    ListItem.ThinDivider { visible: header.visible }
}
