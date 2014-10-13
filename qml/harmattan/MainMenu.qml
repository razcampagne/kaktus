/*
  Copyright (C) 2014 Michal Kosciesza <michal@mkiol.net>

  This file is part of Kaktus.

  Kaktus is free software: you can redistribute it and/or modify
  it under the terms of the GNU General Public License as published by
  the Free Software Foundation, either version 3 of the License, or
  (at your option) any later version.

  Kaktus is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
  GNU General Public License for more details.

  You should have received a copy of the GNU General Public License
  along with Kaktus.  If not, see <http://www.gnu.org/licenses/>.
*/

import QtQuick 1.1
import com.nokia.meego 1.0

Menu {
    id: menu
    visualParent: pageStack

    onStatusChanged: {
        if (progressPanelDm.open) {
            if (status===DialogStatus.Opening) {
                progressPanelDm.visible = false;
            }
            if (status===DialogStatus.Closed) {
                progressPanelDm.visible = true;
            }
        }

        /*if (progressPanel.open) {
            if (status===DialogStatus.Opening) {
                progressPanel.visible = false;
            }
            if (status===DialogStatus.Closed) {
                progressPanel.visible = true;
            }
        }

        if (progressPanelRemover.open) {
            if (status===DialogStatus.Opening) {
                progressPanelRemover.visible = false;
            }
            if (status===DialogStatus.Closed) {
                progressPanelRemover.visible = true;
            }
        }

        if (bar.open) {
            if (status===DialogStatus.Opening) {
                bar.visible = false;
            }
            if (status===DialogStatus.Closed) {
                bar.visible = true;
            }
        }*/
    }

    MenuLayout {
        MenuItem {
            text: qsTr("About")
            onClicked: pageStack.push(Qt.resolvedUrl("AboutPage.qml"));
        }
        MenuItem {
            text: qsTr("Settings")
            onClicked: pageStack.push(Qt.resolvedUrl("SettingsPage.qml"));
        }
        MenuItem {
            text: qsTr("Exit")
            onClicked: Qt.quit()
        }
    }
}
