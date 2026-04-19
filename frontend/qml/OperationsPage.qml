import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Page {
    title: "Быстрые операции"

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 20
        spacing: 20

        // ================= Учёт рабочего времени =================
        GroupBox {
            Layout.fillWidth: true
            title: "Учёт рабочего времени"

            ColumnLayout {
                anchors.fill: parent
                spacing: 10

                Label {
                    text: "Добавить часы работы к активному станку"
                    font.bold: true
                }

                // Выбор активного станка
                RowLayout {
                    Layout.fillWidth: true
                    Label { text: "Станок в производстве:" }
                    ComboBox {
                        id: inProgressMachineCombo
                        Layout.fillWidth: true
                        model: ListModel { id: inProgressMachineList }
                        textRole: "display"
                        valueRole: "id"
                        
                        Component.onCompleted: refreshInProgressList()
                        
                        function refreshInProgressList() {
                            inProgressMachineList.clear()
                            var machines = backend.getInProgressMachinesList()
                            for (var i = 0; i < machines.length; i++) {
                                inProgressMachineList.append(machines[i])
                            }
                        }
                    }
                    Button {
                        text: "Обновить список"
                        onClicked: inProgressMachineCombo.refreshInProgressList()
                    }
                }

                // Выбор работника
                RowLayout {
                    Layout.fillWidth: true
                    Label { text: "Работник:" }
                    ComboBox {
                        id: employeeComboWorkLog
                        Layout.fillWidth: true
                        model: backend.getEmployeesList()
                        textRole: "name"
                        valueRole: "id"
                    }
                }

                // Количество часов
                RowLayout {
                    Layout.fillWidth: true
                    Label { text: "Отработано часов:" }
                    SpinBox {
                        id: hoursSpinBox
                        Layout.preferredWidth: 150
                        from: 0
                        to: 2400
                        stepSize: 1
                        value: 80
                        editable: true
                        
                        property int decimals: 1
                        property real realValue: value / 10

                        textFromValue: function(value, locale) {
                            return Number(value / 10).toLocaleString(locale, 'f', decimals)
                        }

                        valueFromText: function(text, locale) {
                            return Number.fromLocaleString(locale, text) * 10
                        }
                    }
                    Label { 
                        text: hoursSpinBox.realValue.toFixed(1) + " ч"
                        color: "#666"
                    }
                }

                // Примечание
                RowLayout {
                    Layout.fillWidth: true
                    Label { text: "Примечание:" }
                    TextField {
                        id: workNotesField
                        Layout.fillWidth: true
                        placeholderText: "Описание работы..."
                    }
                }

                // Кнопка добавления
                Button {
                    text: "Добавить часы"
                    Layout.alignment: Qt.AlignRight
                    highlighted: true
                    enabled: inProgressMachineCombo.currentValue && employeeComboWorkLog.currentValue
                    onClicked: {
                        if (backend.logWorkHours(
                            employeeComboWorkLog.currentValue,
                            inProgressMachineCombo.currentValue,
                            hoursSpinBox.realValue,
                            workNotesField.text
                        )) {
                            workNotesField.clear()
                            hoursSpinBox.value = 80
                            inProgressMachineCombo.refreshInProgressList()
                        }
                    }
                }

                Label {
                    text: "Часы работы увеличивают себестоимость выбранного станка"
                    color: "#666"
                    font.pixelSize: 11
                    wrapMode: Text.WordWrap
                }
            }
        }

        // --- Блок сводки по складу (без кастомных фонов) ---
        GroupBox {
            title: "Состояние склада"
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
                        Label { text: "Материалы"; font.bold: true }
                        Label {
                            id: materialsValue
                            text: backend.getMaterialsSummary() || "0.00"
                            font.pixelSize: 18
                        }
                        Label { text: "руб."; color: "gray" }
                    }
                }

                Frame {
                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    ColumnLayout {
                        anchors.centerIn: parent
                        Label { text: "Инструменты"; font.bold: true }
                        Label {
                            id: toolsValue
                            text: backend.getToolsSummary() || "0.00"
                            font.pixelSize: 18
                        }
                        Label { text: "руб."; color: "gray" }
                    }
                }

                Frame {
                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    ColumnLayout {
                        anchors.centerIn: parent
                        Label { text: "Готовая продукция"; font.bold: true }
                        Label {
                            id: finishedValue
                            text: backend.getFinishedGoodsSummary() || "0.00"
                            font.pixelSize: 18
                        }
                        Label { text: "руб."; color: "gray" }
                    }
                }
            }
        }

        // --- Лента последних операций ---
        GroupBox {
            title: "Последние операции"
            Layout.fillWidth: true
            Layout.fillHeight: true

            ListView {
                id: transactionList
                anchors.fill: parent
                model: backend.getRecentTransactions(10)
                delegate: Rectangle {
                    width: parent.width
                    height: 30
                    border.color: "#eee"
                    color: index % 2 ? "#fafafa" : "white"

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 5
                        Text { text: modelData.date; Layout.preferredWidth: 100 }
                        Text { text: modelData.type; Layout.preferredWidth: 120; font.bold: true }
                        Text { text: modelData.description; Layout.fillWidth: true }
                        Text { text: modelData.amount; Layout.preferredWidth: 100; horizontalAlignment: Text.AlignRight }
                    }
                }
            }
        }
    }

    Timer {
        id: summaryTimer
        interval: 30000
        repeat: true
        running: true
        onTriggered: {
            materialsValue.text = backend.getMaterialsSummary();
            toolsValue.text = backend.getToolsSummary();
            finishedValue.text = backend.getFinishedGoodsSummary();
            transactionList.model = backend.getRecentTransactions(10);
        }
    }

    Component.onCompleted: summaryTimer.start()
}