import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Page {
    title: "Быстрые операции"

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 20
        spacing: 20

        // --- Блок учёта рабочего времени ---
        GroupBox {
            title: "Учёт рабочего времени"
            Layout.fillWidth: true
            Layout.preferredHeight: 200

            GridLayout {
                anchors.fill: parent
                columns: 2
                rowSpacing: 10
                columnSpacing: 15

                Label { text: "Работник:" }
                ComboBox {
                    id: employeeCombo
                    Layout.fillWidth: true
                    model: backend.getEmployeesList()
                    textRole: "name"
                    valueRole: "id"
                }

                Label { text: "Готовый станок:" }
                ComboBox {
                    id: finishedGoodCombo
                    Layout.fillWidth: true
                    model: backend.getFinishedGoodsList()
                    textRole: "display"
                    valueRole: "id"
                }

                Label { text: "Часы:" }
                TextField {
                    id: hoursInput
                    Layout.fillWidth: true
                    placeholderText: "Количество часов"
                    validator: DoubleValidator { bottom: 0.1; decimals: 2 }
                }

                Label { text: "Примечание:" }
                TextField {
                    id: notesInput
                    Layout.fillWidth: true
                    placeholderText: "Необязательно"
                }

                Item { Layout.fillWidth: true }

                Button {
                    text: "Записать время"
                    onClicked: {
                        if (employeeCombo.currentValue && finishedGoodCombo.currentValue && hoursInput.text) {
                            var result = backend.logWorkHours(
                                employeeCombo.currentValue,
                                finishedGoodCombo.currentValue,
                                parseFloat(hoursInput.text),
                                notesInput.text
                            );
                            if (result) {
                                hoursInput.clear();
                                notesInput.clear();
                                summaryTimer.start();
                            }
                        }
                    }
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