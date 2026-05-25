import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import TableModels 1.0

Page {
    title: "Сотрудники"

    id: employeesRoot
    property string employeeActionMessage: ""

    EmployeeTableModel { id: employeeModel }

    function employeeColumnWidth(column) {
        if (column === 0) return 50
        if (column === 1) return 150
        if (column === 2) return 100
        if (column === 3) return 120
        return 80
    }

    SplitView {
        anchors.fill: parent
        orientation: Qt.Horizontal

        // ========== ЛЕВАЯ ПАНЕЛЬ: СПИСОК СОТРУДНИКОВ ==========
        Item {
            SplitView.preferredWidth: 500
            SplitView.minimumWidth: 350

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 15
                spacing: 10

                // Заголовок и кнопки управления
                RowLayout {
                    Layout.fillWidth: true
                    Label {
                        text: "Список сотрудников"
                        font.pixelSize: 18
                        font.bold: true
                    }
                    Item { Layout.fillWidth: true }
                    Button {
                        text: "Добавить сотрудника"
                        highlighted: true
                        onClicked: addEmployeeDialog.open()
                    }
                    Button {
                        text: "Обновить"
                        onClicked: employeeModel.refresh()
                    }
                }

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
                            model: ["ID", "Имя", "Ставка", "Должность", "Статус"]
                            Rectangle {
                                width: employeesRoot.employeeColumnWidth(index)
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

                // Таблица сотрудников
                TableView {
                    id: employeeTable
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    model: employeeModel
                    clip: true

                    property int selectedRow: -1
                    property int selectedEmployeeId: -1

                    columnWidthProvider: function(column) {
                        return employeesRoot.employeeColumnWidth(column)
                    }

                    delegate: Rectangle {
                        implicitHeight: 40
                        border.color: "#ddd"
                        color: {
                            if (employeeTable.selectedRow === row) return "#b3d9ff"
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
                                employeeTable.selectedRow = row
                                var emp = employeeModel.get(row)
                                employeeTable.selectedEmployeeId = emp.id
                            }
                        }
                    }
                }

                // Кнопки действий
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 5

                    Button {
                        text: "Редактировать"
                        enabled: employeeTable.selectedEmployeeId > 0
                        onClicked: {
                            var emp = employeeModel.get(employeeTable.selectedRow)
                            editEmployeeDialog.employeeId = emp.id
                            editEmployeeDialog.employeeName = emp.name
                            editEmployeeDialog.employeeRate = emp.rate
                            editEmployeeDialog.employeePosition = emp.position || ""
                            editEmployeeDialog.employeeActive = emp.active
                            editEmployeeDialog.open()
                        }
                    }

                    Button {
                        text: employeeTable.selectedEmployeeId > 0 ? 
                              (employeeModel.get(employeeTable.selectedRow).active ? "Деактивировать" : "Активировать") : 
                              "Изменить статус"
                        enabled: employeeTable.selectedEmployeeId > 0
                        onClicked: {
                            backend.toggleEmployeeActive(employeeTable.selectedEmployeeId)
                            employeeModel.refresh()
                        }
                    }

                    Button {
                        text: "Удалить"
                        enabled: employeeTable.selectedEmployeeId > 0
                        onClicked: {
                            var emp = employeeModel.get(employeeTable.selectedRow)
                            deleteEmployeeDialog.employeeId = emp.id
                            deleteEmployeeDialog.employeeName = emp.name
                            deleteEmployeeDialog.open()
                        }
                    }

                    Item { Layout.fillWidth: true }

                    Button {
                        text: "Расчёт зарплаты"
                        onClicked: payrollDialog.open()
                    }

                    Button {
                        text: "Премия"
                        onClicked: bonusDialog.open()
                    }

                    Button {
                        text: "Взаиморасчёты"
                        enabled: employeeTable.selectedEmployeeId > 0
                        onClicked: {
                            var emp = employeeModel.get(employeeTable.selectedRow)
                            settlementDialog.employeeId = emp.id
                            settlementDialog.employeeName = emp.name
                            settlementDialog.open()
                        }
                    }
                }

                Label {
                    Layout.fillWidth: true
                    text: employeesRoot.employeeActionMessage
                    color: employeesRoot.employeeActionMessage.indexOf("Нельзя") >= 0 || employeesRoot.employeeActionMessage.indexOf("Ошибка") >= 0 ? "#b94a48" : "#2f6f3e"
                    wrapMode: Text.WordWrap
                    visible: text.length > 0
                }
            }
        }

        // ========== ПРАВАЯ ПАНЕЛЬ: ИСТОРИЯ ДЕЙСТВИЙ ==========
        Item {
            id: workHistoryPane
            SplitView.fillWidth: true
            SplitView.minimumWidth: 400

            property int selectedWorkLogId: -1
            property int selectedHistoryRow: -1

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 15
                spacing: 10

                // Заголовок истории
                RowLayout {
                    Layout.fillWidth: true
                    Label {
                        text: "История работы"
                        font.pixelSize: 18
                        font.bold: true
                    }
                    Item { Layout.fillWidth: true }
                    Button {
                        text: "Обновить историю"
                        onClicked: {
                            workHistoryList.loadHistory()
                            workHistoryPane.selectedWorkLogId = -1
                            workHistoryPane.selectedHistoryRow = -1
                        }
                    }
                }

                // Фильтры
                GroupBox {
                    Layout.fillWidth: true
                    title: "Фильтры"

                    GridLayout {
                        anchors.fill: parent
                        columns: 4
                        columnSpacing: 10
                        rowSpacing: 5

                        Label { text: "С даты:" }
                        TextField {
                            id: dateFromField
                            Layout.fillWidth: true
                            placeholderText: "ГГГГ-ММ-ДД"
                            text: {
                                var date = new Date()
                                date.setMonth(date.getMonth() - 1)
                                Qt.formatDate(date, "yyyy-MM-dd")
                            }
                        }

                        Label { text: "По дату:" }
                        TextField {
                            id: dateToField
                            Layout.fillWidth: true
                            placeholderText: "ГГГГ-ММ-ДД"
                            text: Qt.formatDate(new Date(), "yyyy-MM-dd")
                        }

                        Label { text: "Сотрудник:" }
                        ComboBox {
                            id: filterEmployeeCombo
                            Layout.fillWidth: true
                            Layout.columnSpan: 3
                            model: ListModel {
                                id: filterEmployeeList
                                ListElement { employee_id: -1; name: "Все сотрудники" }
                            }
                            textRole: "name"
                            valueRole: "employee_id"
                            
                            Component.onCompleted: {
                                var emps = backend.getEmployeesList()
                                for (var i = 0; i < emps.length; i++) {
                                    filterEmployeeList.append({
                                        employee_id: emps[i].id,
                                        name: emps[i].name
                                    })
                                }
                            }
                        }

                        Button {
                            text: "Применить фильтр"
                            Layout.columnSpan: 4
                            Layout.fillWidth: true
                            highlighted: true
                            onClicked: workHistoryList.loadHistory()
                        }
                    }
                }

                // Заголовок таблицы истории
                Rectangle {
                    Layout.fillWidth: true
                    height: 35
                    color: "#e8e8e8"
                    border.color: "#ccc"

                    Row {
                        anchors.fill: parent
                        spacing: 0
                        Repeater {
                            model: ["ID", "Дата", "Сотрудник", "Станок", "Часы", "Стоимость", "Примечание"]
                            Rectangle {
                                width: index === 0 ? 50 : index === 1 ? 100 : index === 2 ? 150 : index === 3 ? 150 : index === 4 ? 80 : index === 5 ? 120 : 260
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

                // Список истории работы
                ScrollView {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true

                    ListView {
                        id: workHistoryList
                        model: ListModel { id: workHistoryModel }
                        spacing: 0

                        delegate: Rectangle {
                            width: workHistoryList.width
                            height: 48
                            border.color: "#ddd"
                            color: {
                                if (workHistoryPane.selectedHistoryRow === index) return "#b3d9ff"
                                return index % 2 ? "#f9f9f9" : "white"
                            }

                            Row {
                                anchors.fill: parent
                                spacing: 0

                                // ID
                                Rectangle {
                                    width: 50
                                    height: parent.height
                                    color: "transparent"
                                    Text {
                                        anchors.centerIn: parent
                                        text: model.work_log_id
                                        font.pixelSize: 13
                                    }
                                }

                                // Дата
                                Rectangle {
                                    width: 100
                                    height: parent.height
                                    color: "transparent"
                                    Text {
                                        anchors.centerIn: parent
                                        text: model.date
                                        font.pixelSize: 13
                                    }
                                }

                                // Сотрудник
                                Rectangle {
                                    width: 150
                                    height: parent.height
                                    color: "transparent"
                                    Text {
                                        anchors.centerIn: parent
                                        text: model.employee_name
                                        font.pixelSize: 13
                                        elide: Text.ElideRight
                                        width: parent.width - 10
                                    }
                                }

                                // Станок
                                Rectangle {
                                    width: 150
                                    height: parent.height
                                    color: "transparent"
                                    Text {
                                        anchors.centerIn: parent
                                        text: model.machine_model || "—"
                                        font.pixelSize: 13
                                        elide: Text.ElideRight
                                        width: parent.width - 10
                                    }
                                }

                                // Часы
                                Rectangle {
                                    width: 80
                                    height: parent.height
                                    color: "transparent"
                                    Text {
                                        anchors.centerIn: parent
                                        text: model.hours.toFixed(1) + " ч"
                                        font.pixelSize: 13
                                    }
                                }

                                // Стоимость
                                Rectangle {
                                    width: 120
                                    height: parent.height
                                    color: "transparent"
                                    Text {
                                        anchors.centerIn: parent
                                        text: model.cost.toFixed(2) + " ₽"
                                        font.pixelSize: 13
                                        font.bold: true
                                        color: "#2c5aa0"
                                    }
                                }

                                // Примечание
                                Rectangle {
                                    width: 260
                                    height: parent.height
                                    color: "transparent"
                                    Text {
                                        anchors.verticalCenter: parent.verticalCenter
                                        anchors.left: parent.left
                                        anchors.leftMargin: 6
                                        anchors.right: parent.right
                                        anchors.rightMargin: 6
                                        text: model.notes || ""
                                        font.pixelSize: 13
                                        wrapMode: Text.WordWrap
                                        maximumLineCount: 2
                                        elide: Text.ElideRight
                                    }
                                }
                            }

                            MouseArea {
                                anchors.fill: parent
                                onClicked: {
                                    workHistoryPane.selectedHistoryRow = index
                                    workHistoryPane.selectedWorkLogId = model.work_log_id
                                }
                            }
                        }

                        function loadHistory() {
                            workHistoryModel.clear()
                            var employeeId = filterEmployeeCombo.currentValue
                            var history = backend.getWorkHistory(
                                dateFromField.text,
                                dateToField.text,
                                employeeId > 0 ? employeeId : null
                            )
                            for (var i = 0; i < history.length; i++) {
                                var h = history[i] || {}
                                workHistoryModel.append({
                                    "work_log_id": h.work_log_id !== undefined ? h.work_log_id : -1,
                                    "date": h.date !== undefined ? h.date : "",
                                    "employee_name": h.employee_name !== undefined ? h.employee_name : "",
                                    "machine_model": h.machine_model !== undefined ? h.machine_model : "",
                                    "hours": h.hours !== undefined ? h.hours : 0,
                                    "cost": h.cost !== undefined ? h.cost : 0,
                                    "notes": h.notes !== undefined ? h.notes : ""
                                })
                            }
                        }

                        Component.onCompleted: loadHistory()
                    }
                }

                Label {
                    visible: workHistoryModel.count === 0
                    text: "Нет записей о работе за выбранный период"
                    color: "#666"
                    Layout.alignment: Qt.AlignHCenter
                }

                // КНОПКА УДАЛЕНИЯ
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 10

                    Label {
                        visible: workHistoryPane.selectedWorkLogId > 0
                        text: "Выбрана запись ID: " + workHistoryPane.selectedWorkLogId
                        font.bold: true
                        color: "#2c5aa0"
                    }

                    Item { Layout.fillWidth: true }

                    Button {
                        text: "Удалить выбранную запись"
                        enabled: workHistoryPane.selectedWorkLogId > 0
                        highlighted: workHistoryPane.selectedWorkLogId > 0
                        onClicked: {
                            var selectedId = workHistoryPane.selectedWorkLogId
                            var selectedIndex = workHistoryPane.selectedHistoryRow
                            
                            if (selectedId > 0 && selectedIndex >= 0) {
                                var record = workHistoryModel.get(selectedIndex)
                                undoWorkLogDialog.workLogId = selectedId
                                undoWorkLogDialog.employeeName = record.employee_name
                                undoWorkLogDialog.hours = record.hours
                                undoWorkLogDialog.machineModel = record.machine_model
                                undoWorkLogDialog.open()
                            }
                        }
                    }
                }
            }
        }
    }

    // ========== ДИАЛОГИ ==========

    // Добавление сотрудника
    Dialog {
        id: addEmployeeDialog
        title: "Добавить сотрудника"
        standardButtons: Dialog.Ok | Dialog.Cancel
        width: 450
        height: 300

        ColumnLayout {
            anchors.fill: parent
            spacing: 10

            Label { text: "Имя:" }
            TextField {
                id: newEmployeeName
                Layout.fillWidth: true
                placeholderText: "Фамилия Имя Отчество"
            }

            Label { text: "Почасовая ставка (руб/ч):" }
            TextField {
                id: newEmployeeRate
                Layout.fillWidth: true
                validator: DoubleValidator { bottom: 0.01 }
                placeholderText: "Например: 500"
            }

            Label { text: "Должность:" }
            TextField {
                id: newEmployeePosition
                Layout.fillWidth: true
                placeholderText: "Например: Слесарь, Сборщик"
            }

            Label {
                id: addEmployeeError
                color: "red"
                visible: false
                text: "Заполните имя и ставку"
            }
        }

        onOpened: {
            newEmployeeName.clear()
            newEmployeeRate.clear()
            newEmployeePosition.clear()
            addEmployeeError.visible = false
        }

        onAccepted: {
            if (newEmployeeName.text && newEmployeeRate.text) {
                if (backend.addEmployee(
                    newEmployeeName.text,
                    parseFloat(newEmployeeRate.text),
                    newEmployeePosition.text
                )) {
                    employeeModel.refresh()
                    filterEmployeeList.clear()
                    filterEmployeeList.append({employee_id: -1, name: "Все сотрудники"})
                    var emps = backend.getEmployeesList()
                    for (var i = 0; i < emps.length; i++) {
                        filterEmployeeList.append({
                            employee_id: emps[i].id,
                            name: emps[i].name
                        })
                    }
                }
            } else {
                addEmployeeError.visible = true
            }
        }
    }

    // Редактирование сотрудника
    Dialog {
        id: editEmployeeDialog
        title: "Редактировать сотрудника"
        standardButtons: Dialog.Ok | Dialog.Cancel
        width: 450
        height: 350

        property int employeeId: -1
        property string employeeName: ""
        property real employeeRate: 0
        property string employeePosition: ""
        property bool employeeActive: true

        ColumnLayout {
            anchors.fill: parent
            spacing: 10

            Label { text: "Имя:" }
            TextField {
                id: editEmployeeName
                Layout.fillWidth: true
                text: editEmployeeDialog.employeeName
            }

            Label { text: "Почасовая ставка (руб/ч):" }
            TextField {
                id: editEmployeeRate
                Layout.fillWidth: true
                validator: DoubleValidator { bottom: 0.01 }
                text: editEmployeeDialog.employeeRate.toString()
            }

            Label { text: "Должность:" }
            TextField {
                id: editEmployeePosition
                Layout.fillWidth: true
                text: editEmployeeDialog.employeePosition
            }

            CheckBox {
                id: editEmployeeActive
                text: "Активен"
                checked: editEmployeeDialog.employeeActive
            }
        }

        onAccepted: {
            if (backend.updateEmployee(
                employeeId,
                editEmployeeName.text,
                parseFloat(editEmployeeRate.text),
                editEmployeePosition.text,
                editEmployeeActive.checked
            )) {
                employeeModel.refresh()
            }
        }
    }

    // Расчёт зарплаты
    Dialog {
        id: payrollDialog
        title: "Расчёт зарплаты"
        standardButtons: Dialog.Close
        width: 500
        height: 450

        ColumnLayout {
            anchors.fill: parent
            spacing: 10

            Label { text: "Период:" }
            RowLayout {
                Layout.fillWidth: true
                TextField {
                    id: payrollStartDate
                    Layout.fillWidth: true
                    placeholderText: "ГГГГ-ММ-ДД"
                    text: {
                        var date = new Date()
                        date.setDate(1)
                        Qt.formatDate(date, "yyyy-MM-dd")
                    }
                }
                Label { text: "—" }
                TextField {
                    id: payrollEndDate
                    Layout.fillWidth: true
                    placeholderText: "ГГГГ-ММ-ДД"
                    text: Qt.formatDate(new Date(), "yyyy-MM-dd")
                }
            }

            Button {
                text: "Рассчитать"
                Layout.fillWidth: true
                highlighted: true
                onClicked: {
                    var result = backend.calculatePayroll(payrollStartDate.text, payrollEndDate.text)
                    payrollResultText.text = result
                }
            }

            ScrollView {
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true

                TextArea {
                    id: payrollResultText
                    implicitWidth: 0
                    width: parent.availableWidth
                    readOnly: true
                    wrapMode: TextArea.Wrap
                    font.family: "Courier New"
                    font.pixelSize: 12
                    text: "Нажмите 'Рассчитать' для получения данных"
                }
            }
        }
    }

    // Расчёт и фиксация премии
    Dialog {
        id: bonusDialog
        title: "Премия сотрудникам"
        standardButtons: Dialog.Close
        width: 560
        height: 560

        function refreshLastPaidUntil() {
            var lastPaid = backend.getLastBonusPaidUntil()
            if (lastPaid) {
                var nextDate = new Date(lastPaid + "T00:00:00")
                nextDate.setDate(nextDate.getDate() + 1)
                lastBonusPaidLabel.text = "Предыдущая премия выписана по: " + lastPaid +
                    "\nСледующий период можно начать с: " + Qt.formatDate(nextDate, "yyyy-MM-dd")
            } else {
                lastBonusPaidLabel.text = "Предыдущих выплат премии нет"
            }
        }

        ColumnLayout {
            anchors.fill: parent
            spacing: 10

            Label {
                id: lastBonusPaidLabel
                Layout.fillWidth: true
                text: "Предыдущих выплат премии нет"
                color: "#2c5aa0"
                font.bold: true
                wrapMode: Text.WordWrap
            }

            Label { text: "Период расчёта:" }
            RowLayout {
                Layout.fillWidth: true

                TextField {
                    id: bonusStartDate
                    Layout.fillWidth: true
                    placeholderText: "ГГГГ-ММ-ДД"
                    text: {
                        var date = new Date()
                        date.setDate(1)
                        Qt.formatDate(date, "yyyy-MM-dd")
                    }
                }

                Label { text: "—" }

                TextField {
                    id: bonusEndDate
                    Layout.fillWidth: true
                    placeholderText: "ГГГГ-ММ-ДД"
                    text: Qt.formatDate(new Date(), "yyyy-MM-dd")
                }
            }

            Label { text: "Процент премии:" }
            RowLayout {
                Layout.fillWidth: true

                TextField {
                    id: bonusPercentField
                    Layout.fillWidth: true
                    placeholderText: "Например: 10"
                    validator: DoubleValidator { bottom: 0 }
                    text: "10"
                }

                Label {
                    text: "%"
                    font.bold: true
                }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                Button {
                    text: "Рассчитать премию"
                    Layout.fillWidth: true
                    highlighted: true
                    onClicked: {
                        var result = backend.calculateBonus(
                            bonusStartDate.text,
                            bonusEndDate.text,
                            parseFloat((bonusPercentField.text || "0").replace(",", "."))
                        )
                        bonusResultText.text = result.ok ? result.text : result.message
                    }
                }

                Button {
                    text: "Сохранить выплату"
                    Layout.fillWidth: true
                    onClicked: {
                        var result = backend.saveBonusPayment(
                            bonusStartDate.text,
                            bonusEndDate.text,
                            parseFloat((bonusPercentField.text || "0").replace(",", "."))
                        )
                        bonusResultText.text = result.ok
                            ? result.message + "\n\n" + result.text
                            : result.message
                        bonusDialog.refreshLastPaidUntil()
                    }
                }
            }

            ScrollView {
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true

                TextArea {
                    id: bonusResultText
                    implicitWidth: 0
                    width: parent.availableWidth
                    readOnly: true
                    wrapMode: TextArea.Wrap
                    font.family: "Courier New"
                    font.pixelSize: 12
                    text: "Выберите период, укажите процент и нажмите 'Рассчитать премию'."
                }
            }
        }

        onOpened: {
            refreshLastPaidUntil()
        }
    }

    // Взаиморасчёты по зарплате и услугам сотрудника
    Dialog {
        id: settlementDialog
        title: "Взаиморасчёты сотрудника"
        standardButtons: Dialog.Close
        width: 760
        height: 680

        property int employeeId: -1
        property string employeeName: ""
        property int selectedSettlementId: -1

        function formatMoney(value) {
            return (Number(value) || 0).toFixed(2) + " руб."
        }

        function balanceText(value, positiveText, negativeText) {
            var amount = Number(value) || 0
            if (amount > 0) {
                return positiveText + ": " + formatMoney(amount)
            }
            if (amount < 0) {
                return negativeText + ": " + formatMoney(Math.abs(amount))
            }
            return "Баланс закрыт: 0.00 руб."
        }

        function loadSettlements() {
            settlementModel.clear()
            selectedSettlementId = -1
            if (employeeId <= 0) {
                return
            }
            var result = backend.getEmployeeSettlementSummary(
                employeeId,
                settlementStartDate.text,
                settlementEndDate.text
            )
            if (!result.ok) {
                settlementStatusLabel.text = result.message
                return
            }
            salaryAccruedLabel.text = "Начислено за работу: " + formatMoney(result.salary_accrued)
            salaryPaidLabel.text = "Выплаты/корректировки: " + formatMoney(result.salary_paid)
            salaryBalanceLabel.text = balanceText(result.salary_balance, "Переплата по зарплате", "Недоплата по зарплате")
            serviceBalanceLabel.text = balanceText(result.service_balance, "Недоплата за услуги", "Переплата/зачёт за услуги")
            totalBalanceLabel.text = balanceText(result.total_balance, "Итого недоплата сотруднику", "Итого переплата/зачёт")
            settlementStatusLabel.text = ""

            var rows = result.entries || []
            for (var i = 0; i < rows.length; i++) {
                settlementModel.append(rows[i])
            }
        }

        ColumnLayout {
            anchors.fill: parent
            spacing: 10

            Label {
                Layout.fillWidth: true
                text: settlementDialog.employeeName
                    ? "Сотрудник: " + settlementDialog.employeeName
                    : "Выберите сотрудника"
                font.bold: true
                font.pixelSize: 16
                color: "#2c5aa0"
            }

            GroupBox {
                Layout.fillWidth: true
                title: "Период"

                GridLayout {
                    anchors.fill: parent
                    columns: 5
                    columnSpacing: 8
                    rowSpacing: 6

                    Label { text: "С:" }
                    TextField {
                        id: settlementStartDate
                        Layout.fillWidth: true
                        placeholderText: "ГГГГ-ММ-ДД"
                        text: {
                            var date = new Date()
                            date.setDate(1)
                            Qt.formatDate(date, "yyyy-MM-dd")
                        }
                    }

                    Label { text: "По:" }
                    TextField {
                        id: settlementEndDate
                        Layout.fillWidth: true
                        placeholderText: "ГГГГ-ММ-ДД"
                        text: Qt.formatDate(new Date(), "yyyy-MM-dd")
                    }

                    Button {
                        text: "Обновить"
                        highlighted: true
                        onClicked: settlementDialog.loadSettlements()
                    }
                }
            }

            GroupBox {
                Layout.fillWidth: true
                title: "Итоги"

                ColumnLayout {
                    anchors.fill: parent
                    spacing: 4

                    Label { id: salaryAccruedLabel; Layout.fillWidth: true; text: "Начислено за работу: 0.00 руб." }
                    Label { id: salaryPaidLabel; Layout.fillWidth: true; text: "Выплаты/корректировки: 0.00 руб." }
                    Label { id: salaryBalanceLabel; Layout.fillWidth: true; text: "Баланс закрыт: 0.00 руб."; font.bold: true }
                    Label { id: serviceBalanceLabel; Layout.fillWidth: true; text: "Баланс закрыт: 0.00 руб."; font.bold: true }
                    Label { id: totalBalanceLabel; Layout.fillWidth: true; text: "Баланс закрыт: 0.00 руб."; font.bold: true; color: "#2c5aa0" }
                    Label {
                        Layout.fillWidth: true
                        text: "Подсказка: положительная услуга означает долг перед сотрудником, отрицательная — переплату или зачёт."
                        wrapMode: Text.WordWrap
                        color: "#666"
                        font.pixelSize: 12
                    }
                }
            }

            GroupBox {
                Layout.fillWidth: true
                title: "Добавить запись"

                GridLayout {
                    anchors.fill: parent
                    columns: 6
                    columnSpacing: 8
                    rowSpacing: 6

                    ComboBox {
                        id: settlementTypeCombo
                        Layout.preferredWidth: 120
                        textRole: "label"
                        valueRole: "value"
                        model: ListModel {
                            ListElement { label: "Услуга"; value: "service" }
                            ListElement { label: "Зарплата"; value: "salary" }
                        }
                    }

                    TextField {
                        id: settlementDateField
                        Layout.preferredWidth: 115
                        placeholderText: "ГГГГ-ММ-ДД"
                        text: Qt.formatDate(new Date(), "yyyy-MM-dd")
                    }

                    TextField {
                        id: settlementTitleField
                        Layout.fillWidth: true
                        placeholderText: "Название: аренда площади, оплата, корректировка"
                    }

                    TextField {
                        id: settlementAmountField
                        Layout.preferredWidth: 110
                        placeholderText: "Сумма"
                        validator: DoubleValidator {}
                    }

                    Button {
                        text: "Добавить"
                        highlighted: true
                        onClicked: {
                            var result = backend.addEmployeeSettlement(
                                settlementDialog.employeeId,
                                settlementTypeCombo.model.get(settlementTypeCombo.currentIndex).value,
                                settlementDateField.text,
                                settlementTitleField.text,
                                parseFloat((settlementAmountField.text || "0").replace(",", "."))
                            )
                            settlementStatusLabel.text = result.message
                            if (result.ok) {
                                settlementTitleField.clear()
                                settlementAmountField.clear()
                                settlementDialog.loadSettlements()
                            }
                        }
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
                        model: ["Дата", "Тип", "Название", "Сумма", ""]
                        Rectangle {
                            width: index === 0 ? 110 : index === 1 ? 100 : index === 2 ? 330 : index === 3 ? 110 : 80
                            height: 34
                            color: "transparent"
                            Text {
                                anchors.centerIn: parent
                                text: modelData
                                font.bold: true
                                font.pixelSize: 13
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
                    id: settlementList
                    width: parent.availableWidth
                    model: ListModel { id: settlementModel }
                    spacing: 0

                    delegate: Rectangle {
                        width: settlementList.width
                        height: 38
                        color: settlementDialog.selectedSettlementId === model.id
                            ? "#b3d9ff"
                            : (index % 2 ? "#f9f9f9" : "white")
                        border.color: "#ddd"

                        Row {
                            anchors.fill: parent
                            spacing: 0

                            Text { width: 110; anchors.verticalCenter: parent.verticalCenter; horizontalAlignment: Text.AlignHCenter; text: model.date; font.pixelSize: 13 }
                            Text { width: 100; anchors.verticalCenter: parent.verticalCenter; horizontalAlignment: Text.AlignHCenter; text: model.type_label; font.pixelSize: 13 }
                            Text { width: 330; anchors.verticalCenter: parent.verticalCenter; text: model.title; elide: Text.ElideRight; font.pixelSize: 13 }
                            Text {
                                width: 110
                                anchors.verticalCenter: parent.verticalCenter
                                horizontalAlignment: Text.AlignRight
                                text: (model.amount || 0).toFixed(2) + " руб.  "
                                font.pixelSize: 13
                                font.bold: true
                                color: (model.amount || 0) < 0 ? "#b94a48" : "#2c5aa0"
                            }
                            Button {
                                width: 80
                                height: 30
                                anchors.verticalCenter: parent.verticalCenter
                                text: "Удалить"
                                onClicked: {
                                    var result = backend.deleteEmployeeSettlement(model.id)
                                    settlementStatusLabel.text = result.message
                                    settlementDialog.loadSettlements()
                                }
                            }
                        }

                    }
                }
            }

            Label {
                id: settlementStatusLabel
                Layout.fillWidth: true
                text: ""
                color: "#b94a48"
                wrapMode: Text.WordWrap
            }
        }

        onOpened: {
            settlementStatusLabel.text = ""
            loadSettlements()
        }
    }

    Dialog {
        id: deleteEmployeeDialog
        title: "Удалить сотрудника"
        standardButtons: Dialog.Yes | Dialog.No
        width: 460
        height: 220

        property int employeeId: -1
        property string employeeName: ""

        ColumnLayout {
            anchors.fill: parent
            spacing: 10

            Label {
                text: "Удалить сотрудника?"
                font.bold: true
                font.pixelSize: 16
            }

            Label {
                text: deleteEmployeeDialog.employeeName
                    ? "Сотрудник: " + deleteEmployeeDialog.employeeName
                    : ""
                Layout.fillWidth: true
                wrapMode: Text.WordWrap
            }

            Label {
                text: "Удаление возможно только если у сотрудника нет связанных часов и взаиморасчётов."
                Layout.fillWidth: true
                wrapMode: Text.WordWrap
                color: "#666"
            }
        }

        onAccepted: {
            var result = backend.deleteEmployee(deleteEmployeeDialog.employeeId)
            employeesRoot.employeeActionMessage = result.message || ""
            if (result.ok) {
                employeeModel.refresh()
                employeeTable.selectedEmployeeId = -1
                employeeTable.selectedRow = -1
            }
        }
    }

    // Отмена записи о работе
    Dialog {
        id: undoWorkLogDialog
        title: "Удалить запись о работе"
        standardButtons: Dialog.Yes | Dialog.No
        width: 500
        height: 250

        property int workLogId: -1
        property string employeeName: ""
        property real hours: 0
        property string machineModel: ""

        ColumnLayout {
            anchors.fill: parent
            spacing: 10

            Label {
                text: "Удалить запись о работе?"
                font.bold: true
                font.pixelSize: 16
            }

            Rectangle {
                Layout.fillWidth: true
                height: 1
                color: "#ccc"
            }

            GridLayout {
                columns: 2
                columnSpacing: 15
                rowSpacing: 8

                Label { text: "ID записи:"; font.bold: true }
                Label { text: undoWorkLogDialog.workLogId }

                Label { text: "Сотрудник:"; font.bold: true }
                Label { text: undoWorkLogDialog.employeeName }

                Label { text: "Часы:"; font.bold: true }
                Label { text: undoWorkLogDialog.hours.toFixed(1) + " ч" }

                Label { text: "Станок:"; font.bold: true }
                Label { text: undoWorkLogDialog.machineModel || "—" }
            }

            Rectangle {
                Layout.fillWidth: true
                height: 1
                color: "#ccc"
            }

            Label {
                text: "⚠ Себестоимость станка будет пересчитана (уменьшена на стоимость этой работы)"
                wrapMode: Text.WordWrap
                Layout.fillWidth: true
                font.pixelSize: 12
                color: "#d9534f"
            }
        }

        onAccepted: {
            if (backend.undoWorkLog(undoWorkLogDialog.workLogId)) {
                workHistoryPane.selectedWorkLogId = -1
                workHistoryPane.selectedHistoryRow = -1
                workHistoryList.loadHistory()
            }
        }
    }

    Component.onCompleted: {
        employeeModel.refresh()
    }
}
