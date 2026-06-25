import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Page {
    title: "Быстрые операции"

    property string successBannerText: ""
    property var tailscaleClients: []
    property string editingClientIp: ""
    property string editingClientName: ""

    function refreshOperationsDashboard() {
        if (!backend) {
            return
        }
        materialsValue.text = backend.getMaterialsSummary()
        toolsValue.text = backend.getToolsSummary()
        finishedValue.text = backend.getFinishedGoodsSummary()
        transactionList.model = backend.getRecentTransactions(50)
    }

    function refreshTailscaleClients() {
        if (!backend) {
            tailscaleClients = []
            return
        }
        backend.touchClientHeartbeat()
        tailscaleClients = backend.getTailscaleClients()
    }

    function formatHoursAndMinutes(hoursValue) {
        var totalMinutes = Math.round(Number(hoursValue) * 60)
        var hours = Math.floor(totalMinutes / 60)
        var minutes = totalMinutes % 60
        return hours + " ч " + minutes + " мин"
    }

    Connections {
        target: backend

        function onOperationsLogChanged() {
            refreshOperationsDashboard()
        }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 20
        spacing: 20

        GroupBox {
            Layout.fillWidth: true
            title: "Клиенты Tailscale"

            ColumnLayout {
                anchors.fill: parent
                spacing: 8

                RowLayout {
                    Layout.fillWidth: true

                    Label {
                        text: "Зелёный: подключен к БД. Жёлтый: в сети, но приложение не активно. Красный: не в сети."
                        color: "#666"
                        wrapMode: Text.WordWrap
                        Layout.fillWidth: true
                    }

                    Button {
                        text: "Обновить"
                        onClicked: refreshTailscaleClients()
                    }
                }

                ListView {
                    id: tailscaleClientsList
                    Layout.fillWidth: true
                    Layout.preferredHeight: 150
                    clip: true
                    model: tailscaleClients

                    delegate: Rectangle {
                        width: ListView.view ? ListView.view.width : parent.width
                        height: 42
                        color: index % 2 ? "#fafafa" : "white"
                        border.color: "#e5e5e5"

                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: 6
                            spacing: 10

                            Rectangle {
                                width: 14
                                height: 14
                                radius: 7
                                color: modelData.status === "green" ? "#2e9d57" : (modelData.status === "yellow" ? "#d8a106" : "#d9534f")
                                border.color: "#777"
                                Layout.alignment: Qt.AlignVCenter
                            }

                            Label {
                                text: (modelData.display_name && modelData.display_name.length > 0 ? modelData.display_name : (modelData.machine_name && modelData.machine_name.length > 0 ? modelData.machine_name : modelData.ip))
                                font.bold: true
                                Layout.preferredWidth: 180
                                elide: Text.ElideRight
                            }

                            Label {
                                text: modelData.ip
                                Layout.preferredWidth: 120
                            }

                            Label {
                                text: modelData.status_text
                                color: modelData.status === "green" ? "#2e7d32" : (modelData.status === "yellow" ? "#9a6b00" : "#c62828")
                                Layout.preferredWidth: 220
                                elide: Text.ElideRight
                            }

                            Label {
                                text: "Последняя активность: " + (modelData.last_seen || "-")
                                Layout.fillWidth: true
                                elide: Text.ElideRight
                            }

                            Button {
                                text: "Имя"
                                onClicked: {
                                    editingClientIp = modelData.ip || ""
                                    editingClientName = modelData.display_name || ""
                                    clientNameField.text = editingClientName
                                    renameClientDialog.open()
                                }
                            }
                        }
                    }
                }
            }
        }

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
                        model: backend ? backend.getEmployeesList() : []
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
                        text: formatHoursAndMinutes(hoursSpinBox.realValue)
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
                        enabled: inProgressMachineCombo.currentIndex >= 0 && employeeComboWorkLog.currentIndex >= 0
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
                                successBannerText = "Часы успешно добавлены"
                                successBanner.open()
                                successBannerTimer.restart()
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
                model: []
                delegate: Rectangle {
                    width: parent.width
                    height: 48
                    border.color: "#eee"
                    color: index % 2 ? "#fafafa" : "white"

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 5
                        Text { text: modelData.date; Layout.preferredWidth: 100 }
                        Text { text: modelData.type; Layout.preferredWidth: 120; font.bold: true }
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 1

                            Text {
                                text: modelData.description
                                Layout.fillWidth: true
                                elide: Text.ElideRight
                            }
                            Text {
                                text: "Кто: " + (modelData.actor || "Неизвестно")
                                color: "#666"
                                font.pixelSize: 11
                                Layout.fillWidth: true
                                elide: Text.ElideRight
                            }
                        }
                        Text { text: modelData.amount; Layout.preferredWidth: 100; horizontalAlignment: Text.AlignRight }
                    }
                }
            }
        }
    }

    Popup {
        id: successBanner
        x: (parent.width - width) / 2
        y: 16
        width: bannerLabel.implicitWidth + 36
        height: 46
        modal: false
        focus: false
        closePolicy: Popup.NoAutoClose
        padding: 0
        background: Rectangle {
            radius: 8
            color: "#dff3e3"
            border.color: "#86c796"
        }

        contentItem: Label {
            id: bannerLabel
            text: successBannerText
            color: "#1f6b33"
            font.bold: true
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            padding: 12
        }
    }

    Dialog {
        id: renameClientDialog
        title: "Имя клиента"
        modal: true
        standardButtons: Dialog.Ok | Dialog.Cancel
        width: 420

        ColumnLayout {
            anchors.fill: parent
            spacing: 10

            Label { text: "IP: " + editingClientIp }
            TextField {
                id: clientNameField
                Layout.fillWidth: true
                placeholderText: "Например: Ноутбук цех"
            }
        }

        onAccepted: {
            var result = backend.updateTailscaleClientName(editingClientIp, clientNameField.text)
            if (result && result.ok) {
                refreshTailscaleClients()
            }
        }
    }

    Timer {
        id: successBannerTimer
        interval: 2200
        repeat: false
        onTriggered: successBanner.close()
    }

    Timer {
        id: summaryTimer
        interval: 30000
        repeat: true
        running: true
        onTriggered: {
            refreshOperationsDashboard();
            refreshTailscaleClients();
        }
    }

    Component.onCompleted: {
        refreshOperationsDashboard()
        refreshTailscaleClients()
        summaryTimer.start()
    }
}

