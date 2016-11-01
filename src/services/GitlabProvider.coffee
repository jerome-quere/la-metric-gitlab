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

class GitlabProvider
    setUrl: (@glUrl) -> this
    setToken: (@glToken) -> this
    $get: () -> new GitlabService(@glUrl, @glToken)

class GitlabService

    constructor: (@glUrl, @glToken) ->
        @todayStats =
            date: null
            issuesCount: 0
        @getOpenedIssuesCount = _.throttle(@_getOpenedIssuesCount, 500, {trailing: false})
        @getCriticalOpenedIssuesCount = _.throttle(@_getCriticalOpenedIssuesCount, 500, {trailing: false})

    getProjectsCount: () -> @getCount "/projects/all"
    getGroups: () -> @getAll "/groups"
    getTodayIssuesCount: () -> @getOpenedIssuesCount().then (count) => count - @todayStats.issuesCount
    _getCriticalOpenedIssuesCount: () => @getIssuesCount({state: 'opened', 'labels': 'Critical'})

    _getOpenedIssuesCount: () =>
        @getIssuesCount({state: 'opened'}).then (count) =>
            now = new Date()
            if @todayStats.date == null or now.getDate() != @todayStats.date.getDate()
                @todayStats.date = now
                @todayStats.issuesCount = count
            return count

    getIssuesCount: (filters) =>
        @getGroups().then (groups) =>
            promises = groups.map (group) => @getCount("/groups/#{group.id}/issues", filters)
            return Promise.all(promises).then (counts) -> counts.reduce (a, b) -> a + b

    get: (path, query = {}) ->
        request
            method: 'GET'
            uri: "#{@glUrl}/api/v3#{path}"
            qs: query
            json: true
            headers:
                'PRIVATE-TOKEN': @glToken
            resolveWithFullResponse: true

    getCount: (path, query = {}) ->
        @get(path, query).then (response) ->  parseInt(response.headers['x-total'])

    getAll: (path, query = {}, page = 1) ->
        query.page = page
        @get(path, query).then (response) =>
            items = response.body
            if (response.headers['x-total-pages'] > page)
                return @getAll(path, query, page + 1).then (data) ->
                    items.concat(data)
            return items

module.exports = GitlabProvider
