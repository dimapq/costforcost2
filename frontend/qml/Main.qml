import QtQuick
import QtQuick.Controls
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
                var result = backend.exportDatabaseDump()
                root.settingsActionMessage = result.message || ""
                root.settingsActionPath = result.path || ""
                settingsResultDialog.open()
            }
        }
        MenuSeparator { }

        MenuItem {
            text: "\u041f\u0440\u043e\u0432\u0435\u0440\u0438\u0442\u044c \u043e\u0431\u043d\u043e\u0432\u043b\u0435\u043d\u0438\u044f"
            onTriggered: updateManager.checkForUpdates(true)
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
        closePolicy: updateManager.busy ? Popup.NoAutoClose : Popup.CloseOnEscape | Popup.CloseOnPressOutside

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
                        text: updateManager.busy
                              ? "Обновление " + appTitle
                              : (updateManager.updateAvailable
                                 ? "Доступно обновление " + updateManager.latestVersion
                                 : "Проверка обновлений")
                        font.pixelSize: 20
                        font.bold: true
                        Layout.fillWidth: true
                        wrapMode: Text.WordWrap
                    }

                    Label {
                        text: "Текущая версия: " + appVersionLabel + (updateManager.latestVersion ? ("    Новая: v" + updateManager.latestVersion) : "")
                        color: "#666"
                        Layout.fillWidth: true
                        wrapMode: Text.WordWrap
                    }
                }
            }

            Label {
                text: updateManager.statusMessage
                visible: text.length > 0
                Layout.fillWidth: true
                wrapMode: Text.WordWrap
                color: updateManager.statusMessage.indexOf("Ошибка") >= 0 ? "#b23b3b" : "#2f2f2f"
            }

            ProgressBar {
                visible: updateManager.busy && updateManager.progress >= 0
                Layout.fillWidth: true
                from: 0
                to: 100
                value: Math.max(0, updateManager.progress)
            }

            Label {
                text: updateManager.releaseNotes.length > 0 ? ("\u0427\u0442\u043e \u0438\u0437\u043c\u0435\u043d\u0438\u043b\u043e\u0441\u044c:\n" + updateManager.releaseNotes) : ""
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
                    visible: !updateManager.busy && !updateManager.updateAvailable && updateManager.statusMessage.length > 0
                    onClicked: {
                        updateManager.dismissStatus()
                        updatePopup.close()
                    }
                }

                Button {
                    text: "Позже"
                    visible: updateManager.updateAvailable && !updateManager.busy
                    onClicked: {
                        updateManager.dismissStatus()
                        updatePopup.close()
                    }
                }

                Button {
                    text: "Обновить сейчас"
                    highlighted: true
                    visible: updateManager.updateAvailable && !updateManager.busy
                    onClicked: updateManager.downloadAndInstallUpdate()
                }
            }
        }
    }

    Connections {
        target: updateManager

        function onBusyChanged() {
            if (updateManager.busy)
                updatePopup.open()
        }

        function onUpdateAvailableChanged() {
            if (updateManager.updateAvailable)
                updatePopup.open()
        }

        function onStatusMessageChanged() {
            if (updateManager.statusMessage.length > 0)
                updatePopup.open()
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
                text: root.settingsActionPath.length > 0 ? ("Файл: " + root.settingsActionPath) : ""
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

    function loadDatabaseConfig() {
        var cfg = backend.getDatabaseConfig()
        dbHostField.text = cfg.host || "localhost"
        dbPortField.text = cfg.port || "5432"
        dbNameField.text = cfg.name || "cost"
        dbUserField.text = cfg.user || "postgres"
        dbPasswordField.text = cfg.password || ""
        configPathLabel.text = "Файл настроек: " + (cfg.config_path || "config.ini")
    }

    Component.onCompleted: {
        loadDatabaseConfig()
        var cfg = backend.getDatabaseConfig()
        if (cfg.connection_confirmed && backend.testDatabaseConfig(cfg.host, cfg.port, cfg.name, cfg.user, cfg.password).ok) {
            root.connectionReady = true
        } else {
            root.connectionReady = false
            root.connectionMessage = cfg.connection_confirmed ? "Не удалось подключиться. Проверьте параметры." : "Первое подключение: проверьте данные из config.ini."
            connectionDialog.open()
        }
        if (updateManager.enabled)
            updateManager.checkForUpdates(false)
    }
}
