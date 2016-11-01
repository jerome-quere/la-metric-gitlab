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

class MainController

    lametricTriggerAction: (res, lametric) ->
        lametric.sendIndicator()
        res.status(200).end()

    projectHookAction: (req, res, lametric) ->
        project = req.body.project;
        attrs = req.body.object_attributes;
        user = req.body.user;
        kind = req.body.object_kind;

        notification = null
        if kind == 'issue' and attrs.action == 'open'
            notification =
                icon: lametric.getIconCode 'openIssue'
                text: "#{user.name} opened an issue on #{project.name}"
        if kind == 'issue' and attrs.action == 'close'
            notification =
                icon: lametric.getIconCode 'closeIssue'
                text: "#{user.name} closed an issue on #{project.name}"
        if kind == 'pipeline' and attrs.status == 'success'
            notification =
                icon: lametric.getIconCode 'check'
                text: "Build on #{project.name} for #{attrs.ref} succeed in #{attrs.duration}"

        if notification then lametric.addNotification(notification)
        res.status(200).end()

module.exports = MainController
