import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Page {
    title: "Финансы и аналитика"

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 20
        spacing: 20

        GroupBox {
            title: "Ключевые показатели"
            Layout.fillWidth: true
            Layout.preferredHeight: 120

            RowLayout {
                anchors.fill: parent
                spacing: 20

                Frame {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    ColumnLayout {
                        anchors.centerIn: parent
                        Label { text: "Общие активы"; font.bold: true }
                        Label { id: totalAssetsLabel; text: "0.00 руб."; font.pixelSize: 18 }
                    }
                }
                Frame {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    ColumnLayout {
                        anchors.centerIn: parent
                        Label { text: "Выручка (месяц)"; font.bold: true }
                        Label { id: revenueLabel; text: "0.00 руб."; font.pixelSize: 18 }
                    }
                }
                Frame {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    ColumnLayout {
                        anchors.centerIn: parent
                        Label { text: "Прибыль (месяц)"; font.bold: true }
                        Label { id: profitLabel; text: "0.00 руб."; font.pixelSize: 18 }
                    }
                }
                Frame {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    ColumnLayout {
                        anchors.centerIn: parent
                        Label { text: "Рентабельность"; font.bold: true }
                        Label { id: marginLabel; text: "0.0 %"; font.pixelSize: 18 }
                    }
                }
            }
        }

        GroupBox {
            title: "Отчёт о прибылях и убытках"
            Layout.fillWidth: true
            Layout.preferredHeight: 320

            ColumnLayout {
                anchors.fill: parent
                spacing: 10

                RowLayout {
                    Layout.fillWidth: true
                    Label { text: "Период:" }
                    TextField { id: startDateField; placeholderText: "ГГГГ-ММ-ДД"; Layout.preferredWidth: 120 }
                    Label { text: "–" }
                    TextField { id: endDateField; placeholderText: "ГГГГ-ММ-ДД"; Layout.preferredWidth: 120 }
                    Button {
                        text: "Обновить"
                        onClicked: {
                            var report = backend.getProfitLossReport(startDateField.text, endDateField.text)
                            var lines = report.split("\n")
                            var model = []
                            for (var i = 0; i < lines.length; i++) if (lines[i].trim() !== "") model.push({"text": lines[i]})
                            reportList.model = model
                            updateDashboard()
                        }
                    }
                    Button { text: "Экспорт в Excel"; onClicked: backend.exportReportToExcel(startDateField.text, endDateField.text) }
                }

                ListView {
                    id: reportList
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true
                    model: []
                    delegate: Text { text: modelData.text; font.family: "Courier New"; font.pixelSize: 12 }
                }
            }
        }

        GroupBox {
            title: "Косвенные расходы"
            Layout.fillWidth: true
            Layout.fillHeight: true

            ColumnLayout {
                anchors.fill: parent
                spacing: 8

                RowLayout {
                    Layout.fillWidth: true
                    TextField { id: indirectMonthField; Layout.preferredWidth: 120; placeholderText: "ГГГГ-ММ" }
                    Button {
                        text: "Пересчитать за месяц"
                        onClicked: {
                            if (indirectMonthField.text) {
                                backend.recalculateIndirectExpenses(indirectMonthField.text)
                                reloadIndirect()
                            }
                        }
                    }
                    Button { text: "Обновить"; onClicked: reloadIndirect() }
                }

                RowLayout {
                    Layout.fillWidth: true
                    Label { text: "Период:" }
                    TextField { id: indirectFromField; Layout.preferredWidth: 120; placeholderText: "ГГГГ-ММ-ДД" }
                    Label { text: "—" }
                    TextField { id: indirectToField; Layout.preferredWidth: 120; placeholderText: "ГГГГ-ММ-ДД" }
                    Button { text: "Показать за период"; onClicked: reloadIndirect() }
                }

                RowLayout {
                    Layout.fillWidth: true
                    TextField { id: indirectName; Layout.preferredWidth: 180; placeholderText: "Категория" }
                    TextField { id: indirectAmount; Layout.preferredWidth: 130; placeholderText: "Сумма/мес"; validator: DoubleValidator { bottom: 0.01 } }
                    CheckBox { id: indirectActive; text: "Активна"; checked: true }
                    TextField { id: indirectNote; Layout.fillWidth: true; placeholderText: "Примечание" }
                    Button {
                        text: "Добавить"
                        onClicked: {
                            if (indirectName.text && indirectAmount.text) {
                                backend.addIndirectCategory(indirectName.text, parseFloat(indirectAmount.text), indirectActive.checked, indirectNote.text)
                                indirectName.clear(); indirectAmount.clear(); indirectNote.clear()
                                reloadIndirect()
                            }
                        }
                    }
                }

                Label { text: "Категории"; font.bold: true }
                ListView {
                    id: indirectCategoriesView
                    Layout.fillWidth: true
                    Layout.preferredHeight: 130
                    clip: true
                    model: ListModel { id: indirectCategoriesModel }
                    delegate: Rectangle {
                        width: indirectCategoriesView.width
                        height: 32
                        color: index % 2 ? "#f9f9f9" : "white"
                        RowLayout {
                            anchors.fill: parent
                            Text { Layout.preferredWidth: 200; text: model.name }
                            Text { Layout.preferredWidth: 120; text: Number(model.monthly_amount).toFixed(2) + " ₽" }
                            Text { Layout.preferredWidth: 90; text: model.is_active ? "Да" : "Нет" }
                            Text { Layout.fillWidth: true; text: model.notes || "-"; elide: Text.ElideRight }
                            Button {
                                text: "Изменить"
                                onClicked: {
                                    editCategoryId = model.id
                                    editCategoryName.text = model.name
                                    editCategoryAmount.text = Number(model.monthly_amount).toFixed(2)
                                    editCategoryActive.checked = model.is_active
                                    editCategoryNote.text = model.notes || ""
                                    editCategoryDialog.open()
                                }
                            }
                            Button { text: "Удалить"; onClicked: { backend.deleteIndirectCategory(model.id); reloadIndirect() } }
                        }
                    }
                }

                Label { text: "Распределение по станкам"; font.bold: true }
                Rectangle {
                    Layout.fillWidth: true
                    height: 32
                    color: "#e8e8e8"
                    border.color: "#ccc"
                    RowLayout {
                        anchors.fill: parent
                        Text { Layout.preferredWidth: 110; text: "Дата"; font.bold: true; horizontalAlignment: Text.AlignHCenter }
                        Text { Layout.preferredWidth: 180; text: "Категория"; font.bold: true; horizontalAlignment: Text.AlignHCenter }
                        Text { Layout.fillWidth: true; text: "Модель станка"; font.bold: true; horizontalAlignment: Text.AlignHCenter }
                        Text { Layout.preferredWidth: 120; text: "Сумма"; font.bold: true; horizontalAlignment: Text.AlignHCenter }
                    }
                }
                ListView {
                    id: indirectAllocView
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true
                    model: ListModel { id: indirectAllocModel }
                    delegate: Rectangle {
                        width: indirectAllocView.width
                        height: 30
                        color: index % 2 ? "#f9f9f9" : "white"
                        RowLayout {
                            anchors.fill: parent
                            Text { Layout.preferredWidth: 110; text: model.date }
                            Text { Layout.preferredWidth: 180; text: model.category; elide: Text.ElideRight }
                            Text { Layout.fillWidth: true; text: model.machine_model; elide: Text.ElideRight }
                            Text { Layout.preferredWidth: 120; text: Number(model.amount).toFixed(2) + " ₽" }
                        }
                    }
                }
            }
        }
    }

    property int editCategoryId: -1

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
                    editCategoryNote.text
                )
                reloadIndirect()
            }
        }
    }

    function updateDashboard() {
        totalAssetsLabel.text = backend.getTotalAssets() + " руб."
        var revenue = backend.getMonthlyRevenue(startDateField.text, endDateField.text)
        var profit = backend.getMonthlyProfit(startDateField.text, endDateField.text)
        revenueLabel.text = revenue + " руб."
        profitLabel.text = profit + " руб."
        var margin = 0.0
        if (parseFloat(revenue) > 0) margin = (parseFloat(profit) / parseFloat(revenue) * 100).toFixed(1)
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
    }

    Component.onCompleted: {
        var today = new Date()
        var year = today.getFullYear()
        var month = String(today.getMonth() + 1).padStart(2, '0')
        startDateField.text = year + "-" + month + "-01"
        var lastDay = new Date(year, today.getMonth() + 1, 0).getDate()
        endDateField.text = year + "-" + month + "-" + String(lastDay).padStart(2, '0')
        indirectMonthField.text = year + "-" + month
        indirectFromField.text = year + "-" + month + "-01"
        indirectToField.text = year + "-" + month + "-" + String(lastDay).padStart(2, '0')
        updateDashboard()
        reloadIndirect()
    }
}
