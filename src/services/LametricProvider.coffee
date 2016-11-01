##
# MIT License
#
# Copyright (c) 2016 Jérôme Quéré <contact@jeromequere.com>
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.
##

_ = require('lodash')
request = require('request-promise')

class LametricProvider
    constructor: () ->
        @accessToken = null
        @pushUrl = null
        @notificationDuration = 1000 * 60 * 2

    setPushUrl: (@pushUrl) -> this
    setAccessToken: (@accessToken) -> this
    setNotificationDuration: (@notificationDuration) -> this

    $get: (gitlab) -> new LametricService(@pushUrl, @accessToken, @notificationDuration, gitlab)


class NotificationsStore
    constructor: () ->
        @items = [];
        @onChangeCb = () ->
        @timeout = null

    onChange: (@onChangeCb) -> this

    add: (value, durationMs) ->
        nowTime = (new Date()).getTime()
        @items.push({value: value, endTime: nowTime + durationMs})
        @updateTimeout()

    empty: () ->
        @clear()
        return @items.length == 0

    getAll: () ->
        @clear()
        return _.map(@items, 'value')

    clear: () ->
        nowTime = (new Date()).getTime()
        _.remove @items, (item) -> item.endTime < nowTime

    updateTimeout: () ->
        if @timeout then clearTimeout(@timeout)
        if @empty() then return @timeout = null
        nowTime = (new Date()).getTime()
        minEndTime = _(@items).map('endTime').min()
        @timeout = setTimeout () =>
            @onChangeCb()
            @updateTimeout()
        , Math.max(0, minEndTime - nowTime)

class LametricService
    constructor: (@pushUrl, @accessToken, @notificationDuration, @gitlab) ->
        @notificationStore = new NotificationsStore()
        @notificationStore.onChange(@onNotificationStoreChange)
        @icons =
            openIssue:  'i2186'
            closeIssue: 'i2187'
            redCircle:  'i902'
            check:      'i544'
            up:         'i4103'
            down:       'i402'
            equal:      'i401'
            gitlab:     'i4151'

    addNotification: (notification) ->
        @notificationStore.add(notification, @notificationDuration * 1000)
        @sendNotifications @notificationStore.getAll()

    sendNotifications: (notifications) -> @post frames: notifications

    onNotificationStoreChange: () =>
        notifications = @notificationStore.getAll()
        if notifications.length
            @sendNotifications(notifications)
        else
            @sendIndicator()

    sendIndicator: () =>
        promises = [
            @gitlab.getOpenedIssuesCount(),
            @gitlab.getCriticalOpenedIssuesCount(),
            @gitlab.getTodayIssuesCount()
        ]

        Promise.all(promises).then (data) =>
            [openedIssuesCount, criticalIssuesCount, todayIssuesCount] = data;
            if (todayIssuesCount > 0 ) then todayIssuesCountIcon = 'up'
            if (todayIssuesCount < 0 ) then todayIssuesCountIcon = 'down'
            if (todayIssuesCount == 0 ) then todayIssuesCountIcon = 'equal'
            if not @notificationStore.empty()
                return
            @post frames: [
                { text: "#{openedIssuesCount}", icon: 'i4151', index: 1 },
                { text: "#{criticalIssuesCount}", icon: @icons.redCircle, index: 1 },
                { text: "#{todayIssuesCount}", icon: @icons[todayIssuesCountIcon],  index: 2 }
            ]

    getIconCode: (name) -> @icons[name] || @icons.gitlab

    post: (body) ->
        options =
            method: 'POST'
            uri: @pushUrl
            json: true
            headers:
                accept: 'application/json'
                'x-access-token': @accessToken
                'cache-control': 'no-cache'
            body: body
        return request(options)

module.exports = LametricProvider