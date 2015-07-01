@Packages = new Mongo.Collection('packages')
Packages._ensureIndex({name:1, version:1})

@SyncToken = new Mongo.Collection('token')

@PackageServer = DDP.connect('https://packages.meteor.com/')

@getSyncToken = ->
  token = SyncToken.findOne()
  if token
    return R.omit(['_id'], token)
  else
    return undefined

@setSyncToken = (syncToken) ->
  SyncToken.remove({})
  SyncToken.insert(syncToken)

processVersion = (doc) ->
  obj = {}
  obj._id = doc._id
  obj.dependencies = R.keys(doc.dependencies)
  obj.version = doc.version
  obj.name = doc.packageName
  obj.description = doc.description
  return obj

@updatePackageData = (collections) ->
  packages = R.map(processVersion, collections.versions)
  for p in packages
    Packages.upsert(p._id, p)

@update = ->
  console.log "updating..."
  updateLoop()

@updateLoop = ->
  upToDate = false
  while not upToDate
    token = getSyncToken()
    console.log "...fetch, #{token?.versions}"
    {syncToken, collections, upToDate, resetData} = PackageServer.call("syncNewPackageData", token or  {format: "1.1"})

    if resetData
      console.log "...reset"
      SyncToken.remove({})
      Packages.remove({})
    
    setSyncToken(syncToken)
    
    if collections?.versions
      console.log "...upsert #{collections?.versions?.length}"
      updatePackageData(collections)
    
    if upToDate
      console.log("...done")
      return
    else
      console.log("...not done yet")
