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

bodyParser = require('body-parser');
chalk = require('chalk')
expressValidator = require('express-validator')
logger = require('morgan')
radis = require('radis')

ConfigProvider = require('./services/ConfigProvider')
ExpressProvider = require('./services/ExpressProvider')
GitlabProvider = require('./services/GitlabProvider')
LametricProvider = require('./services/LametricProvider')

MainController = require('./controllers/MainController')

module.exports = radis.module('app', [])
    .provider 'express', ExpressProvider
    .provider 'config', ConfigProvider
    .provider 'gitlab', GitlabProvider
    .provider 'lametric', LametricProvider

    .config (configProvider, gitlabProvider, lametricProvider) ->
        gitlabProvider
            .setUrl configProvider.get('gitlab.baseUrl')
            .setToken configProvider.get('gitlab.token')

        lametricProvider
            .setPushUrl configProvider.get('lametric.pushUrl')
            .setAccessToken configProvider.get('lametric.accessToken')
            .setNotificationDuration configProvider.get('lametric.notificationDuration')

    .run (express, config, $injector, lametric) ->
        lametric.sendIndicator()

        mainCtrl = $injector.instantiate(MainController)
        express
            .use logger('dev')
            .use(bodyParser.json())
            .use expressValidator()
            .get '/lametric-trigger', $injector.lift(mainCtrl.lametricTriggerAction, ['req', 'res', 'next'])
            .post '/project-hook', $injector.lift(mainCtrl.projectHookAction, ['req', 'res', 'next'])
            .listen config.get('port'), () ->
                console.log("#{chalk.green('✓')} Express server listening on port #{config.get('port')}")
