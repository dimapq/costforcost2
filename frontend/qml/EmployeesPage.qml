import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import TableModels 1.0

Page {
    title: "Сотрудники"

    EmployeeTableModel { id: employeeModel }

    RowLayout {
        anchors.fill: parent
        anchors.margins: 10
        spacing: 10

        // Левая панель — таблица сотрудников
        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 5

            RowLayout {
                Layout.fillWidth: true
                TextField {
                    id: employeeSearchField
                    Layout.fillWidth: true
                    placeholderText: "Поиск по имени..."
                }
                Button {
                    text: "Обновить"
                    onClicked: employeeModel.refresh()
                }
            }

            TableView {
                id: employeeTable
                Layout.fillWidth: true
                Layout.fillHeight: true
                model: employeeModel
                clip: true
                columnWidthProvider: function(column) {
                    if (column === 0) return 50    // ID
                    if (column === 1) return 200   // Имя
                    if (column === 2) return 100   // Ставка
                    if (column === 3) return 120   // Должность
                    return 80                      // Статус
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
                        var emp = employeeModel.get(currentRow)
                        editNameField.text = emp.name
                        editRateField.text = emp.rate
                        editPositionField.text = emp.position
                        editActiveCheck.checked = emp.active
                        selectedEmployeeId = emp.id
                    }
                }
            }

            RowLayout {
                Layout.fillWidth: true
                Button {
                    text: "Добавить"
                    onClicked: addEmployeeDialog.open()
                }
                Button {
                    text: "Редактировать"
                    enabled: selectedEmployeeId > 0
                    onClicked: {
                        if (selectedEmployeeId > 0) {
                            backend.updateEmployee(selectedEmployeeId, editNameField.text, parseFloat(editRateField.text), editPositionField.text, editActiveCheck.checked)
                            employeeModel.refresh()
                            clearEditForm()
                        }
                    }
                }
                Button {
                    text: "Уволить/Восстановить"
                    enabled: selectedEmployeeId > 0
                    onClicked: {
                        if (selectedEmployeeId > 0) {
                            backend.toggleEmployeeActive(selectedEmployeeId)
                            employeeModel.refresh()
                            clearEditForm()
                        }
                    }
                }
            }
        }

        // Правая панель — детали и расчёт зарплаты
        ColumnLayout {
            Layout.preferredWidth: 300
            Layout.fillHeight: true
            spacing: 10

            GroupBox {
                title: "Детали сотрудника"
                Layout.fillWidth: true
                GridLayout {
                    anchors.fill: parent
                    columns: 2
                    rowSpacing: 5
                    columnSpacing: 10

                    Label { text: "Имя:" }
                    TextField { id: editNameField; Layout.fillWidth: true }
                    Label { text: "Ставка (руб/ч):" }
                    TextField { id: editRateField; Layout.fillWidth: true; validator: DoubleValidator { bottom: 0.01 } }
                    Label { text: "Должность:" }
                    TextField { id: editPositionField; Layout.fillWidth: true }
                    Label { text: "Активен:" }
                    CheckBox { id: editActiveCheck }
                }
            }

            GroupBox {
                title: "Расчёт зарплаты"
                Layout.fillWidth: true
                Layout.preferredHeight: 200
                ColumnLayout {
                    anchors.fill: parent
                    spacing: 5
                    Label { text: "Период:" }
                    RowLayout {
                        TextField { id: startDateField; placeholderText: "ГГГГ-ММ-ДД"; Layout.fillWidth: true }
                        Label { text: "–" }
                        TextField { id: endDateField; placeholderText: "ГГГГ-ММ-ДД"; Layout.fillWidth: true }
                    }
                    Button {
                        text: "Рассчитать"
                        Layout.fillWidth: true
                        onClicked: {
                            var result = backend.calculatePayroll(startDateField.text, endDateField.text)
                            payrollResultText.text = result
                        }
                    }
                    ScrollView {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        TextArea {
                            id: payrollResultText
                            readOnly: true
                            wrapMode: Text.Wrap
                        }
                    }
                }
            }
        }
    }

    // Диалог добавления нового сотрудника
    Dialog {
        id: addEmployeeDialog
        title: "Добавить сотрудника"
        standardButtons: Dialog.Ok | Dialog.Cancel
        width: 400
        height: 250
        ColumnLayout {
            anchors.fill: parent
            spacing: 10
            Label { text: "Имя:" }
            TextField { id: newName; Layout.fillWidth: true }
            Label { text: "Ставка (руб/ч):" }
            TextField { id: newRate; Layout.fillWidth: true; validator: DoubleValidator { bottom: 0.01 } }
            Label { text: "Должность:" }
            TextField { id: newPosition; Layout.fillWidth: true }
        }
        onAccepted: {
            if (newName.text && newRate.text) {
                backend.addEmployee(newName.text, parseFloat(newRate.text), newPosition.text)
                employeeModel.refresh()
                newName.clear()
                newRate.clear()
                newPosition.clear()
            }
        }
    }

    property int selectedEmployeeId: -1

    function clearEditForm() {
        editNameField.clear()
        editRateField.clear()
        editPositionField.clear()
        editActiveCheck.checked = true
        selectedEmployeeId = -1
    }

    Component.onCompleted: employeeModel.refresh()
}