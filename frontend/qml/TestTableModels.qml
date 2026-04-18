import QtQuick
import TableModels 1.0

Item {
    MaterialTableModel { id: testModel }
    Component.onCompleted: console.log("TableModels works!")
}