class Twitter
  constructor: (selector, username, count) ->
    @selector = selector
    @username = username
    @count = count
    @target = $(selector)
    if @target?
      $.ajax
        url: "http://twitter-zacharydenton.herokuapp.com/?trim_user=true&count=#{@count+10}&include_entities=1&exclude_replies=true&callback=?"
        dataType: "jsonp"
        error: (err) ->
          @target.addClass("error").text("Twitter's busted")
        success: (data) =>
          @render data.slice(0, @count)

  linkifyTweet: (text, url) ->
    text = text.replace(/(https?:\/\/)([\w\-:;?&=+.%#\/]+)/gi, '<a href="$1$2">$2</a>')
      .replace(/(^|\W)@(\w+)/g, '$1<a href="http://twitter.com/$2">@$2</a>')
      .replace(/(^|\W)#(\w+)/g, '$1<a href="http://search.twitter.com/search?q=%23$2">#$2</a>')
  
    # Use twitter's api to replace t.co shortened urls with expanded ones.
    for u in url
      if u.expanded_url?
        shortUrl = new RegExp(u.url, 'g')
        text = text.replace(shortUrl, u.expanded_url)
        shortUrl = new RegExp(">"+(u.url.replace(/https?:\/\//, '')), 'g')
        text = text.replace(shortUrl, ">"+u.display_url)
    text

  renderTweet: (tweet) ->
    "<div class='tweet'><p>#{@linkifyTweet(tweet.text.replace(/\n/g, '<br>'), tweet.entities.urls)}</p><a href='http://twitter.com/#{@username}/status/#{tweet.id_str}'><time datetime='#{tweet.created_at}'>#{prettyDate(tweet.created_at)}</time></a></div><hr class='short'>"

  render: (tweets) ->
    @target.html (@renderTweet tweet for tweet in tweets).join('')

class GitHub
  constructor: (selector, username, count) ->
    @selector = selector
    @username = username
    @count = count
    @target = $(selector)
    if @target?
      $.ajax
        url: "https://api.github.com/users/#{@username}/events/public"
        dataType: 'jsonp'
        error: (err) ->
          @target.addClass("error").text("GitHub's busted")
        success: (data) =>
          @render data.data

  repoUrl: (event) ->
    "<a href='https://github.com/#{event.repo.name}'>#{event.repo.name.replace("#{@username}/", "")}</a>"

  issueUrl: (event) ->
    "<a title='#{_.escape event.payload.issue.title}' href='#{event.payload.issue.html_url}'>issue ##{event.payload.issue.number}</a>"

  commitUrl: (event) ->
    num_commits = event.payload.commits.length
    if num_commits == 1
      commit = event.payload.commits[0]
      "<a href='https://github.com/#{event.repo.name}/commit/#{commit.sha}' title='#{_.escape commit.message}'>1 commit</a>"
    else
      "<a href='https://github.com/#{event.repo.name}/commits?author=#{@username}'>#{num_commits} commits</a>"

  renderEvent: (event) ->
    content = ""
    switch event.type
      when "WatchEvent"
        content = "Starred #{@repoUrl event}."
      when "IssuesEvent"
        if event.payload.action == "closed"
          content = "Closed #{@repoUrl event} #{@issueUrl event}."
      when "PushEvent"
        content = "Pushed #{@commitUrl event} to #{@repoUrl event}."
      when "PublicEvent"
        content = "Open sourced #{@repoUrl event}."
      when "ForkEvent"
        content = "Forked #{@repoUrl event} to <a href='#{event.payload.forkee.html_url}'>#{event.payload.forkee.full_name}</a>."
      when "FollowEvent"
        content = "Followed <a href='#{event.payload.target.html_url}'>#{event.payload.target.login}</a>."
      when "IssueCommentEvent"
        content = "Commented on #{@repoUrl event} #{@issueUrl event}."
      when "CreateEvent"
        if event.payload.description
          content = "Created #{@repoUrl event} &mdash; #{_.escape event.payload.description}."
        else
          content = "Created #{@repoUrl event}."

    if content
      "<div class='tweet'><p>#{content}</p><time datetime='#{event.created_at}'>#{prettyDate(event.created_at)}</time></div><hr class='short'>"
    else
      ""

  render: (events) ->
    contents = []
    for event in events
      content = @renderEvent event
      contents.push content if content
    @target.html contents.slice(0, @count).join('')

class GooglePlus
  constructor: (selector, userId, count) ->
    @selector = selector
    @userId = userId
    @count = count
    @target = $(selector)
    if @target?
      $.ajax
        url: "https://www.googleapis.com/plus/v1/people/#{@userId}/activities/public?key=AIzaSyDd0bEHYWJbctBAd814stqn2_1xlaWnu5w"
        dataType: 'jsonp'
        error: (err) ->
          @target.addClass("error").text("Google+ is busted")
        success: (data) =>
          @render data.items.slice(0, @count)

  renderAttachment: (attachment) ->
    content = ""
    switch attachment.objectType
      when "article"
        if attachment.image
          if attachment.content
            content += "<div class='block-image block-image-left'><a href='#{attachment.url}'><img src='#{attachment.image.url}' /></a></div>"
            content += "<p><a href='#{attachment.url}'>#{attachment.displayName}</a></p>"
          else
            content += "<a href='#{attachment.fullImage.url}'><img src='#{attachment.fullImage.url}' /></a>"
        else
          content += "<p><a href='#{attachment.url}'>#{attachment.displayName}</a></p>"
      when "video"
        videoId = attachment.url.split('=')[1]
        content = "<div class='video'><iframe src='http://www.youtube.com/embed/#{videoId}?autohide=1' frameborder='0' width='560' height='315'></iframe></div>"
      when "photo"
        content = "<a href='#{attachment.fullImage.url}'><img src='#{attachment.image.url}' /></a>"

  renderActivity: (activity) ->
    content = ""
    attachments = activity.object.attachments
    if attachments?
      type = attachments[0].objectType
      switch type
        when "article"
          if activity.object.content?
            attachment = attachments[0]
            if attachment.fullImage
              if attachment.content
                content += "<div class='block-image block-image-left'><a href='#{attachment.url}'><img src='#{resizeImage {url: attachment.fullImage.url, resize_w: 192}}' /></a></div>"
                content += "<p><a href='#{attachment.url}'>#{attachment.displayName}</a></p>"
              else
                content += "<a href='#{attachment.fullImage.url}'><img src='#{resizeImage {url: attachment.fullImage.url, resize_w: 384}}' /></a>"
            else
              content += "<p><a href='#{attachment.url}'>#{attachment.displayName}</a></p>"
            content += "<p>#{activity.object.content}</p>"
        when "video"
          if activity.object.content?
            attachment = attachments[0]
            videoId = attachment.url.split('=')[1]
            content += "<div class='video'><iframe src='http://www.youtube.com/embed/#{videoId}?autohide=1' frameborder='0' width='560' height='315'></iframe></div>"
            content += "<p>#{activity.object.content}</p>"
        when "photo"
          content += ("<a href='#{attachment.fullImage.url}'><img src='#{resizeImage {url: attachment.fullImage.url, resize_w: 384}}' /></a>" for attachment in attachments).join('')
          if activity.object.content
            content += "<p>#{activity.object.content}</p>"


      content += "<hr>"
    content

  render: (activities) ->
    @target.html (@renderActivity activity for activity in activities).join('')

class Lastfm
  constructor: (selector, username, count) ->
    @apikey = "bb0c1a31447cadfef07cf434223a1377"
    @selector = selector
    @username = username
    @count = count
    @target = $(selector)
    if @target?
      $.ajax
        url: "http://ws.audioscrobbler.com/2.0/?method=user.gettopalbums&user=#{@username}&period=7day&api_key=#{@apikey}&format=json"
        dataType: "jsonp"
        error: (err) ->
          @target.addClass("error").text("Last.fm's busted")
        success: (data) =>
          @render (album for album in data.topalbums.album when not album.image[3]['#text'].match(/noimage/)?).slice(0, @count)

  render: (albums) ->
    @target.html ("<a href='#{album.url}'><img title='#{_.escape album.artist.name} &mdash; #{_.escape album.name}' src='#{resizeImage {url: album.image[3]['#text'], resize_w: 192}}' /></a><hr class='short'>" for album in albums).join('')
    
prettyDate = (time) ->
  if navigator.appName == 'Microsoft Internet Explorer'
    return "<span>&infin;</span>" # because IE date parsing isn't fun.

  say =
    just_now:    " now",
    minute_ago:  "1 minute ago",
    minutes_ago: " minutes ago",
    hour_ago:    "1 hour ago",
    hours_ago:   " hours ago",
    yesterday:   "1 day ago",
    days_ago:    " days ago",
    last_week:   "1 week ago",
    weeks_ago:   " weeks ago"

  current_date = new Date()
  current_date_time = current_date.getTime()
  current_date_full = current_date_time + (1 * 60000)
  date = new Date(time)
  diff = ((current_date_full - date.getTime()) / 1000)
  day_diff = Math.floor(diff / 86400)

  if isNaN(day_diff) or day_diff < 0
    return "<span>&infin;</span>"

  day_diff == 0 and (
    diff < 60 and say.just_now or
    diff < 120 and say.minute_ago or
    diff < 3600 and Math.floor(diff / 60) + say.minutes_ago or
    diff < 7200 and say.hour_ago or
    diff < 86400 and Math.floor(diff / 3600) + say.hours_ago) or
    day_diff == 1 and say.yesterday or
    day_diff < 7 and day_diff + say.days_ago or
    day_diff == 7 and say.last_week or
    day_diff > 7 and Math.ceil(day_diff / 7) + say.weeks_ago

resizeImage = (options) ->
  # need url, resize_w and/or resize_h
  options ?= {}
  if options.url.indexOf '.gif' isnt -1
    options.url
  else
    "http://images1-focus-opensocial.googleusercontent.com/gadgets/proxy?container=focus&#{$.param options}"

$ ->
  twitter = new Twitter("#tweets", "zacharydenton", 8)
  github = new GitHub("#github-feed", "zacharydenton", 14)
  googleplus = new GooglePlus("#googleplus", "103362376417669694940", 8)
  lastfm = new Lastfm("#lastfm", "zacharydenton", 10)
