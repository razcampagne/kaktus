/*
 * Copyright (C) 2015 Michal Kosciesza <michal@mkiol.net>
 * 
 * This file is part of Kaktus.
 * 
 * Kaktus is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 * 
 * Kaktus is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 * 
 * You should have received a copy of the GNU General Public License
 * along with Kaktus.  If not, see <http://www.gnu.org/licenses/>.
 */

import bb.cascades 1.2

Page {

    id: root

    titleBar: TitleBar {
        title: qsTr("Settings")
    }

    property bool dark: Application.themeSupport.theme.colorTheme.style == VisualStyle.Dark

    function disconnectSignals() {
    }

    attachedObjects: [
        SignOutDialog {
            id: signOutDialog
            onOk: {
                settings.signedIn = false;
            }
        }
    ]

    Container {

        ScrollView {
            Container {
                Header {
                    title: settings.signinType < 10 ? "Netvibes" : "Old Reader"
                }

                Container {
                    leftPadding: utils.du(2)
                    rightPadding: utils.du(2)
                    topPadding: utils.du(2)
                    bottomPadding: utils.du(2)

                    TextLabel {
                        text: settings.signedIn ? qsTr("Signed in with") : qsTr("Not signed in")
                        value: settings.signedIn ? settings.signinType == 0 ? settings.getUsername() : settings.signinType == 1 ? "Twitter" : settings.signinType == 2 ? "Facebook" : settings.signinType == 10 ? settings.getUsername() : "" : ""
                        enabled: settings.signedIn
                        buttonText: qsTr("Sign out")
                        onClicked: {
                            signOutDialog.show();
                        }
                    }

                    TextLabel {
                        text: settings.signedIn && utils.defaultDashboardName() !== "" ? qsTr("Dashboard in use") : qsTr("Dashboard not selected")
                        value: settings.signedIn && utils.defaultDashboardName() !== "" ? utils.defaultDashboardName() : ""
                        buttonText: settings.signedIn ? qsTr("Change") : ""
                        visible: settings.signinType < 10
                        onClicked: {
                            utils.setDashboardModel();
                            nav.push(dashboardPage.createObject());
                        }
                    }
                }

                Header {
                    title: qsTr("Syncronization")
                    visible: settings.signinType >= 10
                }

                Container {
                    leftPadding: utils.du(2)
                    rightPadding: utils.du(2)
                    topPadding: utils.du(2)
                    bottomPadding: utils.du(2)
                    visible: settings.signinType >= 10

                    DropDown {
                        title: qsTr("Sync timeframe")
                        enabled: settings.signinType >= 10

                        selectedIndex: {
                            var retention = settings.getRetentionDays();
                            if (retention < 1)
                                return 5;
                            if (retention < 3)
                                return 0;
                            if (retention < 7)
                                return 1;
                            if (retention < 14)
                                return 2;
                            if (retention < 30)
                                return 3;
                            return 4;
                        }

                        options: [
                            Option {
                                value: 1
                                text: qsTr("1 Day")
                            },
                            Option {
                                value: 3
                                text: qsTr("3 Days")
                            },
                            Option {
                                value: 7
                                text: qsTr("1 Week")
                            },
                            Option {
                                value: 14
                                text: qsTr("2 Weeks")
                            },
                            Option {
                                value: 30
                                enabled: !utils.isLight()
                                text: enabled ? qsTr("1 Month") : qsTr("1 Month (only in pro edition)")
                            },
                            Option {
                                value: 0
                                enabled: !utils.isLight()
                                text: enabled ? qsTr("Wide as possible") : qsTr("Wide as possible (only in pro edition)")
                            }
                        ]

                        onSelectedOptionChanged: {
                            settings.setRetentionDays(selectedOption.value);
                        }

                    }

                    Label {
                        multiline: true
                        textStyle.base: SystemDefaults.TextStyles.SubtitleText
                        textStyle.color: utils.secondaryText()
                        text: qsTr("Most recent articles will be syncronized according to the defined timeframe. " + "Regardless of the value, all starred, liked and shared items will be synced as well. " + "Be aware, this parameter has significant impact on the speed of synchronization.")
                    }
                }

                Header {
                    title: qsTr("Cache")
                }

                Container {
                    leftPadding: utils.du(2)
                    rightPadding: utils.du(2)
                    topPadding: utils.du(2)
                    bottomPadding: utils.du(2)

                    TextLabel {
                        text: qsTr("Current cache size")
                        value: utils.getHumanFriendlySizeString(dm.cacheSize)
                        buttonText: dm.cacheSize > 0 ? qsTr("Delete cache") : ""
                        onClicked: {
                            //notification.show(qsTr("Removing cache..."));
                            fetcher.cancel();
                            dm.cancel();
                            dm.removeCache();
                        }
                    }

                    DropDown {
                        title: qsTr("Network mode")
                        options: [
                            Option {
                                id: defaultNetworkModeOption
                                selected: ! settings.offlineMode
                                imageSource: dark ? "asset:///network-online.png" : "asset:///network-onlined.png"
                                value: false
                                text: qsTr("Online")
                            },
                            Option {
                                selected: settings.offlineMode
                                imageSource: dark ? "asset:///network-offline.png" : "asset:///network-offlined.png"
                                value: true
                                text: enabled ? qsTr("Offline") : qsTr("Offline (only in pro edition)")
                                enabled: ! utils.isLight()
                            }
                        ]
                        onSelectedOptionChanged: {
                            settings.offlineMode = selectedOption.value;
                        }

                    }
                    
                    Label {
                        multiline: true
                        textStyle.base: SystemDefaults.TextStyles.SubtitleText
                        textStyle.color: utils.secondaryText()
                        text: qsTr("In the offline mode, Kaktus will only use local cache to get web pages and images, so "+
                                   "network connection won't be needed.")
                    }

                    DropDown {
                        title: qsTr("Cache articles")
                        options: [
                            Option {
                                selected: settings.cachingMode == 0
                                value: 0
                                text: qsTr("Never")
                            },
                            Option {
                                selected: settings.cachingMode == 1
                                value: 1
                                text: enabled ? qsTr("WiFi only") : qsTr("WiFi only (only in pro edition)")
                                enabled: ! utils.isLight()
                            },
                            Option {
                                selected: settings.cachingMode == 2
                                value: 2
                                text: enabled ? qsTr("Always") : qsTr("Always (only in pro edition)")
                                enabled: ! utils.isLight()
                            }
                        ]
                        onSelectedOptionChanged: {
                            settings.cachingMode = selectedOption.value;
                        }
                    }

                    Label {
                        multiline: true
                        textStyle.base: SystemDefaults.TextStyles.SubtitleText
                        textStyle.color: utils.secondaryText()
                        text: qsTr("After sync the content of all items will be downloaded " + "and cached for access in the offline mode.")
                    }
                }

                Header {
                    title: qsTr("UI")
                }

                Container {

                    leftPadding: utils.du(2)
                    rightPadding: utils.du(2)
                    topPadding: utils.du(2)
                    bottomPadding: utils.du(2)

                    /*DropDown {
                     * title: qsTr("Language")
                     * options: [
                     * Option {
                     * selected: settings.locale === ""
                     * value: ""
                     * text: qsTr("Default")
                     * },
                     * Option {
                     * selected: settings.locale === "cs"
                     * value: "cs"
                     * text: "Čeština"
                     * },
                     * Option {
                     * selected: settings.locale === "en"
                     * value: "en"
                     * text: "English"
                     * },
                     * Option {
                     * selected: settings.locale === "fa"
                     * value: "fa"
                     * text: "فارسی"
                     * },
                     * Option {
                     * selected: settings.locale === "nl"
                     * value: "nl"
                     * text: "Nederlands"
                     * },
                     * Option {
                     * selected: settings.locale === "pl"
                     * value: "pl"
                     * text: "Polski"
                     * },
                     * Option {
                     * selected: settings.locale === "ru"
                     * value: "ru"
                     * text: "Русский"
                     * },
                     * Option {
                     * selected: settings.locale === "tr"
                     * value: "tr"
                     * text: "Türkçe"
                     * }
                     * ]
                     * onSelectedOptionChanged: {
                     * if (settings.locale != selectedOption.value) {
                     * settings.locale = selectedOption.value;
                     * notification.show(qsTr("Changes will take effect after you restart Kaktus."));
                     * }
                     * 
                     * }
                     }*/

                    //ViewModeDropDown {}

                    /*ToggleComponent {
                     * text: qsTr("Show only unread articles")
                     * checked: settings.showOnlyUnread
                     * 
                     * onCheckedChanged: {
                     * settings.showOnlyUnread = checked;
                     * }
                     }*/

                    ToggleComponent {
                        text: qsTr("Read mode")
                        description: qsTr("Web pages will be reformatted into an easy to read version.")
                        iconSource: checked ? "asset:///reader.png" : "asset:///reader-disabled.png"
                        checked: settings.readerMode

                        onCheckedChanged: {
                            settings.readerMode = checked;
                        }
                    }

                    ToggleComponent {
                        text: qsTr("Show images")
                        checked: settings.showTabIcons

                        onCheckedChanged: {
                            settings.showTabIcons = checked;
                        }
                    }

                    /*ToggleComponent {
                     * text: qsTr("Power save mode")
                     * description: qsTr("When the phone or app goes to the idle state, " + "all opened web pages will be closed to lower power consumption.")
                     * checked: settings.powerSaveMode
                     * 
                     * onCheckedChanged: {
                     * settings.powerSaveMode = checked;
                     * }
                     }*/

                    /*DropDown {
                     * title: qsTr("Orientation")
                     * options: [
                     * Option {
                     * selected: settings.allowedOrientations == value
                     * value: 0
                     * text: qsTr("Dynamic")
                     * },
                     * Option {
                     * selected: settings.allowedOrientations == value
                     * value: 1
                     * text: qsTr("Portrait")
                     * },
                     * Option {
                     * selected: settings.allowedOrientations == value
                     * value: 2
                     * text: qsTr("Landscape")
                     * }
                     * ]
                     * onSelectedOptionChanged: {
                     * settings.allowedOrientations = selectedOption.value;
                     * }
                     }*/

                    DropDown {
                        title: qsTr("Theme")
                        visible: utils.checkOSVersion(10, 3)
                        options: [
                            /*Option {
                             * selected: settings.theme == value
                             * value: 0
                             * text: qsTr("Default")
                             },*/
                            Option {
                                selected: settings.theme == value
                                value: 1
                                text: qsTr("Bright")
                            },
                            Option {
                                selected: settings.theme == value
                                value: 2
                                text: qsTr("Dark")
                            }
                        ]
                        onSelectedOptionChanged: {
                            if (settings.theme != selectedOption.value)
                                notification.show(qsTr("Changes will take effect after you restart Kaktus."));
                            settings.theme = selectedOption.value;
                        }
                    }

                    DropDown {
                        title: enabled ? qsTr("Offline viewer style") : qsTr("Offline viewer (only in pro edition)")
                        enabled: ! utils.isLight()
                        options: [
                            Option {
                                selected: settings.offlineTheme == value
                                value: String("black")
                                text: qsTr("Black")
                            },
                            Option {
                                selected: settings.offlineTheme == value
                                value: String("white")
                                text: qsTr("White")
                            }
                        ]
                        onSelectedOptionChanged: {
                            settings.offlineTheme = selectedOption.value;
                        }
                    }

                    DropDown {
                        title: qsTr("Web viewer font size")
                        options: [
                            Option {
                                selected: settings.fontSize == value
                                value: 0
                                text: qsTr("-50%")
                            },
                            Option {
                                selected: settings.fontSize == value
                                value: 1
                                text: qsTr("Normal")
                            },
                            Option {
                                selected: settings.fontSize == value
                                value: 2
                                text: qsTr("+50%")
                            }
                        ]
                    onSelectedOptionChanged: {
                        settings.fontSize = selectedOption.value;
                    }
                }
            }

            /*Header {
                title: qsTr("Other")
            }

            Container {

                leftPadding: ui.du(2)
                rightPadding: ui.du(2)
                topPadding: ui.du(2)
                bottomPadding: ui.du(2)

                Button {
                    text: qsTr("Show User Guide")

                    onClicked: {
                        //guide.show();
                        notification.show("Not implemented yet :-(");
                    }
                }

            }*/

        }
    }
}
}
