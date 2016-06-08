# Fluent::Plugin::HttpForward

This gem provides a buffered HTTP output plugin for Fluentd which also optionally supports authentication.

## Requirements

* Fluetnd v0.14+

## Installation

```ruby
gem 'fluent-plugin-http_forward'
```

## Configuration Options

```
<match **>
  @type http_forward
  url   http://remote.example.com/%{tag}
  verb  post
  content_type  application/json # optional override
  <authentication>
    method    basic
    username  user
    password  pass
  </authentication>
  <format>
    @type json
  </format>
  <buffer tag>                  # if buffering, specify tag for in_http compat
    chunk_limit_size 8388608    # optional, maximum chunk size, default 8MB
    total_limit_size 536760912  # optional, maximum buffer size, default 512M
    chunk_records_limit 10      # optional, maximum records per chunk
    flush_interval 60           # optional, maximum time between flush
    flush_thread_count 1        # optional, async threads to flush buffer
  </buffer>

## Status

At present, only the JSON format has been tested. There's an optional msgpack format available that is as of yet untested because in_http does not currently support it. 

