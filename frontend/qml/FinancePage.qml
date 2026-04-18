import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Page {
    title: "Финансы и аналитика"

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 20
        spacing: 20

        // --- Дашборд с ключевыми показателями ---
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
                        Label {
                            id: totalAssetsLabel
                            text: "0.00 руб."
                            font.pixelSize: 18
                        }
                    }
                }

                Frame {
                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    ColumnLayout {
                        anchors.centerIn: parent
                        Label { text: "Выручка (месяц)"; font.bold: true }
                        Label {
                            id: revenueLabel
                            text: "0.00 руб."
                            font.pixelSize: 18
                        }
                    }
                }

                Frame {
                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    ColumnLayout {
                        anchors.centerIn: parent
                        Label { text: "Прибыль (месяц)"; font.bold: true }
                        Label {
                            id: profitLabel
                            text: "0.00 руб."
                            font.pixelSize: 18
                        }
                    }
                }

                Frame {
                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    ColumnLayout {
                        anchors.centerIn: parent
                        Label { text: "Рентабельность"; font.bold: true }
                        Label {
                            id: marginLabel
                            text: "0.0 %"
                            font.pixelSize: 18
                        }
                    }
                }
            }
        }

        // --- Отчёт о прибылях и убытках ---
        GroupBox {
            title: "Отчёт о прибылях и убытках"
            Layout.fillWidth: true
            Layout.fillHeight: true

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
                            for (var i = 0; i < lines.length; i++) {
                                if (lines[i].trim() !== "") {
                                    model.push({"text": lines[i]})
                                }
                            }
                            reportList.model = model
                            updateDashboard()
                        }
                    }
                    Button {
                        text: "Экспорт в Excel"
                        onClicked: backend.exportReportToExcel(startDateField.text, endDateField.text)
                    }
                }

                ListView {
                    id: reportList
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true
                    model: []
                    delegate: Text {
                        text: modelData.text
                        font.family: "Courier New"
                        font.pixelSize: 12
                    }
                }
            }
        }
    }

    // Обновление дашборда при загрузке и после расчёта
    function updateDashboard() {
        totalAssetsLabel.text = backend.getTotalAssets() + " руб."
        var revenue = backend.getMonthlyRevenue(startDateField.text, endDateField.text)
        var profit = backend.getMonthlyProfit(startDateField.text, endDateField.text)
        revenueLabel.text = revenue + " руб."
        profitLabel.text = profit + " руб."
        var margin = 0.0
        if (parseFloat(revenue) > 0) {
            margin = (parseFloat(profit) / parseFloat(revenue) * 100).toFixed(1)
        }
        marginLabel.text = margin + " %"
    }

    Component.onCompleted: {
        // Установить период по умолчанию (текущий месяц)
        var today = new Date()
        var year = today.getFullYear()
        var month = String(today.getMonth() + 1).padStart(2, '0')
        startDateField.text = year + "-" + month + "-01"
        var lastDay = new Date(year, today.getMonth() + 1, 0).getDate()
        endDateField.text = year + "-" + month + "-" + String(lastDay).padStart(2, '0')
        updateDashboard()
    }
}