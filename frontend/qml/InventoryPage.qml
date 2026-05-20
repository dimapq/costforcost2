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
        TabButton { text: "Раскрой плит" }
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
            property string selectedMaterialUnit: ""
            property real selectedMaterialQty: 0
            property real selectedMaterialPrice: 0
            property string selectedMaterialSource: ""
            property string selectedMaterialNotes: ""
            property string selectedMaterialUpdatedDate: ""

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
                    Button {
                        text: "Редактировать материал"
                        enabled: materialsTab.selectedMaterialId > 0
                        onClicked: {
                            editMaterialNameField.text = materialsTab.selectedMaterialName
                            editMaterialUnitField.text = materialsTab.selectedMaterialUnit
                            editMaterialQtyField.text = materialsTab.selectedMaterialQty.toFixed(2)
                            editMaterialPriceField.text = materialsTab.selectedMaterialPrice > 0 ? materialsTab.selectedMaterialPrice.toFixed(2) : ""
                            editMaterialSourceField.text = materialsTab.selectedMaterialSource
                            editMaterialNotesField.text = materialsTab.selectedMaterialNotes
                            editMaterialUpdatedDateField.text = materialsTab.selectedMaterialUpdatedDate || new Date().toISOString().slice(0, 10)
                            editMaterialReasonField.clear()
                            editMaterialDialog.open()
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
                            model: ["ID", "Название", "Остаток", "Цена за ед.", "Сумма", "Откуда взят", "Примечание", "Дата обновления"]
                            Rectangle {
                                width: index === 0 ? 50 : index === 1 ? 220 : index === 2 ? 90 : index === 3 ? 110 : index === 4 ? 110 : index === 5 ? 220 : index === 6 ? 260 : 130
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
                        if (column === 6) return 260
                        return 130
                    }
                    delegate: Rectangle {
                        implicitHeight: 34
                        border.color: "#ddd"
                        color: materialsTab.selectedMaterialRow === row ? "#b3d9ff" : (row % 2 ? "#f9f9f9" : "white")
                        Text {
                            anchors.fill: parent
                            anchors.margins: 6
                            text: display === undefined || display === null ? "" : display
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
                                materialsTab.selectedMaterialUnit = item.unit || ""
                                materialsTab.selectedMaterialQty = item.quantity || 0
                                materialsTab.selectedMaterialPrice = item.price || 0
                                materialsTab.selectedMaterialSource = item.source || ""
                                materialsTab.selectedMaterialNotes = item.notes || ""
                                materialsTab.selectedMaterialUpdatedDate = item.updated_date || ""
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
                height: 510
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
                    Label { text: "Дата обновления (ГГГГ-ММ-ДД):" }
                    TextField { id: matUpdatedDate; Layout.fillWidth: true; text: new Date().toISOString().slice(0, 10); placeholderText: "2026-05-18" }
                    CheckBox { id: matIsCash; text: "Наличка" }
                }
                onAccepted: {
                    if (matName.text && matPrice.text && matQty.text) {
                        backend.addMaterial(
                            matName.text,
                            matUnit.text,
                            parseFloat(matPrice.text),
                            parseFloat(matQty.text),
                            matSource.text,
                            matNote.text,
                            matUpdatedDate.text,
                            matIsCash.checked
                        )
                        materialModel.refresh()
                        matName.clear()
                        matUnit.text = "шт"
                        matPrice.clear()
                        matQty.clear()
                        matSource.clear()
                        matNote.clear()
                        matUpdatedDate.text = new Date().toISOString().slice(0, 10)
                        matIsCash.checked = false
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

            Dialog {
                id: editMaterialDialog
                title: "Редактировать материал"
                standardButtons: Dialog.Ok | Dialog.Cancel
                width: 520
                height: 570

                ColumnLayout {
                    anchors.fill: parent
                    spacing: 8

                    Label { text: "Название:" }
                    TextField { id: editMaterialNameField; Layout.fillWidth: true }

                    Label { text: "Единица измерения:" }
                    TextField { id: editMaterialUnitField; Layout.fillWidth: true; placeholderText: "шт, м, кг..." }

                    Label { text: "Остаток на складе:" }
                    TextField { id: editMaterialQtyField; Layout.fillWidth: true; validator: DoubleValidator { bottom: 0 } }

                    Label { text: "Цена за единицу (оставьте пустым, если не менять):" }
                    TextField { id: editMaterialPriceField; Layout.fillWidth: true; validator: DoubleValidator { bottom: 0 } }

                    Label { text: "Откуда взят:" }
                    TextField { id: editMaterialSourceField; Layout.fillWidth: true }

                    Label { text: "Примечание:" }
                    TextField { id: editMaterialNotesField; Layout.fillWidth: true }

                    Label { text: "Дата обновления (ГГГГ-ММ-ДД):" }
                    TextField { id: editMaterialUpdatedDateField; Layout.fillWidth: true; placeholderText: "2026-05-18" }

                    Label { text: "Причина/комментарий к изменению:" }
                    TextField { id: editMaterialReasonField; Layout.fillWidth: true; placeholderText: "Например: уточнение карточки материала" }
                }

                onAccepted: {
                    if (materialsTab.selectedMaterialId > 0 && editMaterialNameField.text && editMaterialQtyField.text) {
                        if (backend.updateMaterial(
                            materialsTab.selectedMaterialId,
                            editMaterialNameField.text,
                            editMaterialUnitField.text,
                            parseFloat(editMaterialQtyField.text),
                            editMaterialSourceField.text,
                            editMaterialNotesField.text,
                            editMaterialUpdatedDateField.text,
                            editMaterialPriceField.text ? parseFloat(editMaterialPriceField.text) : 0,
                            editMaterialReasonField.text
                        )) {
                            materialModel.refresh()
                            materialsTab.selectedMaterialRow = -1
                            materialsTab.selectedMaterialId = -1
                            materialsTab.selectedMaterialName = ""
                            materialsTab.selectedMaterialUnit = ""
                            materialsTab.selectedMaterialQty = 0
                            materialsTab.selectedMaterialPrice = 0
                            materialsTab.selectedMaterialSource = ""
                            materialsTab.selectedMaterialNotes = ""
                            materialsTab.selectedMaterialUpdatedDate = ""
                        }
                    }
                }
            }
        }

        // ================= ВКЛАДКА РАСКРОЙ ПЛИТ =================
        Item {
            id: plateCutTab
            property int selectedLotRow: -1
            property int selectedPurchaseId: -1
            property string selectedMaterialName: ""
            property string selectedUnit: ""
            property real selectedRemaining: 0
            property real selectedPrice: 0
            property string selectedUpdatedDate: ""

            ListModel { id: plateLotsModel }
            ListModel { id: platePartChoicesModel }

            function reloadLots() {
                plateLotsModel.clear()
                var rows = backend.getAreaMaterialLots()
                for (var i = 0; i < rows.length; i++) {
                    var lot = rows[i] || {}
                    plateLotsModel.append({
                        purchase_id: lot.purchase_id !== undefined ? lot.purchase_id : -1,
                        material_id: lot.material_id !== undefined ? lot.material_id : -1,
                        material_name: lot.material_name || "",
                        unit: lot.unit || "",
                        remaining_quantity: lot.remaining_quantity !== undefined ? lot.remaining_quantity : 0,
                        original_quantity: lot.original_quantity !== undefined ? lot.original_quantity : 0,
                        price_per_unit: lot.price_per_unit !== undefined ? lot.price_per_unit : 0,
                        purchase_date: lot.purchase_date || "",
                        source: lot.source || "",
                        updated_date: lot.updated_date || "",
                        notes: lot.notes || ""
                    })
                }
                if (plateCutTab.selectedPurchaseId > 0) {
                    plateCutTab.reloadPartChoices()
                } else {
                    platePartChoicesModel.clear()
                }
            }

            function reloadPartChoices() {
                platePartChoicesModel.clear()
                if (plateCutTab.selectedPurchaseId <= 0)
                    return
                var rows = backend.getPlateConversionHistory(plateCutTab.selectedPurchaseId)
                for (var i = 0; i < rows.length; i++) {
                    var item = rows[i] || {}
                    var countText = item.conversion_count !== undefined ? item.conversion_count : 0
                    platePartChoicesModel.append({
                        target_material_id: item.target_material_id !== undefined ? item.target_material_id : -1,
                        target_name: item.target_name || "",
                        target_unit: item.target_unit || "",
                        source_quantity: item.source_quantity !== undefined ? item.source_quantity : 0,
                        target_quantity: item.target_quantity !== undefined ? item.target_quantity : 0,
                        conversion_count: countText,
                        last_converted_at: item.last_converted_at || "",
                        notes: item.notes || "",
                        choice_label: (item.target_name || "") + " (" + countText + " раз)"
                    })
                }
            }

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 10
                spacing: 10

                RowLayout {
                    Layout.fillWidth: true
                    Label { text: "Плиты и листы по партиям"; font.bold: true; font.pixelSize: 18 }
                    Item { Layout.fillWidth: true }
                    Button { text: "Добавить плиту"; onClicked: addPlateDialog.open() }
                    Button { text: "Обновить"; onClicked: plateCutTab.reloadLots() }
                    Button {
                        text: "Сделать деталь"
                        enabled: plateCutTab.selectedPurchaseId > 0
                        highlighted: plateCutTab.selectedPurchaseId > 0
                        onClicked: {
                            lotSourceLabel.text = "Партия #" + plateCutTab.selectedPurchaseId + ": " + plateCutTab.selectedMaterialName +
                                " | Остаток: " + plateCutTab.selectedRemaining.toFixed(4) + " " + plateCutTab.selectedUnit +
                                " | Цена: " + plateCutTab.selectedPrice.toFixed(2) + " руб./" + plateCutTab.selectedUnit
                            lotPartName.clear()
                            lotAreaQty.clear()
                            lotPartQty.text = "1"
                            lotPartUnit.text = "шт"
                            lotUpdatedDate.text = plateCutTab.selectedUpdatedDate || new Date().toISOString().slice(0, 10)
                            lotNotes.clear()
                            lotUseExisting.checked = platePartChoicesModel.count > 0
                            lotExistingPart.currentIndex = platePartChoicesModel.count > 0 ? 0 : -1
                            if (platePartChoicesModel.count > 0) {
                                var firstPart = platePartChoicesModel.get(0)
                                lotPartName.text = firstPart.target_name || ""
                                lotPartUnit.text = firstPart.target_unit || "шт"
                            } else {
                                lotPartName.clear()
                                lotPartUnit.text = "шт"
                            }
                            lotConvertStatus.text = ""
                            convertLotDialog.open()
                        }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    height: 34
                    color: "#e8e8e8"
                    border.color: "#ccc"
                    Row {
                        anchors.fill: parent
                        spacing: 0
                        Repeater {
                            model: ["ID партии", "Материал", "Остаток", "Было", "Цена", "Дата", "Откуда", "Примечание"]
                            Rectangle {
                                width: index === 0 ? 90 : index === 1 ? 230 : index === 2 ? 110 : index === 3 ? 100 : index === 4 ? 100 : index === 5 ? 110 : index === 6 ? 180 : 260
                                height: 34
                                color: "transparent"
                                Text { anchors.centerIn: parent; text: modelData; font.pixelSize: 13; font.bold: true }
                            }
                        }
                    }
                }

                ListView {
                    id: plateLotsView
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true
                    model: plateLotsModel
                    delegate: Rectangle {
                        width: plateLotsView.width
                        height: 36
                        border.color: "#ddd"
                        color: plateCutTab.selectedLotRow === index ? "#b3d9ff" : (index % 2 ? "#f9f9f9" : "white")
                        Row {
                            anchors.fill: parent
                            spacing: 0
                            Text { width: 90; anchors.verticalCenter: parent.verticalCenter; horizontalAlignment: Text.AlignHCenter; text: model.purchase_id; font.pixelSize: 13 }
                            Text { width: 230; anchors.verticalCenter: parent.verticalCenter; text: model.material_name; elide: Text.ElideRight; font.pixelSize: 13 }
                            Text { width: 110; anchors.verticalCenter: parent.verticalCenter; horizontalAlignment: Text.AlignRight; text: Number(model.remaining_quantity).toFixed(4) + " " + model.unit + "  "; font.pixelSize: 13 }
                            Text { width: 100; anchors.verticalCenter: parent.verticalCenter; horizontalAlignment: Text.AlignRight; text: Number(model.original_quantity).toFixed(4) + "  "; font.pixelSize: 13 }
                            Text { width: 100; anchors.verticalCenter: parent.verticalCenter; horizontalAlignment: Text.AlignRight; text: Number(model.price_per_unit).toFixed(2) + "  "; font.pixelSize: 13 }
                            Text { width: 110; anchors.verticalCenter: parent.verticalCenter; horizontalAlignment: Text.AlignHCenter; text: model.purchase_date; font.pixelSize: 13 }
                            Text { width: 180; anchors.verticalCenter: parent.verticalCenter; text: model.source || "-"; elide: Text.ElideRight; font.pixelSize: 13 }
                            Text { width: 260; anchors.verticalCenter: parent.verticalCenter; text: model.notes || "-"; elide: Text.ElideRight; font.pixelSize: 13 }
                        }
                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                plateCutTab.selectedLotRow = index
                                plateCutTab.selectedPurchaseId = model.purchase_id
                                plateCutTab.selectedMaterialName = model.material_name
                                plateCutTab.selectedUnit = model.unit
                                plateCutTab.selectedRemaining = model.remaining_quantity
                                plateCutTab.selectedPrice = model.price_per_unit
                                plateCutTab.selectedUpdatedDate = model.updated_date || ""
                                plateCutTab.reloadPartChoices()
                            }
                        }
                    }
                }

                Label {
                    Layout.fillWidth: true
                    text: "Здесь показаны отдельные партии/плиты. Выбирайте конкретный ID партии, чтобы списать площадь именно из неё."
                    color: "#666"
                    wrapMode: Text.WordWrap
                }
            }

            Dialog {
                id: addPlateDialog
                title: "Добавить плиту"
                standardButtons: Dialog.Ok | Dialog.Cancel
                width: 520
                height: 500

                ColumnLayout {
                    anchors.fill: parent
                    spacing: 10
                    Label { text: "Название плиты:" }
                    TextField { id: plateNameField; Layout.fillWidth: true; placeholderText: "Например: Алюминиевая плита 1200x2400" }
                    Label { text: "Цена за единицу (руб./м²):" }
                    TextField { id: platePriceField; Layout.fillWidth: true; validator: DoubleValidator { bottom: 0.0001 } }
                    Label { text: "Площадь / количество (м²):" }
                    TextField { id: plateQtyField; Layout.fillWidth: true; text: "1"; validator: DoubleValidator { bottom: 0.0001 } }
                    Label { text: "Источник:" }
                    TextField { id: plateSourceField; Layout.fillWidth: true; placeholderText: "Поставщик, сайт, ссылка" }
                    Label { text: "Дата обновления:" }
                    TextField { id: plateDateField; Layout.fillWidth: true; text: new Date().toISOString().slice(0, 10); placeholderText: "2026-05-19" }
                    Label { text: "Примечание:" }
                    TextField { id: plateNotesField; Layout.fillWidth: true; placeholderText: "Например: лист под раскрой" }
                    CheckBox { id: plateCashField; text: "Наличка" }
                    Label { id: plateAddStatus; Layout.fillWidth: true; wrapMode: Text.WordWrap; color: "#b94a48"; text: "" }
                }

                onAccepted: {
                    if (!plateNameField.text || !platePriceField.text || !plateQtyField.text) {
                        plateAddStatus.text = "Заполните название, цену и количество"
                        addPlateDialog.open()
                        return
                    }
                    var ok = backend.addPlate(
                        plateNameField.text,
                        parseFloat((platePriceField.text || "0").replace(",", ".")),
                        parseFloat((plateQtyField.text || "0").replace(",", ".")),
                        plateSourceField.text,
                        plateNotesField.text,
                        plateDateField.text,
                        plateCashField.checked
                    )
                    if (ok) {
                        materialModel.refresh()
                        plateCutTab.reloadLots()
                        plateNameField.clear()
                        platePriceField.clear()
                        plateQtyField.text = "1"
                        plateSourceField.clear()
                        plateNotesField.clear()
                        plateDateField.text = new Date().toISOString().slice(0, 10)
                        plateCashField.checked = false
                    } else {
                        plateAddStatus.text = "Не удалось добавить плиту"
                        addPlateDialog.open()
                    }
                }
            }

            Dialog {
                id: convertLotDialog
                title: "Сделать деталь из выбранной плиты"
                standardButtons: Dialog.Ok | Dialog.Cancel
                width: 540
                height: 430

                ColumnLayout {
                    anchors.fill: parent
                    spacing: 10
                    CheckBox {
                        id: lotUseExisting
                        text: "Использовать уже изготовленную деталь из этой плиты"
                        checked: platePartChoicesModel.count > 0
                        enabled: platePartChoicesModel.count > 0
                    }
                    ComboBox {
                        id: lotExistingPart
                        Layout.fillWidth: true
                        model: platePartChoicesModel
                        textRole: "choice_label"
                        enabled: lotUseExisting.checked && platePartChoicesModel.count > 0
                        onActivated: {
                            var choice = platePartChoicesModel.get(currentIndex)
                            lotPartName.text = choice.target_name || ""
                            lotPartUnit.text = choice.target_unit || "шт"
                        }
                    }
                    Label { id: lotSourceLabel; Layout.fillWidth: true; wrapMode: Text.WordWrap; font.bold: true; text: "" }
                    Label { text: "Название готовой детали:" }
                    TextField { id: lotPartName; Layout.fillWidth: true; enabled: !lotUseExisting.checked; placeholderText: "Например: Боковая панель 420x300" }
                    Label { text: "Сколько списать из этой плиты (м²):" }
                    TextField {
                        id: lotAreaQty
                        Layout.fillWidth: true
                        validator: DoubleValidator { bottom: 0.0001 }
                        placeholderText: "Например: 0.35"
                    }
                    Label { text: "Сколько деталей получится:" }
                    TextField {
                        id: lotPartQty
                        Layout.fillWidth: true
                        validator: DoubleValidator { bottom: 0.0001 }
                        text: "1"
                    }
                    Label { text: "Единица измерения детали:" }
                    TextField { id: lotPartUnit; Layout.fillWidth: true; enabled: !lotUseExisting.checked; text: "шт" }
                    Label { text: "Дата обновления:" }
                    TextField { id: lotUpdatedDate; Layout.fillWidth: true; text: new Date().toISOString().slice(0, 10); placeholderText: "2026-05-19" }
                    Label { text: "Примечание:" }
                    TextField { id: lotNotes; Layout.fillWidth: true; placeholderText: "Например: раскрой алюминиевой плиты" }
                    Label { id: lotConvertStatus; Layout.fillWidth: true; wrapMode: Text.WordWrap; color: "#b94a48"; text: "" }
                }

                onAccepted: {
                    var areaValue = parseFloat((lotAreaQty.text || "0").replace(",", "."))
                    var partValue = parseFloat((lotPartQty.text || "1").replace(",", "."))
                    var result
                    if (lotUseExisting.checked && platePartChoicesModel.count > 0 && lotExistingPart.currentIndex >= 0) {
                        var chosen = platePartChoicesModel.get(lotExistingPart.currentIndex)
                        result = backend.convertMaterialLotToExistingPart(
                            plateCutTab.selectedPurchaseId,
                            chosen.target_material_id,
                            areaValue,
                            partValue,
                            lotUpdatedDate.text,
                            lotNotes.text
                        )
                    } else {
                        result = backend.convertMaterialLotToPart(
                            plateCutTab.selectedPurchaseId,
                            lotPartName.text,
                            areaValue,
                            partValue,
                            lotPartUnit.text,
                            lotUpdatedDate.text,
                            lotNotes.text
                        )
                    }
                    if (result.ok) {
                        materialModel.refresh()
                        plateCutTab.reloadLots()
                        plateCutTab.selectedLotRow = -1
                        plateCutTab.selectedPurchaseId = -1
                    } else {
                        lotConvertStatus.text = result.message || "Не удалось сделать деталь"
                        convertLotDialog.open()
                    }
                }
            }

            Component.onCompleted: reloadLots()
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
