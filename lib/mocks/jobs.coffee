_ = require 'underscore'
async = require 'async'
{EventEmitter}  = require 'events'

class MockJob extends EventEmitter
  constructor: ->
    super
    @handle = 'job_handle'
    @events = []
  delayEmit: (event, timeout, args...) =>
    @events.push {event, timeout, args}
  intervalEmit: (event, timeout, data) ->
    interval = Math.floor timeout / (data.length + 1)
    @delayEmit event, (i + 1) * interval, el for el, i in data
  start: =>
    events =
      if @events.length < 2
        @events
      else
        events = _.sortBy @events, (e) -> e.timeout
        event_pairs = _.zip events, _.rest(events).concat [_.last events]
        _.map event_pairs, ([event, next_event]) ->
          _.extend event, timeout: next_event.timeout - event.timeout
    async.forEachSeries events, ({event, timeout, args}, cb_fe) =>
      setTimeout =>
        @emit event, @handle, args...
        cb_fe()
      , timeout
    , -> # No errors to handle
    @

class CompleteJob extends MockJob
  constructor: (timeout = 0) ->
    super
    @delayEmit 'complete', timeout

class DataJob extends CompleteJob
  constructor: (data, timeout = 0) ->
    # Add 1 so 'complete' event fires last
    super timeout + 1
    @intervalEmit 'data', timeout, data

class FailJob extends MockJob
  constructor: (timeout = 0) ->
    super
    @delayEmit 'fail', timeout

class ErrorJob extends FailJob
  constructor: (messages, timeout = 0) ->
    # Add 1 so 'fail' event fires last
    super timeout + 1
    @intervalEmit 'warning', timeout, messages

module.exports = {MockJob, CompleteJob, DataJob, FailJob, ErrorJob}
