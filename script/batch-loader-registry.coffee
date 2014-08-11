
app.service 'ksc.batchLoaderRegistry', [
  'ksc.error', 'ksc.utils',
  (error, utils) ->

    ###
    A registry service for {BatchLoader} instances and interface for $http.get
    users to try and use a batch loader

    @note This is meant to be a low-level service, no high level code should be
      using this API

    @author Greg Varsanyi
    ###
    class BatchLoaderRegistry

      # @property [Array] list of registered
      map: {}

      ###
      Add a GET request to a {BatchLoader} instance request list if there is one
      to accept it and return its promise (or false if none found to take it)

      @param [string] url url string without query parameters
      @param [Object] query_parameters (optional) key-value map of query params

      @return [false|Promise] Promise from a {BatchLoader#get} if any
      ###
      get: (url, query_parameters) ->
        for endpoint, loader of @map
          if promise = loader.get url, query_parameters
            return promise
        false

      ###
      Register a {BatchLoader} instance using its {BatchLoader#endpoint}
      property as key on map

      @param [BatchLoader] loader {BatchLoader} instance to be registered

      @throw [KeyError] if loader is already registered or key is bugous

      @return [BatchLoader] registered {BatchLoader} instance
      ###
      register: (loader) ->
        if utils.isKeyConform endpoint = loader?.endpoint
          error.Key {endpoint: endpoint, required: 'url'}

        if @map[endpoint]
          error.Key {endpoint, description: 'already registered'}

        @map[endpoint] = loader

      ###
      Unregister a {BatchLoader} instance using its {BatchLoader#endpoint}
      property as key on map

      @param [BatchLoader] loader {BatchLoader} instance to be unregistered

      @return [boolean] indicates if removal has happened
      ###
      unregister: (loader) ->
        delete @map[loader.endpoint]


    new BatchLoaderRegistry
]
