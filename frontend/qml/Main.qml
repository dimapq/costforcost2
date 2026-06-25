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
    property string selectedConnectionMode: "online"
    property string connectionDialogTitleText: "Подключение к онлайн-базе"
    property string connectionDialogHintText: "Введите параметры онлайн-базы и нажмите «Сохранить и подключиться». После успешного входа параметры сохраняются в config.ini и используются автоматически при следующем запуске."
    property string onlineConfigPreview: ""
    property string onlineConfigExportPath: ""
    property string onlineHostValue: ""
    property string onlinePortValue: ""
    property string onlineDbNameValue: ""
    property string onlineUserValue: ""
    property string onlinePasswordMaskedValue: ""
    property string fifoAutotestMessage: "Автотест FIFO ещё не запускался."
    property string fifoAutotestDetails: ""
    property color fifoAutotestColor: "#bcbcbc"
    property var backendObj: (typeof backend !== "undefined") ? backend : null
    property var updateManagerObj: (typeof updateManager !== "undefined") ? updateManager : null
    property string userManualText: "Руководство пользователя\n\n"
        + "1. Общий порядок работы\n"
        + "Приложение ведёт учёт материалов, станков, сотрудников, операций и финансов. Обычный сценарий: заполнить склад, настроить модели станков, запустить производство, добавить трудозатраты и расходы, завершить производство и проверить финансовый результат.\n\n"
        + "2. Вкладка «Операции»\n"
        + "Быстрые действия, учёт рабочего времени, журнал последних операций и сводка по складу.\n\n"
        + "3. Склад -> Материалы\n"
        + "Основной склад материалов. Здесь можно добавлять, редактировать, пересчитывать остатки и смотреть, где используется каждый материал.\n\n"
        + "4. Склад -> Составные материалы\n"
        + "Создание рецептов из нескольких компонентов и выпуск составного материала.\n\n"
        + "5. Склад -> Раскрой плит\n"
        + "Работа с плитными материалами, шаблонами, чертежами, файлами обработки и выпуском деталей из конкретных плит.\n\n"
        + "6. Склад -> Инструменты\n"
        + "Учёт инструмента, списание и амортизация.\n\n"
        + "7. Сотрудники\n"
        + "Сотрудники, ставки, история работ, зарплата, премии и взаиморасчёты.\n\n"
        + "8. Станки -> Редактор моделей\n"
        + "Настройка состава материалов, норм, инструмента и других параметров для каждой модели станка.\n\n"
        + "9. Станки -> В процессе\n"
        + "Резервирование материалов, добавление часов, контроль косвенных расходов, отмена или завершение производства.\n\n"
        + "10. Станки -> На складе\n"
        + "Готовые, но ещё не проданные станки с деталями себестоимости и датами производства.\n\n"
        + "11. Станки -> Проданные\n"
        + "Проданные станки, дата продажи, покупатель, цена продажи, прибыль и налоговая себестоимость.\n\n"
        + "12. Финансы\n"
        + "Прибыль и убытки, налоги, косвенные и прочие расходы.\n\n"
        + "13. Настройки\n"
        + "Подключение к базе, полный экспорт в Excel, SQL-дамп, проверка обновлений и это руководство.\n\n"
        + "14. С чего начать\n"
        + "Сначала проверьте подключение к базе, затем заполните склад, сотрудников и модели станков."

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
                root.selectedConnectionMode = "online"
                loadDatabaseConfig("online")
                root.connectionMessage = ""
                connectionDialog.open()
            }
        }

        MenuSeparator { }

        MenuItem {
            text: "\u041f\u043e\u043a\u0430\u0437\u0430\u0442\u044c \u043f\u0430\u0440\u0430\u043c\u0435\u0442\u0440\u044b \u043e\u043d\u043b\u0430\u0439\u043d-\u043f\u043e\u0434\u043a\u043b\u044e\u0447\u0435\u043d\u0438\u044f"
            onTriggered: {
                root.refreshOnlineConnectionInfo()
                onlineConnectionDialog.open()
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
                var result = backendObj ? backendObj.exportDatabaseDump() : {"message": "Бэкенд недоступен", "path": ""}
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
            text: "Автотесты"
            onTriggered: {
                root.fifoAutotestMessage = "Автотест FIFO ещё не запускался."
                root.fifoAutotestDetails = ""
                root.fifoAutotestColor = "#bcbcbc"
                autotestsDialog.open()
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
                text: "Подключение к онлайн-базе"
                font.pixelSize: 24
                font.bold: true
                Layout.alignment: Qt.AlignHCenter
            }
            Label {
                text: root.connectionDialogHintText
                color: "#555"
                wrapMode: Text.WordWrap
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignHCenter
            }

            Button {
                text: "Настроить подключение"
                Layout.alignment: Qt.AlignHCenter
                onClicked: {
                    root.connectionMessage = ""
                    loadDatabaseConfig("online")
                    connectionDialog.open()
                }
            }
        }
    }

    Dialog {
        id: connectionDialog
        title: root.connectionDialogTitleText
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

            Label {
                text: root.connectionDialogHintText
                color: "#555"
                wrapMode: Text.WordWrap
                Layout.fillWidth: true
            }

            GridLayout {
                columns: 2
                Layout.fillWidth: true
                columnSpacing: 10
                rowSpacing: 8

                Label { text: "Хост:" }
                TextField { id: dbHostField; Layout.fillWidth: true; placeholderText: "100.86.4.84" }

                Label { text: "Порт:" }
                TextField { id: dbPortField; Layout.fillWidth: true; placeholderText: "5432"; validator: IntValidator { bottom: 1; top: 65535 } }

                Label { text: "База данных:" }
                TextField { id: dbNameField; Layout.fillWidth: true; placeholderText: "cost" }

                Label { text: "Пользователь:" }
                TextField { id: dbUserField; Layout.fillWidth: true; placeholderText: "cost_client_app" }

                Label { text: "Пароль:" }
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
                        var result = backendObj ? backendObj.saveDatabaseConfigForMode("online", dbHostField.text, dbPortField.text, dbNameField.text, dbUserField.text, dbPasswordField.text) : {"ok": false, "message": "Бэкенд недоступен"}
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
        nameFilters: ["SQL-дамп (*.sql)", "Все файлы (*)"]
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
        id: onlineConnectionDialog
        title: "\u041f\u0430\u0440\u0430\u043c\u0435\u0442\u0440\u044b \u043e\u043d\u043b\u0430\u0439\u043d-\u043f\u043e\u0434\u043a\u043b\u044e\u0447\u0435\u043d\u0438\u044f"
        modal: true
        width: Math.min(root.width - 40, 760)
        height: Math.min(root.height - 40, 640)

        ColumnLayout {
            anchors.fill: parent
            spacing: 10

            Label {
                text: "\u0417\u0434\u0435\u0441\u044c \u0441\u043e\u0431\u0440\u0430\u043d\u044b \u043f\u0430\u0440\u0430\u043c\u0435\u0442\u0440\u044b \u0434\u043b\u044f \u043a\u043b\u0438\u0435\u043d\u0442\u0441\u043a\u043e\u0433\u043e \u043f\u0440\u0438\u043b\u043e\u0436\u0435\u043d\u0438\u044f: \u043c\u043e\u0436\u043d\u043e \u043f\u043e\u0441\u043c\u043e\u0442\u0440\u0435\u0442\u044c \u0434\u0430\u043d\u043d\u044b\u0435, \u0432\u044b\u0433\u0440\u0443\u0437\u0438\u0442\u044c \u043e\u0442\u0434\u0435\u043b\u044c\u043d\u044b\u0439 config.ini \u0438 \u0441\u043c\u0435\u043d\u0438\u0442\u044c \u043f\u0430\u0440\u043e\u043b\u044c."
                wrapMode: Text.WordWrap
                Layout.fillWidth: true
            }

            GridLayout {
                columns: 2
                Layout.fillWidth: true
                columnSpacing: 10
                rowSpacing: 8

                Label { text: "Хост:" }
                TextField { readOnly: true; text: root.onlineHostValue; Layout.fillWidth: true }

                Label { text: "Порт:" }
                TextField { readOnly: true; text: root.onlinePortValue; Layout.fillWidth: true }

                Label { text: "База данных:" }
                TextField { readOnly: true; text: root.onlineDbNameValue; Layout.fillWidth: true }

                Label { text: "Пользователь:" }
                TextField { readOnly: true; text: root.onlineUserValue; Layout.fillWidth: true }

                Label { text: "Пароль:" }
                TextField { readOnly: true; text: root.onlinePasswordMaskedValue; Layout.fillWidth: true }
            }

            Label {
                text: root.onlineConfigExportPath.length > 0 ? ("Последний клиентский config.ini: " + root.onlineConfigExportPath) : ""
                visible: root.onlineConfigExportPath.length > 0
                color: "#555"
                wrapMode: Text.WordWrap
                Layout.fillWidth: true
            }

            ScrollView {
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true

                TextArea {
                    readOnly: true
                    wrapMode: TextEdit.NoWrap
                    text: root.onlineConfigPreview
                    textFormat: TextEdit.PlainText
                    selectByMouse: true
                }
            }

            RowLayout {
                Layout.fillWidth: true

                Button {
                    text: "Выгрузить клиентский config.ini"
                    onClicked: {
                        var result = backendObj ? backendObj.exportClientOnlineConfig() : {"ok": false, "message": "\u0411\u044d\u043a\u0435\u043d\u0434 \u043d\u0435\u0434\u043e\u0441\u0442\u0443\u043f\u0435\u043d", "path": ""}
                        root.settingsActionMessage = result.message || ""
                        root.settingsActionPath = result.path || ""
                        if (result.ok) {
                            root.onlineConfigExportPath = result.path || ""
                            root.refreshOnlineConnectionInfo()
                        }
                        settingsResultDialog.open()
                    }
                }

                Button {
                    text: "\u0421\u043c\u0435\u043d\u0438\u0442\u044c \u043f\u0430\u0440\u043e\u043b\u044c"
                    onClicked: {
                        newOnlinePasswordField.text = ""
                        confirmOnlinePasswordField.text = ""
                        onlinePasswordChangeDialog.open()
                    }
                }

                Item { Layout.fillWidth: true }

                Button {
                    text: "\u0417\u0430\u043a\u0440\u044b\u0442\u044c"
                    onClicked: onlineConnectionDialog.close()
                }
            }
        }
    }

    Dialog {
        id: onlinePasswordChangeDialog
        title: "\u0421\u043c\u0435\u043d\u0430 \u043f\u0430\u0440\u043e\u043b\u044f \u043e\u043d\u043b\u0430\u0439\u043d-\u043f\u043e\u0434\u043a\u043b\u044e\u0447\u0435\u043d\u0438\u044f"
        modal: true
        width: 520

        ColumnLayout {
            anchors.fill: parent
            spacing: 10

            Label {
                text: "\u041f\u0430\u0440\u043e\u043b\u044c \u0431\u0443\u0434\u0435\u0442 \u0438\u0437\u043c\u0435\u043d\u0435\u043d \u0443 \u043f\u043e\u043b\u044c\u0437\u043e\u0432\u0430\u0442\u0435\u043b\u044f \u043e\u043d\u043b\u0430\u0439\u043d-\u0431\u0430\u0437\u044b \u0438 \u043e\u0434\u043d\u043e\u0432\u0440\u0435\u043c\u0435\u043d\u043d\u043e \u0437\u0430\u043f\u0438\u0441\u0430\u043d \u0432 \u043a\u043b\u0438\u0435\u043d\u0442\u0441\u043a\u0438\u0439 config.ini."
                wrapMode: Text.WordWrap
                Layout.fillWidth: true
            }

            Label { text: "\u041d\u043e\u0432\u044b\u0439 \u043f\u0430\u0440\u043e\u043b\u044c:" }
            TextField {
                id: newOnlinePasswordField
                Layout.fillWidth: true
                echoMode: TextInput.Password
            }

            Label { text: "\u041f\u043e\u0432\u0442\u043e\u0440 \u043f\u0430\u0440\u043e\u043b\u044f:" }
            TextField {
                id: confirmOnlinePasswordField
                Layout.fillWidth: true
                echoMode: TextInput.Password
            }

            RowLayout {
                Layout.fillWidth: true
                Item { Layout.fillWidth: true }
                Button {
                    text: "\u041e\u0442\u043c\u0435\u043d\u0430"
                    onClicked: onlinePasswordChangeDialog.close()
                }
                Button {
                    text: "\u0421\u043c\u0435\u043d\u0438\u0442\u044c \u043f\u0430\u0440\u043e\u043b\u044c"
                    highlighted: true
                    enabled: newOnlinePasswordField.text.length >= 8 && newOnlinePasswordField.text === confirmOnlinePasswordField.text
                    onClicked: {
                        var result = backendObj ? backendObj.rotateOnlineDatabasePassword(newOnlinePasswordField.text) : {"ok": false, "message": "\u0411\u044d\u043a\u0435\u043d\u0434 \u043d\u0435\u0434\u043e\u0441\u0442\u0443\u043f\u0435\u043d", "path": ""}
                        root.settingsActionMessage = result.message || ""
                        root.settingsActionPath = result.path || ""
                        if (result.ok) {
                            root.onlineConfigExportPath = result.path || ""
                            root.refreshOnlineConnectionInfo()
                            onlinePasswordChangeDialog.close()
                        }
                        settingsResultDialog.open()
                    }
                }
            }
        }
    }

    Dialog {
        id: autotestsDialog
        title: "Автотесты"
        modal: true
        width: 760
        height: 620

        ListModel { id: autotestResultsModel }

        ColumnLayout {
            anchors.fill: parent
            spacing: 12

            Label {
                text: "Автотесты выполняют безопасные проверки: часть работает только на чтение, а часть использует транзакции с откатом."
                wrapMode: Text.WordWrap
                Layout.fillWidth: true
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                color: "#fafafa"
                border.color: "#dddddd"
                radius: 6

                ListView {
                    anchors.fill: parent
                    anchors.margins: 8
                    clip: true
                    spacing: 8
                    model: autotestResultsModel
                    delegate: Rectangle {
                        width: ListView.view ? ListView.view.width : 0
                        height: autotestColumn.implicitHeight + 14
                        radius: 6
                        border.color: indicator === "green" ? "#84c784" : "#e59a9a"
                        color: indicator === "green" ? "#eef9ee" : "#fff1f1"

                        ColumnLayout {
                            id: autotestColumn
                            anchors.fill: parent
                            anchors.margins: 8
                            spacing: 4

                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 8

                                Rectangle {
                                    width: 18
                                    height: 18
                                    radius: 9
                                    color: indicator === "green" ? "#4caf50" : "#d9534f"
                                    border.color: "#666"
                                    border.width: 1
                                }

                                Label {
                                    text: name
                                    font.bold: true
                                }

                                Item { Layout.fillWidth: true }
                            }

                            Label {
                                text: message
                                wrapMode: Text.WordWrap
                                Layout.fillWidth: true
                            }

                            Label {
                                text: details
                                visible: details.length > 0
                                wrapMode: Text.WordWrap
                                Layout.fillWidth: true
                                color: "#555"
                            }
                        }
                    }
                }
            }

            RowLayout {
                Layout.fillWidth: true
                Button {
                    text: "Запустить все автотесты"
                    highlighted: true
                    onClicked: {
                        autotestResultsModel.clear()
                        var results = backendObj ? backendObj.runAllAutotests() : []
                        if (!results || results.length === 0) {
                            autotestResultsModel.append({
                                name: "Автотесты",
                                indicator: "red",
                                message: "Не удалось получить результаты автотестов.",
                                details: backendObj ? "" : "Бэкенд недоступен."
                            })
                            return
                        }
                        for (var i = 0; i < results.length; i++) {
                            var item = results[i] || {}
                            autotestResultsModel.append({
                                name: item.name || ("Тест " + (i + 1)),
                                indicator: item.indicator || "red",
                                message: item.message || "",
                                details: item.details || ""
                            })
                        }
                    }
                }
                Item { Layout.fillWidth: true }
                Button {
                    text: "Закрыть"
                    onClicked: autotestsDialog.close()
                }
            }
        }
    }

    Dialog {
        id: settingsResultDialog
        title: "\u0420\u0435\u0437\u0443\u043b\u044c\u0442\u0430\u0442"
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
                text: root.settingsActionPath.length > 0 ? ("\u0424\u0430\u0439\u043b: " + root.settingsActionPath) : ""
                visible: root.settingsActionPath.length > 0
                color: "#555"
                wrapMode: Text.WordWrap
                Layout.fillWidth: true
            }

            RowLayout {
                Layout.fillWidth: true
                Item { Layout.fillWidth: true }
                Button {
                    text: "\u0417\u0430\u043a\u0440\u044b\u0442\u044c"
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

    function updateConnectionModeTexts() {
        root.connectionDialogTitleText = "Подключение к онлайн-базе"
        root.connectionDialogHintText = "Введите параметры онлайн-базы и нажмите «Сохранить и подключиться». После успешного входа параметры сохраняются в config.ini и используются автоматически при следующем запуске."
    }

    function loadDatabaseConfig(mode) {
        var cfg = backendObj ? backendObj.getDatabaseConfigForMode("online") : {}
        updateConnectionModeTexts()
        dbHostField.text = cfg.host || "localhost"
        dbPortField.text = cfg.port || "5432"
        dbNameField.text = cfg.name || "cost"
        dbUserField.text = cfg.user || "cost_client_app"
        dbPasswordField.text = cfg.password || ""
        configPathLabel.text = "Файл настроек: " + (cfg.config_path || "config.ini")
    }


    function refreshOnlineConnectionInfo() {
        var info = backendObj ? backendObj.getOnlineConnectionInfo() : {"ok": false, "message": "\u0411\u044d\u043a\u0435\u043d\u0434 \u043d\u0435\u0434\u043e\u0441\u0442\u0443\u043f\u0435\u043d"}
        if (!info.ok) {
            root.settingsActionMessage = info.message || "\u041d\u0435 \u0443\u0434\u0430\u043b\u043e\u0441\u044c \u043f\u043e\u043b\u0443\u0447\u0438\u0442\u044c \u043f\u0430\u0440\u0430\u043c\u0435\u0442\u0440\u044b \u043e\u043d\u043b\u0430\u0439\u043d-\u043f\u043e\u0434\u043a\u043b\u044e\u0447\u0435\u043d\u0438\u044f."
            root.settingsActionPath = ""
            settingsResultDialog.open()
            return
        }
        root.onlineHostValue = info.host || ""
        root.onlinePortValue = info.port || ""
        root.onlineDbNameValue = info.name || ""
        root.onlineUserValue = info.user || ""
        root.onlinePasswordMaskedValue = info.masked_password || ""
        root.onlineConfigPreview = info.config_text || ""
    }
    function beginConnectionFlow(mode) {
        root.selectedConnectionMode = "online"
        root.connectionReady = false
        root.connectionMessage = ""
        loadDatabaseConfig("online")
        var cfg = backendObj ? backendObj.activateDatabaseMode("online") : {}
        if (backendObj && cfg.connection_confirmed && backendObj.testDatabaseConfig(cfg.host, cfg.port, cfg.name, cfg.user, cfg.password).ok) {
            root.connectionReady = true
            return
        }
        if (cfg.connection_confirmed)
            root.connectionMessage = "Не удалось подключиться. Проверьте параметры."
        else
            root.connectionMessage = "Введите параметры онлайн-базы."
        connectionDialog.open()
    }

    Component.onCompleted: {
        var startupMode = "online"
        updateConnectionModeTexts()
        loadDatabaseConfig("online")
        root.connectionReady = false
        root.selectedConnectionMode = startupMode
        root.connectionMessage = ""
        if (updateManagerObj && updateManagerObj.enabled)
            updateManagerObj.checkForUpdates(false)
        beginConnectionFlow("online")
    }

}




