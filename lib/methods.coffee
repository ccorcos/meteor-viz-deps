Meteor.methods
  packages: (versions) ->
    if Meteor.isServer
      update()
      R.pipe(
        R.split('\n'), 
        R.map(R.split('@'))
        R.map ([name, version]) ->
          Packages.findOne({name, version})
        R.flatten
      )(versions)