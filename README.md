# LaMetric app for gitlab

This LaMetric apps allow you to display information about your gitlab instance on yout [LaMetric device](lametric.com)

### Quick start
 1) Generate a personal gitlab token
    https://your.gitlab.com/profile/personal_access_tokens
 2) Create an indicator lametric app
   - Go to https://developer.lametric.com
   - Create an indicator app
   - Add an action button url to "yourserver.com/lametric-trigger"
   - Get the Push URL and Access token
 3) Lauch the server
 ```bash
 docker run                                                         \
    -e GITLAB__BASEURL=your.gitlab.com                              \
    -e GITLAB__TOKEN=XXXXXXXX                                       \
    -e LAMETRIC__PUSH_URL=https://developer.lametric.com/XXXXXX     \
    -e LAMETRIC__ACCESS_TOKEN=XXXXXXX                               \
    -e LAMETRIC__NOTIFICATION_DURATION=120                          \
    -p 8080:8080
    jeromequere/la-metric-gitlab
 ```
 4) Install the app on you lametric device
 
### Environment variables
  - **GITLAB__BASEURL**: Your gitlab base url 
  - **GITLAB__TOKEN**: A gitlab  personal access tokens
  - **LAMETRIC__PUSH_URL**: The push url provided by lametric when you create your app
  - **LAMETRIC__ACCESS_TOKEN**: The access token provided by lametric when you create your app
  - **LAMETRIC__NOTIFICATION_DURATION**: Number of seconds notifications are display on the device *(default: 120)*
  