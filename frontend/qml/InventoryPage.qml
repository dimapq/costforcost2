import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import TableModels 1.0

Page {
    title: "Склад и инструменты"

    // Модели объявлены один раз в корне страницы
    MaterialTableModel { id: materialModel }
    ToolsTableModel { id: toolsModel }

    TabBar {
        id: bar
        width: parent.width
        TabButton { text: "Материалы" }
        TabButton { text: "Инструменты" }
    }

    StackLayout {
        id: stack
        anchors.top: bar.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        currentIndex: bar.currentIndex

        // ================= ВКЛАДКА МАТЕРИАЛЫ =================
        Item {
            id: materialsTab
            property int selectedMaterialRow: -1
            property int selectedMaterialId: -1
            property string selectedMaterialName: ""
            property real selectedMaterialQty: 0

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 10
                spacing: 10

                // Панель инструментов
                RowLayout {
                    Layout.fillWidth: true
                    TextField {
                        id: materialSearchField
                        Layout.fillWidth: true
                        placeholderText: "Поиск по названию..."
                    }
                    Button {
                        text: "Обновить"
                        onClicked: materialModel.refresh()
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    Button {
                        text: "Добавить вручную"
                        onClicked: manualAddDialog.open()
                    }
                    Button {
                        text: "Парсинг по ссылке"
                        onClicked: parseDialog.open()
                    }
                    Button {
                        text: "Инвентаризация"
                        onClicked: inventoryDialog.open()
                    }
                    Item { Layout.fillWidth: true }
                    Button {
                        text: "Изменить количество"
                        enabled: materialsTab.selectedMaterialId > 0
                        highlighted: materialsTab.selectedMaterialId > 0
                        onClicked: {
                            editQtyField.text = materialsTab.selectedMaterialQty.toFixed(2)
                            editReasonField.clear()
                            editQtyDialog.open()
                        }
                    }
                    Button {
                        text: "Удалить со склада"
                        enabled: materialsTab.selectedMaterialId > 0
                        onClicked: {
                            deleteReasonField.clear()
                            deleteMaterialDialog.open()
                        }
                    }
                }

                // Таблица материалов
                Rectangle {
                    Layout.fillWidth: true
                    height: 34
                    color: "#e8e8e8"
                    border.color: "#ccc"
                    Row {
                        anchors.fill: parent
                        spacing: 0
                        Repeater {
                            model: ["ID", "Название", "Остаток", "Цена за ед.", "Сумма", "Откуда взят", "Примечание"]
                            Rectangle {
                                width: index === 0 ? 50 : index === 1 ? 220 : index === 2 ? 90 : index === 3 ? 110 : index === 4 ? 110 : index === 5 ? 220 : 260
                                height: 34
                                color: "transparent"
                                Text {
                                    anchors.centerIn: parent
                                    text: modelData
                                    font.pixelSize: 13
                                    font.bold: true
                                }
                            }
                        }
                    }
                }
                TableView {
                    id: materialTable
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    model: materialModel
                    clip: true
                    columnWidthProvider: function(column) {
                        if (column === 0) return 50
                        if (column === 1) return 220
                        if (column === 2) return 90
                        if (column === 3) return 110
                        if (column === 4) return 110
                        if (column === 5) return 220
                        return 260
                    }
                    delegate: Rectangle {
                        implicitHeight: 34
                        border.color: "#ddd"
                        color: materialsTab.selectedMaterialRow === row ? "#b3d9ff" : (row % 2 ? "#f9f9f9" : "white")
                        Text {
                            anchors.fill: parent
                            anchors.margins: 6
                            text: display
                            font.pixelSize: 14
                            verticalAlignment: Text.AlignVCenter
                            elide: Text.ElideRight
                        }
                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                materialsTab.selectedMaterialRow = row
                                var item = materialModel.get(row)
                                materialsTab.selectedMaterialId = item.id || -1
                                materialsTab.selectedMaterialName = item.name || ""
                                materialsTab.selectedMaterialQty = item.quantity || 0
                            }
                        }
                    }
                }
            }

            // Диалог добавления вручную
            Dialog {
                id: manualAddDialog
                title: "Добавить материал вручную"
                standardButtons: Dialog.Ok | Dialog.Cancel
                width: 460
                height: 420
                ColumnLayout {
                    anchors.fill: parent
                    spacing: 10
                    Label { text: "Название:" }
                    TextField { id: matName; Layout.fillWidth: true }
                    Label { text: "Единица измерения:" }
                    TextField { id: matUnit; Layout.fillWidth: true; text: "шт" }
                    Label { text: "Цена за единицу (руб):" }
                    TextField { id: matPrice; Layout.fillWidth: true; validator: DoubleValidator { bottom: 0.01 } }
                    Label { text: "Количество:" }
                    TextField { id: matQty; Layout.fillWidth: true; validator: DoubleValidator { bottom: 0.01 } }
                    Label { text: "Откуда взят:" }
                    TextField { id: matSource; Layout.fillWidth: true; placeholderText: "Поставщик, сайт или ссылка" }
                    Label { text: "Примечание:" }
                    TextField { id: matNote; Layout.fillWidth: true; placeholderText: "Дополнительная информация" }
                }
                onAccepted: {
                    if (matName.text && matPrice.text && matQty.text) {
                        backend.addMaterial(
                            matName.text,
                            matUnit.text,
                            parseFloat(matPrice.text),
                            parseFloat(matQty.text),
                            matSource.text,
                            matNote.text
                        )
                        materialModel.refresh()
                        matName.clear()
                        matUnit.text = "шт"
                        matPrice.clear()
                        matQty.clear()
                        matSource.clear()
                        matNote.clear()
                    }
                }
            }

            // Диалог парсинга по ссылке
            Dialog {
                id: parseDialog
                title: "Быстрое добавление по ссылке"
                standardButtons: Dialog.Ok | Dialog.Cancel
                width: 500
                height: 200
                ColumnLayout {
                    anchors.fill: parent
                    spacing: 10
                    Label { text: "Вставьте ссылку на товар:" }
                    TextField { id: urlInput; Layout.fillWidth: true }
                }
                onAccepted: {
                    if (urlInput.text) {
                        backend.parseAndAddMaterial(urlInput.text)
                        materialModel.refresh()
                        urlInput.clear()
                    }
                }
            }

            // Диалог инвентаризации
            Dialog {
                id: inventoryDialog
                title: "Корректировка остатка"
                standardButtons: Dialog.Ok | Dialog.Cancel
                width: 400
                height: 300
                ColumnLayout {
                    anchors.fill: parent
                    spacing: 10
                    Label { text: "Выберите материал:" }
                    ComboBox {
                        id: materialCombo
                        Layout.fillWidth: true
                        model: backend.getMaterialsList()
                        textRole: "name"
                        valueRole: "id"
                    }
                    Label { text: "Новый остаток:" }
                    TextField { id: newQty; Layout.fillWidth: true; validator: DoubleValidator { bottom: 0 } }
                    Label { text: "Причина:" }
                    TextField { id: reason; Layout.fillWidth: true }
                }
                onAccepted: {
                    if (materialCombo.currentValue && newQty.text) {
                        backend.adjustInventory(materialCombo.currentValue, parseFloat(newQty.text), reason.text)
                        materialModel.refresh()
                        materialsTab.selectedMaterialRow = -1
                        materialsTab.selectedMaterialId = -1
                        materialsTab.selectedMaterialName = ""
                        materialsTab.selectedMaterialQty = 0
                        newQty.clear()
                        reason.clear()
                    }
                }
            }

            Dialog {
                id: editQtyDialog
                title: "Изменить количество"
                standardButtons: Dialog.Ok | Dialog.Cancel
                width: 420
                height: 260

                ColumnLayout {
                    anchors.fill: parent
                    spacing: 10
                    Label { text: "Материал: " + materialsTab.selectedMaterialName }
                    Label { text: "Текущий остаток: " + materialsTab.selectedMaterialQty.toFixed(2) }
                    Label { text: "Новый остаток:" }
                    TextField {
                        id: editQtyField
                        Layout.fillWidth: true
                        validator: DoubleValidator { bottom: 0 }
                    }
                    Label { text: "Причина изменения:" }
                    TextField {
                        id: editReasonField
                        Layout.fillWidth: true
                        placeholderText: "Например: пересчёт остатков"
                    }
                }

                onAccepted: {
                    if (materialsTab.selectedMaterialId > 0 && editQtyField.text) {
                        backend.adjustInventory(
                            materialsTab.selectedMaterialId,
                            parseFloat(editQtyField.text),
                            editReasonField.text
                        )
                        materialModel.refresh()
                        materialsTab.selectedMaterialRow = -1
                        materialsTab.selectedMaterialId = -1
                        materialsTab.selectedMaterialName = ""
                        materialsTab.selectedMaterialQty = 0
                        editQtyField.clear()
                        editReasonField.clear()
                    }
                }
            }

            Dialog {
                id: deleteMaterialDialog
                title: "Удалить материал со склада"
                standardButtons: Dialog.Yes | Dialog.No
                width: 420
                height: 220

                ColumnLayout {
                    anchors.fill: parent
                    spacing: 10
                    Label {
                        Layout.fillWidth: true
                        wrapMode: Text.WordWrap
                        text: "Удалить со склада материал '" + materialsTab.selectedMaterialName + "'?\nОстаток будет установлен в 0."
                    }
                    Label { text: "Причина (необязательно):" }
                    TextField {
                        id: deleteReasonField
                        Layout.fillWidth: true
                        placeholderText: "Например: списание"
                    }
                }

                onAccepted: {
                    if (materialsTab.selectedMaterialId > 0) {
                        backend.adjustInventory(materialsTab.selectedMaterialId, 0, deleteReasonField.text)
                        materialModel.refresh()
                        materialsTab.selectedMaterialRow = -1
                        materialsTab.selectedMaterialId = -1
                        materialsTab.selectedMaterialName = ""
                        materialsTab.selectedMaterialQty = 0
                        deleteReasonField.clear()
                    }
                }
            }
        }

        // ================= ВКЛАДКА ИНСТРУМЕНТЫ =================
        Item {
            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 10
                spacing: 10

                // Панель инструментов
                RowLayout {
                    Layout.fillWidth: true
                    TextField {
                        id: toolSearchField
                        Layout.fillWidth: true
                        placeholderText: "Поиск по названию..."
                    }
                    Button {
                        text: "Обновить"
                        onClicked: toolsModel.refresh()
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    Button {
                        text: "Добавить инструмент"
                        onClicked: addToolDialog.open()
                    }
                    Button {
                        text: "Списать"
                        onClicked: writeOffDialog.open()
                    }
                    Button {
                        text: "Начислить амортизацию"
                        onClicked: depreciateDialog.open()
                    }
                }

                // Таблица инструментов
                TableView {
                    id: toolsTable
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    model: toolsModel
                    clip: true
                    columnWidthProvider: function(column) {
                        if (column === 0) return 50
                        if (column === 1) return 250
                        if (column === 2) return 100
                        if (column === 3) return 120
                        return 100
                    }
                    delegate: Rectangle {
                        implicitHeight: 30
                        border.color: "#ddd"
                        color: row % 2 ? "#f9f9f9" : "white"
                        Text {
                            anchors.centerIn: parent
                            text: display
                            font.pixelSize: 14
                        }
                    }
                }
            }

            // Диалог добавления инструмента
            Dialog {
                id: addToolDialog
                title: "Добавить инструмент"
                standardButtons: Dialog.Ok | Dialog.Cancel
                width: 400
                height: 350
                ColumnLayout {
                    anchors.fill: parent
                    spacing: 10
                    Label { text: "Название:" }
                    TextField { id: toolName; Layout.fillWidth: true }
                    Label { text: "Инвентарный номер:" }
                    TextField { id: invNum; Layout.fillWidth: true }
                    Label { text: "Стоимость покупки:" }
                    TextField { id: toolCost; Layout.fillWidth: true; validator: DoubleValidator { bottom: 0.01 } }
                    Label { text: "Срок службы (месяцев, необязательно):" }
                    TextField { id: toolLife; Layout.fillWidth: true; validator: IntValidator { bottom: 1 } }
                    Label { text: "Примечание:" }
                    TextField { id: toolNote; Layout.fillWidth: true }
                }
                onAccepted: {
                    if (toolName.text && toolCost.text) {
                        backend.addTool(toolName.text, invNum.text, parseFloat(toolCost.text), toolLife.text ? parseInt(toolLife.text) : 0, toolNote.text)
                        toolsModel.refresh()
                        toolName.clear()
                        invNum.clear()
                        toolCost.clear()
                        toolLife.clear()
                        toolNote.clear()
                    }
                }
            }

            // Диалог списания
            Dialog {
                id: writeOffDialog
                title: "Списать инструмент"
                standardButtons: Dialog.Ok | Dialog.Cancel
                width: 400
                height: 250
                ColumnLayout {
                    anchors.fill: parent
                    spacing: 10
                    Label { text: "Выберите инструмент:" }
                    ComboBox {
                        id: toolComboWriteOff
                        Layout.fillWidth: true
                        model: backend.getToolsList()
                        textRole: "name"
                        valueRole: "id"
                    }
                    Label { text: "Причина списания:" }
                    TextField { id: woReason; Layout.fillWidth: true }
                }
                onAccepted: {
                    if (toolComboWriteOff.currentValue) {
                        backend.writeOffTool(toolComboWriteOff.currentValue, woReason.text)
                        toolsModel.refresh()
                        woReason.clear()
                    }
                }
            }

            // Диалог начисления амортизации
            Dialog {
                id: depreciateDialog
                title: "Начислить амортизацию"
                standardButtons: Dialog.Ok | Dialog.Cancel
                width: 400
                height: 250
                ColumnLayout {
                    anchors.fill: parent
                    spacing: 10
                    Label { text: "Выберите инструмент:" }
                    ComboBox {
                        id: toolComboDepr
                        Layout.fillWidth: true
                        model: backend.getToolsList()
                        textRole: "name"
                        valueRole: "id"
                    }
                    Label { text: "Сумма (руб):" }
                    TextField { id: deprAmount; Layout.fillWidth: true; validator: DoubleValidator { bottom: 0.01 } }
                }
                onAccepted: {
                    if (toolComboDepr.currentValue && deprAmount.text) {
                        backend.depreciateTool(toolComboDepr.currentValue, parseFloat(deprAmount.text))
                        toolsModel.refresh()
                        deprAmount.clear()
                    }
                }
            }
        }
    }

    // Обновление обеих моделей при загрузке страницы
    Component.onCompleted: {
        materialModel.refresh()
        toolsModel.refresh()
    }
}
