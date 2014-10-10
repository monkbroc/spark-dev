{WorkspaceView} = require 'atom'
$ = require('atom').$
SettingsHelper = require '../../lib/utils/settings-helper'
_s = require 'underscore.string'

describe 'Select Wifi View', ->
  activationPromise = null
  sparkIde = null
  selectWifiView = null

  beforeEach ->
    atom.workspaceView = new WorkspaceView
    activationPromise = atom.packages.activatePackage('spark-ide').then ({mainModule}) ->
      sparkIde = mainModule

    originalProfile = SettingsHelper.getProfile()

    # Mock serial
    require.cache[require.resolve('serialport')].exports = require '../stubs/serialport-success'

    waitsForPromise ->
      activationPromise

  describe '', ->
    it 'tests hiding and showing', ->
      SettingsHelper.setCredentials 'foo@bar.baz', '0123456789abcdef0123456789abcdef'

      # Test core:cancel
      atom.workspaceView.trigger 'spark-ide:setup-wifi', ['foo']

      runs ->
        expect(atom.workspaceView.find('#spark-ide-select-wifi-view')).toExist()
        atom.workspaceView.trigger 'core:cancel'
        expect(atom.workspaceView.find('#spark-ide-select-wifi-view')).not.toExist()

        # Test core:close
        atom.workspaceView.trigger 'spark-ide:setup-wifi', ['foo']

      runs ->
        expect(atom.workspaceView.find('#spark-ide-select-wifi-view')).toExist()
        atom.workspaceView.trigger 'core:close'
        expect(atom.workspaceView.find('#spark-ide-select-wifi-view')).not.toExist()

        SettingsHelper.clearCredentials()


    it 'tests loading items', ->
      SettingsHelper.setCredentials 'foo@bar.baz', '0123456789abcdef0123456789abcdef'

      sparkIde.initView 'select-wifi'
      selectWifiView = sparkIde.selectWifiView

      spyOn selectWifiView, 'listNetworks'

      atom.workspaceView.trigger 'spark-ide:setup-wifi', ['foo']

      runs ->
        expect(atom.workspaceView.find('#spark-ide-select-wifi-view')).toExist()
        expect(selectWifiView.find('span.loading-message').text()).toEqual('Scaning for networks...')
        expect(selectWifiView.listNetworks).toHaveBeenCalled()

        jasmine.unspy selectWifiView, 'listNetworks'
        SettingsHelper.clearCredentials()
        atom.workspaceView.trigger 'core:close'

    fit 'test listing networks on Darwin', ->
      SettingsHelper.setCredentials 'foo@bar.baz', '0123456789abcdef0123456789abcdef'

      process.platform = 'darwin'

      sparkIde.initView 'select-wifi'
      selectWifiView = sparkIde.selectWifiView

      spyOn(selectWifiView, 'listNetworksDarwin').andCallThrough()
      spyOn(selectWifiView.cp, 'exec').andCallFake (command, callback) =>
        if _s.endsWith(command) == '-I'
          stdout = "     agrCtlRSSI: -40\n\
     agrExtRSSI: 0\n\
    agrCtlNoise: -92\n\
    agrExtNoise: 0\n\
          state: running\n\
        op mode: station \n\
     lastTxRate: 130\n\
        maxRate: 144\n\
lastAssocStatus: 0\n\
    802.11 auth: open\n\
      link auth: wpa2-psk\n\
          BSSID: fc:91:e3:47:92:d3\n\
           SSID: foo\n\
            MCS: 15\n\
        channel: 6"

        else
          stdout = "                            SSID BSSID             RSSI CHANNEL HT CC SECURITY (auth/unicast/group)\n\
                      UPC0044189 fc:94:e3:32:3e:a8 -49  11      Y  -- NONE \n\
                     UPC Wi-Free fe:94:e3:32:3e:aa -51  11      Y  -- WPA(802.1x/AES,TKIP/TKIP) \n\
                          pstryk c8:3a:35:11:8d:b0 -83  6,-1    Y  -- WEP \n\
                     UPC Wi-Free fe:94:e3:21:92:d5 -36  6       Y  -- WPA(802.1x/AES,TKIP/TKIP) \n\
                             foo fc:94:e3:21:92:d3 -37  6       Y  -- WPA(PSK/AES,TKIP/TKIP) WPA2(PSK/AES,TKIP/TKIP) "

        callback '', stdout

      spyOn selectWifiView, 'setItems'

      atom.workspaceView.trigger 'spark-ide:setup-wifi', ['foo']

      runs ->
        expect(atom.workspaceView.find('#spark-ide-select-wifi-view')).toExist()
        expect(selectWifiView.find('span.loading-message').text()).toEqual('Scaning for networks...')
        expect(selectWifiView.listNetworksDarwin).toHaveBeenCalled()

        expect(selectWifiView.setItems).toHaveBeenCalled()
        expect(selectWifiView.setItems.calls.length).toEqual(2)
        args = selectWifiView.setItems.calls[1].args[0]
        
        expect(args.length).toEqual(5)
        expect(args[0].ssid).toEqual('foo')
        expect(args[0].bssid).toEqual('fc:94:e3:21:92:d3')
        expect(args[0].rssi).toEqual('-37')
        expect(args[0].channel).toEqual('6')
        expect(args[0].ht).toEqual('Y')
        expect(args[0].cc).toEqual('--')
        expect(args[0].security_string).toEqual('WPA(PSK/AES,TKIP/TKIP) WPA2(PSK/AES,TKIP/TKIP) ')
        expect(args[0].security).toEqual(3)

        expect(args[1].security).toEqual(0)
        expect(args[2].security).toEqual(2)
        expect(args[3].security).toEqual(1)

        expect(args[4].ssid).toEqual('Enter SSID manually')
        expect(args[4].security).toBe(null)

        jasmine.unspy selectWifiView, 'setItems'
        jasmine.unspy selectWifiView.cp, 'exec'
        jasmine.unspy selectWifiView, 'listNetworksDarwin'
        SettingsHelper.clearCredentials()
        atom.workspaceView.trigger 'core:close'