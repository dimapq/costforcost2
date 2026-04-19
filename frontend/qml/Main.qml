import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

ApplicationWindow {
    visible: true
    width: 1200
    height: 800
    title: "MachineCost Pro"

    header: TabBar {
        id: tabBar
        TabButton { text: "⚡ Операции" }
        TabButton { text: "📦 Склад" }
        TabButton { text: "👥 Сотрудники" }
        TabButton { text: "🏭 Станки" }
        TabButton { text: "💰 Финансы" }
         TabButton { text: "Учёт работы" } 
    }
    StackLayout {
        id: stackLayout
        anchors.fill: parent
        currentIndex: tabBar.currentIndex

        OperationsPage { }    // Страница 1
        InventoryPage { }     // Страница 2
        EmployeesPage { }     // Страница 3
        MachinesPage { }      // Страница 4
        FinancePage { }       // Страница 5
        WorkLogPage {} 

   }
    
}