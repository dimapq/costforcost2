import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import TableModels 1.0

Page {
    title: "Станки"

    TabBar {
        id: bar
        width: parent.width
        TabButton { text: "В процессе" }
        TabButton { text: "Готовые" }
        TabButton { text: "Редактор моделей" }
    }

    StackLayout {
        anchors.top: bar.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        currentIndex: bar.currentIndex

        // ================= ВКЛАДКА 1: В ПРОЦЕССЕ =================
        Item {
            property int selectedInProgressId: -1

            InProgressModel { id: inProgressModel }

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 10
                spacing: 10

                RowLayout {
                    Layout.fillWidth: true
                    Button {
                        text: "Обновить"
                        onClicked: inProgressModel.refresh()
                    }
                }

                // Заголовок таблицы
                Rectangle {
                    Layout.fillWidth: true
                    height: 30
                    color: "#e8e8e8"
                    RowLayout {
                        anchors.fill: parent
                        spacing: 0
                        Repeater {
                            model: ["ID", "Модель", "Дата начала", "Примечание"]
                            Rectangle {
                                width: index === 0 ? 50 : index === 1 ? 200 : index === 2 ? 150 : 150
                                height: 30
                                border.color: "#ccc"
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
                    id: inProgressTable
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    model: inProgressModel
                    clip: true
                    columnWidthProvider: function(column) {
                        if (column === 0) return 50
                        if (column === 1) return 200
                        if (column === 2) return 150
                        return 150
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
                    onCurrentRowChanged: {
                        if (currentRow >= 0) {
                            var item = inProgressModel.get(currentRow)
                            selectedInProgressId = item.id
                        }
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    Button {
                        text: "Завершить производство"
                        enabled: selectedInProgressId > 0
                        onClicked: completeDialog.open()
                    }
                }
            }

            // ДИАЛОГ ВНУТРИ ITEM
            Dialog {
                id: completeDialog
                title: "Завершение производства"
                standardButtons: Dialog.Ok | Dialog.Cancel
                width: 400
                height: 200
                ColumnLayout {
                    anchors.fill: parent
                    Label { text: "Инвентарный номер (необязательно):" }
                    TextField { id: invNumberField; Layout.fillWidth: true }
                }
                onAccepted: {
                    backend.completeMachine(selectedInProgressId, invNumberField.text)
                    inProgressModel.refresh()
                    invNumberField.clear()
                }
            }

            Component.onCompleted: inProgressModel.refresh()
        }

        // ================= ВКЛАДКА 2: ГОТОВЫЕ =================
        Item {
            property int selectedFinishedId: -1

            FinishedGoodsModel { id: finishedModel }

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 10
                spacing: 10

                RowLayout {
                    Layout.fillWidth: true
                    TextField {
                        id: finishedSearchField
                        Layout.fillWidth: true
                        placeholderText: "Поиск..."
                        onTextChanged: finishedModel.setFilter(text)
                    }
                    Button {
                        text: "Обновить"
                        onClicked: {
                            finishedSearchField.clear()
                            finishedModel.setFilter("")
                            finishedModel.refresh()
                        }
                    }
                }

                // Заголовок таблицы
                Rectangle {
                    Layout.fillWidth: true
                    height: 30
                    color: "#e8e8e8"
                    RowLayout {
                        anchors.fill: parent
                        spacing: 0
                        Repeater {
                            model: ["ID", "Модель", "Инв. №", "Дата", "Покупатель", "Цена"]
                            Rectangle {
                                width: index === 0 ? 50 : index === 1 ? 150 : 100
                                height: 30
                                border.color: "#ccc"
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
                    id: finishedTable
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    model: finishedModel
                    clip: true
                    columnWidthProvider: function(column) {
                        if (column === 0) return 50
                        if (column === 1) return 150
                        if (column === 2) return 100
                        if (column === 3) return 100
                        if (column === 4) return 100
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
                    onCurrentRowChanged: {
                        if (currentRow >= 0) {
                            var fg = finishedModel.get(currentRow)
                            selectedFinishedId = fg.id
                        }
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    Button {
                        text: "Продать"
                        enabled: selectedFinishedId > 0
                        onClicked: sellDialog.open()
                    }
                }
            }

            // ДИАЛОГ ВНУТРИ ITEM
            Dialog {
                id: sellDialog
                title: "Продажа станка"
                standardButtons: Dialog.Ok | Dialog.Cancel
                width: 400
                height: 250
                ColumnLayout {
                    anchors.fill: parent
                    Label { text: "Цена продажи (руб):" }
                    TextField {
                        id: sellPriceField
                        Layout.fillWidth: true
                        validator: DoubleValidator { bottom: 0.01 }
                    }
                    Label { text: "Покупатель:" }
                    TextField { id: buyerField; Layout.fillWidth: true }

                    Label {
                        id: sellErrorLabel
                        color: "red"
                        visible: false
                        text: "Заполните все поля"
                    }
                }
                onAccepted: {
                    if (sellPriceField.text && buyerField.text) {
                        sellErrorLabel.visible = false
                        backend.sellFinishedGood(selectedFinishedId, parseFloat(sellPriceField.text), buyerField.text)
                        finishedModel.refresh()
                        sellPriceField.clear()
                        buyerField.clear()
                    } else {
                        sellErrorLabel.visible = true
                    }
                }
                onClosed: {
                    sellErrorLabel.visible = false
                    sellPriceField.clear()
                    buyerField.clear()
                }
            }

            Component.onCompleted: finishedModel.refresh()
        }
       // ================= ВКЛАДКА 3: РЕДАКТОР МОДЕЛЕЙ =================
        Item {
            id: tab3Root
            property int selectedMachineId: -1
            property string selectedMachineModel: ""

            MachineListModel { id: machineModel }
            MachineSpecModel { id: specModel }

            RowLayout {
                anchors.fill: parent
                anchors.margins: 10
                spacing: 10

                // Левая часть — список моделей
                ColumnLayout {
                    Layout.preferredWidth: 300
                    Layout.fillHeight: true
                    spacing: 5

                    RowLayout {
                        Layout.fillWidth: true
                        TextField {
                            id: modelSearchField
                            Layout.fillWidth: true
                            placeholderText: "Поиск модели..."
                            onTextChanged: machineModel.setFilter(text)
                        }
                        Button {
                            text: "Обновить"
                            onClicked: {
                                modelSearchField.clear()
                                machineModel.setFilter("")
                                machineModel.refresh()
                                modelCountText.text = "Найдено моделей: " + machineModel.rowCount()
                            }
                        }
                    }

                    Label {
                        id: modelCountText
                        text: "Найдено моделей: 0"
                    }

                    ListView {
                        id: machineListView
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        model: machineModel
                        clip: true
                        delegate: Rectangle {
                            width: machineListView.width
                            height: 40
                            border.color: "#ccc"
                            color: machineListView.currentIndex === index ? "#e0f0ff" : "white"

                            RowLayout {
                                anchors.fill: parent
                                anchors.margins: 5
                                Text {
                                    text: display.model
                                    Layout.fillWidth: true
                                    font.pixelSize: 14
                                    color: "black"
                                }
                                Text {
                                    text: display.cost.toFixed(2) + " ₽"
                                    Layout.preferredWidth: 100
                                    horizontalAlignment: Text.AlignRight
                                    color: "black"
                                }
                            }

                            MouseArea {
                                anchors.fill: parent
                                onClicked: {
                                    machineListView.currentIndex = index
                                    var m = machineModel.get(index)
                                    tab3Root.selectedMachineId = m.id
                                    tab3Root.selectedMachineModel = m.model
                                    specModel.setMachineId(m.id)
                                    specModel.refresh()
                                }
                            }
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 5
                        Button {
                            text: "Добавить модель"
                            onClicked: addModelDialog.open()
                        }
                        Button {
                            text: "Удалить модель"
                            enabled: tab3Root.selectedMachineId > 0
                            onClicked: deleteModelDialog.open()
                        }
                    }

                    // НОВАЯ КНОПКА "Начать производство"
                    Button {
                        Layout.fillWidth: true
                        text: "Начать производство"
                        enabled: tab3Root.selectedMachineId > 0
                        highlighted: true
                        onClicked: startProductionDialog.open()
                    }
                }

                // Правая часть — спецификация
                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    spacing: 5

                    Label {
                        text: tab3Root.selectedMachineId > 0 ? "Спецификация модели: " + tab3Root.selectedMachineModel : "Выберите модель"
                        font.bold: true
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        height: 30
                        color: "#e8e8e8"
                        visible: tab3Root.selectedMachineId > 0
                        RowLayout {
                            anchors.fill: parent
                            spacing: 0
                            Repeater {
                                model: ["ID", "Материал", "Кол-во", "Цена/ед"]
                                Rectangle {
                                    width: index === 0 ? 50 : index === 1 ? 300 : index === 2 ? 80 : 100
                                    height: 30
                                    border.color: "#ccc"
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
                        id: specTable
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        model: specModel
                        clip: true
                        visible: tab3Root.selectedMachineId > 0
                        columnWidthProvider: function(column) {
                            if (column === 0) return 50
                            if (column === 1) return 300
                            if (column === 2) return 80
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

                    Label {
                        visible: tab3Root.selectedMachineId > 0 && specModel.rowCount() === 0
                        text: "Спецификация пуста. Добавьте материалы."
                        color: "#666"
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        visible: tab3Root.selectedMachineId > 0
                        Button {
                            text: "Добавить материал"
                            onClicked: addMaterialToSpecDialog.open()
                        }
                        Button {
                            text: "Удалить материал"
                            enabled: specTable.currentRow >= 0
                            onClicked: {
                                var row = specTable.currentRow
                                var matId = specModel.getMaterialId(row)
                                if (matId > 0) {
                                    backend.removeMaterialFromMachine(tab3Root.selectedMachineId, matId)
                                    specModel.refresh()
                                    machineModel.refresh()
                                    modelCountText.text = "Найдено моделей: " + machineModel.rowCount()
                                }
                            }
                        }
                        Button {
                            text: "Изменить количество"
                            enabled: specTable.currentRow >= 0
                            onClicked: {
                                var row = specTable.currentRow
                                var matId = specModel.getMaterialId(row)
                                var curQty = specModel.getQuantity(row)
                                editQtyDialog.materialId = matId
                                editQtyDialog.currentQty = curQty
                                editQtyDialog.open()
                            }
                        }
                    }
                }
            }

            // ДИАЛОГИ
            Dialog {
                id: addModelDialog
                title: "Добавить модель станка"
                standardButtons: Dialog.Ok | Dialog.Cancel
                width: 400
                height: 150
                ColumnLayout {
                    anchors.fill: parent
                    Label { text: "Название модели:" }
                    TextField { id: newModelName; Layout.fillWidth: true }
                }
                onAccepted: {
                    if (newModelName.text) {
                        backend.addMachineModel(newModelName.text)
                        machineModel.refresh()
                        modelCountText.text = "Найдено моделей: " + machineModel.rowCount()
                        newModelName.clear()
                    }
                }
            }

            Dialog {
                id: deleteModelDialog
                title: "Удаление модели станка"
                standardButtons: Dialog.Yes | Dialog.No
                width: 400
                height: 150
                Label {
                    text: "Удалить модель \"" + tab3Root.selectedMachineModel + "\"?\n\nЭто удалит спецификацию, но не затронет готовые станки."
                    wrapMode: Text.WordWrap
                    anchors.fill: parent
                    anchors.margins: 10
                }
                onAccepted: {
                    if (backend.deleteMachineModel(tab3Root.selectedMachineId)) {
                        tab3Root.selectedMachineId = -1
                        tab3Root.selectedMachineModel = ""
                        specModel.setMachineId(-1)
                        specModel.refresh()
                        machineModel.refresh()
                        modelCountText.text = "Найдено моделей: " + machineModel.rowCount()
                    }
                }
            }

            // НОВЫЙ ДИАЛОГ "Начать производство"
            Dialog {
                id: startProductionDialog
                title: "Начать производство станка"
                standardButtons: Dialog.Ok | Dialog.Cancel
                width: 500
                height: 250
                ColumnLayout {
                    anchors.fill: parent
                    spacing: 10

                    Label {
                        text: "Модель: " + tab3Root.selectedMachineModel
                        font.bold: true
                    }

                    Label { text: "Количество станков:" }
                    SpinBox {
                        id: quantitySpinBox
                        Layout.fillWidth: true
                        from: 1
                        to: 100
                        value: 1
                    }

                    Label { text: "Примечание (необязательно):" }
                    TextField {
                        id: productionNotesField
                        Layout.fillWidth: true
                        placeholderText: "Серийный номер, комментарий..."
                    }

                    Label {
                        text: "Станки будут добавлены в активный пул со статусом 'В процессе'."
                        wrapMode: Text.WordWrap
                        color: "#666"
                        font.pixelSize: 11
                    }
                }
                onAccepted: {
                    if (backend.startProduction(tab3Root.selectedMachineId, quantitySpinBox.value, productionNotesField.text)) {
                        productionNotesField.clear()
                        quantitySpinBox.value = 1
                    }
                }
            }

            Dialog {
                id: addMaterialToSpecDialog
                title: "Добавить материал"
                standardButtons: Dialog.Ok | Dialog.Cancel
                width: 500
                height: 200
                ColumnLayout {
                    anchors.fill: parent
                    Label { text: "Материал:" }
                    ComboBox {
                        id: materialComboSpec
                        Layout.fillWidth: true
                        model: backend.getMaterialsList()
                        textRole: "name"
                        valueRole: "id"
                    }
                    Label { text: "Количество:" }
                    TextField {
                        id: specQty
                        Layout.fillWidth: true
                        validator: DoubleValidator { bottom: 0.01 }
                    }
                }
                onAccepted: {
                    if (materialComboSpec.currentValue && specQty.text) {
                        backend.addMaterialToMachine(tab3Root.selectedMachineId, materialComboSpec.currentValue, parseFloat(specQty.text))
                        specModel.refresh()
                        machineModel.refresh()
                        modelCountText.text = "Найдено моделей: " + machineModel.rowCount()
                        specQty.clear()
                    }
                }
            }

            Dialog {
                id: editQtyDialog
                title: "Изменить количество"
                standardButtons: Dialog.Ok | Dialog.Cancel
                width: 300
                height: 150
                property int materialId: -1
                property real currentQty: 0
                ColumnLayout {
                    anchors.fill: parent
                    Label { text: "Новое количество:" }
                    TextField {
                        id: newQtyField
                        Layout.fillWidth: true
                        validator: DoubleValidator { bottom: 0.01 }
                    }
                }
                onOpened: newQtyField.text = currentQty.toString()
                onAccepted: {
                    if (newQtyField.text) {
                        backend.updateMaterialInMachine(tab3Root.selectedMachineId, materialId, parseFloat(newQtyField.text))
                        specModel.refresh()
                        machineModel.refresh()
                        modelCountText.text = "Найдено моделей: " + machineModel.rowCount()
                    }
                }
            }

            Component.onCompleted: {
                machineModel.refresh()
                modelCountText.text = "Найдено моделей: " + machineModel.rowCount()
            }
        }
    }
}