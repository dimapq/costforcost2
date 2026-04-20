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
            id: tab1Root
            property int selectedInProgressId: -1
            property int selectedRow: -1

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
                        implicitHeight: 35
                        border.color: "#ddd"
                        color: {
                            if (tab1Root.selectedRow === row) return "#b3d9ff"
                            return row % 2 ? "#f9f9f9" : "white"
                        }
                        
                        Text {
                            anchors.centerIn: parent
                            text: display
                            font.pixelSize: 14
                            color: "black"
                        }
                        
                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                tab1Root.selectedRow = row
                                var item = inProgressModel.get(row)
                                tab1Root.selectedInProgressId = item.id
                            }
                        }
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    Button {
                        text: "Завершить производство"
                        enabled: tab1Root.selectedInProgressId > 0
                        highlighted: tab1Root.selectedInProgressId > 0
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
                    backend.completeMachine(tab1Root.selectedInProgressId, invNumberField.text)
                    tab1Root.selectedRow = -1
                    tab1Root.selectedInProgressId = -1
                    inProgressModel.refresh()
                    invNumberField.clear()
                }
            }

            Component.onCompleted: inProgressModel.refresh()
        }

        // ================= ВКЛАДКА 2: ГОТОВЫЕ =================
        Item {
            id: tab2Root
            property int selectedFinishedId: -1
            property int selectedRow: -1

            FinishedGoodsModel { id: finishedModel }

            TabBar {
                id: finishedTabBar
                width: parent.width
                TabButton { text: "На складе" }
                TabButton { text: "Проданные" }
            }

            StackLayout {
                anchors.top: finishedTabBar.bottom
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                currentIndex: finishedTabBar.currentIndex


                // ========== ПОДВКЛАДКА: НА СКЛАДЕ ==========
                Item {
                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 10
                        spacing: 10

                        RowLayout {
                            Layout.fillWidth: true
                            TextField {
                                id: inStockSearchField
                                Layout.fillWidth: true
                                placeholderText: "Поиск..."
                                onTextChanged: finishedModel.setFilter(text)
                            }
                            Button {
                                text: "Обновить"
                                onClicked: {
                                    inStockSearchField.clear()
                                    finishedModel.setFilter("")
                                    finishedModel.refresh()
                                    tab2Root.selectedRow = -1
                                    tab2Root.selectedFinishedId = -1
                                }
                            }
                        }

                        ScrollView {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            clip: true
                            
                            ColumnLayout {
                                width: inStockSearchField.width + 200
                                spacing: 0

                                // Заголовок таблицы
                                Rectangle {
                                    Layout.fillWidth: true
                                    height: 35
                                    color: "#e8e8e8"
                                    border.color: "#ccc"

                                    Row {
                                        anchors.fill: parent
                                        spacing: 0
                                        Repeater {
                                            model: ["ID", "Модель", "Инв. №", "Дата", "Материалы", "Работа", "Себестоимость"]
                                            Rectangle {
                                                width: index === 0 ? 50 : index === 1 ? 200 : index === 2 ? 100 : index === 3 ? 110 : index === 4 ? 120 : index === 5 ? 120 : 140
                                                height: 35
                                                border.width: 0
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

                                // Данные
                                Repeater {
                                    model: finishedModel
                                    
                                    Rectangle {
                                        Layout.fillWidth: true
                                        height: 40
                                        border.color: "#ddd"
                                        color: {
                                            if (tab2Root.selectedRow === index) return "#b3d9ff"
                                            return index % 2 ? "#f9f9f9" : "white"
                                        }

                                        property var rowData: finishedModel.get(index)

                                        Row {
                                            anchors.fill: parent
                                            spacing: 0

                                            // ID
                                            Rectangle {
                                                width: 50
                                                height: 40
                                                color: "transparent"
                                                Text {
                                                    anchors.centerIn: parent
                                                    text: rowData.id || ""
                                                    font.pixelSize: 14
                                                }
                                            }

                                            // Модель
                                            Rectangle {
                                                width: 200
                                                height: 40
                                                color: "transparent"
                                                Text {
                                                    anchors.centerIn: parent
                                                    text: rowData.model || ""
                                                    font.pixelSize: 14
                                                    elide: Text.ElideRight
                                                    width: parent.width - 10
                                                }
                                            }

                                            // Инв. №
                                            Rectangle {
                                                width: 100
                                                height: 40
                                                color: "transparent"
                                                Text {
                                                    anchors.centerIn: parent
                                                    text: rowData.inv_num || "—"
                                                    font.pixelSize: 14
                                                }
                                            }

                                            // Дата
                                            Rectangle {
                                                width: 110
                                                height: 40
                                                color: "transparent"
                                                Text {
                                                    anchors.centerIn: parent
                                                    text: rowData.produced_date || ""
                                                    font.pixelSize: 14
                                                }
                                            }

                                            // Материалы
                                            Rectangle {
                                                width: 120
                                                height: 40
                                                color: "transparent"
                                                Text {
                                                    anchors.centerIn: parent
                                                    text: rowData.materials_cost ? rowData.materials_cost.toFixed(2) + " ₽" : "—"
                                                    font.pixelSize: 14
                                                    color: "#666"
                                                }
                                            }

                                            // Работа
                                            Rectangle {
                                                width: 120
                                                height: 40
                                                color: "transparent"
                                                Text {
                                                    anchors.centerIn: parent
                                                    text: rowData.labor_cost ? rowData.labor_cost.toFixed(2) + " ₽" : "—"
                                                    font.pixelSize: 14
                                                    color: "#666"
                                                }
                                            }

                                            // Себестоимость
                                            Rectangle {
                                                width: 140
                                                height: 40
                                                color: "transparent"
                                                Text {
                                                    anchors.centerIn: parent
                                                    text: rowData.cost ? rowData.cost.toFixed(2) + " ₽" : "—"
                                                    font.pixelSize: 14
                                                    font.bold: true
                                                    color: "#2c5aa0"
                                                }
                                            }
                                        }

                                        MouseArea {
                                            anchors.fill: parent
                                            onClicked: {
                                                tab2Root.selectedRow = index
                                                tab2Root.selectedFinishedId = rowData.id
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 5
                            Button {
                                text: "Продать"
                                enabled: tab2Root.selectedFinishedId > 0
                                highlighted: tab2Root.selectedFinishedId > 0
                                onClicked: sellDialog.open()
                            }
                            Button {
                                text: "Детали себестоимости"
                                enabled: tab2Root.selectedFinishedId > 0
                                onClicked: costDetailsDialog.open()
                            }
                        }
                    }
                }

                // ========== ПОДВКЛАДКА: ПРОДАННЫЕ ==========
                Item {
                    id: soldTab
                    property int selectedSoldId: -1
                    property int selectedSoldRow: -1
                    
                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 10
                        spacing: 10

                        RowLayout {
                            Layout.fillWidth: true
                            TextField {
                                id: soldSearchField
                                Layout.fillWidth: true
                                placeholderText: "Поиск..."
                                onTextChanged: filterSoldMachines(text)
                            }
                            Button {
                                text: "Обновить"
                                onClicked: {
                                    soldSearchField.clear()
                                    soldTab.selectedSoldId = -1
                                    soldTab.selectedSoldRow = -1
                                    soldListView.loadSoldMachines()
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
                                    model: ["ID", "Модель", "Инв. №", "Дата продажи", "Покупатель", "Цена продажи", "Прибыль"]
                                    Rectangle {
                                        width: index === 0 ? 50 : index === 1 ? 150 : index === 2 ? 100 : index === 3 ? 120 : index === 4 ? 150 : index === 5 ? 120 : 100
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

                        ScrollView {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            clip: true

                            ListView {
                                id: soldListView
                                model: ListModel { id: soldListModel }
                                spacing: 0

                                property var allSoldData: []

                                delegate: Rectangle {
                                    width: soldListView.width
                                    height: 35
                                    border.color: "#ddd"
                                    color: {
                                        if (soldTab.selectedSoldRow === index) return "#b3d9ff"
                                        return index % 2 ? "#f9f9f9" : "white"
                                    }

                                    RowLayout {
                                        anchors.fill: parent
                                        spacing: 0
                                        Text {
                                            Layout.preferredWidth: 50
                                            text: model.id
                                            horizontalAlignment: Text.AlignHCenter
                                            verticalAlignment: Text.AlignVCenter
                                            font.pixelSize: 14
                                        }
                                        Text {
                                            Layout.preferredWidth: 150
                                            text: model.machine_model
                                            horizontalAlignment: Text.AlignHCenter
                                            verticalAlignment: Text.AlignVCenter
                                            font.pixelSize: 14
                                        }
                                        Text {
                                            Layout.preferredWidth: 100
                                            text: model.inv_num || "—"
                                            horizontalAlignment: Text.AlignHCenter
                                            verticalAlignment: Text.AlignVCenter
                                            font.pixelSize: 14
                                        }
                                        Text {
                                            Layout.preferredWidth: 120
                                            text: model.sale_date || "—"
                                            horizontalAlignment: Text.AlignHCenter
                                            verticalAlignment: Text.AlignVCenter
                                            font.pixelSize: 14
                                        }
                                        Text {
                                            Layout.preferredWidth: 150
                                            text: model.buyer || "—"
                                            horizontalAlignment: Text.AlignHCenter
                                            verticalAlignment: Text.AlignVCenter
                                            font.pixelSize: 14
                                        }
                                        Text {
                                            Layout.preferredWidth: 120
                                            text: model.sale_price ? model.sale_price.toFixed(2) + " ₽" : "—"
                                            horizontalAlignment: Text.AlignHCenter
                                            verticalAlignment: Text.AlignVCenter
                                            font.pixelSize: 14
                                        }
                                        Text {
                                            Layout.preferredWidth: 100
                                            text: model.profit ? model.profit.toFixed(2) + " ₽" : "—"
                                            horizontalAlignment: Text.AlignHCenter
                                            verticalAlignment: Text.AlignVCenter
                                            font.pixelSize: 14
                                            font.bold: true
                                            color: model.profit > 0 ? "#28a745" : model.profit < 0 ? "#dc3545" : "#666"
                                        }
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        onClicked: {
                                            soldTab.selectedSoldRow = index
                                            soldTab.selectedSoldId = model.id
                                        }
                                    }
                                }

                                function loadSoldMachines() {
                                    soldListModel.clear()
                                    allSoldData = backend.getSoldMachinesList()
                                    for (var i = 0; i < allSoldData.length; i++) {
                                        var item = allSoldData[i] || {}
                                        soldListModel.append({
                                            "id": item.id !== undefined ? item.id : -1,
                                            "machine_model": item.machine_model !== undefined ? item.machine_model : "",
                                            "inv_num": item.inv_num !== undefined ? item.inv_num : "",
                                            "sale_date": item.sale_date !== undefined ? item.sale_date : "",
                                            "buyer": item.buyer !== undefined ? item.buyer : "",
                                            "sale_price": item.sale_price !== undefined ? item.sale_price : 0,
                                            "profit": item.profit !== undefined ? item.profit : 0
                                        })
                                    }
                                }

                                Component.onCompleted: loadSoldMachines()
                            }
                        }

                        Label {
                            visible: soldListModel.count === 0
                            text: "Нет проданных станков"
                            color: "#666"
                        }

                        // КНОПКА ВОЗВРАТА
                        RowLayout {
                            Layout.fillWidth: true
                            Button {
                                text: "Вернуть на склад"
                                enabled: soldTab.selectedSoldId > 0
                                highlighted: soldTab.selectedSoldId > 0
                                onClicked: returnToStockDialog.open()
                            }
                        }
                    }

                    // ДИАЛОГ ПОДТВЕРЖДЕНИЯ ВОЗВРАТА
                    Dialog {
                        id: returnToStockDialog
                        title: "Возврат станка на склад"
                        standardButtons: Dialog.Yes | Dialog.No
                        width: 450
                        height: 180

                        Label {
                            text: "Вернуть проданный станок на склад?\n\n" +
                                "• Станок получит статус 'На складе'\n" +
                                "• Запись о продаже будет удалена\n" +
                                "• Информация о покупателе и дате продажи будет очищена"
                            wrapMode: Text.WordWrap
                            anchors.fill: parent
                            anchors.margins: 10
                        }

                        onAccepted: {
                            if (backend.returnMachineToStock(soldTab.selectedSoldId)) {
                                soldTab.selectedSoldId = -1
                                soldTab.selectedSoldRow = -1
                                soldListView.loadSoldMachines()
                                finishedModel.refresh()
                            }
                        }
                    }

                    function filterSoldMachines(searchText) {
                        soldListModel.clear()
                        var filtered = soldListView.allSoldData.filter(function(item) {
                            if (!searchText) return true
                            var search = searchText.toLowerCase()
                            return (item.machine_model && item.machine_model.toLowerCase().includes(search)) ||
                                (item.inv_num && item.inv_num.toLowerCase().includes(search)) ||
                                (item.buyer && item.buyer.toLowerCase().includes(search))
                        })
                        for (var i = 0; i < filtered.length; i++) {
                            var item = filtered[i] || {}
                            soldListModel.append({
                                "id": item.id !== undefined ? item.id : -1,
                                "machine_model": item.machine_model !== undefined ? item.machine_model : "",
                                "inv_num": item.inv_num !== undefined ? item.inv_num : "",
                                "sale_date": item.sale_date !== undefined ? item.sale_date : "",
                                "buyer": item.buyer !== undefined ? item.buyer : "",
                                "sale_price": item.sale_price !== undefined ? item.sale_price : 0,
                                "profit": item.profit !== undefined ? item.profit : 0
                            })
                        }
                    }
                }
            }
        
                    // ========== ДИАЛОГИ ==========
            Dialog {
                id: sellDialog
                title: "Продажа станка"
                standardButtons: Dialog.Ok | Dialog.Cancel
                width: 550
                height: 520

                ColumnLayout {
                    anchors.fill: parent
                    spacing: 10

                    Label {
                        text: "Инвентарный номер:"
                    }
                    TextField {
                        id: sellInvNumberField
                        Layout.fillWidth: true
                        placeholderText: "Введите или оставьте пустым"
                    }

                    Label { text: "Дата продажи:" }
                    TextField {
                        id: sellDateField
                        Layout.fillWidth: true
                        placeholderText: "ГГГГ-ММ-ДД (Enter = сегодня)"
                        text: Qt.formatDate(new Date(), "yyyy-MM-dd")
                    }

                    Label { text: "Покупатель:" }
                    TextField {
                        id: buyerField
                        Layout.fillWidth: true
                        placeholderText: "ФИО или название организации"
                    }

                    Label { text: "Цена продажи (руб):" }
                    TextField {
                        id: sellPriceField
                        Layout.fillWidth: true
                        validator: DoubleValidator { bottom: 0.01 }
                        placeholderText: "Введите цену"
                    }

                    // БЛОК ТРАНСПОРТИРОВКИ
                    GroupBox {
                        Layout.fillWidth: true
                        title: "Транспортировка"

                        ColumnLayout {
                            anchors.fill: parent
                            spacing: 10

                            ButtonGroup { id: shippingGroup }

                            RadioButton {
                                id: shippingFreeRadio
                                text: "Бесплатная (клиент оплачивает)"
                                checked: true
                                ButtonGroup.group: shippingGroup
                            }

                            RadioButton {
                                id: shippingPaidRadio
                                text: "Платная (добавить к себестоимости)"
                                ButtonGroup.group: shippingGroup
                            }

                            RowLayout {
                                visible: shippingPaidRadio.checked
                                Layout.fillWidth: true
                                
                                Label { text: "Стоимость доставки (руб):" }
                                TextField {
                                    id: shippingCostField
                                    Layout.fillWidth: true
                                    validator: DoubleValidator { bottom: 0 }
                                    placeholderText: "0"
                                    text: "0"
                                }
                            }

                            Label {
                                visible: shippingPaidRadio.checked
                                text: "⚠ Стоимость доставки будет добавлена к себестоимости станка"
                                font.pixelSize: 11
                                color: "#666"
                                wrapMode: Text.WordWrap
                                Layout.fillWidth: true
                            }
                        }
                    }

                    Label {
                        id: sellErrorLabel
                        color: "red"
                        visible: false
                        text: "Заполните покупателя и цену"
                    }
                }

                onOpened: {
                    sellInvNumberField.clear()
                    sellDateField.text = Qt.formatDate(new Date(), "yyyy-MM-dd")
                    buyerField.clear()
                    sellPriceField.clear()
                    shippingFreeRadio.checked = true
                    shippingCostField.text = "0"
                    sellErrorLabel.visible = false
                }

                onAccepted: {
                    if (sellPriceField.text && buyerField.text) {
                        sellErrorLabel.visible = false
                        
                        var shippingCost = 0
                        if (shippingPaidRadio.checked && shippingCostField.text) {
                            shippingCost = parseFloat(shippingCostField.text)
                        }
                        
                        if (backend.sellFinishedGoodWithShipping(
                            tab2Root.selectedFinishedId,
                            parseFloat(sellPriceField.text),
                            buyerField.text,
                            sellInvNumberField.text,
                            sellDateField.text,
                            shippingCost
                        )) {
                            tab2Root.selectedRow = -1
                            tab2Root.selectedFinishedId = -1
                            finishedModel.refresh()
                        }
                    } else {
                        sellErrorLabel.visible = true
                    }
                }
            }

            Dialog {
                id: costDetailsDialog
                title: "Детали себестоимости станка"
                standardButtons: Dialog.Close
                width: 600
                height: 500

                ColumnLayout {
                    anchors.fill: parent
                    spacing: 10

                    Label {
                        id: costDetailsHeader
                        text: "Загрузка..."
                        font.bold: true
                        font.pixelSize: 14
                    }

                    ScrollView {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        clip: true

                        TextArea {
                            id: costDetailsText
                            readOnly: true
                            wrapMode: TextArea.Wrap
                            font.family: "Courier New"
                            font.pixelSize: 12
                            text: "Загрузка данных..."
                        }
                    }
                }

                onOpened: {
                    var details = backend.getMachineCostDetails(tab2Root.selectedFinishedId)
                    costDetailsHeader.text = details.header
                    costDetailsText.text = details.breakdown
                }
            }

            Component.onCompleted: {
                finishedModel.refresh()
            }
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

                    // Заголовок таблицы спецификации
                    Rectangle {
                        Layout.fillWidth: true
                        height: 30
                        color: "#e8e8e8"
                        visible: tab3Root.selectedMachineId > 0
                        RowLayout {
                            anchors.fill: parent
                            spacing: 0
                            Repeater {
                                model: ["ID", "Материал", "Кол-во", "Цена/ед", "Сумма"]
                                Rectangle {
                                    width: index === 0 ? 50 : index === 1 ? 250 : index === 2 ? 80 : index === 3 ? 100 : 100
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
                            if (column === 1) return 250
                            if (column === 2) return 80
                            if (column === 3) return 100
                            return 100
                        }
                        selectionBehavior: TableView.SelectRows
                        
                        delegate: Rectangle {
                            implicitHeight: 35
                            border.color: "#ddd"
                            color: {
                                if (specTable.currentRow === row) return "#b3d9ff"
                                return row % 2 ? "#f9f9f9" : "white"
                            }
                            
                            Text {
                                anchors.centerIn: parent
                                text: display
                                font.pixelSize: 14
                                color: "black"
                            }
                            
                            MouseArea {
                                anchors.fill: parent
                                onClicked: {
                                    specTable.currentRow = row
                                    specTable.forceActiveFocus()
                                }
                            }
                        }
                    }

                    // ИТОГОВАЯ СУММА
                    Rectangle {
                        Layout.fillWidth: true
                        height: 35
                        color: "#fff9e6"
                        border.color: "#ccc"
                        visible: tab3Root.selectedMachineId > 0 && specModel.rowCount() > 0
                        
                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: 5
                            
                            Label {
                                text: "ИТОГО:"
                                font.bold: true
                                font.pixelSize: 14
                                Layout.fillWidth: true
                            }
                            
                            Label {
                                id: totalCostLabel
                                text: calculateTotalCost() + " ₽"
                                font.bold: true
                                font.pixelSize: 14
                                color: "#2c5aa0"
                                horizontalAlignment: Text.AlignRight
                                Layout.preferredWidth: 100
                                
                                function calculateTotalCost() {
                                    var total = 0.0
                                    for (var i = 0; i < specModel.rowCount(); i++) {
                                        var qty = specModel.getQuantity(i)
                                        var price = specModel.getPrice(i)
                                        if (price !== null && price > 0) {
                                            total += qty * price
                                        }
                                    }
                                    return total.toFixed(2)
                                }
                                
                                Connections {
                                    target: specModel
                                    function onModelReset() {
                                        totalCostLabel.text = totalCostLabel.calculateTotalCost() + " ₽"
                                    }
                                }
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
                        spacing: 5
                        
                        Button {
                            text: "Добавить материал"
                            onClicked: addMaterialToSpecDialog.open()
                        }
                        
                        Button {
                            text: "Изменить количество"
                            enabled: specTable.currentRow >= 0
                            highlighted: specTable.currentRow >= 0
                            onClicked: {
                                var row = specTable.currentRow
                                var matId = specModel.getMaterialId(row)
                                var curQty = specModel.getQuantity(row)
                                editQtyDialog.materialId = matId
                                editQtyDialog.currentQty = curQty
                                editQtyDialog.open()
                            }
                        }
                        
                        Button {
                            text: "Удалить материал"
                            enabled: specTable.currentRow >= 0
                            highlighted: specTable.currentRow >= 0
                            onClicked: {
                                var row = specTable.currentRow
                                var matId = specModel.getMaterialId(row)
                                if (matId > 0) {
                                    backend.removeMaterialFromMachine(tab3Root.selectedMachineId, matId)
                                    specTable.currentRow = -1
                                    specModel.refresh()
                                    machineModel.refresh()
                                    modelCountText.text = "Найдено моделей: " + machineModel.rowCount()
                                }
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
