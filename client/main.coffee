Session.setDefault('versions', null)
Session.setDefault('loading', false)
Session.setDefault('current', {})

Template.main.helpers
  versions: () ->
    Session.get('versions')
  loading: () ->
    Session.get('loading')
  current: ->
    Session.get('current')

Template.main.events
  'click button.visualize': (e,t) ->
    versions = R.trim(t.find('textarea').value)
    if versions isnt ''
      Session.set('loading', true)
      Session.set('versions', versions)
      Meteor.call 'packages', versions, (err, packages) ->
        Session.set('loading', false)
        Meteor.defer ->
          renderVis(packages)
  'click button.reset': (e,t) ->
    Session.set('versions', null)


renderVis = (packages) ->
  console.log("render!", packages)

  remove = R.curry (name, list) ->
    newList = []
    for node in list
      if node.name isnt name
        newDeps = []
        for dep in node.dependencies
          if dep isnt name
            newDeps.push(dep)
        node.dependencies = newDeps
        newList.push(node)
    return newList

  
  nodes = R.pipe(
    remove('meteor')
    remove('meteor-platform')
  )(packages)

  makeLinks = (list) ->
    links = []
    map = {}
    for node in list
      map[node.name] = node
    for node in list
      for dep in node.dependencies
        unless map[dep]
          map[dep] = {name:dep, deps:[], from:[]}
        # links.push({source:node, target:map[dep]})
        links.push([node, map[dep]])
    return links

  links = makeLinks(nodes)

  diameter = 960
  radius = diameter / 2
  innerRadius = radius - 120

  radial = (list) ->
    len = list.length
    y = innerRadius
    dx = 360 / len
    x = 0
    for node in list
      node.y = y
      node.x = x
      x += dx

  radial(nodes)

  @nodes = nodes

  svg = d3.select("#viz").append("svg")
    .attr("width", diameter)
    .attr("height", diameter)
    .append("g")
    .attr("transform", "translate(" + radius + "," + radius + ")");

  line = d3.svg.line.radial()
    .interpolate('bundle')
    .tension(.85)
    .radius((d) -> d.y )
    .angle((d) -> d.x / 180 * Math.PI )

  svg.selectAll(".link")
      .data(links)
    .enter().append("path")
      .attr("class", "link")
      .attr("d", line)

  svg.selectAll(".node")
      .data(nodes)
    .enter().append("g")
      .attr("class", "node")
      .attr("transform", (d) ->  "rotate(" + (d.x - 90) + ")translate(" + d.y + ")" )
    .append("text")
      .attr("dx", (d) -> if d.x < 180 then 8 else -8 )
      .attr("dy", ".31em")
      .attr("text-anchor", (d) -> if d.x < 180 then "start" else "end")
      .attr("transform", (d) ->  if d.x < 180 then null else "rotate(180)")
      .text((d) ->  d.name )
