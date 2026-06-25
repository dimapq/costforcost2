import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

ApplicationWindow {
    id: root
    visible: true
    width: 1200
    height: 800
    title: appTitle + " - startup check"
    color: "#202020"

    property var runner: startupTestRunner

    ListModel {
        id: testModel
    }

    function setTests(tests) {
        testModel.clear()
        for (var i = 0; i < tests.length; i++) {
            testModel.append({
                name: tests[i],
                status: "pending"
            })
        }
    }

    function updateTestStatus(index, status, name) {
        if (index >= 0 && index < testModel.count) {
            testModel.setProperty(index, "status", status)
            if (name) {
                testModel.setProperty(index, "name", name)
            }
        }
    }

    function showFailure(errorText) {
        statusLabel.text = errorText
        statusLabel.color = "#ffb3b3"
        failedButtons.visible = true
    }

    function showSuccess() {
        statusLabel.text = "All startup checks passed. Launching application..."
        statusLabel.color = "#d7ffd7"
        failedButtons.visible = false
    }

    Component.onCompleted: {
        setTests(root.runner.testNames())
        root.runner.runTests()
    }

    Connections {
        target: root.runner

        function onTestCountChanged(count) {
            if (testModel.count !== count) {
                var names = root.runner.testNames()
                root.setTests(names)
            }
        }

        function onTestStatusChanged(index, status, name) {
            root.updateTestStatus(index, status, name)
            if (status === "running") {
                statusLabel.text = "Running: " + name
                statusLabel.color = "#dddddd"
            }
        }

        function onAllTestsPassed() {
            root.showSuccess()
        }

        function onTestsFailed(errorText) {
            root.showFailure(errorText)
        }
    }

    Rectangle {
        anchors.fill: parent
        color: "#202020"
    }

    ColumnLayout {
        anchors.centerIn: parent
        width: Math.min(parent.width - 48, 640)
        spacing: 24

        Label {
            Layout.alignment: Qt.AlignHCenter
            text: "Startup self-check"
            color: "white"
            font.pixelSize: 26
            font.bold: true
        }

        Item {
            id: circleArea
            Layout.alignment: Qt.AlignHCenter
            Layout.preferredWidth: 360
            Layout.preferredHeight: 360

            Repeater {
                model: testModel

                Rectangle {
                    width: 28
                    height: 28
                    radius: 14

                    property real angle: (index / Math.max(testModel.count, 1)) * Math.PI * 2 - Math.PI / 2
                    property real centerX: circleArea.width / 2
                    property real centerY: circleArea.height / 2
                    property real radiusDistance: 140

                    x: centerX + Math.cos(angle) * radiusDistance - width / 2
                    y: centerY + Math.sin(angle) * radiusDistance - height / 2

                    color: {
                        if (status === "passed") return "#3cb043"
                        if (status === "failed") return "#d93636"
                        if (status === "running") return "#e6c229"
                        return "#777777"
                    }

                    border.color: "#ffffff"
                    border.width: status === "running" ? 2 : 1

                    ToolTip.visible: mouseArea.containsMouse
                    ToolTip.text: name + ": " + status

                    MouseArea {
                        id: mouseArea
                        anchors.fill: parent
                        hoverEnabled: true
                    }

                    SequentialAnimation on opacity {
                        running: status === "running"
                        loops: Animation.Infinite

                        NumberAnimation {
                            to: 0.35
                            duration: 400
                        }

                        NumberAnimation {
                            to: 1.0
                            duration: 400
                        }
                    }
                }
            }

            Label {
                anchors.centerIn: parent
                text: testModel.count + " checks"
                color: "white"
                font.pixelSize: 20
            }
        }

        Label {
            id: statusLabel
            Layout.fillWidth: true
            color: "#dddddd"
            text: "Waiting for startup checks..."
            font.pixelSize: 16
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.WordWrap
            maximumLineCount: 8
            elide: Text.ElideRight
        }

        RowLayout {
            id: failedButtons
            Layout.alignment: Qt.AlignHCenter
            visible: false
            spacing: 10

            Button {
                text: "Retry tests"
                onClicked: {
                    root.setTests(root.runner.testNames())
                    statusLabel.text = "Restarting startup checks..."
                    statusLabel.color = "#dddddd"
                    failedButtons.visible = false
                    root.runner.runTests()
                }
            }

            Button {
                text: "Launch previous release"
                onClicked: root.runner.launchPreviousRelease()
            }

            Button {
                text: "Close"
                onClicked: Qt.quit()
            }
        }
    }
}
