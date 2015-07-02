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
  @packages = packages

  width = 500
  height = 500
  color = d3.scale.category20()

  @force = force = d3.layout.force()
    .charge(-80)
    .linkDistance(100)
    .gravity(.1)
    .linkStrength(.1)
    .size([width, height])

  @svg = svg = d3.select('#viz')
    .append('svg')
    .attr('width', width)
    .attr('height', height)

  @nodes = nodes = packages.filter(({name}) -> 
    name isnt "meteor" and name isnt "meteor-platform"
  ).map((node) ->
    node.dependencies = node.dependencies.filter((name) ->
      name isnt "meteor" and name isnt "meteor-platform"
    )
    node
  )

  map = {}
  for node in nodes
    map[node.name] = node
    node.imported = []

  for node in nodes
    for dep in node.dependencies
      if map[dep]
        map[dep].imported.push(node.name)

  @links = links = []

  find = (name) ->
    for node in nodes
      if name is node.name
        return node
    console.warn("NOT FOUND", name)
    return undefined

  for {name, dependencies} in nodes
    for dep in (dependencies or [])
      source = find(name)
      target = find(dep)
      if source and target
        links.push({source, target})

  force
    .nodes(nodes)
    .links(links)
    .start()

  link = svg.selectAll('.link')
    .data(links)
    .enter()
    .append('line')
    .attr('class', 'link')
    # .style('stroke-width', (d) -> Math.sqrt d.value)

  node = svg.selectAll('.node')
    .data(nodes)
    .enter()

  circle = node.append('circle')
    .attr('class', 'node')
    .attr('r', 5)
    .style('fill', (d) -> color d.group)
    .call(force.drag)
    .on('mouseover', (d) -> Session.set('current', d))

  text = node.append("text")
    .attr("dx", 12)
    .attr("dy", ".10em")
    .text((d) -> d.name)

  force.on 'tick', ->
    link.attr 'x1', (d) -> d.source.x
      .attr 'y1', (d) -> d.source.y
      .attr 'x2', (d) -> d.target.x
      .attr 'y2', (d) -> d.target.y
    
    circle.attr 'cx', (d) -> d.x
      .attr 'cy', (d) -> d.y

    text.attr 'transform', (d) -> 'translate(' + d.x + ',' + d.y + ')'

