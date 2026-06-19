import QtQuick
import QtQuick.Controls
import QtQuick.Dialogs
import QtQuick.Layouts

ApplicationWindow {
    id: root
    visible: true
    width: 1200
    height: 800
    title: appTitle

    property bool connectionReady: false
    property string connectionMessage: ""
    property string settingsActionMessage: ""
    property string settingsActionPath: ""
    property string selectedDumpPath: ""
    property var backendObj: (typeof backend !== "undefined") ? backend : null
    property var updateManagerObj: (typeof updateManager !== "undefined") ? updateManager : null
    property string userManualText: "User Manual\n\n"
        + "1. General workflow\n"
        + "The app tracks materials, machines, employees, operations, and finances. Typical workflow: fill the warehouse, configure machine models, start production, add labor and expenses, finish production, and review finance results.\n\n"
        + "2. Operations tab\n"
        + "Quick actions, work time entry, last operations log, and warehouse summary.\n\n"
        + "3. Warehouse -> Materials\n"
        + "Main material stock. You can add, edit, recount, and review where each material is used.\n\n"
        + "4. Warehouse -> Composite materials\n"
        + "Create recipes from several components and produce a composite material.\n\n"
        + "5. Warehouse -> Plate cutting\n"
        + "Manage plate materials, templates, drawings, process files, and produce parts from specific plates.\n\n"
        + "6. Warehouse -> Tools\n"
        + "Tool inventory, write-off, and depreciation.\n\n"
        + "7. Employees\n"
        + "Employees, rates, job history, salary, bonus, and settlements.\n\n"
        + "8. Machines -> Model editor\n"
        + "Configure bill of materials, norms, tools, and other parameters for each machine model.\n\n"
        + "9. Machines -> In progress\n"
        + "Reserve materials, add labor, monitor indirect expenses, cancel or finish production.\n\n"
        + "10. Machines -> In stock\n"
        + "Finished but unsold machines with cost details and production dates.\n\n"
        + "11. Machines -> Sold\n"
        + "Sold machines, sale date, customer, sale price, profit, and tax cost values.\n\n"
        + "12. Finance\n"
        + "Profit and loss, taxes, indirect expenses, and other expenses.\n\n"
        + "13. Settings\n"
        + "Database connection, full Excel export, SQL dump, update check, and this manual.\n\n"
        + "14. Recommended start\n"
        + "Check database connection first, then fill warehouse, employees, and machine models."

    header: ToolBar {
        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 10
            anchors.rightMargin: 10
            spacing: 10

            Image {
                source: appLogoPath
                sourceSize.width: 32
                sourceSize.height: 32
                fillMode: Image.PreserveAspectFit
                smooth: true
                Layout.preferredWidth: 36
                Layout.preferredHeight: 36
            }

            Label {
                text: appTitle
                font.pixelSize: 16
                font.bold: true
                color: "#2f2f2f"
                Layout.rightMargin: 8
            }

            TabBar {
                id: tabBar
                enabled: root.connectionReady
                Layout.fillWidth: true
                TabButton { text: "Операции" }
                TabButton { text: "Склад" }
                TabButton { text: "Сотрудники" }
                TabButton { text: "Станки" }
                TabButton { text: "Финансы" }
            }

            ToolButton {
                id: settingsButton
                text: "⚙"
                font.pixelSize: 22
                onClicked: settingsMenu.popup()
            }
        }
    }

    Menu {
        id: settingsMenu

        MenuItem {
            text: "Настройка подключения"
            onTriggered: {
                loadDatabaseConfig()
                root.connectionMessage = ""
                connectionDialog.open()
            }
        }

        MenuSeparator { }

        MenuItem {
            text: "Руководство пользователя"
            onTriggered: userManualDialog.open()
        }

        MenuSeparator { }

        MenuItem {
            text: "Выгрузка всей БД в Excel"
            onTriggered: {
                var result = backend.exportFullDatabaseToExcel()
                root.settingsActionMessage = result.message || ""
                root.settingsActionPath = result.path || ""
                settingsResultDialog.open()
            }
        }

        MenuItem {
            text: "Дамп всей базы для экспорта"
            onTriggered: {
                var result = backendObj ? backendObj.exportDatabaseDump() : {"message": "Backend недоступен", "path": ""}
                root.settingsActionMessage = result.message || ""
                root.settingsActionPath = result.path || ""
                settingsResultDialog.open()
            }
        }
        MenuItem {
            text: "\u0417\u0430\u0433\u0440\u0443\u0437\u0438\u0442\u044c \u0434\u0430\u043c\u043f \u0431\u0430\u0437\u044b"
            onTriggered: {
                root.selectedDumpPath = ""
                importDumpFileDialog.open()
            }
        }

        MenuItem {
            text: "\u0423\u0434\u0430\u043b\u0438\u0442\u044c \u0432\u0441\u0435 \u0434\u0430\u043d\u043d\u044b\u0435 \u0431\u0430\u0437\u044b"
            onTriggered: {
                clearDataPhraseField.text = ""
                clearDataWarningDialog.open()
            }
        }

        MenuSeparator { }

        MenuItem {
            text: "\u041f\u0440\u043e\u0432\u0435\u0440\u0438\u0442\u044c \u043e\u0431\u043d\u043e\u0432\u043b\u0435\u043d\u0438\u044f"
            onTriggered: { if (updateManagerObj) updateManagerObj.checkForUpdates(true) }
        }
    }

    StackLayout {
        id: stackLayout
        anchors.fill: parent
        currentIndex: tabBar.currentIndex
        enabled: root.connectionReady
        opacity: root.connectionReady ? 1.0 : 0.35

        Loader { active: root.connectionReady; sourceComponent: operationsComponent }
        Loader { active: root.connectionReady; sourceComponent: inventoryComponent }
        Loader { active: root.connectionReady; sourceComponent: employeesComponent }
        Loader { active: root.connectionReady; sourceComponent: machinesComponent }
        Loader { active: root.connectionReady; sourceComponent: financeComponent }
    }

    Component { id: operationsComponent; OperationsPage { } }
    Component { id: inventoryComponent; InventoryPage { } }
    Component { id: employeesComponent; EmployeesPage { } }
    Component { id: machinesComponent; MachinesPage { } }
    Component { id: financeComponent; FinancePage { } }

    Rectangle {
        anchors.fill: parent
        visible: !root.connectionReady
        color: "#f3efe6"
        z: 1

        ColumnLayout {
            anchors.centerIn: parent
            width: Math.min(parent.width - 80, 620)
            spacing: 12

            Label {
                text: "Настройка подключения к базе данных"
                font.pixelSize: 24
                font.bold: true
                Layout.alignment: Qt.AlignHCenter
            }
            Label {
                text: "Проверьте параметры из config.ini и нажмите «Сохранить и подключиться»."
                color: "#555"
                wrapMode: Text.WordWrap
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignHCenter
            }
        }
    }

    Dialog {
        id: connectionDialog
        title: "Подключение к базе данных"
        modal: true
        closePolicy: root.connectionReady ? Popup.CloseOnEscape | Popup.CloseOnPressOutside : Popup.NoAutoClose
        width: 560
        height: 520
        z: 10

        ColumnLayout {
            anchors.fill: parent
            spacing: 10

            Label {
                id: configPathLabel
                text: "config.ini"
                color: "#666"
                wrapMode: Text.WordWrap
                Layout.fillWidth: true
            }

            GridLayout {
                columns: 2
                Layout.fillWidth: true
                columnSpacing: 10
                rowSpacing: 8

                Label { text: "Host:" }
                TextField { id: dbHostField; Layout.fillWidth: true; placeholderText: "localhost" }

                Label { text: "Port:" }
                TextField { id: dbPortField; Layout.fillWidth: true; placeholderText: "5432"; validator: IntValidator { bottom: 1; top: 65535 } }

                Label { text: "Database:" }
                TextField { id: dbNameField; Layout.fillWidth: true; placeholderText: "cost" }

                Label { text: "User:" }
                TextField { id: dbUserField; Layout.fillWidth: true; placeholderText: "postgres" }

                Label { text: "Password:" }
                TextField { id: dbPasswordField; Layout.fillWidth: true; echoMode: TextInput.Password }
            }

            Label {
                text: root.connectionMessage
                visible: root.connectionMessage.length > 0
                color: root.connectionMessage.indexOf("успеш") >= 0 || root.connectionMessage.indexOf("сохранено") >= 0 ? "#2f6f3e" : "#b23b3b"
                wrapMode: Text.WordWrap
                Layout.fillWidth: true
            }

            Item { Layout.fillHeight: true }

            RowLayout {
                Layout.fillWidth: true
                Button {
                    text: "Проверить"
                    onClicked: {
                        var result = backend.testDatabaseConfig(dbHostField.text, dbPortField.text, dbNameField.text, dbUserField.text, dbPasswordField.text)
                        root.connectionMessage = result.message
                    }
                }
                Item { Layout.fillWidth: true }
                Button {
                    text: "Сохранить и подключиться"
                    highlighted: true
                    onClicked: {
                        var result = backend.saveDatabaseConfig(dbHostField.text, dbPortField.text, dbNameField.text, dbUserField.text, dbPasswordField.text)
                        root.connectionMessage = result.message
                        if (result.ok) {
                            root.connectionReady = true
                            connectionDialog.close()
                        }
                    }
                }
                Button {
                    text: "Закрыть"
                    enabled: root.connectionReady
                    onClicked: connectionDialog.close()
                }
            }
        }
    }


    Popup {
        id: updatePopup
        modal: true
        focus: true
        x: Math.round((root.width - width) / 2)
        y: Math.round((root.height - height) / 2)
        width: Math.min(root.width - 40, 470)
        padding: 16
        closePolicy: updateManagerObj && updateManagerObj.busy ? Popup.NoAutoClose : Popup.CloseOnEscape | Popup.CloseOnPressOutside

        background: Rectangle {
            radius: 12
            color: "white"
            border.color: "#d8dee7"
        }

        ColumnLayout {
            anchors.fill: parent
            spacing: 12

            RowLayout {
                Layout.fillWidth: true
                spacing: 12

                Image {
                    source: updateLogoPath
                    sourceSize.width: 72
                    sourceSize.height: 72
                    fillMode: Image.PreserveAspectFit
                    Layout.preferredWidth: 72
                    Layout.preferredHeight: 72
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 4

                    Label {
                        text: updateManagerObj && updateManagerObj.busy
                              ? "Обновление " + appTitle
                              : (updateManagerObj && updateManagerObj.updateAvailable
                                 ? "Доступно обновление " + updateManagerObj.latestVersion
                                 : "Проверка обновлений")
                        font.pixelSize: 20
                        font.bold: true
                        Layout.fillWidth: true
                        wrapMode: Text.WordWrap
                    }

                    Label {
                        text: "Текущая версия: " + appVersionLabel + ((updateManagerObj && updateManagerObj.latestVersion) ? ("    Новая: v" + updateManagerObj.latestVersion) : "")
                        color: "#666"
                        Layout.fillWidth: true
                        wrapMode: Text.WordWrap
                    }
                }
            }

            Label {
                text: updateManagerObj ? updateManagerObj.statusMessage : ""
                visible: text.length > 0
                Layout.fillWidth: true
                wrapMode: Text.WordWrap
                color: text.indexOf("Ошибка") >= 0 ? "#b23b3b" : "#2f2f2f"
            }

            ProgressBar {
                visible: updateManagerObj && updateManagerObj.busy && updateManagerObj.progress >= 0
                Layout.fillWidth: true
                from: 0
                to: 100
                value: Math.max(0, updateManagerObj ? updateManagerObj.progress : 0)
            }

            Label {
                text: updateManagerObj && updateManagerObj.releaseNotes.length > 0 ? ("\u0427\u0442\u043e \u0438\u0437\u043c\u0435\u043d\u0438\u043b\u043e\u0441\u044c:\n" + updateManagerObj.releaseNotes) : ""
                visible: text.length > 0
                Layout.fillWidth: true
                wrapMode: Text.WordWrap
                color: "#555"
            }

            RowLayout {
                Layout.fillWidth: true
                Item { Layout.fillWidth: true }

                Button {
                    text: "Закрыть"
                    visible: updateManagerObj && !updateManagerObj.busy && !updateManagerObj.updateAvailable && updateManagerObj.statusMessage.length > 0
                    onClicked: {
                        if (updateManagerObj) updateManagerObj.dismissStatus()
                        updatePopup.close()
                    }
                }

                Button {
                    text: "Позже"
                    visible: updateManagerObj && updateManagerObj.updateAvailable && !updateManagerObj.busy
                    onClicked: {
                        if (updateManagerObj) updateManagerObj.dismissStatus()
                        updatePopup.close()
                    }
                }

                Button {
                    text: "Обновить сейчас"
                    highlighted: true
                    visible: updateManagerObj && updateManagerObj.updateAvailable && !updateManagerObj.busy
                    onClicked: { if (updateManagerObj) updateManagerObj.downloadAndInstallUpdate() }
                }
            }
        }
    }

    Connections {
        target: updateManagerObj

        function onBusyChanged() {
            if (updateManagerObj && updateManagerObj.busy)
                updatePopup.open()
        }

        function onUpdateAvailableChanged() {
            if (updateManagerObj && updateManagerObj.updateAvailable)
                updatePopup.open()
        }

        function onStatusMessageChanged() {
            if (updateManagerObj && updateManagerObj.statusMessage.length > 0)
                updatePopup.open()
        }
    }

    Dialog {
        id: userManualDialog
        title: "Руководство пользователя"
        modal: true
        width: Math.min(root.width - 40, 900)
        height: Math.min(root.height - 40, 760)

        ColumnLayout {
            anchors.fill: parent
            spacing: 10

            ScrollView {
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true

                TextArea {
                    readOnly: true
                    wrapMode: TextEdit.Wrap
                    text: root.userManualText
                    textFormat: TextEdit.PlainText
                    selectByMouse: true
                }
            }

            RowLayout {
                Layout.fillWidth: true
                Item { Layout.fillWidth: true }
                Button {
                    text: "Закрыть"
                    onClicked: userManualDialog.close()
                }
            }
        }
    }

    FileDialog {
        id: importDumpFileDialog
        title: "\u0412\u044b\u0431\u043e\u0440 SQL-\u0434\u0430\u043c\u043f\u0430"
        fileMode: FileDialog.OpenFile
        nameFilters: ["SQL dump (*.sql)", "All files (*)"]
        onAccepted: {
            root.selectedDumpPath = root.normalizeFilePath(selectedFile)
            importDumpPhraseField.text = ""
            importDumpWarningDialog.open()
        }
    }

    Dialog {
        id: importDumpWarningDialog
        title: "\u0418\u043c\u043f\u043e\u0440\u0442 \u0434\u0430\u043c\u043f\u0430 \u0431\u0430\u0437\u044b"
        modal: true
        width: 560

        ColumnLayout {
            anchors.fill: parent
            spacing: 10

            Label {
                text: "\u0412\u044b\u0431\u0440\u0430\u043d\u043d\u044b\u0439 \u0434\u0430\u043c\u043f \u043f\u043e\u043b\u043d\u043e\u0441\u0442\u044c\u044e \u0437\u0430\u043c\u0435\u043d\u0438\u0442 \u0442\u0435\u043a\u0443\u0449\u0435\u0435 \u0441\u043e\u0434\u0435\u0440\u0436\u0438\u043c\u043e\u0435 \u0431\u0430\u0437\u044b."
                wrapMode: Text.WordWrap
                Layout.fillWidth: true
            }

            Label {
                text: "\u0420\u0435\u043a\u043e\u043c\u0435\u043d\u0434\u0443\u0435\u0442\u0441\u044f: \u0441\u043d\u0430\u0447\u0430\u043b\u0430 \u0441\u0434\u0435\u043b\u0430\u0442\u044c \u0434\u0430\u043c\u043f \u0442\u0435\u043a\u0443\u0449\u0435\u0439 \u0431\u0430\u0437\u044b, \u0430 \u0437\u0430\u0442\u0435\u043c \u043f\u0440\u043e\u0434\u043e\u043b\u0436\u0438\u0442\u044c \u0438\u043c\u043f\u043e\u0440\u0442."
                wrapMode: Text.WordWrap
                Layout.fillWidth: true
                color: "#8a5a00"
            }

            Label {
                text: root.selectedDumpPath.length > 0 ? ("\u0424\u0430\u0439\u043b: " + root.selectedDumpPath) : ""
                visible: root.selectedDumpPath.length > 0
                color: "#555"
                wrapMode: Text.WordWrap
                Layout.fillWidth: true
            }

            RowLayout {
                Layout.fillWidth: true
                Item { Layout.fillWidth: true }
                Button {
                    text: "\u041e\u0442\u043c\u0435\u043d\u0430"
                    onClicked: importDumpWarningDialog.close()
                }
                Button {
                    text: "\u041f\u0440\u043e\u0434\u043e\u043b\u0436\u0438\u0442\u044c"
                    highlighted: true
                    onClicked: {
                        importDumpWarningDialog.close()
                        importDumpPhraseDialog.open()
                    }
                }
            }
        }
    }

    Dialog {
        id: importDumpPhraseDialog
        title: "\u0418\u0442\u043e\u0433\u043e\u0432\u043e\u0435 \u043f\u043e\u0434\u0442\u0432\u0435\u0440\u0436\u0434\u0435\u043d\u0438\u0435"
        modal: true
        width: 560

        ColumnLayout {
            anchors.fill: parent
            spacing: 10

            Label {
                text: "\u0412\u0432\u0435\u0434\u0438\u0442\u0435 IMPORT, \u0447\u0442\u043e\u0431\u044b \u043f\u043e\u0434\u0442\u0432\u0435\u0440\u0434\u0438\u0442\u044c \u0437\u0430\u0433\u0440\u0443\u0437\u043a\u0443 \u0434\u0430\u043c\u043f\u0430 \u0438 \u0437\u0430\u043c\u0435\u043d\u0443 \u0442\u0435\u043a\u0443\u0449\u0438\u0445 \u0434\u0430\u043d\u043d\u044b\u0445."
                wrapMode: Text.WordWrap
                Layout.fillWidth: true
            }

            TextField {
                id: importDumpPhraseField
                Layout.fillWidth: true
                placeholderText: "IMPORT"
            }

            RowLayout {
                Layout.fillWidth: true
                Item { Layout.fillWidth: true }
                Button {
                    text: "\u041d\u0430\u0437\u0430\u0434"
                    onClicked: importDumpPhraseDialog.close()
                }
                Button {
                    text: "\u0417\u0430\u0433\u0440\u0443\u0437\u0438\u0442\u044c \u0434\u0430\u043c\u043f"
                    highlighted: true
                    enabled: importDumpPhraseField.text.trim() === "IMPORT" && root.selectedDumpPath.length > 0
                    onClicked: {
                        importDumpPhraseDialog.close()
                        var result = backendObj ? backendObj.importDatabaseDump(root.selectedDumpPath) : {"message": "\u0411\u044d\u043a\u0435\u043d\u0434 \u043d\u0435\u0434\u043e\u0441\u0442\u0443\u043f\u0435\u043d", "path": ""}
                        root.settingsActionMessage = result.message || ""
                        root.settingsActionPath = result.path || ""
                        settingsResultDialog.open()
                    }
                }
            }
        }
    }

    Dialog {
        id: clearDataWarningDialog
        title: "\u0423\u0434\u0430\u043b\u0435\u043d\u0438\u0435 \u0432\u0441\u0435\u0445 \u0434\u0430\u043d\u043d\u044b\u0445"
        modal: true
        width: 560

        ColumnLayout {
            anchors.fill: parent
            spacing: 10

            Label {
                text: "\u042d\u0442\u043e \u0434\u0435\u0439\u0441\u0442\u0432\u0438\u0435 \u0443\u0434\u0430\u043b\u0438\u0442 \u0432\u0441\u0435 \u0437\u0430\u043f\u0438\u0441\u0438 \u0438\u0437 \u0431\u0430\u0437\u044b, \u043d\u043e \u0441\u043e\u0445\u0440\u0430\u043d\u0438\u0442 \u0441\u0442\u0440\u0443\u043a\u0442\u0443\u0440\u0443 \u0442\u0430\u0431\u043b\u0438\u0446."
                wrapMode: Text.WordWrap
                Layout.fillWidth: true
            }

            Label {
                text: "\u0418\u0441\u043f\u043e\u043b\u044c\u0437\u0443\u0439\u0442\u0435 \u044d\u0442\u043e \u0442\u043e\u043b\u044c\u043a\u043e \u0435\u0441\u043b\u0438 \u0442\u043e\u0447\u043d\u043e \u0443\u0432\u0435\u0440\u0435\u043d\u044b, \u0447\u0442\u043e \u0442\u0435\u043a\u0443\u0449\u0438\u0435 \u0434\u0430\u043d\u043d\u044b\u0435 \u0431\u043e\u043b\u044c\u0448\u0435 \u043d\u0435 \u043d\u0443\u0436\u043d\u044b."
                wrapMode: Text.WordWrap
                Layout.fillWidth: true
                color: "#8a5a00"
            }

            RowLayout {
                Layout.fillWidth: true
                Item { Layout.fillWidth: true }
                Button {
                    text: "\u041e\u0442\u043c\u0435\u043d\u0430"
                    onClicked: clearDataWarningDialog.close()
                }
                Button {
                    text: "\u041f\u0440\u043e\u0434\u043e\u043b\u0436\u0438\u0442\u044c"
                    highlighted: true
                    onClicked: {
                        clearDataWarningDialog.close()
                        clearDataPhraseDialog.open()
                    }
                }
            }
        }
    }

    Dialog {
        id: clearDataPhraseDialog
        title: "\u0412\u0442\u043e\u0440\u043e\u0435 \u043f\u043e\u0434\u0442\u0432\u0435\u0440\u0436\u0434\u0435\u043d\u0438\u0435"
        modal: true
        width: 560

        ColumnLayout {
            anchors.fill: parent
            spacing: 10

            Label {
                text: "\u0412\u0432\u0435\u0434\u0438\u0442\u0435 DELETE ALL, \u0447\u0442\u043e\u0431\u044b \u0440\u0430\u0437\u0431\u043b\u043e\u043a\u0438\u0440\u043e\u0432\u0430\u0442\u044c \u0444\u0438\u043d\u0430\u043b\u044c\u043d\u0443\u044e \u043a\u043d\u043e\u043f\u043a\u0443 \u0443\u0434\u0430\u043b\u0435\u043d\u0438\u044f."
                wrapMode: Text.WordWrap
                Layout.fillWidth: true
            }

            TextField {
                id: clearDataPhraseField
                Layout.fillWidth: true
                placeholderText: "DELETE ALL"
            }

            RowLayout {
                Layout.fillWidth: true
                Item { Layout.fillWidth: true }
                Button {
                    text: "\u041d\u0430\u0437\u0430\u0434"
                    onClicked: clearDataPhraseDialog.close()
                }
                Button {
                    text: "\u041f\u0440\u043e\u0434\u043e\u043b\u0436\u0438\u0442\u044c"
                    highlighted: true
                    enabled: clearDataPhraseField.text.trim() === "DELETE ALL"
                    onClicked: {
                        clearDataPhraseDialog.close()
                        clearDataFinalDialog.open()
                    }
                }
            }
        }
    }

    Dialog {
        id: clearDataFinalDialog
        title: "\u041f\u043e\u0441\u043b\u0435\u0434\u043d\u0435\u0435 \u043f\u043e\u0434\u0442\u0432\u0435\u0440\u0436\u0434\u0435\u043d\u0438\u0435"
        modal: true
        width: 560

        ColumnLayout {
            anchors.fill: parent
            spacing: 10

            Label {
                text: "\u041d\u0430\u0436\u043c\u0438\u0442\u0435 \u0444\u0438\u043d\u0430\u043b\u044c\u043d\u0443\u044e \u043a\u043d\u043e\u043f\u043a\u0443 \u0442\u043e\u043b\u044c\u043a\u043e \u0435\u0441\u043b\u0438 \u0432\u044b \u0434\u0435\u0439\u0441\u0442\u0432\u0438\u0442\u0435\u043b\u044c\u043d\u043e \u0445\u043e\u0442\u0438\u0442\u0435 \u0441\u0442\u0435\u0440\u0435\u0442\u044c \u0432\u0441\u0435 \u0442\u0435\u043a\u0443\u0449\u0438\u0435 \u0437\u0430\u043f\u0438\u0441\u0438."
                wrapMode: Text.WordWrap
                Layout.fillWidth: true
            }

            RowLayout {
                Layout.fillWidth: true
                Item { Layout.fillWidth: true }
                Button {
                    text: "\u041e\u0442\u043c\u0435\u043d\u0430"
                    onClicked: clearDataFinalDialog.close()
                }
                Button {
                    text: "\u0423\u0434\u0430\u043b\u0438\u0442\u044c \u0432\u0441\u0435 \u0434\u0430\u043d\u043d\u044b\u0435 \u0441\u0435\u0439\u0447\u0430\u0441"
                    highlighted: true
                    onClicked: {
                        clearDataFinalDialog.close()
                        var result = backendObj ? backendObj.clearAllDatabaseData() : {"message": "\u0411\u044d\u043a\u0435\u043d\u0434 \u043d\u0435\u0434\u043e\u0441\u0442\u0443\u043f\u0435\u043d", "path": ""}
                        root.settingsActionMessage = result.message || ""
                        root.settingsActionPath = ""
                        settingsResultDialog.open()
                    }
                }
            }
        }
    }

    Dialog {
        id: settingsResultDialog
        title: "Результат"
        modal: true
        width: 560

        ColumnLayout {
            anchors.fill: parent
            spacing: 10

            Label {
                text: root.settingsActionMessage
                wrapMode: Text.WordWrap
                Layout.fillWidth: true
            }

            Label {
                text: root.settingsActionPath.length > 0 ? ("Р¤Р°Р№Р»: " + root.settingsActionPath) : ""
                visible: root.settingsActionPath.length > 0
                color: "#555"
                wrapMode: Text.WordWrap
                Layout.fillWidth: true
            }

            RowLayout {
                Layout.fillWidth: true
                Item { Layout.fillWidth: true }
                Button {
                    text: "Закрыть"
                    onClicked: settingsResultDialog.close()
                }
            }
        }
    }

    function normalizeFilePath(urlValue) {
        var value = urlValue ? urlValue.toString() : ""
        if (value.indexOf("file:///") === 0)
            value = decodeURIComponent(value.substring(8))
        return value
    }

    function loadDatabaseConfig() {
        var cfg = backendObj ? backendObj.getDatabaseConfig() : {}
        dbHostField.text = cfg.host || "localhost"
        dbPortField.text = cfg.port || "5432"
        dbNameField.text = cfg.name || "cost"
        dbUserField.text = cfg.user || "postgres"
        dbPasswordField.text = cfg.password || ""
        configPathLabel.text = "Файл настроек: " + (cfg.config_path || "config.ini")
    }

    Component.onCompleted: {
        loadDatabaseConfig()
        var cfg = backendObj ? backendObj.getDatabaseConfig() : {}
        if (backendObj && cfg.connection_confirmed && backendObj.testDatabaseConfig(cfg.host, cfg.port, cfg.name, cfg.user, cfg.password).ok) {
            root.connectionReady = true
        } else {
            root.connectionReady = false
            root.connectionMessage = cfg.connection_confirmed ? "Не удалось подключиться. Проверьте параметры." : "Первое подключение: проверьте данные из config.ini."
            connectionDialog.open()
        }
        if (updateManagerObj && updateManagerObj.enabled)
            updateManagerObj.checkForUpdates(false)
    }
}




