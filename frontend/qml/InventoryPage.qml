import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Dialogs
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
        TabButton { text: "Составные материалы" }
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
            property string selectedMaterialCategory: ""
            property real selectedMaterialLowThreshold: 1
            property real selectedMaterialEnoughThreshold: 3

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
                    ComboBox {
                        id: materialCategoryFilter
                        Layout.preferredWidth: 180
                        model: ["Все", "Материалы", "Составные", "Раскрой плит"]
                        onCurrentTextChanged: materialModel.setCategoryFilter(currentText)
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
                        text: "Добавить по ссылке"
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
                            editMaterialLowThresholdField.text = materialsTab.selectedMaterialLowThreshold.toString()
                            editMaterialEnoughThresholdField.text = materialsTab.selectedMaterialEnoughThreshold.toString()
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
                            model: ["ID", "Название", "Категория", "Остаток", "Цена за ед.", "Сумма", "Используется в", "Откуда взят", "Примечание", "Дата обновления"]
                            Rectangle {
                                width: index === 0 ? 50 : index === 1 ? 220 : index === 2 ? 130 : index === 3 ? 90 : index === 4 ? 110 : index === 5 ? 110 : index === 6 ? 220 : index === 7 ? 200 : index === 8 ? 240 : 130
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
                        if (column === 2) return 130
                        if (column === 3) return 90
                        if (column === 4) return 110
                        if (column === 5) return 110
                        if (column === 6) return 220
                        if (column === 7) return 200
                        if (column === 8) return 240
                        return 130
                    }
                    delegate: Rectangle {
                        implicitHeight: 34
                        border.color: "#ddd"
                        color: {
                            if (materialsTab.selectedMaterialRow === row)
                                return "#b3d9ff"
                            var item = materialModel.get(row)
                            var state = item.stock_state || ""
                            if (state === "empty")
                                return "#ffd9d9"
                            if (state === "low")
                                return "#fff4cc"
                            return "#dff2df"
                        }
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
                                materialsTab.selectedMaterialCategory = item.category || ""
                                materialsTab.selectedMaterialUnit = item.unit || ""
                                materialsTab.selectedMaterialQty = Number(item.quantity || 0)
                                materialsTab.selectedMaterialPrice = Number(item.price || 0)
                                materialsTab.selectedMaterialSource = item.source || ""
                                materialsTab.selectedMaterialNotes = item.notes || ""
                                materialsTab.selectedMaterialUpdatedDate = item.updated_date || ""
                                materialsTab.selectedMaterialLowThreshold = Number(item.low_stock_threshold || 1)
                                materialsTab.selectedMaterialEnoughThreshold = Number(item.enough_stock_threshold || 3)
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
                width: 500
                height: 700
                modal: true
                contentItem: ScrollView {
                    clip: true
                    ScrollBar.vertical.policy: ScrollBar.AsNeeded
                    ColumnLayout {
                        width: Math.max(manualAddDialog.availableWidth - 24, 320)
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
                        Label { text: "Порог мало:" }
                        TextField { id: matLowThreshold; Layout.fillWidth: true; text: "1"; validator: DoubleValidator { bottom: 0 } }
                        Label { text: "Порог достаточно:" }
                        TextField { id: matEnoughThreshold; Layout.fillWidth: true; text: "3"; validator: DoubleValidator { bottom: 0.01 } }
                        CheckBox { id: matIsCash; text: "Наличка" }
                    }
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
                            matIsCash.checked,
                            matLowThreshold.text ? parseFloat(matLowThreshold.text) : 1,
                            matEnoughThreshold.text ? parseFloat(matEnoughThreshold.text) : 3
                        )
                        materialModel.refresh()
                        matName.clear()
                        matUnit.text = "шт"
                        matPrice.clear()
                        matQty.clear()
                        matSource.clear()
                        matNote.clear()
                        matUpdatedDate.text = new Date().toISOString().slice(0, 10)
                        matLowThreshold.text = "1"
                        matEnoughThreshold.text = "3"
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
                        model: backend ? backend.getMaterialsList() : []
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
                        text: "Удалить со склада материал \"" + materialsTab.selectedMaterialName + "\"?\nОстаток будет установлен в 0."
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
                height: 650

                ColumnLayout {
                    anchors.fill: parent
                    spacing: 8

                    Label { text: "Название:" }
                    TextField { id: editMaterialNameField; Layout.fillWidth: true }

                    Label { text: "Единица измерения:" }
                    TextField { id: editMaterialUnitField; Layout.fillWidth: true; placeholderText: "шт, м, кг..." }

                    Label { text: "Количество:" }
                    TextField { id: editMaterialQtyField; Layout.fillWidth: true; validator: DoubleValidator { bottom: 0 } }

                    Label { text: "Цена за единицу (оставьте пустым, если не менять):" }
                    TextField { id: editMaterialPriceField; Layout.fillWidth: true; validator: DoubleValidator { bottom: 0 } }

                    Label { text: "Откуда взят:" }
                    TextField { id: editMaterialSourceField; Layout.fillWidth: true }

                    Label { text: "Примечание:" }
                    TextField { id: editMaterialNotesField; Layout.fillWidth: true }

                    Label { text: "Дата обновления (ГГГГ-ММ-ДД):" }
                    TextField { id: editMaterialUpdatedDateField; Layout.fillWidth: true; placeholderText: "2026-05-18" }

                    Label { text: "Порог мало:" }
                    TextField { id: editMaterialLowThresholdField; Layout.fillWidth: true; text: "1"; validator: DoubleValidator { bottom: 0 } }

                    Label { text: "Порог достаточно:" }
                    TextField { id: editMaterialEnoughThresholdField; Layout.fillWidth: true; text: "3"; validator: DoubleValidator { bottom: 0.01 } }

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
                            editMaterialReasonField.text,
                            editMaterialLowThresholdField.text ? parseFloat(editMaterialLowThresholdField.text) : 1,
                            editMaterialEnoughThresholdField.text ? parseFloat(editMaterialEnoughThresholdField.text) : 3
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
                            materialsTab.selectedMaterialLowThreshold = 1
                            materialsTab.selectedMaterialEnoughThreshold = 3
                        }
                    }
                }
            }
        }

        // ================= СОСТАВНЫЕ МАТЕРИАЛЫ =================
        Item {
            id: compositeTab
            property int selectedRecipeRow: -1
            property int selectedRecipeId: -1
            property int selectedOutputMaterialId: -1
            property string selectedRecipeName: ""
            property string selectedRecipeUnit: "шт"
            property real selectedOutputQuantity: 1
            property string statusMessage: ""

            ListModel { id: compositeRecipesModel }
            ListModel { id: compositeRecipeItemsModel }
            ListModel { id: compositeRecipeDraftModel }
            ListModel { id: compositeMaterialsOptionsModel }

            function reloadRecipes() {
                compositeRecipesModel.clear()
                var rows = backend.getCompositeMaterialRecipes()
                for (var i = 0; i < rows.length; i++)
                    compositeRecipesModel.append(rows[i])
                if (selectedRecipeId > 0)
                    reloadRecipeItems(selectedRecipeId)
            }

            function reloadRecipeItems(recipeId) {
                compositeRecipeItemsModel.clear()
                if (!recipeId || recipeId <= 0)
                    return
                var rows = backend.getCompositeMaterialRecipeItems(recipeId)
                for (var i = 0; i < rows.length; i++)
                    compositeRecipeItemsModel.append(rows[i])
            }

            function reloadMaterialsOptions() {
                compositeMaterialsOptionsModel.clear()
                var rows = backend.getMaterialsList()
                for (var i = 0; i < rows.length; i++)
                    compositeMaterialsOptionsModel.append(rows[i])
            }

            function resetDraftRecipe() {
                compositeRecipeDraftModel.clear()
                compositeNameField.clear()
                compositeUnitField.text = "шт"
                compositeOutputQtyField.text = "1"
                compositeSourceField.text = "Составной материал"
                compositeNotesField.clear()
                compositeUpdatedDateField.text = new Date().toISOString().slice(0, 10)
                compositeLowThresholdField.text = "1"
                compositeStatusLabel.text = ""
            }

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 10
                spacing: 10

                RowLayout {
                    Layout.fillWidth: true
                    Label { text: "Составление материалов"; font.bold: true; font.pixelSize: 18 }
                    Item { Layout.fillWidth: true }
                    Button {
                        text: "Новый рецепт"
                        onClicked: {
                            compositeTab.resetDraftRecipe()
                            compositeTab.reloadMaterialsOptions()
                            addCompositeRecipeDialog.open()
                        }
                    }
                    Button {
                        text: "Удалить рецепт"
                        enabled: compositeTab.selectedRecipeId > 0
                        onClicked: deleteCompositeRecipeDialog.open()
                    }
                    Button {
                        text: "Обновить"
                        onClicked: compositeTab.reloadRecipes()
                    }
                }

                SplitView {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    orientation: Qt.Horizontal

                    Item {
                        SplitView.preferredWidth: 430
                        SplitView.minimumWidth: 320

                        ColumnLayout {
                            anchors.fill: parent
                            spacing: 8

                            Rectangle {
                                Layout.fillWidth: true
                                height: 34
                                color: "#e8e8e8"
                                border.color: "#ccc"
                                Row {
                                    anchors.fill: parent
                                    spacing: 0
                                    Repeater {
                                        model: ["Материал", "Выход", "Остаток", "Статус"]
                                        Rectangle {
                                            width: index === 0 ? 170 : index === 1 ? 70 : index === 2 ? 80 : 100
                                            height: 34
                                            color: "transparent"
                                            Text { anchors.centerIn: parent; text: modelData; font.pixelSize: 13; font.bold: true }
                                        }
                                    }
                                }
                            }

                            ListView {
                                id: compositeRecipesView
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                clip: true
                                model: compositeRecipesModel
                                delegate: Rectangle {
                                    width: compositeRecipesView.width
                                    height: 40
                                    border.color: "#ddd"
                                    color: compositeTab.selectedRecipeRow === index ? "#b3d9ff" : (status_key === "craftable" ? "#dff2df" : (status_key === "empty" ? "#fff4cc" : "#ffd9d9"))
                                    Row {
                                        anchors.fill: parent
                                        spacing: 0
                                        Text { width: 170; anchors.verticalCenter: parent.verticalCenter; leftPadding: 6; text: name; font.pixelSize: 13; elide: Text.ElideRight }
                                        Text { width: 70; anchors.verticalCenter: parent.verticalCenter; horizontalAlignment: Text.AlignHCenter; text: output_quantity + " " + unit; font.pixelSize: 13 }
                                        Text { width: 80; anchors.verticalCenter: parent.verticalCenter; horizontalAlignment: Text.AlignHCenter; text: Number(stock_quantity || 0).toFixed(2); font.pixelSize: 13 }
                                        Text { width: 100; anchors.verticalCenter: parent.verticalCenter; horizontalAlignment: Text.AlignHCenter; text: status_text; font.pixelSize: 13; font.bold: true }
                                    }
                                    MouseArea {
                                        anchors.fill: parent
                                        onClicked: {
                                            compositeTab.selectedRecipeRow = index
                                            compositeTab.selectedRecipeId = recipe_id
                                            compositeTab.selectedOutputMaterialId = material_id
                                            compositeTab.selectedRecipeName = name || ""
                                            compositeTab.selectedRecipeUnit = unit || "шт"
                                            compositeTab.selectedOutputQuantity = output_quantity || 1
                                            compositeTab.reloadRecipeItems(recipe_id)
                                        }
                                    }
                                }
                            }
                        }
                    }

                    Item {
                        SplitView.fillWidth: true
                        SplitView.minimumWidth: 450

                        ColumnLayout {
                            anchors.fill: parent
                            spacing: 8

                            Label {
                                text: compositeTab.selectedRecipeId > 0 ? "Рецепт: " + compositeTab.selectedRecipeName : "Выберите рецепт слева"
                                font.bold: true
                                font.pixelSize: 16
                            }

                            RowLayout {
                                Layout.fillWidth: true
                                enabled: compositeTab.selectedRecipeId > 0
                                Label { text: "Партий:" }
                                TextField {
                                    id: compositeCraftBatchesField
                                    text: "1"
                                    Layout.preferredWidth: 90
                                    validator: DoubleValidator { bottom: 0.01 }
                                }
                                Label { text: "Примечание:" }
                                TextField {
                                    id: compositeCraftNotesField
                                    Layout.fillWidth: true
                                    placeholderText: "Например: плановая сборка"
                                }
                                Button {
                                    text: "Изготовить"
                                    enabled: compositeTab.selectedRecipeId > 0
                                    onClicked: {
                                        var result = backend.craftCompositeMaterial(
                                            compositeTab.selectedRecipeId,
                                            compositeCraftBatchesField.text ? parseFloat(compositeCraftBatchesField.text) : 1,
                                            compositeCraftNotesField.text
                                        )
                                        compositeTab.statusMessage = result.message || ""
                                        if (result.ok) {
                                            compositeCraftNotesField.clear()
                                            compositeCraftBatchesField.text = "1"
                                            compositeTab.reloadRecipes()
                                            materialModel.refresh()
                                        }
                                    }
                                }
                            }

                            Rectangle {
                                Layout.fillWidth: true
                                height: 34
                                color: "#e8e8e8"
                                border.color: "#ccc"
                                visible: compositeTab.selectedRecipeId > 0
                                Row {
                                    anchors.fill: parent
                                    spacing: 0
                                    Repeater {
                                        model: ["Компонент", "Требуется", "На складе", "Статус"]
                                        Rectangle {
                                            width: index === 0 ? 220 : index === 1 ? 110 : index === 2 ? 110 : 110
                                            height: 34
                                            color: "transparent"
                                            Text { anchors.centerIn: parent; text: modelData; font.pixelSize: 13; font.bold: true }
                                        }
                                    }
                                }
                            }

                            ListView {
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                clip: true
                                visible: compositeTab.selectedRecipeId > 0
                                model: compositeRecipeItemsModel
                                delegate: Rectangle {
                                    width: ListView.view ? ListView.view.width : 0
                                    height: 38
                                    border.color: "#ddd"
                                    color: enough ? "#dff2df" : "#ffd9d9"
                                    Row {
                                        anchors.fill: parent
                                        spacing: 0
                                        Text { width: 220; anchors.verticalCenter: parent.verticalCenter; leftPadding: 6; text: material_name; font.pixelSize: 13; elide: Text.ElideRight }
                                        Text { width: 110; anchors.verticalCenter: parent.verticalCenter; horizontalAlignment: Text.AlignHCenter; text: required_quantity.toFixed(2) + " " + unit; font.pixelSize: 13 }
                                        Text { width: 110; anchors.verticalCenter: parent.verticalCenter; horizontalAlignment: Text.AlignHCenter; text: in_stock.toFixed(2) + " " + unit; font.pixelSize: 13; font.bold: true }
                                        Text { width: 110; anchors.verticalCenter: parent.verticalCenter; horizontalAlignment: Text.AlignHCenter; text: enough ? "Можно" : "Нельзя"; font.pixelSize: 13; font.bold: true }
                                    }
                                }
                            }

                            Label {
                                visible: compositeTab.selectedRecipeId > 0 && compositeRecipeItemsModel.count === 0
                                text: "У этого рецепта ещё нет компонентов"
                                color: "#666"
                            }

                            Label {
                                visible: compositeTab.statusMessage.length > 0
                                text: compositeTab.statusMessage
                                color: compositeTab.statusMessage.indexOf("Ошибка") >= 0 || compositeTab.statusMessage.indexOf("Нельзя") >= 0 ? "#d9534f" : "#2f6f3e"
                                wrapMode: Text.WordWrap
                                Layout.fillWidth: true
                            }
                        }
                    }
                }
            }

            Dialog {
                id: addCompositeRecipeDialog
                title: "Новый составной материал"
                standardButtons: Dialog.Ok | Dialog.Cancel
                width: 640
                height: 760
                modal: true
                focus: true

                ScrollView {
                    anchors.fill: parent
                    clip: true
                    ColumnLayout {
                        width: addCompositeRecipeDialog.availableWidth
                        spacing: 8

                        Label { text: "Название:" }
                        TextField { id: compositeNameField; Layout.fillWidth: true }
                        Label { text: "Единица измерения:" }
                        TextField { id: compositeUnitField; Layout.fillWidth: true; text: "шт" }
                        Label { text: "Количество на выходе:" }
                        TextField { id: compositeOutputQtyField; Layout.fillWidth: true; text: "1"; validator: DoubleValidator { bottom: 0.01 } }
                        Label { text: "Откуда взят:" }
                        TextField { id: compositeSourceField; Layout.fillWidth: true; text: "Составной материал" }
                        Label { text: "Примечание:" }
                        TextField { id: compositeNotesField; Layout.fillWidth: true }
                        Label { text: "Дата обновления (ГГГГ-ММ-ДД):" }
                        TextField { id: compositeUpdatedDateField; Layout.fillWidth: true; text: new Date().toISOString().slice(0, 10) }
                        Label { text: "Порог мало:" }
                        TextField { id: compositeLowThresholdField; Layout.fillWidth: true; text: "1"; validator: DoubleValidator { bottom: 0 } }
                        Label { text: "Порог достаточно:" }
                        TextField { id: compositeEnoughThresholdField; Layout.fillWidth: true; text: "3"; validator: DoubleValidator { bottom: 0.01 } }

                        Rectangle { Layout.fillWidth: true; height: 1; color: "#ddd" }
                        Label { text: "Компоненты рецепта"; font.bold: true }

                        RowLayout {
                            Layout.fillWidth: true
                            ComboBox {
                                id: compositeComponentCombo
                                Layout.fillWidth: true
                                model: compositeMaterialsOptionsModel
                                textRole: "name"
                                valueRole: "id"
                            }
                            TextField {
                                id: compositeComponentQtyField
                                Layout.preferredWidth: 110
                                text: "1"
                                validator: DoubleValidator { bottom: 0.01 }
                            }
                            Button {
                                text: "Добавить"
                                onClicked: {
                                    if (!compositeComponentCombo.currentValue || !compositeComponentQtyField.text)
                                        return
                                    compositeRecipeDraftModel.append({
                                        material_id: compositeComponentCombo.currentValue,
                                        material_name: compositeComponentCombo.currentText,
                                        quantity: parseFloat(compositeComponentQtyField.text)
                                    })
                                    compositeComponentQtyField.text = "1"
                                }
                            }
                        }

                        ListView {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 220
                            clip: true
                            model: compositeRecipeDraftModel
                            delegate: Rectangle {
                                width: ListView.view ? ListView.view.width : 0
                                height: 36
                                border.color: "#ddd"
                                color: index % 2 ? "#f9f9f9" : "white"
                                RowLayout {
                                    anchors.fill: parent
                                    anchors.margins: 6
                                    Label { Layout.fillWidth: true; text: material_name }
                                    Label { text: Number(quantity || 0).toFixed(2) }
                                    Button {
                                        text: "Удалить"
                                        onClicked: compositeRecipeDraftModel.remove(index)
                                    }
                                }
                            }
                        }

                        Label {
                            id: compositeStatusLabel
                            Layout.fillWidth: true
                            wrapMode: Text.WordWrap
                            color: "#d9534f"
                        }
                    }
                }

                onAccepted: {
                    var components = []
                    for (var i = 0; i < compositeRecipeDraftModel.count; i++) {
                        var item = compositeRecipeDraftModel.get(i)
                        components.push({
                            material_id: item.material_id,
                            quantity: item.quantity
                        })
                    }
                    var result = backend.addCompositeMaterialRecipe(
                        compositeNameField.text,
                        compositeUnitField.text,
                        compositeOutputQtyField.text ? parseFloat(compositeOutputQtyField.text) : 1,
                        compositeSourceField.text,
                        compositeNotesField.text,
                        compositeUpdatedDateField.text,
                        compositeLowThresholdField.text ? parseFloat(compositeLowThresholdField.text) : 1,
                        compositeEnoughThresholdField.text ? parseFloat(compositeEnoughThresholdField.text) : 3,
                        components
                    )
                    compositeStatusLabel.text = result.message || ""
                    if (result.ok) {
                        addCompositeRecipeDialog.close()
                        compositeTab.reloadRecipes()
                        materialModel.refresh()
                    }
                }
            }

            Dialog {
                id: deleteCompositeRecipeDialog
                title: "Удалить рецепт"
                standardButtons: Dialog.Yes | Dialog.No
                width: 420
                height: 180
                ColumnLayout {
                    anchors.fill: parent
                    spacing: 10
                    Label {
                        Layout.fillWidth: true
                        wrapMode: Text.WordWrap
                        text: "Удалить рецепт составного материала \"" + compositeTab.selectedRecipeName + "\"?"
                    }
                }
                onAccepted: {
                    var result = backend.deleteCompositeMaterialRecipe(compositeTab.selectedRecipeId)
                    compositeTab.statusMessage = result.message || ""
                    if (result.ok) {
                        compositeTab.selectedRecipeId = -1
                        compositeTab.selectedRecipeRow = -1
                        compositeTab.selectedRecipeName = ""
                        compositeRecipeItemsModel.clear()
                        compositeTab.reloadRecipes()
                    }
                }
            }

            Component.onCompleted: reloadRecipes()
        }

        // ================= ВКЛАДКА РАСКРОЙ ПЛИТ =================
        Item {
            id: plateCutTab
            property int selectedTemplateRow: -1
            property int selectedTemplateId: -1
            property string selectedTemplateName: ""
            property int selectedTemplateMinutes: 0
            property int selectedTemplateMaterialTypeId: -1
            property string selectedTemplateMaterialTypeName: ""
            property string selectedTemplateUnit: "шт"
            property string selectedTemplateDrawingPath: ""
            property string selectedTemplateProcessPath: ""
            property string selectedTemplateDrawingName: ""
            property string selectedTemplateProcessName: ""
            property string selectedTemplateNotes: ""
            property string templateExportStatus: ""
            property int selectedLotRow: -1
            property int selectedPurchaseId: -1
            property string selectedMaterialName: ""
            property string selectedUnit: ""
            property real selectedRemaining: 0
            property real selectedPrice: 0
            property string selectedUpdatedDate: ""
            property string selectedLotSource: ""
            property string selectedLotNotes: ""

            ListModel { id: plateMaterialTypesModel }
            ListModel { id: plateTemplatesModel }
            ListModel { id: plateLotsModel }

            function normalizeFilePath(urlValue) {
                var value = urlValue ? urlValue.toString() : ""
                if (value.indexOf("file:///") === 0)
                    value = decodeURIComponent(value.substring(8))
                return value
            }

            function formatMinutes(totalMinutes) {
                var minutes = Number(totalMinutes || 0)
                var hours = Math.floor(minutes / 60)
                var rest = minutes % 60
                if (hours > 0 && rest > 0)
                    return hours + " ч " + rest + " мин"
                if (hours > 0)
                    return hours + " ч"
                return rest + " мин"
            }

            function clearLotSelection() {
                selectedLotRow = -1
                selectedPurchaseId = -1
                selectedMaterialName = ""
                selectedUnit = ""
                selectedRemaining = 0
                selectedPrice = 0
                selectedUpdatedDate = ""
                selectedLotSource = ""
                selectedLotNotes = ""
            }

            function clearTemplateSelection() {
                selectedTemplateRow = -1
                selectedTemplateId = -1
                selectedTemplateName = ""
                selectedTemplateUnit = "шт"
                selectedTemplateMinutes = 0
                selectedTemplateMaterialTypeId = -1
                selectedTemplateMaterialTypeName = ""
                selectedTemplateDrawingPath = ""
                selectedTemplateProcessPath = ""
                selectedTemplateDrawingName = ""
                selectedTemplateProcessName = ""
                selectedTemplateNotes = ""
                templateExportStatus = ""
                clearLotSelection()
                plateLotsModel.clear()
            }

            function reloadMaterialTypes() {
                plateMaterialTypesModel.clear()
                var rows = backend.getPlateMaterialTypes()
                for (var i = 0; i < rows.length; i++) {
                    var item = rows[i] || {}
                    plateMaterialTypesModel.append({
                        id: item.id !== undefined ? item.id : -1,
                        name: item.name || ""
                    })
                }
            }

            function reloadTemplates() {
                plateTemplatesModel.clear()
                var rows = backend.getPlatePartTemplates()
                for (var i = 0; i < rows.length; i++) {
                    var item = rows[i] || {}
                    plateTemplatesModel.append({
                        template_id: item.id !== undefined ? item.id : -1,
                        name: item.name || "",
                        material_type_id: item.material_type_id !== undefined ? item.material_type_id : -1,
                        material_type_name: item.material_type_name || "",
                        part_unit: item.part_unit || "шт",
                        production_minutes: item.production_minutes !== undefined ? item.production_minutes : 0,
                        drawing_file_path: item.drawing_file_path || "",
                        process_file_path: item.process_file_path || "",
                        drawing_file_name: item.drawing_file_name || "",
                        process_file_name: item.process_file_name || "",
                        has_drawing_file: item.has_drawing_file || false,
                        has_process_file: item.has_process_file || false,
                        notes: item.notes || ""
                    })
                }
                clearTemplateSelection()
            }

            function reloadLots() {
                plateLotsModel.clear()
                clearLotSelection()
                if (selectedTemplateMaterialTypeId <= 0)
                    return
                var rows = backend.getAreaMaterialLots(selectedTemplateMaterialTypeId)
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
                        notes: lot.notes || "",
                        material_type_id: lot.material_type_id !== undefined ? lot.material_type_id : -1,
                        material_type_name: lot.material_type_name || ""
                    })
                }
            }

            function openManufactureDialog() {
                manufactureStatus.text = ""
                manufactureAreaField.clear()
                manufactureQtyField.text = "1"
                manufactureDateField.text = selectedUpdatedDate || new Date().toISOString().slice(0, 10)
                manufactureNotesField.text = selectedTemplateNotes || ""
                manufactureDialog.open()
            }

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 10
                spacing: 10

                RowLayout {
                    Layout.fillWidth: true
                    Label { text: "Раскрой плит"; font.bold: true; font.pixelSize: 18 }
                    Item { Layout.fillWidth: true }
                    Button { text: "Добавить шаблон детали"; onClicked: { templateStatus.text = ""; addTemplateDialog.open() } }
                    Button { text: "Добавить плиту"; onClicked: { plateAddStatus.text = ""; addPlateDialog.open() } }
                    Button {
                        text: "Удалить шаблон"
                        enabled: plateCutTab.selectedTemplateId > 0
                        onClicked: deleteTemplateDialog.open()
                    }
                    Button {
                        text: "Удалить плиту"
                        enabled: plateCutTab.selectedPurchaseId > 0
                        onClicked: {
                            deletePlateReasonField.clear()
                            deletePlateDialog.open()
                        }
                    }
                    Button {
                        text: "Обновить"
                        onClicked: {
                            plateCutTab.reloadMaterialTypes()
                            plateCutTab.reloadTemplates()
                        }
                    }
                    Button {
                        text: "Изготовить деталь"
                        enabled: plateCutTab.selectedTemplateId > 0 && plateCutTab.selectedPurchaseId > 0
                        highlighted: enabled
                        onClicked: plateCutTab.openManufactureDialog()
                    }
                }

                Label {
                    Layout.fillWidth: true
                    wrapMode: Text.WordWrap
                    color: "#555"
                    text: "Сначала выберите шаблон детали. После этого справа отобразятся только те плиты, которые подходят по материалу."
                }

                SplitView {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    orientation: Qt.Horizontal

                    Item {
                        SplitView.preferredWidth: 560
                        SplitView.minimumWidth: 420

                        ColumnLayout {
                            anchors.fill: parent
                            spacing: 8

                            Rectangle {
                                Layout.fillWidth: true
                                height: 34
                                color: "#e8e8e8"
                                border.color: "#ccc"
                                Row {
                                    anchors.fill: parent
                                    spacing: 0
                                    Repeater {
                                        model: ["Деталь", "Материал", "Ед.", "Время", "Чертеж", "Обработка"]
                                        Rectangle {
                                            width: index === 0 ? 190 : index === 1 ? 120 : index === 2 ? 55 : index === 3 ? 85 : 120
                                            height: 34
                                            color: "transparent"
                                            Text { anchors.centerIn: parent; text: modelData; font.pixelSize: 13; font.bold: true }
                                        }
                                    }
                                }
                            }

                            ListView {
                                id: plateTemplatesView
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                clip: true
                                model: plateTemplatesModel
                                delegate: Rectangle {
                                    width: plateTemplatesView.width
                                    height: 40
                                    border.color: "#ddd"
                                    color: plateCutTab.selectedTemplateRow === index ? "#b3d9ff" : (index % 2 ? "#f9f9f9" : "white")
                                    Row {
                                        anchors.fill: parent
                                        spacing: 0
                                        Text { width: 190; anchors.verticalCenter: parent.verticalCenter; leftPadding: 6; text: name; elide: Text.ElideRight; font.pixelSize: 13 }
                                        Text { width: 120; anchors.verticalCenter: parent.verticalCenter; text: material_type_name; elide: Text.ElideRight; font.pixelSize: 13 }
                                        Text { width: 55; anchors.verticalCenter: parent.verticalCenter; horizontalAlignment: Text.AlignHCenter; text: part_unit; font.pixelSize: 13 }
                                        Text { width: 85; anchors.verticalCenter: parent.verticalCenter; horizontalAlignment: Text.AlignHCenter; text: plateCutTab.formatMinutes(production_minutes); font.pixelSize: 13 }
                                        Text { width: 120; anchors.verticalCenter: parent.verticalCenter; text: has_drawing_file ? "Есть" : "-"; horizontalAlignment: Text.AlignHCenter; font.pixelSize: 13 }
                                        Text { width: 120; anchors.verticalCenter: parent.verticalCenter; text: has_process_file ? "Есть" : "-"; horizontalAlignment: Text.AlignHCenter; font.pixelSize: 13 }
                                    }
                                    MouseArea {
                                        anchors.fill: parent
                                        onClicked: {
                                            plateCutTab.selectedTemplateRow = index
                                            plateCutTab.selectedTemplateId = template_id
                                            plateCutTab.selectedTemplateName = name || ""
                                            plateCutTab.selectedTemplateUnit = part_unit || "шт"
                                            plateCutTab.selectedTemplateMinutes = production_minutes || 0
                                            plateCutTab.selectedTemplateMaterialTypeId = material_type_id || -1
                                            plateCutTab.selectedTemplateMaterialTypeName = material_type_name || ""
                                            plateCutTab.selectedTemplateDrawingPath = drawing_file_path || ""
                                            plateCutTab.selectedTemplateProcessPath = process_file_path || ""
                                            plateCutTab.selectedTemplateDrawingName = drawing_file_name || ""
                                            plateCutTab.selectedTemplateProcessName = process_file_name || ""
                                            plateCutTab.selectedTemplateNotes = notes || ""
                                            plateCutTab.templateExportStatus = ""
                                            plateCutTab.reloadLots()
                                        }
                                    }
                                }
                            }

                            Rectangle {
                                Layout.fillWidth: true
                                color: "#f7f7f7"
                                border.color: "#ddd"
                                radius: 4
                                implicitHeight: templateInfoColumn.implicitHeight + 16

                                ColumnLayout {
                                    id: templateInfoColumn
                                    anchors.fill: parent
                                    anchors.margins: 8
                                    spacing: 6
                                    Label { text: plateCutTab.selectedTemplateId > 0 ? "Шаблон: " + plateCutTab.selectedTemplateName : "Шаблон не выбран"; font.bold: true }
                                    Label { text: "Материал: " + (plateCutTab.selectedTemplateMaterialTypeName || "-") }
                                    Label { text: "Время: " + plateCutTab.formatMinutes(plateCutTab.selectedTemplateMinutes) }
                                    Label { text: "Чертеж: " + (plateCutTab.selectedTemplateDrawingName || plateCutTab.selectedTemplateDrawingPath || "-"); Layout.fillWidth: true; wrapMode: Text.WrapAnywhere }
                                    Label { text: "Файл обработки: " + (plateCutTab.selectedTemplateProcessName || plateCutTab.selectedTemplateProcessPath || "-"); Layout.fillWidth: true; wrapMode: Text.WrapAnywhere }
                                    RowLayout {
                                        Layout.fillWidth: true
                                        Button {
                                            text: "Выгрузить чертеж"
                                            enabled: plateCutTab.selectedTemplateId > 0 && (plateCutTab.selectedTemplateDrawingName || plateCutTab.selectedTemplateDrawingPath)
                                            onClicked: exportDrawingDialog.open()
                                        }
                                        Button {
                                            text: "Выгрузить обработку"
                                            enabled: plateCutTab.selectedTemplateId > 0 && (plateCutTab.selectedTemplateProcessName || plateCutTab.selectedTemplateProcessPath)
                                            onClicked: exportProcessDialog.open()
                                        }
                                    }
                                    Label { text: plateCutTab.templateExportStatus; Layout.fillWidth: true; wrapMode: Text.WordWrap; color: plateCutTab.templateExportStatus.indexOf("Ошибка") >= 0 ? "#b94a48" : "#2d6a4f" }
                                }
                            }
                        }
                    }

                    Item {
                        SplitView.preferredWidth: 700
                        SplitView.minimumWidth: 500

                        ColumnLayout {
                            anchors.fill: parent
                            spacing: 8

                            Rectangle {
                                Layout.fillWidth: true
                                height: 34
                                color: "#e8e8e8"
                                border.color: "#ccc"
                                Row {
                                    anchors.fill: parent
                                    spacing: 0
                                    Repeater {
                                        model: ["ID партии", "Плита", "Остаток", "Цена", "Дата", "Откуда взято"]
                                        Rectangle {
                                            width: index === 0 ? 90 : index === 1 ? 210 : index === 2 ? 110 : index === 3 ? 90 : index === 4 ? 110 : 180
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
                                    height: 40
                                    border.color: "#ddd"
                                    color: plateCutTab.selectedLotRow === index ? "#b3d9ff" : (index % 2 ? "#f9f9f9" : "white")
                                    Row {
                                        anchors.fill: parent
                                        spacing: 0
                                        Text { width: 90; anchors.verticalCenter: parent.verticalCenter; horizontalAlignment: Text.AlignHCenter; text: purchase_id; font.pixelSize: 13 }
                                        Text { width: 210; anchors.verticalCenter: parent.verticalCenter; leftPadding: 6; text: material_name; elide: Text.ElideRight; font.pixelSize: 13 }
                                        Text { width: 110; anchors.verticalCenter: parent.verticalCenter; horizontalAlignment: Text.AlignRight; text: Number(remaining_quantity).toFixed(4) + " " + unit + "  "; font.pixelSize: 13 }
                                        Text { width: 90; anchors.verticalCenter: parent.verticalCenter; horizontalAlignment: Text.AlignRight; text: Number(price_per_unit).toFixed(2) + "  "; font.pixelSize: 13 }
                                        Text { width: 110; anchors.verticalCenter: parent.verticalCenter; horizontalAlignment: Text.AlignHCenter; text: purchase_date; font.pixelSize: 13 }
                                        Text { width: 180; anchors.verticalCenter: parent.verticalCenter; leftPadding: 6; text: source || "-"; elide: Text.ElideRight; font.pixelSize: 13 }
                                    }
                                    MouseArea {
                                        anchors.fill: parent
                                        onClicked: {
                                            plateCutTab.selectedLotRow = index
                                            plateCutTab.selectedPurchaseId = purchase_id
                                            plateCutTab.selectedMaterialName = material_name || ""
                                            plateCutTab.selectedUnit = unit || ""
                                            plateCutTab.selectedRemaining = remaining_quantity || 0
                                            plateCutTab.selectedPrice = price_per_unit || 0
                                            plateCutTab.selectedUpdatedDate = updated_date || ""
                                            plateCutTab.selectedLotSource = source || ""
                                            plateCutTab.selectedLotNotes = notes || ""
                                        }
                                    }
                                }
                            }

                            Rectangle {
                                Layout.fillWidth: true
                                color: "#f7f7f7"
                                border.color: "#ddd"
                                radius: 4
                                implicitHeight: lotInfoColumn.implicitHeight + 16

                                ColumnLayout {
                                    id: lotInfoColumn
                                    anchors.fill: parent
                                    anchors.margins: 8
                                    spacing: 6
                                    Label { text: plateCutTab.selectedPurchaseId > 0 ? "Плита: партия #" + plateCutTab.selectedPurchaseId : "Плита не выбрана"; font.bold: true }
                                    Label { text: "Материал: " + (plateCutTab.selectedMaterialName || "-") }
                                    Label { text: "Остаток: " + (plateCutTab.selectedPurchaseId > 0 ? Number(plateCutTab.selectedRemaining).toFixed(4) + " " + plateCutTab.selectedUnit : "-") }
                                    Label { text: "Цена: " + (plateCutTab.selectedPurchaseId > 0 ? Number(plateCutTab.selectedPrice).toFixed(2) + " руб./" + plateCutTab.selectedUnit : "-") }
                                    Label { text: "Откуда взято: " + (plateCutTab.selectedLotSource || "-"); Layout.fillWidth: true; wrapMode: Text.WordWrap }
                                    Label { text: "Примечание: " + (plateCutTab.selectedLotNotes || "-"); Layout.fillWidth: true; wrapMode: Text.WordWrap }
                                }
                            }
                        }
                    }
                }
            }

            Dialog {
                id: addTemplateDialog
                title: "Добавить шаблон детали"
                standardButtons: Dialog.Ok | Dialog.Cancel
                width: 640
                height: 560

                ScrollView {
                    anchors.fill: parent
                    clip: true
                    ColumnLayout {
                        width: addTemplateDialog.availableWidth
                        spacing: 10
                        Label { text: "Название детали:" }
                        TextField { id: templateNameField; Layout.fillWidth: true; placeholderText: "Например: Боковая панель 420x300" }
                        Label { text: "Материал плиты:" }
                        ComboBox { id: templateMaterialTypeCombo; Layout.fillWidth: true; model: plateMaterialTypesModel; textRole: "name" }
                        Label { text: "Единица измерения:" }
                        TextField { id: templateUnitField; Layout.fillWidth: true; text: "шт" }
                        Label { text: "Время изготовления (минут):" }
                        TextField { id: templateMinutesField; Layout.fillWidth: true; text: "0"; validator: IntValidator { bottom: 0 } }
                        Label { text: "Файл чертежа:" }
                        RowLayout {
                            TextField { id: templateDrawingField; Layout.fillWidth: true; placeholderText: "Путь к файлу чертежа" }
                            Button { text: "Выбрать"; onClicked: drawingFileDialog.open() }
                        }
                        Label { text: "Файл обработки:" }
                        RowLayout {
                            Layout.fillWidth: true
                            TextField { id: templateProcessField; Layout.fillWidth: true; placeholderText: "Путь к файлу обработки" }
                            Button { text: "Выбрать"; onClicked: processFileDialog.open() }
                        }
                        Label { text: "Примечание:" }
                        TextField { id: templateNotesField; Layout.fillWidth: true; placeholderText: "Дополнительная информация" }
                        Label { id: templateStatus; Layout.fillWidth: true; wrapMode: Text.WordWrap; color: "#b94a48"; text: "" }
                    }
                }

                onAccepted: {
                    if (!templateNameField.text || templateMaterialTypeCombo.currentIndex < 0) {
                        templateStatus.text = "Заполните название детали и выберите материал."
                        addTemplateDialog.open()
                        return
                    }
                    var typeItem = plateMaterialTypesModel.get(templateMaterialTypeCombo.currentIndex)
                    var result = backend.addPlatePartTemplate(
                        templateNameField.text,
                        typeItem.id,
                        templateUnitField.text,
                        parseInt(templateMinutesField.text || "0"),
                        templateDrawingField.text,
                        templateProcessField.text,
                        templateNotesField.text
                    )
                    if (result.ok) {
                        plateCutTab.reloadTemplates()
                        templateNameField.clear()
                        templateUnitField.text = "шт"
                        templateMinutesField.text = "0"
                        templateDrawingField.clear()
                        templateProcessField.clear()
                        templateNotesField.clear()
                        templateStatus.text = ""
                    } else {
                        templateStatus.text = result.message || "Не удалось сохранить шаблон детали."
                        addTemplateDialog.open()
                    }
                }
            }

            Dialog {
                id: addPlateDialog
                title: "Добавить плиту"
                standardButtons: Dialog.Ok | Dialog.Cancel
                width: 560
                height: 560

                ScrollView {
                    anchors.fill: parent
                    clip: true
                    ColumnLayout {
                        width: addPlateDialog.availableWidth
                        spacing: 10
                        Label { text: "Материал плиты:" }
                        ComboBox { id: plateMaterialTypeCombo; Layout.fillWidth: true; model: plateMaterialTypesModel; textRole: "name" }
                        Label { text: "Дополнение к названию плиты:" }
                        TextField { id: plateNameField; Layout.fillWidth: true; placeholderText: "Например: 1200x2400 3мм" }
                        Label { text: "Цена за м² (руб.):" }
                        TextField { id: platePriceField; Layout.fillWidth: true; validator: DoubleValidator { bottom: 0.0001 } }
                        Label { text: "Площадь / количество (м²):" }
                        TextField { id: plateQtyField; Layout.fillWidth: true; text: "1"; validator: DoubleValidator { bottom: 0.0001 } }
                        Label { text: "Откуда взято:" }
                        TextField { id: plateSourceField; Layout.fillWidth: true; placeholderText: "Поставщик, сайт, ссылка" }
                        Label { text: "Дата обновления:" }
                        TextField { id: plateDateField; Layout.fillWidth: true; text: new Date().toISOString().slice(0, 10); placeholderText: "2026-05-19" }
                        Label { text: "Примечание:" }
                        TextField { id: plateNotesField; Layout.fillWidth: true; placeholderText: "Например: лист под раскрой" }
                        CheckBox { id: plateCashField; text: "Наличка" }
                        Label { id: plateAddStatus; Layout.fillWidth: true; wrapMode: Text.WordWrap; color: "#b94a48"; text: "" }
                    }
                }

                onAccepted: {
                    if (plateMaterialTypeCombo.currentIndex < 0 || !platePriceField.text || !plateQtyField.text) {
                        plateAddStatus.text = "Выберите материал плиты, цену и количество."
                        addPlateDialog.open()
                        return
                    }
                    var plateType = plateMaterialTypesModel.get(plateMaterialTypeCombo.currentIndex)
                    var ok = backend.addPlate(
                        plateType.id,
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
                        plateAddStatus.text = ""
                    } else {
                        plateAddStatus.text = "Не удалось добавить плиту."
                        addPlateDialog.open()
                    }
                }
            }

            Dialog {
                id: manufactureDialog
                title: "Изготовить деталь из плиты"
                standardButtons: Dialog.Ok | Dialog.Cancel
                width: 560
                height: 420

                ColumnLayout {
                    anchors.fill: parent
                    spacing: 10
                    Label {
                        Layout.fillWidth: true
                        wrapMode: Text.WordWrap
                        font.bold: true
                        text: "Шаблон: " + plateCutTab.selectedTemplateName + " | Материал: " + plateCutTab.selectedTemplateMaterialTypeName
                    }
                    Label {
                        Layout.fillWidth: true
                        wrapMode: Text.WordWrap
                        text: "Плита: партия #" + plateCutTab.selectedPurchaseId + " - " + plateCutTab.selectedMaterialName + ", остаток " + Number(plateCutTab.selectedRemaining).toFixed(4) + " " + plateCutTab.selectedUnit
                    }
                    Label { text: "Сколько списать с плиты (м²):" }
                    TextField {
                        id: manufactureAreaField
                        Layout.fillWidth: true
                        validator: DoubleValidator { bottom: 0.0001 }
                        placeholderText: "Например: 0.35"
                    }
                    Label { text: "Сколько деталей получится:" }
                    TextField { id: manufactureQtyField; Layout.fillWidth: true; text: "1"; validator: DoubleValidator { bottom: 0.0001 } }
                    Label { text: "Дата обновления:" }
                    TextField { id: manufactureDateField; Layout.fillWidth: true; text: new Date().toISOString().slice(0, 10) }
                    Label { text: "Примечание:" }
                    TextField { id: manufactureNotesField; Layout.fillWidth: true; placeholderText: "Например: раскрой партии под заказ" }
                    Label { id: manufactureStatus; Layout.fillWidth: true; wrapMode: Text.WordWrap; color: "#b94a48"; text: "" }
                }

                onAccepted: {
                    var areaValue = parseFloat((manufactureAreaField.text || "0").replace(",", "."))
                    var qtyValue = parseFloat((manufactureQtyField.text || "1").replace(",", "."))
                    var result = backend.convertPlateLotToTemplate(
                        plateCutTab.selectedPurchaseId,
                        plateCutTab.selectedTemplateId,
                        areaValue,
                        qtyValue,
                        manufactureDateField.text,
                        manufactureNotesField.text
                    )
                    if (result.ok) {
                        materialModel.refresh()
                        plateCutTab.reloadLots()
                        manufactureStatus.text = ""
                    } else {
                        manufactureStatus.text = result.message || "Не удалось изготовить деталь."
                        manufactureDialog.open()
                    }
                }
            }

            Dialog {
                id: deleteTemplateDialog
                title: "Удалить шаблон"
                standardButtons: Dialog.Yes | Dialog.No
                width: 420
                height: 180

                ColumnLayout {
                    anchors.fill: parent
                    spacing: 10
                    Label {
                        Layout.fillWidth: true
                        wrapMode: Text.WordWrap
                        text: "Удалить шаблон \"" + plateCutTab.selectedTemplateName + "\"? История производства останется."
                    }
                }

                onAccepted: {
                    var result = backend.deletePlatePartTemplate(plateCutTab.selectedTemplateId)
                    plateCutTab.templateExportStatus = result.message || ""
                    if (result.ok) {
                        plateCutTab.reloadTemplates()
                    } else {
                        deleteTemplateDialog.open()
                    }
                }
            }

            Dialog {
                id: deletePlateDialog
                title: "Удалить плиту"
                standardButtons: Dialog.Yes | Dialog.No
                width: 460
                height: 240

                ColumnLayout {
                    anchors.fill: parent
                    spacing: 10
                    Label {
                        Layout.fillWidth: true
                        wrapMode: Text.WordWrap
                        text: "Удалить плиту \"" + plateCutTab.selectedMaterialName + "\" (партия #" + plateCutTab.selectedPurchaseId + ")? Остаток этой партии будет списан в ноль."
                    }
                    Label { text: "Причина:" }
                    TextField {
                        id: deletePlateReasonField
                        Layout.fillWidth: true
                        placeholderText: "Например: ошибочное добавление"
                    }
                }

                onAccepted: {
                    var result = backend.deletePlateLot(plateCutTab.selectedPurchaseId, deletePlateReasonField.text)
                    plateCutTab.templateExportStatus = result.message || ""
                    if (result.ok) {
                        plateCutTab.reloadLots()
                        materialModel.refresh()
                    } else {
                        deletePlateDialog.open()
                    }
                }
            }

            FileDialog {
                id: drawingFileDialog
                title: "Выберите файл чертежа"
                fileMode: FileDialog.OpenFile
                onAccepted: templateDrawingField.text = plateCutTab.normalizeFilePath(selectedFile)
            }

            FileDialog {
                id: processFileDialog
                title: "Выберите файл обработки"
                fileMode: FileDialog.OpenFile
                onAccepted: templateProcessField.text = plateCutTab.normalizeFilePath(selectedFile)
            }

            FileDialog {
                id: exportDrawingDialog
                title: "Сохранить чертеж"
                fileMode: FileDialog.SaveFile
                currentFile: plateCutTab.selectedTemplateDrawingName || "drawing.dat"
                onAccepted: {
                    var result = backend.exportPlateTemplateDrawingFile(
                        plateCutTab.selectedTemplateId,
                        plateCutTab.normalizeFilePath(selectedFile)
                    )
                    plateCutTab.templateExportStatus = result.message || (result.ok ? "Чертеж выгружен." : "Ошибка экспорта чертежа.")
                }
            }

            FileDialog {
                id: exportProcessDialog
                title: "Сохранить файл обработки"
                fileMode: FileDialog.SaveFile
                currentFile: plateCutTab.selectedTemplateProcessName || "process.dat"
                onAccepted: {
                    var result = backend.exportPlateTemplateProcessFile(
                        plateCutTab.selectedTemplateId,
                        plateCutTab.normalizeFilePath(selectedFile)
                    )
                    plateCutTab.templateExportStatus = result.message || (result.ok ? "Файл обработки выгружен." : "Ошибка экспорта файла обработки.")
                }
            }
            Component.onCompleted: {
                reloadMaterialTypes()
                reloadTemplates()
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
                        model: backend ? backend.getToolsList() : []
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
                        model: backend ? backend.getToolsList() : []
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
