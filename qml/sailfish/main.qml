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

import QtQuick 2.0
import Sailfish.Silica 1.0

ApplicationWindow {
    id: app

    property bool progress: false

    cover: CoverPage {}

    Component.onCompleted: {
        db.init();
    }

    function resetView() {
        if (!settings.signedIn) {
            pageStack.replaceAbove(null,Qt.resolvedUrl("FirstPage.qml"));
            return;
        }

        // Reconnect fetcher
        if (typeof fetcher === 'undefined') {
            var type = settings.signinType;
            if (type < 10)
                reconnectFetcher(1);
            else if (type == 10)
                reconnectFetcher(2);
        }

        utils.setRootModel();

        pageStack.busyChanged.connect(resetViewDone);
        switch (settings.viewMode) {
        case 0:
        case 1:
            pageStack.replaceAbove(null,Qt.resolvedUrl("TabPage.qml"));
            break;
        case 2:
            pageStack.replaceAbove(null,Qt.resolvedUrl("FeedPage.qml"),{"title": qsTr("Feeds")});
            break;
        case 3:
        case 4:
        case 5:
            pageStack.replaceAbove(null,Qt.resolvedUrl("EntryPage.qml"));
            break;
        }
    }

    function resetViewDone() {
        if (!pageStack.busy) {
            pageStack.busyChanged.disconnect(resetViewDone);
            app.progress = false;
        }
    }

    Connections {
        target: settings

        onError: {
            console.log("Settings error! code=" + code);
            Qt.quit();
        }

        onDashboardInUseChanged: {
            resetView();
            //notification.show(qsTr("Dashboard changed!"));
        }

        onViewModeChanged: {
            resetView();
            //notification.show(qsTr("Browsing mode changed!"));
        }

        onSignedInChanged: {
            if (!settings.signedIn) {
                //notification.show(qsTr("Signed out!"));
                fetcher.cancel(); dm.cancel();
                db.init();
            } else {
                if(!settings.helpDone)
                    guide.showDelayed();
            }
        }
    }

    Connections {
        target: db

        onError: {
            console.log("DB error! code="+code);

            if (code==511) {
                notification.show(qsTr("Something went wrong :-(\nRestart the app to rebuild cache data."));
                return;
            }

            Qt.quit();
        }

        onEmpty: {
            dm.removeCache();
            if (settings.viewMode!=0)
                settings.viewMode=0;
            else
                resetView();
        }

        onNotEmpty: {
            resetView()
        }
    }

    Connections {
        target: dm

        /*onBusyChanged: {
            console.log("DM busy", dm.busy);
        }*/

        onProgress: {
            //console.log("DM busy", dm.busy);
            //console.log("DM progress: " + remaining);
            progressPanelDm.text = qsTr("%1 more items left...").arg(remaining);
            if (remaining === 0) {
                progressPanelDm.text = qsTr("All done!");
            }
        }

        onNetworkNotAccessible: {
            notification.show(qsTr("Download failed!\nNetwork connection is unavailable."));
        }

        onRemoverProgressChanged: {
            progressPanelRemover.progress = current / total;
        }

        /*onError: {
            console.log("DM error code:", code);
        }*/
    }

    function reconnectFetcher(type) {
        disconnectFetcher();
        cover.disconnectFetcher();

        utils.resetFetcher(type);

        connectFetcher();
        cover.connectFetcher();
    }

    function connectFetcher() {
        if (typeof fetcher === 'undefined')
            return;
        fetcher.ready.connect(fetcherReady);
        fetcher.newAuthUrl.connect(fetcherNewAuthUrl);
        fetcher.errorGettingAuthUrl.connect(fetcherErrorGettingAuthUrl);
        fetcher.networkNotAccessible.connect(fetcherNetworkNotAccessible);
        fetcher.error.connect(fetcherError);
        fetcher.errorCheckingCredentials.connect(fetcherErrorCheckingCredentials);
        fetcher.credentialsValid.connect(fetcherCredentialsValid);
        fetcher.progress.connect(fetcherProgress);
        fetcher.uploading.connect(fetcherUploading);
        fetcher.busyChanged.connect(fetcherBusyChanged);
    }

    function disconnectFetcher() {
        if (typeof fetcher === 'undefined')
            return;
        fetcher.ready.disconnect(fetcherReady);
        fetcher.newAuthUrl.disconnect(fetcherNewAuthUrl);
        fetcher.errorGettingAuthUrl.disconnect(fetcherErrorGettingAuthUrl);
        fetcher.networkNotAccessible.disconnect(fetcherNetworkNotAccessible);
        fetcher.error.disconnect(fetcherError);
        fetcher.errorCheckingCredentials.disconnect(fetcherErrorCheckingCredentials);
        fetcher.credentialsValid.disconnect(fetcherCredentialsValid);
        fetcher.progress.disconnect(fetcherProgress);
        fetcher.uploading.disconnect(fetcherUploading);
        fetcher.busyChanged.disconnect(fetcherBusyChanged);
    }

    property bool fetcherBusyStatus: false

    function fetcherReady() {
        //console.log("Fetcher ready");
        resetView();

        switch (settings.cachingMode) {
        case 0:
            return;
        case 1:
            if (dm.isWLANConnected()) {
                dm.startFeedDownload();
            }
            return;
        case 2:
            dm.startFeedDownload();
            return;
        }
    }

    function fetcherNewAuthUrl(url, type) {
        pageStack.push(Qt.resolvedUrl("AuthWebViewPage.qml"),{"url":url,"type":type,"code": 400});
    }

    function fetcherErrorGettingAuthUrl() {
        notification.show(qsTr("Something goes wrong. Unable to sign in! :-("));
    }

    function fetcherNetworkNotAccessible() {
        notification.show(qsTr("Sync failed!\nNetwork connection is unavailable."));
    }

    function fetcherError(code) {
        console.log("Fetcher error");
        console.log("code=" + code);

        if (code < 400)
            return;
        if (code >= 400 && code < 500) {
            if (code == 402)
                notification.show(qsTr("The user name or password is incorrect!"));
            /*if (code == 403) {
                notification.show(qsTr("Your login credentials have expired!"));
                if (settings.getSigninType()>0) {
                    fetcher.getAuthUrl();
                    return;
                }
            }*/
            //console.log("settings.signinType",settings.getSigninType());

            // Sign in
            var type = settings.signinType;
            if (type < 10) {
                pageStack.push(Qt.resolvedUrl("NvSignInDialog.qml"),{"code": code});
                return;
            }
            if (type == 10) {
                pageStack.push(Qt.resolvedUrl("OldReaderSignInDialog.qml"),{"code": code});
                return;
            }

        } else {
            // Unknown error
            notification.show(qsTr("Something went wrong :-(\nAn unknown error occurred."));
        }
    }

    function fetcherErrorCheckingCredentials() {
        notification.show(qsTr("The user name or password is incorrect!"));
    }

    function fetcherCredentialsValid() {
        notification.show(qsTr("You are signed in!"));
    }

    function fetcherProgress(current, total) {
        progressPanel.text = qsTr("Receiving data... ");
        progressPanel.progress = current / total;
    }

    function fetcherUploading() {
        progressPanel.text = qsTr("Sending data...");
    }

    function fetcherBusyChanged() {

        if (app.fetcherBusyStatus != fetcher.busy)
            app.fetcherBusyStatus = fetcher.busy;

        switch(fetcher.busyType) {
        case 1:
            progressPanel.text = qsTr("Initiating...");
            progressPanel.progress = 0;
            break;
        case 2:
            progressPanel.text = qsTr("Updating...");
            progressPanel.progress = 0;
            break;
        case 3:
            progressPanel.text = qsTr("Signing in...");
            progressPanel.progress = 0;
            break;
        case 4:
            progressPanel.text = qsTr("Signing in...");
            progressPanel.progress = 0;
            break;
        case 11:
            progressPanel.text = qsTr("Waiting for network...");
            progressPanel.progress = 0;
            break;
        case 21:
            progressPanel.text = qsTr("Waiting for network...");
            progressPanel.progress = 0;
            break;
        case 31:
            progressPanel.text = qsTr("Waiting for network...");
            progressPanel.progress = 0;
            break;
        }
    }

    /*Connections {
        target: fetcher

        onReady: {
            //console.log("Fetcher ready");
            resetView();

            switch (settings.cachingMode) {
            case 0:
                return;
            case 1:
                if (dm.isWLANConnected()) {
                    dm.startFeedDownload();
                }
                return;
            case 2:
                dm.isWLANConnected();
                return;
            }
        }

        onNewAuthUrl: {
            pageStack.push(Qt.resolvedUrl("AuthWebViewPage.qml"),{"url":url,"type":type,"code": 400});
        }

        onErrorGettingAuthUrl: {
            notification.show(qsTr("Something goes wrong. Unable to sign in! :-("));
        }

        onNetworkNotAccessible: {
            notification.show(qsTr("Sync failed!\nNetwork connection is unavailable."));
        }

        onError: {
            console.log("Fetcher error");
            console.log("code=" + code);

            if (code < 400)
                return;
            if (code >= 400 && code < 500) {
                if (code == 402)
                    notification.show(qsTr("The user name or password is incorrect!"));

                console.log("settings.signinType",settings.getSigninType());

                // Sign in
                var type = settings.getSigninType();
                if (type < 10) {
                    pageStack.push(Qt.resolvedUrl("NvSignInDialog.qml"),{"code": code});
                    return;
                }
                if (type == 10) {
                    pageStack.push(Qt.resolvedUrl("OldReaderSignInDialog.qml"),{"code": code});
                    return;
                }

            } else {
                // Unknown error
                notification.show(qsTr("Something went wrong :-(\nAn unknown error occurred."));
            }
        }

        onErrorCheckingCredentials: {
            notification.show(qsTr("The user name or password is incorrect!"));
        }

        onCredentialsValid: {
            notification.show(qsTr("You are signed in!"));
        }

        onProgress: {
            progressPanel.text = qsTr("Receiving data... ");
            progressPanel.progress = current / total;
        }

        onUploading: {
            progressPanel.text = qsTr("Sending data...");
        }

        onBusyChanged: {
            switch(fetcher.busyType) {
            case 1:
                progressPanel.text = qsTr("Initiating...");
                progressPanel.progress = 0;
                break;
            case 2:
                progressPanel.text = qsTr("Updating...");
                progressPanel.progress = 0;
                break;
            case 3:
                progressPanel.text = qsTr("Signing in...");
                progressPanel.progress = 0;
                break;
            case 4:
                progressPanel.text = qsTr("Signing in...");
                progressPanel.progress = 0;
                break;
            case 11:
                progressPanel.text = qsTr("Waiting for network...");
                progressPanel.progress = 0;
                break;
            case 21:
                progressPanel.text = qsTr("Waiting for network...");
                progressPanel.progress = 0;
                break;
            case 31:
                progressPanel.text = qsTr("Waiting for network...");
                progressPanel.progress = 0;
                break;
            }
        }
    }*/

    Notification {
        id: notification
    }

    property int panelHeightPortrait: 1.1*Theme.itemSizeSmall
    property int panelHeightLandscape: Theme.itemSizeSmall
    property int flickHeight: {
        var size = 0;
        var d = app.orientation==Orientation.Portrait ? app.panelHeightPortrait : app.panelHeightLandscape;
        if (bar.open)
            size += d;
        if (progressPanel.open||progressPanelRemover.open||progressPanelDm.open)
            size += d;
        return app.orientation==Orientation.Portrait ? app.height-size : app.width-size;
    }
    property int panelX: {
        if (app.orientation==Orientation.Portrait)
            return 0;
        if (bar.open)
            return 2*app.panelHeightLandscape;
        return app.panelHeightLandscape;
    }
    property int panelY: {
        if (app.orientation==Orientation.Portrait) {
            if (bar.open)
                return app.height-2*app.panelHeightPortrait;
            return app.height-app.panelHeightPortrait;
        }
        return 0;
    }

    ProgressPanel {
        id: progressPanelRemover
        open: dm.removerBusy
        onCloseClicked: dm.removerCancel();

        rotation: app.orientation==Orientation.Portrait ? 0 : 90
        transformOrigin: Item.TopLeft
        height: app.orientation==Orientation.Portrait ? panelHeightPortrait : panelHeightLandscape
        width: app.orientation==Orientation.Portrait ? app.width : app.height
        y: panelY
        x: panelX
        text: qsTr("Removing cache data...");
        Behavior on y { NumberAnimation { duration: 200;easing.type: Easing.OutQuad } }
        Behavior on x { NumberAnimation { duration: 200;easing.type: Easing.OutQuad } }
    }

    ProgressPanel {
        id: progressPanelDm
        open: dm.busy && !app.fetcherBusyStatus
        onCloseClicked: dm.cancel();

        rotation: app.orientation==Orientation.Portrait ? 0 : 90
        transformOrigin: Item.TopLeft
        height: app.orientation==Orientation.Portrait ? panelHeightPortrait : panelHeightLandscape
        width: app.orientation==Orientation.Portrait ? app.width : app.height
        y: panelY
        x: panelX
        Behavior on y { NumberAnimation { duration: 200;easing.type: Easing.OutQuad } }
        Behavior on x { NumberAnimation { duration: 200;easing.type: Easing.OutQuad } }
    }

    ProgressPanel {
        id: progressPanel
        open: app.fetcherBusyStatus
        onCloseClicked: fetcher.cancel();

        rotation: app.orientation==Orientation.Portrait ? 0 : 90
        transformOrigin: Item.TopLeft
        height: app.orientation==Orientation.Portrait ? panelHeightPortrait : panelHeightLandscape
        width: app.orientation==Orientation.Portrait ? app.width : app.height
        y: panelY
        x: panelX
        Behavior on y { NumberAnimation { duration: 200;easing.type: Easing.OutQuad } }
        Behavior on x { NumberAnimation { duration: 200;easing.type: Easing.OutQuad } }
    }

    ControlBar {
        id: bar
        rotation: app.orientation==Orientation.Portrait ? 0 : 90
        transformOrigin: Item.TopLeft
        height: app.orientation==Orientation.Portrait ? panelHeightPortrait : panelHeightLandscape
        width: app.orientation==Orientation.Portrait ? app.width : app.height
        y: app.orientation==Orientation.Portrait ? app.height-height : 0
        x: app.orientation==Orientation.Portrait ? 0 : height
    }

    Guide {
        id: guide

        rotation: app.orientation==Orientation.Portrait ? 0 : 90
        transformOrigin: Item.TopLeft
        height: app.orientation==Orientation.Portrait ? app.height : app.width
        width: app.orientation==Orientation.Portrait ? app.width : app.height
        y: app.orientation==Orientation.Portrait ? app.height-height : 0
        x: app.orientation==Orientation.Portrait ? 0 : height
    }

}

//fillMode: Image.PreserveAspectFit
//source: "image://theme/graphic-gradient-edge?"+Theme.highlightBackgroundColor
//source: "image://theme/graphic-gradient-home-bottom?"+Theme.highlightBackgroundColor
//source: "image://theme/graphic-gradient-home-top?"+Theme.highlightBackgroundColor

