ruby tc.rb  http://10.177.235.49:6160/ocpp  rere  reset TYPE Hard
ruby tc.rb  http://10.177.235.49:6160/ocpp  rere  clearCache
ruby tc.rb  http://10.177.235.49:6160/ocpp  rere changeAvailability CONID 1 TYPE Operative
ruby tc.rb  http://10.177.235.49:6160/ocpp  rere  remoteStartTransaction CONID 1 TAGID 112233
ruby tc.rb  http://10.177.235.49:6160/ocpp  rere  remoteStopTransaction TANSCTIONID 1111
ruby tc.rb  http://10.177.235.49:6160/ocpp  rere  unlockConnector  CONID 1
