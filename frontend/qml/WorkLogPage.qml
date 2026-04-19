import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import TableModels 1.0

Page {
    title: "Учёт работы"

    id: workLogRoot
    property int selectedMachineId: -1
    property string selectedMachineModel: ""

    InProgressModel { id: activePoolModel }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 20
        spacing: 15

        // Заголовок
        Label {
            text: "Активный пул станков в производстве"
            font.pixelSize: 18
            font.bold: true
        }

        // Таблица активных станков
        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 5

            RowLayout {
                Layout.fillWidth: true
                Label {
                    text: "Выберите станок для добавления часов работы:"
                    font.pixelSize: 13
                }
                Item { Layout.fillWidth: true }
                Button {
                    text: "Обновить"
                    onClicked: activePoolModel.refresh()
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
                            width: index === 0 ? 60 : index === 1 ? 250 : index === 2 ? 150 : 200
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
                id: activePoolTable
                Layout.fillWidth: true
                Layout.fillHeight: true
                model: activePoolModel
                clip: true
                columnWidthProvider: function(column) {
                    if (column === 0) return 60
                    if (column === 1) return 250
                    if (column === 2) return 150
                    return 200
                }
                delegate: Rectangle {
                    implicitHeight: 35
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
                        var machine = activePoolModel.get(currentRow)
                        workLogRoot.selectedMachineId = machine.id
                        workLogRoot.selectedMachineModel = machine.model
                    }
                }
            }

            Label {
                visible: activePoolModel.rowCount() === 0
                text: "Нет станков в производстве. Добавьте станок в активный пул на странице 'Станки' → 'Редактор моделей'."
                color: "#666"
                wrapMode: Text.WordWrap
            }
        }

        // Форма добавления часов
        GroupBox {
            Layout.fillWidth: true
            title: "Добавить часы работы"
            enabled: workLogRoot.selectedMachineId > 0

            ColumnLayout {
                anchors.fill: parent
                spacing: 10

                Label {
                    text: workLogRoot.selectedMachineId > 0 
                          ? "Выбранный станок: " + workLogRoot.selectedMachineModel + " (ID: " + workLogRoot.selectedMachineId + ")"
                          : "Выберите станок в таблице выше"
                    font.bold: true
                    color: workLogRoot.selectedMachineId > 0 ? "#2c5aa0" : "#999"
                }

                GridLayout {
                    columns: 2
                    columnSpacing: 10
                    rowSpacing: 10

                    Label { text: "Работник:" }
                    ComboBox {
                        id: employeeCombo
                        Layout.fillWidth: true
                        model: backend.getEmployeesList()
                        textRole: "name"
                        valueRole: "id"
                    }

                    Label { text: "Отработано часов:" }
                    SpinBox {
                        id: hoursSpinBox
                        Layout.fillWidth: true
                        from: 0
                        to: 240
                        stepSize: 1
                        value: 8
                        editable: true
                        
                        property int decimals: 2
                        property real realValue: value / 10

                        validator: DoubleValidator {
                            bottom: Math.min(hoursSpinBox.from, hoursSpinBox.to)
                            top: Math.max(hoursSpinBox.from, hoursSpinBox.to)
                        }

                        textFromValue: function(value, locale) {
                            return Number(value / 10).toLocaleString(locale, 'f', hoursSpinBox.decimals)
                        }

                        valueFromText: function(text, locale) {
                            return Number.fromLocaleString(locale, text) * 10
                        }
                    }

                    Label { text: "Примечание:" }
                    TextField {
                        id: workNotesField
                        Layout.fillWidth: true
                        placeholderText: "Комментарий к работе..."
                    }
                }

                Button {
                    text: "Добавить часы"
                    Layout.alignment: Qt.AlignRight
                    highlighted: true
                    enabled: workLogRoot.selectedMachineId > 0 && employeeCombo.currentValue
                    onClicked: {
                        if (backend.logWorkHours(
                            employeeCombo.currentValue,
                            workLogRoot.selectedMachineId,
                            hoursSpinBox.realValue,
                            workNotesField.text
                        )) {
                            workNotesField.clear()
                            hoursSpinBox.value = 80
                            activePoolModel.refresh()
                        }
                    }
                }
            }
        }
    }

    Component.onCompleted: {
        activePoolModel.refresh()
    }
}