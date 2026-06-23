import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Page {
    title: "Финансы и аналитика"
    property bool compactLayout: width < 1180
    property int editCategoryId: -1
    property string miscExpenseStatusMessage: ""

    ListModel { id: miscExpenseMachineModel }
    ListModel { id: miscExpenseListModel }
    ListModel {
        id: miscAssignModeModel
        ListElement { label: "Без привязки"; value: "none" }
        ListElement { label: "Выбранные станки"; value: "selected" }
        ListElement { label: "Все станки"; value: "all" }
    }

    ScrollView {
        id: scrollView
        anchors.fill: parent
        clip: true
        padding: 20
        ScrollBar.vertical.policy: ScrollBar.AsNeeded

        ColumnLayout {
            width: scrollView.availableWidth
            spacing: 18

            GroupBox {
                title: "Ключевые показатели"
                Layout.fillWidth: true

                GridLayout {
                    anchors.fill: parent
                    columns: compactLayout ? 2 : 4
                    columnSpacing: 12
                    rowSpacing: 12

                    Frame {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 96

                        ColumnLayout {
                            anchors.fill: parent
                            anchors.margins: 14
                            spacing: 6

                            Label { text: "Общие активы"; font.bold: true; color: "#5d6470" }
                            Item { Layout.fillHeight: true }
                            Label { id: totalAssetsLabel; text: "0.00 руб."; font.pixelSize: 22; font.bold: true }
                        }
                    }

                    Frame {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 96

                        ColumnLayout {
                            anchors.fill: parent
                            anchors.margins: 14
                            spacing: 6

                            Label { text: "Выручка"; font.bold: true; color: "#5d6470" }
                            Label { text: "Текущий период"; color: "#888"; font.pixelSize: 12 }
                            Item { Layout.fillHeight: true }
                            Label { id: revenueLabel; text: "0.00 руб."; font.pixelSize: 22; font.bold: true; color: "#1d5f7a" }
                        }
                    }

                    Frame {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 96

                        ColumnLayout {
                            anchors.fill: parent
                            anchors.margins: 14
                            spacing: 6

                            Label { text: "Прибыль"; font.bold: true; color: "#5d6470" }
                            Label { text: "Текущий период"; color: "#888"; font.pixelSize: 12 }
                            Item { Layout.fillHeight: true }
                            Label { id: profitLabel; text: "0.00 руб."; font.pixelSize: 22; font.bold: true; color: "#2f6f3e" }
                        }
                    }

                    Frame {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 96

                        ColumnLayout {
                            anchors.fill: parent
                            anchors.margins: 14
                            spacing: 6

                            Label { text: "Рентабельность"; font.bold: true; color: "#5d6470" }
                            Label { text: "Соотношение прибыли"; color: "#888"; font.pixelSize: 12 }
                            Item { Layout.fillHeight: true }
                            Label { id: marginLabel; text: "0.0 %"; font.pixelSize: 22; font.bold: true }
                        }
                    }
                }
            }

            GridLayout {
                Layout.fillWidth: true
                columns: compactLayout ? 1 : 2
                columnSpacing: 18
                rowSpacing: 18

                GroupBox {
                    title: "Отчёт о прибыли и убытках"
                    Layout.fillWidth: true
                    Layout.preferredHeight: 360

                    ColumnLayout {
                        anchors.fill: parent
                        spacing: 10

                        Rectangle {
                            Layout.fillWidth: true
                            color: "#f6f8fb"
                            border.color: "#d9e0e8"
                            radius: 6
                            implicitHeight: compactLayout ? 100 : 54

                            GridLayout {
                                anchors.fill: parent
                                anchors.margins: 10
                                columns: compactLayout ? 2 : 6
                                rowSpacing: 8
                                columnSpacing: 8

                                Label { text: "Период:" }
                                TextField { id: startDateField; placeholderText: "ГГГГ-ММ-ДД"; Layout.preferredWidth: 120 }
                                Label { text: compactLayout ? "По:" : "–" }
                                TextField { id: endDateField; placeholderText: "ГГГГ-ММ-ДД"; Layout.preferredWidth: 120 }
                                Button {
                                    text: "Обновить"
                                    onClicked: {
                                        var report = backend.getProfitLossReport(startDateField.text, endDateField.text)
                                        var lines = report.split("\n")
                                        var model = []
                                        for (var i = 0; i < lines.length; i++) {
                                            if (lines[i].trim() !== "")
                                                model.push({ "text": lines[i] })
                                        }
                                        reportList.model = model
                                        updateDashboard()
                                    }
                                }
                                Button { text: "Excel"; onClicked: backend.exportReportToExcel(startDateField.text, endDateField.text) }
                            }
                        }

                        Frame {
                            Layout.fillWidth: true
                            Layout.fillHeight: true

                            ListView {
                                id: reportList
                                anchors.fill: parent
                                anchors.margins: 8
                                clip: true
                                spacing: 4
                                model: []

                                delegate: Rectangle {
                                    width: reportList.width
                                    height: reportText.implicitHeight + 10
                                    color: index % 2 ? "#fbfbfb" : "white"

                                    Text {
                                        id: reportText
                                        anchors.fill: parent
                                        anchors.margins: 5
                                        text: modelData.text
                                        font.family: "Courier New"
                                        font.pixelSize: 12
                                        wrapMode: Text.WordWrap
                                    }
                                }
                            }
                        }
                    }
                }

                GroupBox {
                    title: "Расчёт налогов"
                    Layout.fillWidth: true
                    Layout.preferredHeight: 360

                    ColumnLayout {
                        anchors.fill: parent
                        spacing: 10

                        Rectangle {
                            Layout.fillWidth: true
                            color: "#f6f8fb"
                            border.color: "#d9e0e8"
                            radius: 6
                            implicitHeight: compactLayout ? 138 : 86

                            GridLayout {
                                anchors.fill: parent
                                anchors.margins: 10
                                columns: compactLayout ? 2 : 7
                                rowSpacing: 8
                                columnSpacing: 8

                                Label { text: "Период:" }
                                TextField { id: taxStartField; Layout.preferredWidth: 120; placeholderText: "ГГГГ-ММ-ДД" }
                                Label { text: compactLayout ? "По:" : "—" }
                                TextField { id: taxEndField; Layout.preferredWidth: 120; placeholderText: "ГГГГ-ММ-ДД" }
                                Label { text: "Ставка %:" }
                                TextField { id: taxRateField; Layout.preferredWidth: 80; text: "6"; validator: DoubleValidator { bottom: 0 } }
                                Item { Layout.fillWidth: true }

                                Item { visible: !compactLayout }
                                Item { visible: !compactLayout }
                                Item { visible: !compactLayout }
                                Item { visible: !compactLayout }
                                Item { visible: !compactLayout }
                                Button { text: "Рассчитать"; onClicked: updateTaxReport() }
                                Button { text: "Отметить оплату"; onClicked: saveTaxPayment() }
                            }
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            color: "#f8faf7"
                            border.color: "#d6dfd2"
                            radius: 6

                            GridLayout {
                                anchors.fill: parent
                                anchors.margins: 12
                                columns: compactLayout ? 2 : 4
                                rowSpacing: 8
                                columnSpacing: 12

                                Label { text: "Доходы без налички:"; font.bold: true }
                                Label { id: taxIncomeLabel; text: "0.00 руб." }
                                Label { text: "Расходы без налички:"; font.bold: true }
                                Label { id: taxExpenseLabel; text: "0.00 руб." }

                                Label { text: "Налоговая база:"; font.bold: true }
                                Label { id: taxBaseLabel; text: "0.00 руб." }
                                Label { text: "Налог:"; font.bold: true }
                                Label { id: taxAmountLabel; text: "0.00 руб."; color: "#9b2f2f"; font.bold: true }

                                Label { text: "Исключено наличных:"; font.bold: true }
                                Label { id: taxCashExcludedLabel; text: "0.00 руб."; Layout.columnSpan: compactLayout ? 1 : 3 }

                                Label { text: "Последняя оплата:"; font.bold: true }
                                Label {
                                    id: taxLastPaymentLabel
                                    text: "Налог ещё не отмечался как уплаченный"
                                    wrapMode: Text.WordWrap
                                    Layout.columnSpan: compactLayout ? 1 : 3
                                }
                            }
                        }
                    }
                }
            }

            GroupBox {
                title: "Прочие расходы"
                Layout.fillWidth: true

                GridLayout {
                    anchors.fill: parent
                    columns: compactLayout ? 1 : 2
                    columnSpacing: 18
                    rowSpacing: 18

                    GroupBox {
                        title: "Новый расход"
                        Layout.fillWidth: true
                        Layout.preferredHeight: 430

                        ColumnLayout {
                            anchors.fill: parent
                            spacing: 10

                            GridLayout {
                                Layout.fillWidth: true
                                columns: compactLayout ? 2 : 4
                                columnSpacing: 8
                                rowSpacing: 8

                                Label { text: "????????:" }
                                TextField { id: miscExpenseDateField; Layout.preferredWidth: 120; placeholderText: "ГГГГ-ММ-ДД" }
                                Label { text: "Сумма:" }
                                TextField { id: miscExpenseAmountField; Layout.preferredWidth: 120; placeholderText: "0.00"; validator: DoubleValidator { bottom: 0.01 } }

                                Label { text: "Название:" }
                                TextField { id: miscExpenseTitleField; Layout.fillWidth: true; Layout.columnSpan: compactLayout ? 1 : 3; placeholderText: "Например: доставка, комиссия, упаковка" }

                                Label { text: "Лицо:" }
                                TextField { id: miscExpensePersonField; Layout.fillWidth: true; placeholderText: "Кому относится расход" }
                                CheckBox { id: miscExpenseCash; text: "Наличка" }
                                Item { visible: compactLayout }

                                Label { text: "Привязка:" }
                                ComboBox {
                                    id: miscAssignModeCombo
                                    Layout.fillWidth: true
                                    Layout.columnSpan: compactLayout ? 1 : 3
                                    model: miscAssignModeModel
                                    textRole: "label"
                                    valueRole: "value"
                                }

                                Label { text: "Примечание:" }
                                TextField {
                                    id: miscExpenseNotesField
                                    Layout.fillWidth: true
                                    Layout.columnSpan: compactLayout ? 1 : 3
                                    placeholderText: "Дополнительная информация"
                                }
                            }

                            Rectangle {
                                Layout.fillWidth: true
                                visible: miscAssignModeCombo.currentValue === "selected"
                                color: "#f8fafc"
                                border.color: "#d9e0e8"
                                radius: 6
                                implicitHeight: 215

                                ColumnLayout {
                                    anchors.fill: parent
                                    anchors.margins: 10
                                    spacing: 8

                                    RowLayout {
                                        Layout.fillWidth: true
                                        Label { text: "Выберите один или несколько станков"; font.bold: true; Layout.fillWidth: true }
                                        Button {
                                            text: "Все"
                                            onClicked: {
                                                for (var i = 0; i < miscExpenseMachineModel.count; i++)
                                                    miscExpenseMachineModel.setProperty(i, "checked", true)
                                            }
                                        }
                                        Button {
                                            text: "Снять"
                                            onClicked: {
                                                for (var i = 0; i < miscExpenseMachineModel.count; i++)
                                                    miscExpenseMachineModel.setProperty(i, "checked", false)
                                            }
                                        }
                                    }

                                    ScrollView {
                                        Layout.fillWidth: true
                                        Layout.fillHeight: true
                                        clip: true

                                        ListView {
                                            id: miscExpenseMachineList
                                            model: miscExpenseMachineModel
                                            spacing: 4

                                            delegate: Rectangle {
                                                width: miscExpenseMachineList.width
                                                height: 34
                                                radius: 4
                                                color: model.checked ? "#e8f3ff" : (index % 2 ? "#fafafa" : "white")
                                                border.color: "#e4e7eb"

                                                RowLayout {
                                                    anchors.fill: parent
                                                    anchors.leftMargin: 8
                                                    anchors.rightMargin: 8
                                                    spacing: 8

                                                    CheckBox {
                                                        checked: model.checked
                                                        onToggled: miscExpenseMachineModel.setProperty(index, "checked", checked)
                                                    }
                                                    Label {
                                                        Layout.fillWidth: true
                                                        text: model.display
                                                        elide: Text.ElideRight
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }

                            RowLayout {
                                Layout.fillWidth: true
                                Button {
                                    text: "Сохранить расход"
                                    highlighted: true
                                    onClicked: {
                                        var mode = miscAssignModeCombo.currentValue || "none"
                                        var selectedIds = []
                                        if (mode === "selected")
                                            selectedIds = selectedMiscExpenseIds()
                                        var result = backend.addMiscExpense(
                                            miscExpenseDateField.text,
                                            miscExpenseTitleField.text,
                                            parseFloat((miscExpenseAmountField.text || "0").replace(",", ".")),
                                            miscExpenseCash.checked,
                                            miscExpensePersonField.text,
                                            miscExpenseNotesField.text,
                                            mode,
                                            selectedIds
                                        )
                                        miscExpenseStatusMessage = result.message || ""
                                        if (result.ok) {
                                            resetMiscExpenseForm()
                                            reloadMiscExpenses()
                                            updateDashboard()
                                        }
                                    }
                                }
                                Button {
                                    text: "Обновить список"
                                    onClicked: {
                                        reloadMiscExpenseTargets()
                                        reloadMiscExpenses()
                                    }
                                }
                            }

                            Label {
                                Layout.fillWidth: true
                                text: miscExpenseStatusMessage
                                visible: text.length > 0
                                wrapMode: Text.WordWrap
                                color: miscExpenseStatusMessage.indexOf("Ошибка") >= 0 || miscExpenseStatusMessage.indexOf("Укажите") >= 0 || miscExpenseStatusMessage.indexOf("Выберите") >= 0 ? "#b94a48" : "#2f6f3e"
                            }
                        }
                    }

                    GroupBox {
                        title: "Последние прочие расходы"
                        Layout.fillWidth: true
                        Layout.preferredHeight: 430

                        ColumnLayout {
                            anchors.fill: parent
                            spacing: 8

                            ListView {
                                id: miscExpenseView
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                clip: true
                                spacing: 6
                                model: miscExpenseListModel

                                delegate: Rectangle {
                                    width: miscExpenseView.width
                                    height: compactLayout ? 112 : 76
                                    radius: 4
                                    color: index % 2 ? "#f9f9f9" : "white"
                                    border.color: "#e4e7eb"

                                    ColumnLayout {
                                        anchors.fill: parent
                                        anchors.margins: 8
                                        spacing: 4

                                        RowLayout {
                                            Layout.fillWidth: true
                                            Label { text: model.title; font.bold: true; Layout.fillWidth: true; elide: Text.ElideRight }
                                            Label { text: Number(model.amount).toFixed(2) + " руб."; color: "#1d5f7a"; font.bold: true }
                                            Label { text: model.is_cash ? "Наличка" : "Безнал"; color: model.is_cash ? "#8b5a00" : "#2a5f9e" }
                                        }

                                        RowLayout {
                                            Layout.fillWidth: true
                                            Label { text: model.date; color: "#666" }
                                            Label { text: model.person_name ? ("Лицо: " + model.person_name) : "Лицо не указано"; color: "#666"; Layout.fillWidth: true; elide: Text.ElideRight }
                                            Button {
                                                text: "Удалить"
                                                onClicked: {
                                                    var result = backend.deleteMiscExpense(model.id)
                                                    miscExpenseStatusMessage = result.message || ""
                                                    if (result.ok) {
                                                        reloadMiscExpenses()
                                                        updateDashboard()
                                                    }
                                                }
                                            }
                                        }

                                        Label { text: model.target_summary; Layout.fillWidth: true; elide: Text.ElideRight; color: "#444" }
                                        Label { text: model.notes || "Без примечания"; Layout.fillWidth: true; elide: Text.ElideRight; color: "#777" }
                                    }
                                }
                            }
                        }
                    }
                }
            }

            GroupBox {
                title: "Косвенные расходы"
                Layout.fillWidth: true

                ColumnLayout {
                    anchors.fill: parent
                    spacing: 12

                    Rectangle {
                        Layout.fillWidth: true
                        color: "#f6f8fb"
                        border.color: "#d9e0e8"
                        radius: 6
                        implicitHeight: compactLayout ? 132 : 96

                        GridLayout {
                            anchors.fill: parent
                            anchors.margins: 10
                            columns: compactLayout ? 2 : 8
                            rowSpacing: 8
                            columnSpacing: 8

                            Label { text: "Месяц:" }
                            TextField { id: indirectMonthField; Layout.preferredWidth: 120; placeholderText: "ГГГГ-ММ" }
                            Button {
                                text: "Пересчитать"
                                onClicked: {
                                    if (indirectMonthField.text) {
                                        backend.recalculateIndirectExpenses(indirectMonthField.text)
                                        reloadIndirect()
                                    }
                                }
                            }
                            Button { text: "Обновить"; onClicked: reloadIndirect() }
                            Label { text: compactLayout ? "С:" : "Период:" }
                            TextField { id: indirectFromField; Layout.preferredWidth: 120; placeholderText: "ГГГГ-ММ-ДД" }
                            Label { text: compactLayout ? "По:" : "—" }
                            TextField { id: indirectToField; Layout.preferredWidth: 120; placeholderText: "ГГГГ-ММ-ДД" }

                            Item { visible: !compactLayout }
                            Item { visible: !compactLayout }
                            Item { visible: !compactLayout }
                            Item { visible: !compactLayout }
                            Item { visible: !compactLayout }
                            Item { visible: !compactLayout }
                            Button { text: "Показать за период"; onClicked: reloadIndirect() }
                            Item { visible: !compactLayout }
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        color: "#fff7e6"
                        border.color: "#e2c27a"
                        radius: 6
                        implicitHeight: compactLayout ? 92 : 58

                        GridLayout {
                            anchors.fill: parent
                            anchors.margins: 10
                            columns: compactLayout ? 1 : 4
                            rowSpacing: 6
                            columnSpacing: 18

                            Label { text: "Простой по косвенным расходам"; font.bold: true; color: "#7a4b00" }
                            Label { id: indirectIdleDaysLabel; text: "Дней простоя: 0"; font.bold: true }
                            Label { id: indirectIdleAmountLabel; text: "Набежало: 0.00 руб."; font.bold: true; color: "#9b2f2f" }
                            Label { id: indirectIdlePeriodLabel; text: ""; color: "#666"; wrapMode: Text.WordWrap; Layout.fillWidth: true }
                        }
                    }

                    GridLayout {
                        Layout.fillWidth: true
                        columns: compactLayout ? 1 : 2
                        columnSpacing: 18
                        rowSpacing: 18

                        GroupBox {
                            title: "Управление категориями"
                            Layout.fillWidth: true
                            Layout.preferredHeight: 360

                            ColumnLayout {
                                anchors.fill: parent
                                spacing: 10

                                Rectangle {
                                    Layout.fillWidth: true
                                    color: "#f8fafc"
                                    border.color: "#dde5ed"
                                    radius: 6
                                    implicitHeight: compactLayout ? 138 : 96

                                    GridLayout {
                                        anchors.fill: parent
                                        anchors.margins: 10
                                        columns: compactLayout ? 2 : 4
                                        rowSpacing: 8
                                        columnSpacing: 8

                                        Label { text: "Категория:" }
                                        TextField { id: indirectName; Layout.fillWidth: true; placeholderText: "Название" }
                                        Label { text: "Сумма/мес:" }
                                        TextField { id: indirectAmount; Layout.preferredWidth: 130; placeholderText: "0.00"; validator: DoubleValidator { bottom: 0.01 } }

                                        CheckBox { id: indirectActive; text: "Активна"; checked: true }
                                        CheckBox { id: indirectCash; text: "Наличка" }
                                        TextField {
                                            id: indirectNote
                                            Layout.fillWidth: true
                                            Layout.columnSpan: compactLayout ? 1 : 2
                                            placeholderText: "Примечание"
                                        }
                                        Button {
                                            text: "Добавить"
                                            onClicked: {
                                                if (indirectName.text && indirectAmount.text) {
                                                    backend.addIndirectCategory(indirectName.text, parseFloat(indirectAmount.text), indirectActive.checked, indirectCash.checked, indirectNote.text)
                                                    indirectName.clear()
                                                    indirectAmount.clear()
                                                    indirectNote.clear()
                                                    indirectCash.checked = false
                                                    reloadIndirect()
                                                }
                                            }
                                        }
                                    }
                                }

                                ListView {
                                    id: indirectCategoriesView
                                    Layout.fillWidth: true
                                    Layout.fillHeight: true
                                    clip: true
                                    spacing: 6
                                    model: ListModel { id: indirectCategoriesModel }

                                    delegate: Rectangle {
                                        width: indirectCategoriesView.width
                                        height: compactLayout ? 76 : 40
                                        radius: 4
                                        color: index % 2 ? "#f9f9f9" : "white"
                                        border.color: "#e4e7eb"

                                        ColumnLayout {
                                            anchors.fill: parent
                                            anchors.margins: 8
                                            spacing: 4

                                            RowLayout {
                                                Layout.fillWidth: true
                                                Label { text: model.name; font.bold: true; Layout.fillWidth: true; elide: Text.ElideRight }
                                                Label { text: Number(model.monthly_amount).toFixed(2) + " ₽"; color: "#1d5f7a" }
                                                Label { text: model.is_cash ? "Наличка" : "Безнал"; color: model.is_cash ? "#8b5a00" : "#2a5f9e" }
                                                Label { text: model.is_active ? "Активна" : "Пауза"; color: model.is_active ? "#2f6f3e" : "#a05a00" }
                                            }

                                            RowLayout {
                                                Layout.fillWidth: true
                                                Label { text: model.notes || "Без примечания"; color: "#666"; Layout.fillWidth: true; elide: Text.ElideRight }
                                                Button {
                                                    text: "Изменить"
                                                    onClicked: {
                                                        editCategoryId = model.id
                                                        editCategoryName.text = model.name
                                                        editCategoryAmount.text = Number(model.monthly_amount).toFixed(2)
                                                        editCategoryActive.checked = model.is_active
                                                        editCategoryCash.checked = model.is_cash || false
                                                        editCategoryNote.text = model.notes || ""
                                                        editCategoryDialog.open()
                                                    }
                                                }
                                                Button { text: "Удалить"; onClicked: { backend.deleteIndirectCategory(model.id); reloadIndirect() } }
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        GroupBox {
                            title: "Распределение по станкам"
                            Layout.fillWidth: true
                            Layout.preferredHeight: 360

                            ColumnLayout {
                                anchors.fill: parent
                                spacing: 8

                                Rectangle {
                                    Layout.fillWidth: true
                                    height: 34
                                    color: "#eef2f6"
                                    border.color: "#d6dce3"
                                    radius: 4

                                    RowLayout {
                                        anchors.fill: parent
                                        anchors.leftMargin: 8
                                        anchors.rightMargin: 8
                                        spacing: 8

                                        Text { Layout.preferredWidth: 100; text: "????????"; font.bold: true; verticalAlignment: Text.AlignVCenter }
                                        Text { Layout.preferredWidth: 170; text: "Категория"; font.bold: true; verticalAlignment: Text.AlignVCenter }
                                        Text { Layout.fillWidth: true; text: "Модель станка"; font.bold: true; verticalAlignment: Text.AlignVCenter }
                                        Text { Layout.preferredWidth: 120; text: "Сумма"; font.bold: true; horizontalAlignment: Text.AlignRight; verticalAlignment: Text.AlignVCenter }
                                    }
                                }

                                ListView {
                                    id: indirectAllocView
                                    Layout.fillWidth: true
                                    Layout.fillHeight: true
                                    clip: true
                                    spacing: 4
                                    model: ListModel { id: indirectAllocModel }

                                    delegate: Rectangle {
                                        width: indirectAllocView.width
                                        height: 34
                                        radius: 4
                                        color: index % 2 ? "#f9f9f9" : "white"
                                        border.color: "#eceff3"

                                        RowLayout {
                                            anchors.fill: parent
                                            anchors.leftMargin: 8
                                            anchors.rightMargin: 8
                                            spacing: 8

                                            Text { Layout.preferredWidth: 100; text: model.date; elide: Text.ElideRight }
                                            Text { Layout.preferredWidth: 170; text: model.category; elide: Text.ElideRight }
                                            Text { Layout.fillWidth: true; text: model.machine_model; elide: Text.ElideRight }
                                            Text { Layout.preferredWidth: 120; text: Number(model.amount).toFixed(2) + " ₽"; horizontalAlignment: Text.AlignRight }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    Dialog {
        id: editCategoryDialog
        title: "Изменить категорию"
        standardButtons: Dialog.Ok | Dialog.Cancel
        width: 440
        height: 260

        ColumnLayout {
            anchors.fill: parent
            spacing: 10

            Label { text: "Название:" }
            TextField { id: editCategoryName; Layout.fillWidth: true }
            Label { text: "Сумма в месяц:" }
            TextField { id: editCategoryAmount; Layout.fillWidth: true; validator: DoubleValidator { bottom: 0.01 } }
            CheckBox { id: editCategoryActive; text: "Активна" }
            CheckBox { id: editCategoryCash; text: "Наличка" }
            Label { text: "Примечание:" }
            TextField { id: editCategoryNote; Layout.fillWidth: true }
        }

        onAccepted: {
            if (editCategoryId > 0 && editCategoryName.text && editCategoryAmount.text) {
                backend.updateIndirectCategory(
                    editCategoryId,
                    editCategoryName.text,
                    parseFloat(editCategoryAmount.text),
                    editCategoryActive.checked,
                    editCategoryCash.checked,
                    editCategoryNote.text
                )
                reloadIndirect()
            }
        }
    }

    function reloadMiscExpenseTargets() {
        var rows = backend.getMiscExpenseMachineTargets()
        miscExpenseMachineModel.clear()
        for (var i = 0; i < rows.length; i++) {
            var row = rows[i] || {}
            miscExpenseMachineModel.append({
                "id": row.id !== undefined ? row.id : -1,
                "display": row.display !== undefined ? row.display : "",
                "checked": false
            })
        }
    }

    function selectedMiscExpenseIds() {
        var ids = []
        for (var i = 0; i < miscExpenseMachineModel.count; i++) {
            var row = miscExpenseMachineModel.get(i)
            if (row.checked)
                ids.push(row.id)
        }
        return ids
    }

    function reloadMiscExpenses() {
        var rows = backend.getMiscExpenses()
        miscExpenseListModel.clear()
        for (var i = 0; i < rows.length; i++) {
            var row = rows[i] || {}
            miscExpenseListModel.append({
                "id": row.id !== undefined ? row.id : -1,
                "date": row.date !== undefined ? row.date : "",
                "title": row.title !== undefined ? row.title : "",
                "amount": row.amount !== undefined ? row.amount : 0,
                "notes": row.notes !== undefined ? row.notes : "",
                "is_cash": row.is_cash !== undefined ? row.is_cash : false,
                "person_name": row.person_name !== undefined ? row.person_name : "",
                "target_summary": row.target_summary !== undefined ? row.target_summary : ""
            })
        }
    }

    function resetMiscExpenseForm() {
        miscExpenseDateField.text = Qt.formatDate(new Date(), "yyyy-MM-dd")
        miscExpenseTitleField.clear()
        miscExpenseAmountField.clear()
        miscExpenseCash.checked = false
        miscExpensePersonField.clear()
        miscExpenseNotesField.clear()
        miscAssignModeCombo.currentIndex = 0
        for (var i = 0; i < miscExpenseMachineModel.count; i++)
            miscExpenseMachineModel.setProperty(i, "checked", false)
    }

    function updateTaxReport() {
        var result = backend.calculateTaxReport(taxStartField.text, taxEndField.text, parseFloat(taxRateField.text || "0"))
        taxIncomeLabel.text = Number(result.income || 0).toFixed(2) + " руб."
        taxExpenseLabel.text = Number(result.expense || 0).toFixed(2) + " руб."
        taxBaseLabel.text = Number(result.base || 0).toFixed(2) + " руб."
        taxAmountLabel.text = Number(result.tax || 0).toFixed(2) + " руб."
        var excluded = Number(result.cash_income_excluded || 0) + Number(result.cash_expense_excluded || 0)
        taxCashExcludedLabel.text = excluded.toFixed(2) + " руб. (операций: " + Number(result.cash_count || 0) + ")"
        updateLastTaxPayment()
    }

    function updateLastTaxPayment() {
        var payment = backend.getLastTaxPayment()
        if (!payment.ok) {
            taxLastPaymentLabel.text = payment.message || "Не удалось прочитать последнюю оплату"
            return
        }
        if (!payment.has_payment) {
            taxLastPaymentLabel.text = "Налог ещё не отмечался как уплаченный"
            return
        }
        taxLastPaymentLabel.text = payment.payment_date + ": " +
            Number(payment.amount || 0).toFixed(2) + " руб. за период " +
            (payment.period_start || "") + " — " + (payment.period_end || "") +
            " (" + Number(payment.rate || 0).toFixed(2) + "%)"
    }

    function saveTaxPayment() {
        var result = backend.saveTaxPayment(
            taxStartField.text,
            taxEndField.text,
            parseFloat((taxRateField.text || "0").replace(",", "."))
        )
        if (result.ok) {
            updateTaxReport()
            updateLastTaxPayment()
        } else {
            taxLastPaymentLabel.text = result.message || "Не удалось сохранить оплату налога"
        }
    }

    function updateDashboard() {
        totalAssetsLabel.text = backend.getTotalAssets() + " руб."
        var revenue = backend.getMonthlyRevenue(startDateField.text, endDateField.text)
        var profit = backend.getMonthlyProfit(startDateField.text, endDateField.text)
        revenueLabel.text = revenue + " руб."
        profitLabel.text = profit + " руб."
        var margin = 0.0
        if (parseFloat(revenue) > 0)
            margin = (parseFloat(profit) / parseFloat(revenue) * 100).toFixed(1)
        marginLabel.text = margin + " %"
    }

    function reloadIndirect() {
        var categories = backend.getIndirectCategories()
        indirectCategoriesModel.clear()
        for (var i = 0; i < categories.length; i++) {
            var c = categories[i]
            indirectCategoriesModel.append({
                "id": c.id !== undefined ? c.id : -1,
                "name": c.name !== undefined ? c.name : "",
                "monthly_amount": c.monthly_amount !== undefined ? c.monthly_amount : 0,
                "is_active": c.is_active !== undefined ? c.is_active : false,
                "is_cash": c.is_cash !== undefined ? c.is_cash : false,
                "notes": c.notes !== undefined ? c.notes : ""
            })
        }

        var allocs = []
        if (indirectFromField.text && indirectToField.text) {
            allocs = backend.getIndirectAllocationsByPeriod(indirectFromField.text, indirectToField.text)
        } else {
            allocs = backend.getIndirectAllocations(indirectMonthField.text)
        }
        indirectAllocModel.clear()
        for (var j = 0; j < allocs.length; j++) {
            var a = allocs[j]
            indirectAllocModel.append({
                "category": a.category !== undefined ? a.category : "",
                "date": a.date !== undefined ? a.date : "",
                "machine_model": a.machine_model !== undefined ? a.machine_model : "",
                "amount": a.amount !== undefined ? a.amount : 0
            })
        }

        var idle = backend.getIndirectIdleSummary(indirectFromField.text, indirectToField.text)
        if (idle.ok) {
            indirectIdleDaysLabel.text = "Дней простоя: " + Number(idle.idle_days || 0)
            indirectIdleAmountLabel.text = "Набежало: " + Number(idle.amount || 0).toFixed(2) + " руб."
            indirectIdlePeriodLabel.text = "Период: " + (idle.date_from || "") + " — " + (idle.date_to || "") +
                ", активных категорий: " + Number(idle.active_categories || 0)
        } else {
            indirectIdleDaysLabel.text = "Дней простоя: 0"
            indirectIdleAmountLabel.text = "Набежало: 0.00 руб."
            indirectIdlePeriodLabel.text = idle.message || "Не удалось рассчитать простой"
        }
    }

    Timer {
        id: indirectIdleNightlyTimer
        interval: msToNextNightUpdate()
        repeat: false
        running: true
        onTriggered: {
            reloadIndirect()
            interval = 24 * 60 * 60 * 1000
            repeat = true
            restart()
        }
    }

    function msToNextNightUpdate() {
        var now = new Date()
        var next = new Date(now.getFullYear(), now.getMonth(), now.getDate() + 1, 0, 5, 0, 0)
        return Math.max(60000, next.getTime() - now.getTime())
    }

    Component.onCompleted: {
        var today = new Date()
        var year = today.getFullYear()
        var month = String(today.getMonth() + 1).padStart(2, "0")
        startDateField.text = year + "-" + month + "-01"
        taxStartField.text = startDateField.text
        var lastDay = new Date(year, today.getMonth() + 1, 0).getDate()
        endDateField.text = year + "-" + month + "-" + String(lastDay).padStart(2, "0")
        taxEndField.text = endDateField.text
        indirectMonthField.text = year + "-" + month
        indirectFromField.text = year + "-" + month + "-01"
        indirectToField.text = year + "-" + month + "-" + String(lastDay).padStart(2, "0")
        resetMiscExpenseForm()
        reloadMiscExpenseTargets()
        reloadMiscExpenses()
        updateDashboard()
        updateTaxReport()
        reloadIndirect()
    }
}

