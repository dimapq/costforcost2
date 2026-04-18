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
                }

                // Таблица материалов
                TableView {
                    id: materialTable
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    model: materialModel
                    clip: true
                    columnWidthProvider: function(column) {
                        if (column === 0) return 50
                        if (column === 1) return 300
                        if (column === 2) return 100
                        if (column === 3) return 120
                        return 120
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

            // Диалог добавления вручную
            Dialog {
                id: manualAddDialog
                title: "Добавить материал вручную"
                standardButtons: Dialog.Ok | Dialog.Cancel
                width: 400
                height: 300
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
                }
                onAccepted: {
                    if (matName.text && matPrice.text && matQty.text) {
                        backend.addMaterial(matName.text, matUnit.text, parseFloat(matPrice.text), parseFloat(matQty.text))
                        materialModel.refresh()
                        matName.clear()
                        matUnit.text = "шт"
                        matPrice.clear()
                        matQty.clear()
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
                        newQty.clear()
                        reason.clear()
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