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

#ifndef DATABASEMANAGER_H
#define DATABASEMANAGER_H

#include <QObject>
#include <QSqlDatabase>
#include <QSqlError>
#include <QSqlQuery>
#include <QFile>
#include <QDir>
#include <QByteArray>
#include <QVariant>
#include <QList>
#include <QMap>

#include "settings.h"

class DatabaseManager : public QObject
{
    Q_OBJECT

public:
    static const int dashboardsLimit = 100;
    static const int tabsLimit = 100;
    static const int feedsLimit = 100;
    static const int entriesLimit = 100;

    struct Dashboard {
        QString id;
        QString name;
        QString title;
        QString description;
    };

    struct Tab {
        QString id;
        QString title;
        QString icon;
    };

    struct Feed {
        QString id;
        QString title;
        QString content;
        QString link;
        QString url;
        QString streamId;
        QString icon;
        int unread;
        int read;
        int readlater;
        int lastUpdate;
    };

    struct Entry {
        QString id;
        QString title;
        QString author;
        QString link;
        QString content;
        QString feedId;
        QString image;
        int read;
        int readlater;
        int date;
    };

    struct CacheItem {
        QString id;
        QString origUrl;
        QString finalUrl;
        QString type;
        QString contentType;
        QString entryId;
        QString feedId;
    };

    enum ActionsTypes {
        SetRead = 11,
        UnSetRead = 10,
        SetReadlater = 21,
        UnSetReadlater = 20,
        SetFeedReadAll = 30,
        UnSetFeedReadAll= 31,
        SetTabReadAll = 40,
        UnSetTabReadAll= 41
    };

    struct Action {
        ActionsTypes type;
        QString feedId;
        QString entryId;
        int olderDate;
        int date;
    };

    struct Flags {
        int unread;
        int read;
        int readlater;
    };

    explicit DatabaseManager(QObject *parent = 0);

    Q_INVOKABLE void init();

    bool cleanDashboards();
    bool cleanTabs();
    bool cleanFeeds();
    bool cleanEntries();
    bool cleanCache();

    bool writeDashboard(const Dashboard &dashboard);
    bool writeTab(const QString &dashboardId, const Tab &tab);
    bool writeFeed(const QString &tabId, const Feed &feed);

    bool updateEntriesReadFlag(const QString &feedId, int read);
    bool updateFeedReadFlag(const QString &feedId, int unread, int read);
    bool updateFeedAllAsReadByTab(const QString &tabId);
    bool updateFeedAllAsUnreadByTab(const QString &tabId);
    //bool updateTabReadFlag(const QString &tabId, int unread, int read);
    bool updateEntriesReadFlagByTab(const QString &tabId, int read);
    bool updateFeedReadlaterFlag(const QString &feedId, int readlater);

    bool writeEntry(const QString &feedId, const Entry &entry);
    bool updateEntryReadFlag(const QString &entryId, int read);
    bool updateEntryReadlaterFlag(const QString &entryId, int readlater);
    bool writeCache(const CacheItem &item, int cacheDate, int flag = 1);
    bool updateEntryCache(const QString &entryId, int cacheDate, int flag = 1);

    bool writeAction(Action &action);
    QList<Action> readActions();

    Dashboard readDashboard(const QString &dashboardId);
    QList<Dashboard> readDashboards();
    bool isDashborardExists();

    QList<Tab> readTabs(const QString &dashboardId);
    QList<Feed> readFeeds(const QString &tabId);
    QList<QString> readFeedsIdsByTab(const QString &tabId);
    QList<QString> readAllFeedIds();
    QMap<QString,QString> readAllFeedsIdsTabs();
    QString readFeedId(const QString &entryId);

    QList<Entry> readEntries(const QString &feedId, int offset, int limit);
    QList<Entry> readEntriesReadlater(const QString &dashboardId, int offset, int limit);
    QList<Entry> readEntriesUnread(const QString &feedId, int offset, int limit);
    QList<Entry> readEntries();
    QList<Entry> readEntriesCachedOlderThan(int cacheDate, int limit);
    QList<QString> readCacheFinalUrlOlderThan(int cacheDate, int limit);
    //QList<CacheItem> readCacheItems();
    QList<QString> readCacheIdsOlderThan(int cacheDate, int limit);

    CacheItem readCacheItemFromOrigUrl(const QString &origUrl);
    CacheItem readCacheItemFromEntryId(const QString &entryId);
    CacheItem readCacheItemFromFinalUrl(const QString &finalUrl);
    CacheItem readCacheItem(const QString &cacheId);
    bool isCacheItemExists(const QString &cacheId);
    bool isCacheItemExistsByFinalUrl(const QString &cacheId);
    bool isCacheItemExistsByEntryId(const QString &entryId);

    QList<QString>  readCacheFinalUrlsByLimit(const QString &feedId, int limit);
    bool removeEntriesByLimit(const QString &feedId, int limit);

    QMap<QString,QString> readNotCachedEntries();
    QMap<QString,int> readFeedsLastUpdate();

    QMap<QString,int> readFeedsFirstUpdate();

    int readLatestEntryDateByFeedId(const QString &feedId);
    int readFeedLastUpadate(const QString &feedId);
    int readTabLastUpadate(const QString &tabId);

    bool removeFeed(const QString &feedId);
    //bool removeCacheItems(const QString &feedId);
    bool removeEntriesOlderThan(int cacheDate, int limit);
    //bool removeCacheItemsOlderThan(int cacheDate, int limit);
    bool removeAction(const QString &entryId);

    int readNotCachedEntriesCount();
    int readEntriesCount();
    int readFeedsCount();
    int readUnreadCount(const QString &dashboardId);

    Flags readTabFlags(const QString &tabId);

    QSqlError lastError();

signals:
    void error();
    void empty();
    void notEmpty();

private:
    QSqlDatabase _db;
    static const QString version;
    QString settingsDir;
    QString dbFilePath;

    bool openDB();
    bool createDB();
    bool deleteDB();

    bool createStructure();
    bool createDashboardsStructure();
    bool createTabsStructure();
    bool createFeedsStructure();
    bool createEntriesStructure();
    bool createCacheStructure();
    bool createActionsStructure();
    bool checkParameters();
    bool isTableExists(const QString &name);
    void decodeBase64(const QVariant &source, QString &result);
};

#endif // DATABASEMANAGER_H
