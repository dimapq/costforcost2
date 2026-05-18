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
            title: "Расчёт налогов"
            Layout.fillWidth: true
            Layout.preferredHeight: 215

            ColumnLayout {
                anchors.fill: parent
                spacing: 8

                RowLayout {
                    Layout.fillWidth: true
                    Label { text: "Период:" }
                    TextField { id: taxStartField; Layout.preferredWidth: 120; placeholderText: "ГГГГ-ММ-ДД" }
                    Label { text: "—" }
                    TextField { id: taxEndField; Layout.preferredWidth: 120; placeholderText: "ГГГГ-ММ-ДД" }
                    Label { text: "Ставка %:" }
                    TextField { id: taxRateField; Layout.preferredWidth: 80; text: "6"; validator: DoubleValidator { bottom: 0 } }
                    Button { text: "Рассчитать"; onClicked: updateTaxReport() }
                    Button { text: "Отметить оплату"; onClicked: saveTaxPayment() }
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    color: "#f8faf7"
                    border.color: "#d6dfd2"
                    radius: 4

                    GridLayout {
                        anchors.fill: parent
                        anchors.margins: 10
                        columns: 4
                        rowSpacing: 6
                        columnSpacing: 12

                        Label { text: "Доходы без налички:"; font.bold: true }
                        Label { id: taxIncomeLabel; text: "0.00 руб." }
                        Label { text: "Расходы без налички:"; font.bold: true }
                        Label { id: taxExpenseLabel; text: "0.00 руб." }

                        Label { text: "Налоговая база:"; font.bold: true }
                        Label { id: taxBaseLabel; text: "0.00 руб." }
                        Label { text: "Налог:"; font.bold: true }
                        Label { id: taxAmountLabel; text: "0.00 руб."; color: "#9b2f2f"; font.bold: true }

                        Label { text: "Исключено наличкой:"; font.bold: true }
                        Label { id: taxCashExcludedLabel; text: "0.00 руб."; Layout.columnSpan: 3 }

                        Label { text: "Последняя оплата:"; font.bold: true }
                        Label { id: taxLastPaymentLabel; text: "Налог ещё не отмечался как уплаченный"; Layout.columnSpan: 3 }
                    }
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

                Rectangle {
                    Layout.fillWidth: true
                    height: 58
                    color: "#fff7e6"
                    border.color: "#e2c27a"
                    radius: 4

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 10
                        spacing: 18

                        Label {
                            text: "Простой по косвенным расходам"
                            font.bold: true
                            color: "#7a4b00"
                        }

                        Label {
                            id: indirectIdleDaysLabel
                            text: "Дней простоя: 0"
                            font.bold: true
                        }

                        Label {
                            id: indirectIdleAmountLabel
                            text: "Набежало: 0.00 руб."
                            font.bold: true
                            color: "#9b2f2f"
                        }

                        Label {
                            id: indirectIdlePeriodLabel
                            Layout.fillWidth: true
                            text: ""
                            color: "#666"
                            elide: Text.ElideRight
                        }
                    }
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
        var month = String(today.getMonth() + 1).padStart(2, '0')
        startDateField.text = year + "-" + month + "-01"
        taxStartField.text = startDateField.text
        var lastDay = new Date(year, today.getMonth() + 1, 0).getDate()
        endDateField.text = year + "-" + month + "-" + String(lastDay).padStart(2, '0')
        taxEndField.text = endDateField.text
        indirectMonthField.text = year + "-" + month
        indirectFromField.text = year + "-" + month + "-01"
        indirectToField.text = year + "-" + month + "-" + String(lastDay).padStart(2, '0')
        updateDashboard()
        updateTaxReport()
        reloadIndirect()
    }
}
