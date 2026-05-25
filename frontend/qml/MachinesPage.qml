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
        TabButton { text: "На складе" }
        TabButton { text: "Проданные" }
        TabButton { text: "Редактор моделей" }
    }

    StackLayout {
        anchors.top: bar.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        currentIndex: bar.currentIndex === 0 ? 0 : (bar.currentIndex === 3 ? 2 : 1)

        // ================= TAB 1: In Progress =================
        Item {
            id: tab1Root
            property int selectedInProgressId: -1
            property int selectedRow: -1
            property string selectedInProgressInventoryNumber: ""
            property string exportMessage: ""

            InProgressModel { id: inProgressModel }

            SplitView {
                anchors.fill: parent
                orientation: Qt.Horizontal

                // Left side: machines in progress
                Item {
                    SplitView.preferredWidth: 400
                    SplitView.minimumWidth: 300

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 10
                        spacing: 10

                        RowLayout {
                            Layout.fillWidth: true
                            Label {
                                text: "Станки в производстве"
                                font.pixelSize: 16
                                font.bold: true
                            }
                            Item { Layout.fillWidth: true }
                            Button {
                                text: "Обновить"
                                onClicked: {
                                    inProgressModel.refresh()
                                    if (tab1Root.selectedInProgressId > 0) {
                                        materialsCheckList.loadMaterialsCheck(tab1Root.selectedInProgressId)
                                    }
                                }
                            }
                        }

                        // Table header
                        Rectangle {
                            Layout.fillWidth: true
                            height: 30
                            color: "#e8e8e8"
                            RowLayout {
                                anchors.fill: parent
                                spacing: 0
                                Repeater {
                                    model: ["#", "Модель", "ID станка", "Дата начала", "Часы", "Косвенные", "Общая", "Примечание"]
                                    Rectangle {
                                        width: index === 0 ? 50 : index === 1 ? 150 : index === 2 ? 110 : index === 3 ? 105 : index === 4 ? 80 : index === 5 ? 110 : index === 6 ? 110 : 180
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
                                if (column === 1) return 150
                                if (column === 2) return 110
                                if (column === 3) return 105
                                if (column === 4) return 80
                                if (column === 5) return 110
                                if (column === 6) return 110
                                return 180
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
                                        tab1Root.selectedInProgressInventoryNumber = item.inventory_number || ""
                                        materialsCheckList.loadMaterialsCheck(item.id)
                                    }
                                }
                            }
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            Button {
                                text: "Завершить производство"
                                enabled: tab1Root.selectedInProgressId > 0 && materialsCheckList.allMaterialsAvailable
                                highlighted: tab1Root.selectedInProgressId > 0 && materialsCheckList.allMaterialsAvailable
                                onClicked: completeDialog.open()
                            }
                            Button {
                                text: "Отменить производство"
                                enabled: tab1Root.selectedInProgressId > 0
                                onClicked: cancelProductionDialog.open()
                            }
                            Button {
                                text: "Excel: выбранный"
                                enabled: tab1Root.selectedInProgressId > 0
                                onClicked: {
                                    var path = backend.exportMissingMaterialsForMachine(tab1Root.selectedInProgressId)
                                    tab1Root.exportMessage = path ? "Файл создан: " + path : "Нет материалов для покупки или ошибка выгрузки"
                                }
                            }
                            Button {
                                text: "Excel: все"
                                onClicked: {
                                    var path = backend.exportMissingMaterialsForAllInProgress()
                                    tab1Root.exportMessage = path ? "Файл создан: " + path : "Нет материалов для покупки или ошибка выгрузки"
                                }
                            }
                            Label {
                                visible: tab1Root.selectedInProgressId > 0 && !materialsCheckList.allMaterialsAvailable
                                text: "Не все материалы доступны"
                                color: "#d9534f"
                                font.bold: true
                            }
                        }

                        Label {
                            visible: tab1Root.exportMessage.length > 0
                            text: tab1Root.exportMessage
                            color: "#2f6f3e"
                            wrapMode: Text.WordWrap
                            Layout.fillWidth: true
                        }
                    }
                }

                // Р СџР В Р С’Р вЂ™Р С’Р Р‡ Р СџР С’Р СњР вЂўР вЂєР В¬: Р СџРЎР‚Р С•Р Р†Р ВµРЎР‚Р С”Р В° Р СР В°РЎвЂљР ВµРЎР‚Р С‘Р В°Р В»Р С•Р Р†
                Item {
                    SplitView.fillWidth: true
                    SplitView.minimumWidth: 450

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 10
                        spacing: 10

                        Label {
                            text: tab1Root.selectedInProgressId > 0 ? 
                                "Выбранный станок (запись " + tab1Root.selectedInProgressId + ", ID станка " + (tab1Root.selectedInProgressInventoryNumber.length > 0 ? tab1Root.selectedInProgressInventoryNumber : "-") + ")" :
                                "Выберите станок слева, чтобы посмотреть проверку материалов"
                            font.pixelSize: 16
                            font.bold: true
                        }

                        // Р вЂ”Р В°Р С–Р С•Р В»Р С•Р Р†Р С•Р С” РЎвЂљР В°Р В±Р В»Р С‘РЎвЂ РЎвЂ№ Р СР В°РЎвЂљР ВµРЎР‚Р С‘Р В°Р В»Р С•Р Р†
                        Rectangle {
                            Layout.fillWidth: true
                            height: 35
                            color: "#e8e8e8"
                            border.color: "#ccc"
                            visible: tab1Root.selectedInProgressId > 0

                            Row {
                                anchors.fill: parent
                                spacing: 0
                                Repeater {
                                    model: ["Материал", "Требуется", "На складе", "Доступно"]
                                    Rectangle {
                                        width: index === 0 ? 200 : index === 1 ? 100 : index === 2 ? 100 : 100
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

                        // Р РЋР С—Р С‘РЎРѓР С•Р С” Р СР В°РЎвЂљР ВµРЎР‚Р С‘Р В°Р В»Р С•Р Р†
                        ScrollView {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            clip: true
                            visible: tab1Root.selectedInProgressId > 0

                            ListView {
                                id: materialsCheckList
                                model: ListModel { id: materialsCheckModel }
                                spacing: 0

                                property bool allMaterialsAvailable: true

                                delegate: Rectangle {
                                    width: materialsCheckList.width
                                    height: 40
                                    border.color: "#ddd"
                                    color: model.available ? "#d4edda" : "#f8d7da"

                                    Row {
                                        anchors.fill: parent
                                        spacing: 0

                                        // Р СљР В°РЎвЂљР ВµРЎР‚Р С‘Р В°Р В»
                                        Rectangle {
                                            width: 200
                                            height: 40
                                            color: "transparent"
                                            Text {
                                                anchors.verticalCenter: parent.verticalCenter
                                                anchors.left: parent.left
                                                anchors.leftMargin: 10
                                                text: model.material_name
                                                font.pixelSize: 13
                                                elide: Text.ElideRight
                                                width: parent.width - 20
                                            }
                                        }

                                        // Р СћРЎР‚Р ВµР В±РЎС“Р ВµРЎвЂљРЎРѓРЎРЏ
                                        Rectangle {
                                            width: 100
                                            height: 40
                                            color: "transparent"
                                            Text {
                                                anchors.centerIn: parent
                                                text: model.required.toFixed(2)
                                                font.pixelSize: 13
                                                font.bold: true
                                            }
                                        }

                                        // Р вЂ™ Р Р…Р В°Р В»Р С‘РЎвЂЎР С‘Р С‘
                                        Rectangle {
                                            width: 100
                                            height: 40
                                            color: "transparent"
                                            Text {
                                                anchors.centerIn: parent
                                                text: model.in_stock.toFixed(2)
                                                font.pixelSize: 13
                                                color: model.available ? "#28a745" : "#dc3545"
                                                font.bold: true
                                            }
                                        }

                                        // Р РЋРЎвЂљР В°РЎвЂљРЎС“РЎРѓ
                                        Rectangle {
                                            width: 100
                                            height: 40
                                            color: "transparent"
                                            Text {
                                                anchors.centerIn: parent
                                                text: model.available ? "OK" : "Не хватает"
                                                font.pixelSize: 13
                                                font.bold: true
                                                color: model.available ? "#28a745" : "#dc3545"
                                            }
                                        }
                                    }
                                }

                                function loadMaterialsCheck(finishedGoodId) {
                                    materialsCheckModel.clear()
                                    var check = backend.checkMaterialsForMachine(finishedGoodId)
                                    
                                    var allAvailable = true
                                    for (var i = 0; i < check.length; i++) {
                                        materialsCheckModel.append(check[i])
                                        if (!check[i].available) {
                                            allAvailable = false
                                        }
                                    }
                                    materialsCheckList.allMaterialsAvailable = allAvailable
                                }
                            }
                        }

                        Label {
                            visible: tab1Root.selectedInProgressId > 0 && materialsCheckModel.count === 0
                            text: "Для этого станка материалы не найдены"
                            color: "#666"
                            Layout.alignment: Qt.AlignHCenter
                        }

                        Label {
                            visible: tab1Root.selectedInProgressId <= 0
                            text: "Выберите станок слева, чтобы посмотреть проверку материалов"
                            color: "#999"
                            font.pixelSize: 14
                            Layout.alignment: Qt.AlignHCenter
                        }

                        // Р ВР Р…РЎвЂћР С•РЎР‚Р СР В°РЎвЂ Р С‘РЎРЏ Р С• Р Р…Р ВµР Т‘Р С•РЎРѓРЎвЂљР В°РЎР‹РЎвЂ°Р С‘РЎвЂ¦ Р СР В°РЎвЂљР ВµРЎР‚Р С‘Р В°Р В»Р В°РЎвЂ¦
                        GroupBox {
                            Layout.fillWidth: true
                            visible: tab1Root.selectedInProgressId > 0 && !materialsCheckList.allMaterialsAvailable
                            title: "Проверка материалов"

                            ColumnLayout {
                                anchors.fill: parent
                                spacing: 5

                                Label {
                                    text: "Не хватает материалов для завершения станка."
                                    font.bold: true
                                    color: "#d9534f"
                                }

                                Label {
                                    text: "При завершении станка эти материалы будут возвращены на склад."
                                    Layout.fillWidth: true
                                    color: "#666"
                                }
                            }
                        }
                    }
                }
            }

            // Р вЂќР ВР С’Р вЂєР С›Р вЂњ Р вЂ™Р СњР Р€Р СћР В Р В ITEM
            Dialog {
                id: completeDialog
                title: "Завершение производства"
                standardButtons: Dialog.Ok | Dialog.Cancel
                width: 400
                height: 200
                ColumnLayout {
                    anchors.fill: parent
                    Label { text: "Инвентарный номер (обязательно):" }
                    TextField { id: invNumberField; Layout.fillWidth: true }
                }
                onAccepted: {
                    backend.completeMachine(tab1Root.selectedInProgressId, invNumberField.text)
                    tab1Root.selectedRow = -1
                    tab1Root.selectedInProgressId = -1
                    tab1Root.selectedInProgressInventoryNumber = ""
                    inProgressModel.refresh()
                    materialsCheckModel.clear()
                    invNumberField.clear()
                }
            }



            Dialog {
                id: cancelProductionDialog
                title: "Отменить производство"
                standardButtons: Dialog.Yes | Dialog.No
                width: 460
                height: 240

                ColumnLayout {
                    anchors.fill: parent
                    spacing: 12

                    Label {
                        text: "Отменить производство выбранного станка?"
                        font.bold: true
                        font.pixelSize: 16
                        Layout.fillWidth: true
                        wrapMode: Text.WordWrap
                    }

                    Label {
                        text: "Запись будет удалена из списка «В процессе». Материалы не возвращаются на склад, потому что они списываются только при завершении производства."
                        Layout.fillWidth: true
                        wrapMode: Text.WordWrap
                        color: "#666"
                    }
                }

                onAccepted: {
                    if (backend.cancelProduction(tab1Root.selectedInProgressId)) {
                        tab1Root.selectedRow = -1
                        tab1Root.selectedInProgressId = -1
                        tab1Root.selectedInProgressInventoryNumber = ""
                        inProgressModel.refresh()
                        materialsCheckModel.clear()
                    }
                }
            }

            Component.onCompleted: inProgressModel.refresh()
        }

        // ================= TAB 2: Finished =================
        Item {
            id: tab2Root
            property int selectedFinishedId: -1
            property int selectedRow: -1

            FinishedGoodsModel { id: finishedModel }


            StackLayout {
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                currentIndex: bar.currentIndex === 2 ? 1 : 0


                // ========== Р СџР С›Р вЂќР вЂ™Р С™Р вЂєР С’Р вЂќР С™Р С’: Р СњР С’ Р РЋР С™Р вЂєР С’Р вЂќР вЂў ==========
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

                                // Р вЂ”Р В°Р С–Р С•Р В»Р С•Р Р†Р С•Р С” РЎвЂљР В°Р В±Р В»Р С‘РЎвЂ РЎвЂ№
                                Rectangle {
                                    Layout.fillWidth: true
                                    height: 35
                                    color: "#e8e8e8"
                                    border.color: "#ccc"

                                    Row {
                                        anchors.fill: parent
                                        spacing: 0
                                        Repeater {
                                            model: ["#", "Модель", "Инв. №", "Дата начала", "Дата окончания", "Материалы", "Работа", "Стоимость", "Косвенные"]
                                            Rectangle {
                                                width: index === 0 ? 50 : index === 1 ? 200 : index === 2 ? 100 : index === 3 ? 110 : index === 4 ? 120 : index === 5 ? 120 : index === 6 ? 120 : index === 7 ? 140 : 130
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

                                // Р вЂќР В°Р Р…Р Р…РЎвЂ№Р Вµ
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

                                            // Р СљР С•Р Т‘Р ВµР В»РЎРЉ
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

                                            // Р ВР Р…Р Р†. РІвЂћвЂ“
                                            Rectangle {
                                                width: 100
                                                height: 40
                                                color: "transparent"
                                                Text {
                                                    anchors.centerIn: parent
                                                    text: rowData.inv_num || "-"
                                                    font.pixelSize: 14
                                                }
                                            }

                                            // Дата начала производства
                                            Rectangle {
                                                width: 110
                                                height: 40
                                                color: "transparent"
                                                Text {
                                                    anchors.centerIn: parent
                                                    text: rowData.start_date || "-"
                                                    font.pixelSize: 14
                                                }
                                            }

                                            // Р вЂќР В°РЎвЂљР В°
                                            Rectangle {
                                                width: 120
                                                height: 40
                                                color: "transparent"
                                                Text {
                                                    anchors.centerIn: parent
                                                    text: rowData.produced_date || ""
                                                    font.pixelSize: 14
                                                }
                                            }

                                            // Р СљР В°РЎвЂљР ВµРЎР‚Р С‘Р В°Р В»РЎвЂ№
                                            Rectangle {
                                                width: 120
                                                height: 40
                                                color: "transparent"
                                                Text {
                                                    anchors.centerIn: parent
                                                    text: rowData.materials_cost ? rowData.materials_cost.toFixed(2) + " руб." : "-"
                                                    font.pixelSize: 14
                                                    color: "#666"
                                                }
                                            }

                                            // Р В Р В°Р В±Р С•РЎвЂљР В°
                                            Rectangle {
                                                width: 120
                                                height: 40
                                                color: "transparent"
                                                Text {
                                                    anchors.centerIn: parent
                                                    text: rowData.labor_cost ? rowData.labor_cost.toFixed(2) + " руб." : "-"
                                                    font.pixelSize: 14
                                                    color: "#666"
                                                }
                                            }

                                            // Р РЋР ВµР В±Р ВµРЎРѓРЎвЂљР С•Р С‘Р СР С•РЎРѓРЎвЂљРЎРЉ
                                            Rectangle {
                                                width: 140
                                                height: 40
                                                color: "transparent"
                                                Text {
                                                    anchors.centerIn: parent
                                                    text: (rowData.cost !== undefined && rowData.cost !== null) ? Number(rowData.cost).toFixed(2) + " руб. (" + Number(rowData.base_cost || 0).toFixed(2) + " руб.)" : "-"
                                                    font.pixelSize: 14
                                                    font.bold: true
                                                    color: "#2c5aa0"
                                                }
                                            }
                                            Rectangle {
                                                width: 130
                                                height: 40
                                                color: "transparent"
                                                Text {
                                                    anchors.centerIn: parent
                                                    text: rowData.indirect_cost !== undefined ? Number(rowData.indirect_cost).toFixed(2) + " руб." : "0.00"
                                                    font.pixelSize: 14
                                                    color: "#6b4f00"
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
                                text: "Sell"
                                enabled: tab2Root.selectedFinishedId > 0
                                highlighted: tab2Root.selectedFinishedId > 0
                                onClicked: sellDialog.open()
                            }

                            Button {
                                text: "Изменить"
                                enabled: tab2Root.selectedFinishedId > 0
                                highlighted: tab2Root.selectedFinishedId > 0
                                onClicked: {
                                    if (tab2Root.selectedRow >= 0) {
                                        var item = finishedModel.get(tab2Root.selectedRow)
                                        editFinishedModelField.text = item.model || ""
                                        editFinishedInvField.text = item.inv_num || ""
                                        editFinishedStartDateField.text = item.start_date || ""
                                        editFinishedDateField.text = item.produced_date || ""
                                        editFinishedCostField.text = (item.cost !== undefined ? Number(item.cost).toFixed(2) : "0.00")
                                        editFinishedIndirectField.text = (item.indirect_cost !== undefined ? Number(item.indirect_cost).toFixed(2) : "0.00")
                                        editFinishedNotesField.text = item.notes || ""
                                        editFinishedDialog.open()
                                    }
                                }
                            }
                            
                            Button {
                                text: "Детали себестоимости"
                                enabled: tab2Root.selectedFinishedId > 0
                                onClicked: costDetailsDialog.open()
                            }
                            
                            Item { Layout.fillWidth: true }
                            
                            Button {
                                text: "Разобрать станок"
                                enabled: tab2Root.selectedFinishedId > 0
                                onClicked: disassembleDialog.open()
                            }
                            
                            Button {
                                text: "Удалить"
                                enabled: tab2Root.selectedFinishedId > 0
                                onClicked: deleteMachineDialog.open()
                            }
                        }
                    }
                }

                // ========== Р СџР С›Р вЂќР вЂ™Р С™Р вЂєР С’Р вЂќР С™Р С’: Р СџР В Р С›Р вЂќР С’Р СњР СњР В«Р вЂў ==========
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

                        // Р вЂ”Р В°Р С–Р С•Р В»Р С•Р Р†Р С•Р С” РЎвЂљР В°Р В±Р В»Р С‘РЎвЂ РЎвЂ№
                        Rectangle {
                            Layout.fillWidth: true
                            height: 30
                            color: "#e8e8e8"
                            RowLayout {
                                anchors.fill: parent
                                spacing: 0
                                Repeater {
                                    model: ["#", "Модель", "Инв. №", "Дата начала", "Дата продажи", "Дней", "Покупатель", "Себестоимость реальная", "Себестоимость налогоуплачиваемая", "Цена продажи", "Прибыль"]
                                    Rectangle {
                                        width: index === 0 ? 50 : index === 1 ? 150 : index === 2 ? 100 : index === 3 ? 110 : index === 4 ? 120 : index === 5 ? 70 : index === 6 ? 150 : index === 7 ? 150 : index === 8 ? 190 : index === 9 ? 120 : 100
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
                                            text: model.inv_num || "-"
                                            horizontalAlignment: Text.AlignHCenter
                                            verticalAlignment: Text.AlignVCenter
                                            font.pixelSize: 14
                                        }
                                        Text {
                                            Layout.preferredWidth: 110
                                            text: model.start_date || "-"
                                            horizontalAlignment: Text.AlignHCenter
                                            verticalAlignment: Text.AlignVCenter
                                            font.pixelSize: 14
                                        }
                                        Text {
                                            Layout.preferredWidth: 120
                                            text: model.sale_date || "-"
                                            horizontalAlignment: Text.AlignHCenter
                                            verticalAlignment: Text.AlignVCenter
                                            font.pixelSize: 14
                                        }
                                        Text {
                                            Layout.preferredWidth: 70
                                            text: model.days_to_sale !== undefined && model.days_to_sale !== null ? model.days_to_sale : "-"
                                            horizontalAlignment: Text.AlignHCenter
                                            verticalAlignment: Text.AlignVCenter
                                            font.pixelSize: 14
                                        }
                                        Text {
                                            Layout.preferredWidth: 150
                                            text: model.buyer || "-"
                                            horizontalAlignment: Text.AlignHCenter
                                            verticalAlignment: Text.AlignVCenter
                                            font.pixelSize: 14
                                        }
                                        Text {
                                            Layout.preferredWidth: 150
                                            text: model.real_cost !== undefined ? model.real_cost.toFixed(2) + " руб." : "-"
                                            horizontalAlignment: Text.AlignHCenter
                                            verticalAlignment: Text.AlignVCenter
                                            font.pixelSize: 14
                                        }
                                        Text {
                                            Layout.preferredWidth: 190
                                            text: model.taxable_cost !== undefined ? model.taxable_cost.toFixed(2) + " руб." : "-"
                                            horizontalAlignment: Text.AlignHCenter
                                            verticalAlignment: Text.AlignVCenter
                                            font.pixelSize: 14
                                        }
                                        Text {
                                            Layout.preferredWidth: 120
                                            text: model.sale_price ? model.sale_price.toFixed(2) + " руб." : "-"
                                            horizontalAlignment: Text.AlignHCenter
                                            verticalAlignment: Text.AlignVCenter
                                            font.pixelSize: 14
                                        }
                                        Text {
                                            Layout.preferredWidth: 100
                                            text: model.profit ? model.profit.toFixed(2) + " руб." : "-"
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
                                            "produced_date": item.produced_date !== undefined ? item.produced_date : "",
                                            "start_date": item.start_date !== undefined ? item.start_date : "",
                                            "indirect_cost": item.indirect_cost !== undefined ? item.indirect_cost : 0,
                                            "real_cost": item.real_cost !== undefined ? item.real_cost : 0,
                                            "taxable_cost": item.taxable_cost !== undefined ? item.taxable_cost : 0,
                                            "sale_date": item.sale_date !== undefined ? item.sale_date : "",
                                            "days_to_sale": item.days_to_sale !== undefined ? item.days_to_sale : null,
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
                            text: "Проданных станков нет"
                            color: "#666"
                        }

                        // Р С™Р СњР С›Р СџР С™Р С’ Р вЂ™Р С›Р вЂ”Р вЂ™Р В Р С’Р СћР С’
                        RowLayout {
                            Layout.fillWidth: true
                            Button {
                                text: "Изменить"
                                enabled: soldTab.selectedSoldId > 0
                                highlighted: soldTab.selectedSoldId > 0
                                onClicked: {
                                    if (soldTab.selectedSoldRow >= 0) {
                                        var row = soldListModel.get(soldTab.selectedSoldRow)
                                        soldEditInvField.text = row.inv_num || ""
                                        soldEditBuyerField.text = row.buyer || ""
                                        soldEditSaleDateField.text = row.sale_date || ""
                                        soldEditProducedDateField.text = row.produced_date || ""
                                        soldEditIndirectField.text = row.indirect_cost !== undefined ? Number(row.indirect_cost).toFixed(2) : "0.00"
                                        editSoldDialog.open()
                                    }
                                }
                            }
                            Button {
                                text: "Вернуть на склад"
                                enabled: soldTab.selectedSoldId > 0
                                highlighted: soldTab.selectedSoldId > 0
                                onClicked: returnToStockDialog.open()
                            }
                        }
                    }

                    // Р вЂќР ВР С’Р вЂєР С›Р вЂњ Р СџР С›Р вЂќР СћР вЂ™Р вЂўР В Р вЂ“Р вЂќР вЂўР СњР ВР Р‡ Р вЂ™Р С›Р вЂ”Р вЂ™Р В Р С’Р СћР С’
                    Dialog {
                        id: editSoldDialog
                        title: "Изменить проданный станок"
                        standardButtons: Dialog.Ok | Dialog.Cancel
                        width: 480
                        height: 320

                        ColumnLayout {
                            anchors.fill: parent
                            spacing: 8
                            Label { text: "Инвентарный номер:" }
                            TextField { id: soldEditInvField; Layout.fillWidth: true }
                            Label { text: "Покупатель:" }
                            TextField { id: soldEditBuyerField; Layout.fillWidth: true }
                            Label { text: "Дата продажи (ГГГГ-ММ-ДД):" }
                            TextField { id: soldEditSaleDateField; Layout.fillWidth: true }
                            Label { text: "Production end date (YYYY-MM-DD):" }
                            TextField { id: soldEditProducedDateField; Layout.fillWidth: true }
                            Label { text: "Indirect expenses:" }
                            TextField { id: soldEditIndirectField; Layout.fillWidth: true; validator: DoubleValidator { bottom: 0 } }
                        }

                        onAccepted: {
                            if (soldTab.selectedSoldId > 0) {
                                if (backend.updateSoldMachine(
                                    soldTab.selectedSoldId,
                                    soldEditInvField.text,
                                    soldEditBuyerField.text,
                                    soldEditSaleDateField.text,
                                    soldEditProducedDateField.text,
                                    parseFloat(soldEditIndirectField.text || "0")
                                )) {
                                    soldListView.loadSoldMachines()
                                    finishedModel.refresh()
                                }
                            }
                        }
                    }

                    Dialog {
                        id: returnToStockDialog
                        title: "Вернуть станок на склад"
                        standardButtons: Dialog.Yes | Dialog.No
                        width: 450
                        height: 180

                        Label {
                            text: "Вернуть проданный станок на склад?\n\n" +
                                "- Станок получит статус 'На складе'\n" +
                                "- Запись о продаже будет удалена\n" +
                                "- Покупатель и дата продажи будут очищены"
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
                                "produced_date": item.produced_date !== undefined ? item.produced_date : "",
                                "start_date": item.start_date !== undefined ? item.start_date : "",
                                "indirect_cost": item.indirect_cost !== undefined ? item.indirect_cost : 0,
                                "real_cost": item.real_cost !== undefined ? item.real_cost : 0,
                                "taxable_cost": item.taxable_cost !== undefined ? item.taxable_cost : 0,
                                "sale_date": item.sale_date !== undefined ? item.sale_date : "",
                                "days_to_sale": item.days_to_sale !== undefined ? item.days_to_sale : null,
                                "buyer": item.buyer !== undefined ? item.buyer : "",
                                "sale_price": item.sale_price !== undefined ? item.sale_price : 0,
                                "profit": item.profit !== undefined ? item.profit : 0
                            })
                        }
                    }
                }
            }
        
                    // ========== Р вЂќР ВР С’Р вЂєР С›Р вЂњР В ==========
            Dialog {
                id: sellDialog
                title: "Sell machine"
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
                        placeholderText: "Enter inventory number or leave empty"
                    }

                    Label { text: "Дата продажи:" }
                    TextField {
                        id: sellDateField
                        Layout.fillWidth: true
                        placeholderText: "YYYY-MM-DD (Enter = today)"
                        text: Qt.formatDate(new Date(), "yyyy-MM-dd")
                    }

                    Label { text: "Покупатель:" }
                    TextField {
                        id: buyerField
                        Layout.fillWidth: true
                        placeholderText: "Имя покупателя или компания"
                    }

                    Label { text: "Цена продажи (руб.):" }
                    TextField {
                        id: sellPriceField
                        Layout.fillWidth: true
                        validator: DoubleValidator { bottom: 0.01 }
                        placeholderText: "Enter sale price"
                    }

                    // Р вЂР вЂєР С›Р С™ Р СћР В Р С’Р СњР РЋР СџР С›Р В Р СћР ВР В Р С›Р вЂ™Р С™Р В
                    GroupBox {
                        Layout.fillWidth: true
                        title: "Shipping"

                        ColumnLayout {
                            anchors.fill: parent
                            spacing: 10

                            ButtonGroup { id: shippingGroup }

                            RadioButton {
                                id: shippingFreeRadio
                                text: "Бесплатная доставка (включена в стоимость)"
                                checked: true
                                ButtonGroup.group: shippingGroup
                            }

                            RadioButton {
                                id: shippingPaidRadio
                                text: "Платная доставка (добавляется как косвенный расход)"
                                ButtonGroup.group: shippingGroup
                            }

                            RowLayout {
                                visible: shippingPaidRadio.checked
                                Layout.fillWidth: true
                                
                                Label { text: "Shipping cost (rub.):" }
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
                                text: "Все расходы на доставку будут добавлены к стоимости станка и сумме продажи."
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
                        text: "Enter sale price and buyer."
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
                title: "Детали себестоимости"
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
                            width: parent.availableWidth
                            readOnly: true
                            wrapMode: TextArea.Wrap
                            font.family: "Courier New"
                            font.pixelSize: 12
                            text: "Загрузка деталей себестоимости..."
                        }
                    }
                }

                onOpened: {
                    var details = backend.getMachineCostDetails(tab2Root.selectedFinishedId)
                    costDetailsHeader.text = details.header
                    costDetailsText.text = details.breakdown
                }
            }

            // Р вЂќР ВР С’Р вЂєР С›Р вЂњ Р В Р С’Р вЂ”Р вЂР С›Р В Р С™Р В Р РЋР СћР С’Р СњР С™Р С’
            Dialog {
                id: disassembleDialog
                title: "Разобрать станок"
                standardButtons: Dialog.Yes | Dialog.No
                width: 550
                height: 400

                ColumnLayout {
                    anchors.fill: parent
                    spacing: 10

                    Label {
                        text: "Разобрать станок и вернуть материалы на склад?"
                        font.bold: true
                        font.pixelSize: 16
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        height: 1
                        color: "#ccc"
                    }

                    Label {
                        text: "What will happen:"
                        font.bold: true
                    }

                    ScrollView {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        clip: true

                        TextArea {
                            id: disassemblePreviewText
                            width: parent.availableWidth
                            readOnly: true
                            wrapMode: TextArea.Wrap
                            font.family: "Courier New"
                            font.pixelSize: 12
                            text: "Загрузка..."
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        height: 1
                        color: "#ccc"
                    }

                    Label {
                        text: "Внимание: это действие нельзя отменить!"
                        color: "#d9534f"
                        font.bold: true
                    }
                }

                onAboutToShow: {
                    var preview = backend.getDisassemblePreview(tab2Root.selectedFinishedId)
                    disassemblePreviewText.text = preview
                }

                onAccepted: {
                    if (backend.disassembleMachine(tab2Root.selectedFinishedId)) {
                        tab2Root.selectedRow = -1
                        tab2Root.selectedFinishedId = -1
                        finishedModel.refresh()
                    }
                }
            }

            Dialog {
                id: editFinishedDialog
                title: "Изменить готовый станок"
                standardButtons: Dialog.Ok | Dialog.Cancel
                width: 520
                height: 520

                ColumnLayout {
                    anchors.fill: parent
                    spacing: 8

                    Label { text: "Модель:" }
                    TextField { id: editFinishedModelField; Layout.fillWidth: true }

                    Label { text: "Инвентарный номер:" }
                    TextField { id: editFinishedInvField; Layout.fillWidth: true }

                    Label { text: "Дата начала производства (ГГГГ-ММ-ДД):" }
                    TextField { id: editFinishedStartDateField; Layout.fillWidth: true; placeholderText: "2026-04-01" }

                    Label { text: "Дата окончания производства (ГГГГ-ММ-ДД):" }
                    TextField { id: editFinishedDateField; Layout.fillWidth: true; placeholderText: "2026-04-28" }

                    Label { text: "Себестоимость:" }
                    TextField { id: editFinishedCostField; Layout.fillWidth: true; validator: DoubleValidator { bottom: 0 } }

                    Label { text: "Косвенные расходы:" }
                    TextField { id: editFinishedIndirectField; Layout.fillWidth: true; validator: DoubleValidator { bottom: 0 } }

                    Label { text: "Примечание:" }
                    TextField { id: editFinishedNotesField; Layout.fillWidth: true }
                }

                onAccepted: {
                    if (tab2Root.selectedFinishedId > 0 && editFinishedModelField.text && editFinishedDateField.text && editFinishedStartDateField.text && editFinishedCostField.text && editFinishedIndirectField.text) {
                        if (backend.updateFinishedGood(
                            tab2Root.selectedFinishedId,
                            editFinishedModelField.text,
                            editFinishedInvField.text,
                            editFinishedStartDateField.text,
                            editFinishedDateField.text,
                            parseFloat(editFinishedCostField.text),
                            parseFloat(editFinishedIndirectField.text),
                            editFinishedNotesField.text
                        )) {
                            finishedModel.refresh()
                        }
                    }
                }
            }

            // Р вЂќР ВР С’Р вЂєР С›Р вЂњ Р Р€Р вЂќР С’Р вЂєР вЂўР СњР ВР Р‡ Р РЋР СћР С’Р СњР С™Р С’
            Dialog {
                id: deleteMachineDialog
                title: "Удалить станок"
                standardButtons: Dialog.Yes | Dialog.No
                width: 500
                height: 250

                ColumnLayout {
                    anchors.fill: parent
                    spacing: 15

                    Label {
                        text: "Удалить станок?"
                        font.bold: true
                        font.pixelSize: 16
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        height: 1
                        color: "#ccc"
                    }

                    Label {
                        text: "This machine will be removed from the database.\n" +
                            "Материалы не будут возвращены на склад.\n" +
                            "Production history will be deleted\n" +
                                "This action cannot be undone"
                        wrapMode: Text.WordWrap
                        Layout.fillWidth: true
                    }


                    Label {
                        text: "If you want to keep the materials, use disassemble instead of delete."
                        color: "#d9534f"
                        font.bold: true
                        wrapMode: Text.WordWrap
                        Layout.fillWidth: true
                    }
                }

                onAccepted: {
                    if (backend.deleteMachine(tab2Root.selectedFinishedId)) {
                        tab2Root.selectedRow = -1
                        tab2Root.selectedFinishedId = -1
                        finishedModel.refresh()
                    }
                }
            }
            
            Component.onCompleted: {
                finishedModel.refresh()
            }
        }
        
        // ================= Р вЂ™Р С™Р вЂєР С’Р вЂќР С™Р С’ 3: Р В Р вЂўР вЂќР С’Р С™Р СћР С›Р В  Р СљР С›Р вЂќР вЂўР вЂєР вЂўР в„ў =================
        Item {
            id: tab3Root
            property int selectedMachineId: -1
            property string selectedMachineModel: ""
            property int selectedSpecRow: -1   // РЎРѓР Р†Р С•РЎвЂ РЎРѓР Р†Р С•Р в„–РЎРѓРЎвЂљР Р†Р С• Р Т‘Р В»РЎРЏ Р С•РЎвЂљРЎРѓР В»Р ВµР В¶Р С‘Р Р†Р В°Р Р…Р С‘РЎРЏ РЎРѓРЎвЂљРЎР‚Р С•Р С”Р С‘ Р Р† РЎРѓР С—Р ВµРЎвЂ Р С‘РЎвЂћР С‘Р С”Р В°РЎвЂ Р С‘Р С‘
            property var allMaterialsForSpec: []

            function refreshMachineSpec() {
                specModel.refresh()
                machineModel.refresh()
                modelCountText.text = "Моделей станков: " + machineModel.rowCount()
            }

            function openEditQuantityDialog(rowIndex) {
                if (rowIndex < 0) {
                    return
                }
                var matId = specModel.getMaterialId(rowIndex)
                var curQty = specModel.getQuantity(rowIndex)
                if (matId <= 0) {
                    return
                }
                selectedSpecRow = rowIndex
                editQtyDialog.materialId = matId
                editQtyDialog.currentQty = curQty
                editQtyDialog.open()
            }

            function removeSpecMaterial(rowIndex) {
                if (rowIndex < 0) {
                    return
                }
                var matId = specModel.getMaterialId(rowIndex)
                if (matId > 0) {
                    backend.removeMaterialFromMachine(selectedMachineId, matId)
                    selectedSpecRow = -1
                    refreshMachineSpec()
                }
            }

            function loadMaterialsForSpec() {
                allMaterialsForSpec = backend.getMaterialsList()
                filterMaterialsForSpec(materialSearchField.text)
            }

            function filterMaterialsForSpec(query) {
                filteredMaterialsModel.clear()
                var search = (query || "").toLowerCase().trim()
                for (var i = 0; i < allMaterialsForSpec.length; i++) {
                    var item = allMaterialsForSpec[i]
                    var name = (item.name || "")
                    if (!search || name.toLowerCase().indexOf(search) !== -1) {
                        filteredMaterialsModel.append({
                            "id": item.id,
                            "name": item.name
                        })
                    }
                }
                if (filteredMaterialsModel.count > 0) {
                    materialComboSpec.currentIndex = 0
                } else {
                    materialComboSpec.currentIndex = -1
                }
            }

            MachineListModel { id: machineModel }
            MachineSpecModel { id: specModel }

            RowLayout {
                anchors.fill: parent
                anchors.margins: 10
                spacing: 10

                // Р вЂєР ВµР Р†Р В°РЎРЏ РЎвЂЎР В°РЎРѓРЎвЂљРЎРЉ РІР‚вЂќ РЎРѓР С—Р С‘РЎРѓР С•Р С” Р СР С•Р Т‘Р ВµР В»Р ВµР в„–
                ColumnLayout {
                    Layout.preferredWidth: 300
                    Layout.fillHeight: true
                    spacing: 5

                    RowLayout {
                        Layout.fillWidth: true
                        TextField {
                            id: modelSearchField
                            Layout.fillWidth: true
                            placeholderText: "Поиск моделей..."
                            onTextChanged: machineModel.setFilter(text)
                        }
                        Button {
                            text: "Обновить"
                            onClicked: {
                                modelSearchField.clear()
                                machineModel.setFilter("")
                                machineModel.refresh()
                                modelCountText.text = "Моделей станков: " + machineModel.rowCount()
                            }
                        }
                    }

                    Label {
                        id: modelCountText
                        text: "Моделей станков: 0"
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
                                    text: display.cost.toFixed(2) + " руб."
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
                                    tab3Root.selectedSpecRow = -1  // РЎРѓР В±РЎР‚Р В°РЎРѓРЎвЂ№Р Р†Р В°Р ВµР С Р Р†РЎвЂ№Р Т‘Р ВµР В»Р ВµР Р…Р С‘Р Вµ Р Р† РЎРѓР С—Р ВµРЎвЂ Р С‘РЎвЂћР С‘Р С”Р В°РЎвЂ Р С‘Р С‘
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

                    Button {
                        Layout.fillWidth: true
                        text: "Начать производство"
                        enabled: tab3Root.selectedMachineId > 0
                        highlighted: true
                        onClicked: startProductionDialog.open()
                    }
                }

                // Р СџРЎР‚Р В°Р Р†Р В°РЎРЏ РЎвЂЎР В°РЎРѓРЎвЂљРЎРЉ РІР‚вЂќ РЎРѓР С—Р ВµРЎвЂ Р С‘РЎвЂћР С‘Р С”Р В°РЎвЂ Р С‘РЎРЏ
                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    spacing: 5

                    Label {
                        text: tab3Root.selectedMachineId > 0 ? "Спецификация станка: " + tab3Root.selectedMachineModel : "Выберите станок"
                        font.bold: true
                    }

                    // Р вЂ”Р В°Р С–Р С•Р В»Р С•Р Р†Р С•Р С” РЎвЂљР В°Р В±Р В»Р С‘РЎвЂ РЎвЂ№ РЎРѓР С—Р ВµРЎвЂ Р С‘РЎвЂћР С‘Р С”Р В°РЎвЂ Р С‘Р С‘
                    Rectangle {
                        Layout.fillWidth: true
                        height: 30
                        color: "#e8e8e8"
                        visible: tab3Root.selectedMachineId > 0
                        RowLayout {
                            anchors.fill: parent
                            spacing: 0
                            Repeater {
                                model: ["#", "Материал", "Кол-во", "Цена/ед.", "Сумма"]
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

                        delegate: Rectangle {
                            implicitHeight: 35
                            border.color: "#ddd"
                            color: {
                                if (tab3Root.selectedSpecRow === row) return "#b3d9ff"
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
                                acceptedButtons: Qt.LeftButton | Qt.RightButton
                                onClicked: {
                                    tab3Root.selectedSpecRow = row
                                }
                                onPressed: function(mouse) {
                                    if (mouse.button === Qt.RightButton) {
                                        tab3Root.selectedSpecRow = row
                                        specRowMenu.popup()
                                    }
                                }
                            }

                            Menu {
                                id: specRowMenu

                                MenuItem {
                                    text: "Изменить количество"
                                    onTriggered: tab3Root.openEditQuantityDialog(row)
                                }

                                MenuItem {
                                    text: "Удалить материал"
                                    onTriggered: tab3Root.removeSpecMaterial(row)
                                }
                            }
                        }
                    }

                    // Р ВР СћР С›Р вЂњР С›Р вЂ™Р С’Р Р‡ Р РЋР Р€Р СљР СљР С’
                    Rectangle {
                        Layout.fillWidth: true
                        height: 35
                        color: "#fff9e6"
                        border.color: "#ccc"
                        visible: tab3Root.selectedMachineId > 0 && specModel.rowCount() > 0
                        
                        RowLayout {
                            Layout.fillWidth: true
                            anchors.margins: 5

                            Label {
                                text: "Итого:"
                                font.bold: true
                                font.pixelSize: 14
                                Layout.fillWidth: true
                            }

                            Label {
                                id: totalCostLabel
                                text: calculateTotalCost() + " руб."
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
                                        totalCostLabel.text = totalCostLabel.calculateTotalCost() + " руб."
                                    }
                                }
                            }
                        }
                    }

                    Label {
                        visible: tab3Root.selectedMachineId > 0 && specModel.rowCount() === 0
                        text: "Материалы ещё не добавлены. Добавьте материалы в спецификацию станка."
                        color: "#666"
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 5

                        Button {
                            text: "Добавить материал"
                            onClicked: addMaterialToSpecDialog.open()
                        }

                        Button {
                            text: "Изменить количество"
                            enabled: tab3Root.selectedSpecRow >= 0
                            highlighted: tab3Root.selectedSpecRow >= 0
                            onClicked: tab3Root.openEditQuantityDialog(tab3Root.selectedSpecRow)
                        }

                        Button {
                            text: "Удалить материал"
                            enabled: tab3Root.selectedSpecRow >= 0
                            highlighted: tab3Root.selectedSpecRow >= 0
                            onClicked: tab3Root.removeSpecMaterial(tab3Root.selectedSpecRow)
                        }
                    }
                }
            }
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
                        modelCountText.text = "Моделей станков: " + machineModel.rowCount()
                        newModelName.clear()
                    }
                }
            }

            Dialog {
                id: deleteModelDialog
                title: "Удалить модель станка"
                standardButtons: Dialog.Yes | Dialog.No
                width: 400
                height: 150
                Label {
                    text: "Удалить модель станка \"" + tab3Root.selectedMachineModel + "\"?\n\nБудет удалена модель и вся связанная спецификация."
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
                        modelCountText.text = "Моделей станков: " + machineModel.rowCount()
                    }
                }
            }

            Dialog {
                id: startProductionDialog
                title: "Начать производство"
                standardButtons: Dialog.Ok | Dialog.Cancel
                width: 500
                height: 250
                ColumnLayout {
                    anchors.fill: parent
                    spacing: 10

                    Label {
                        text: "Станок: " + tab3Root.selectedMachineModel
                        font.bold: true
                    }

                    Label { text: "ID станка:" }
                    TextField {
                        id: productionInventoryNumberField
                        Layout.fillWidth: true
                        placeholderText: "Введите ID или инвентарный номер"
                    }

                    Label { text: "Примечание к производству (необязательно):" }
                    TextField {
                        id: productionNotesField
                        Layout.fillWidth: true
                        placeholderText: "Например: заказ клиента, срочный заказ..."
                    }

                    Label {
                        text: "Это примечание будет сохранено в записи производства."
                        wrapMode: Text.WordWrap
                        color: "#666"
                        font.pixelSize: 11
                    }
                }
                onAccepted: {
                    if (backend.startProduction(tab3Root.selectedMachineId, productionInventoryNumberField.text, productionNotesField.text)) {
                        productionInventoryNumberField.clear()
                        productionNotesField.clear()
                    }
                }
            }

            Dialog {
                id: addMaterialToSpecDialog
                title: "Добавить материал"
                standardButtons: Dialog.Ok | Dialog.Cancel
                width: 500
                height: 280
                ColumnLayout {
                    anchors.fill: parent
                    Label { text: "Поиск по складу:" }
                    TextField {
                        id: materialSearchField
                        Layout.fillWidth: true
                        placeholderText: "Введите название материала..."
                        onTextChanged: tab3Root.filterMaterialsForSpec(text)
                    }
                    Label { text: "Материал:" }
                    ComboBox {
                        id: materialComboSpec
                        Layout.fillWidth: true
                        model: ListModel { id: filteredMaterialsModel }
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
                onOpened: {
                    materialSearchField.clear()
                    tab3Root.loadMaterialsForSpec()
                }
                onAccepted: {
                    if (materialComboSpec.currentValue && specQty.text) {
                        backend.addMaterialToMachine(tab3Root.selectedMachineId, materialComboSpec.currentValue, parseFloat(specQty.text))
                        tab3Root.refreshMachineSpec()
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
                        tab3Root.refreshMachineSpec()
                    }
                }
            }

            Component.onCompleted: {
                machineModel.refresh()
                modelCountText.text = "Моделей станков: " + machineModel.rowCount()
            }
        }
    }
}
