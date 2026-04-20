import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import TableModels 1.0

Page {
    title: "Сотрудники"

    id: employeesRoot

    EmployeeTableModel { id: employeeModel }

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

                    RowLayout {
                        anchors.fill: parent
                        spacing: 0
                        Repeater {
                            model: ["ID", "Имя", "Ставка", "Должность", "Статус"]
                            Rectangle {
                                width: index === 0 ? 50 : index === 1 ? 150 : index === 2 ? 100 : index === 3 ? 120 : 80
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
                        if (column === 0) return 50
                        if (column === 1) return 150
                        if (column === 2) return 100
                        if (column === 3) return 120
                        return 80
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

                    Item { Layout.fillWidth: true }

                    Button {
                        text: "Расчёт зарплаты"
                        onClicked: payrollDialog.open()
                    }
                }
            }
        }

        // ========== ПРАВАЯ ПАНЕЛЬ: ИСТОРИЯ ДЕЙСТВИЙ ==========
        Item {
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
                            parent.parent.parent.selectedWorkLogId = -1
                            parent.parent.parent.selectedHistoryRow = -1
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
                            model: ["ID", "Дата", "Сотрудник", "Станок", "Часы", "Стоимость"]
                            Rectangle {
                                width: index === 0 ? 50 : index === 1 ? 100 : index === 2 ? 180 : index === 3 ? 180 : index === 4 ? 80 : 120
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
                            height: 40
                            border.color: "#ddd"
                            color: {
                                if (parent.parent.parent.parent.selectedHistoryRow === index) return "#b3d9ff"
                                return index % 2 ? "#f9f9f9" : "white"
                            }

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
                                        text: model.work_log_id
                                        font.pixelSize: 13
                                    }
                                }

                                // Дата
                                Rectangle {
                                    width: 100
                                    height: 40
                                    color: "transparent"
                                    Text {
                                        anchors.centerIn: parent
                                        text: model.date
                                        font.pixelSize: 13
                                    }
                                }

                                // Сотрудник
                                Rectangle {
                                    width: 180
                                    height: 40
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
                                    width: 180
                                    height: 40
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
                                    height: 40
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
                                    height: 40
                                    color: "transparent"
                                    Text {
                                        anchors.centerIn: parent
                                        text: model.cost.toFixed(2) + " ₽"
                                        font.pixelSize: 13
                                        font.bold: true
                                        color: "#2c5aa0"
                                    }
                                }
                            }

                            MouseArea {
                                anchors.fill: parent
                                onClicked: {
                                    parent.parent.parent.parent.parent.selectedHistoryRow = index
                                    parent.parent.parent.parent.parent.selectedWorkLogId = model.work_log_id
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
                                workHistoryModel.append(history[i])
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
                        visible: parent.parent.selectedWorkLogId > 0
                        text: "Выбрана запись ID: " + parent.parent.selectedWorkLogId
                        font.bold: true
                        color: "#2c5aa0"
                    }

                    Item { Layout.fillWidth: true }

                    Button {
                        text: "Удалить выбранную запись"
                        enabled: parent.parent.selectedWorkLogId > 0
                        highlighted: parent.parent.selectedWorkLogId > 0
                        onClicked: {
                            var selectedId = parent.parent.selectedWorkLogId
                            var selectedIndex = parent.parent.selectedHistoryRow
                            
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
                    readOnly: true
                    wrapMode: TextArea.Wrap
                    font.family: "Courier New"
                    font.pixelSize: 12
                    text: "Нажмите 'Рассчитать' для получения данных"
                }
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
                // Сбрасываем выбор
                for (var i = 0; i < employeesRoot.children.length; i++) {
                    var child = employeesRoot.children[i]
                    if (child.selectedWorkLogId !== undefined) {
                        child.selectedWorkLogId = -1
                        child.selectedHistoryRow = -1
                        break
                    }
                }
                workHistoryList.loadHistory()
            }
        }
    }

    Component.onCompleted: {
        employeeModel.refresh()
    }
}