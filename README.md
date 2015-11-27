# Logstash Plugin

This is a plugin for [Logstash](https://github.com/elastic/logstash).

It is fully free and fully open source. The license is Apache 2.0, meaning you are pretty much free to use it however you want in whatever way.

## Documentation

The aim of this filter is to recognize a URI in rails `controller#action` form.

### Prerequisite
- rails routes table.
Make use of rails rake `routes`, we can gather all path patterns in a rails application.
`bundle exec rake routes | tail -n +2 > routes_spec`

The result may look like
```
users POST /users(.:format)     users#create
      GET  /users(.:format)     users#index
      GET  /users/:id(.:format) users#show
      ...
```

### Example #1
- with these given logs:
```
2015-11-18T09:45:58.797031Z "GET https://some.domain.com/api/users/1"
```

- you can use `grok` to recognize http verb and uri separately and use `railsroutes` to figure out the rails controller and action, even the parameters inside the uri can be extracted as well.
```
filter {
  grok {
    match => ['message', '%{TIMESTAMP_ISO8601:timestamp} "%{WORD:http_verb} %{URI:url}"']
  }
  railsroutes {
    verb_source => 'http_verb'
    uri_source => 'url'
    routes_spec => '/somewhere/to/your/rails/routes/table'
    api_prefix => 'https://some.domain.com/api'
    target => 'rails'
  }
}
```

- the final event then looks like:
```json
{
    "message": "2015-11-18T09:45:58.797031Z \"GET https://some.domain.com/api/users/1\"",
    "http_verb": "GET",
    "url": "https://some.domain.com/api/users/1",
    "rails": {
        "controller#action": "users#show",
        "id": "1",
        "format": null
    }
}
```

## Contributing

All contributions are welcome: ideas, patches, documentation, bug reports, complaints, and even something you drew up on a napkin.

Programming is not a required skill. Whatever you've seen about open source and maintainers or community members  saying "send patches or die" - you will not see that here.

It is more important to the community that you are able to contribute.

For more information about contributing, see the [CONTRIBUTING](https://github.com/elastic/logstash/blob/master/CONTRIBUTING.md) file.
