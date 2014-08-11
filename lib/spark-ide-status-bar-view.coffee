View = require('atom').View
$ = null
settings = null

module.exports =
class SparkIdeStatusBarView extends View
  @content: ->
    @div class: 'inline-block', id: 'spark-ide-status-bar-view', =>
      @img src: 'atom://spark-ide/images/spark.png', id: 'spark-icon'
      @span id: 'spark-login-status'
      @span id: 'spark-log'
      @span id: 'spark-current-core', class: 'hidden', =>
        @a click: 'selectCore'

  initialize: (serializeState) ->
    $ = require('atom').$

    settings = require './settings'

    if atom.workspaceView.statusBar
      @attach()
    else
      @subscribe atom.packages.once 'activated', @attach

    atom.workspaceView.command 'spark-ide:update-login-status', => @updateLoginStatus()
    atom.workspaceView.command 'spark-ide:update-core-status', => @updateCoreStatus()

  # Returns an object that can be retrieved when package is activated
  serialize: ->

  attach: =>
    atom.workspaceView.statusBar.appendLeft(this)
    @updateLoginStatus()

  # Tear down any state and detach
  destroy: ->
    @remove()

  selectCore: ->
    atom.workspaceView.trigger 'spark-ide:select-core'

  updateCoreStatus: ->
    # TODO: Update core status periodically
    statusElement = this.find('#spark-current-core a')

    if !settings.current_core
      statusElement.text 'No cores selected'
    else
      # TODO: Check if current core is still available
      statusElement.text settings.current_core_name

  updateLoginStatus: ->
    hasToken = !!settings.access_token
    statusElement = this.find('#spark-login-status')
    statusElement.empty()

    ideMenu = atom.menu.template.filter (value) ->
      value.label == 'Spark IDE'

    if hasToken
      statusElement.text(settings.username)
      ideMenu[0].submenu[0].label = 'Log out ' + settings.username
      ideMenu[0].submenu[0].command = 'spark-ide:logout'

      this.find('#spark-current-core').removeClass 'hidden'
      @updateCoreStatus()
    else
      loginButton = $('<a/>').text('Click to log in to Spark Cloud...')
      statusElement.append loginButton
      loginButton.on 'click', =>
        atom.workspaceView.trigger 'spark-ide:login'
      ideMenu[0].submenu[0].label = 'Log in to Spark Cloud...'
      ideMenu[0].submenu[0].command = 'spark-ide:login'

      this.find('#spark-current-core').addClass 'hidden'

    atom.menu.update()

  setStatus: (text, type = null) ->
      el = this.find('.spark-log')
      el.text(text)
        .removeClass()

      if type
        el.addClass('text-' + type)

  clear: ->
    el = this.find('.spark-log')
    self = @
    el.fadeOut ->
      self.setStatus ''
      el.show()