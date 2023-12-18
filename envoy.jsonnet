local pizzaService = {
  name: 'pizza_service',
  health_endpoint: '/health',
  external_host: 'pizzas.localhost',
  upstream_host: 'pizzas',
};

local logFormat = {
  json_format: {
    start_time: '%START_TIME%',
    method: '%REQ(:METHOD)%',
    path: '%REQ(X-ENVOY-ORIGINAL-PATH?:PATH)%',
    protocol: '%PROTOCOL%',
    response_code: '%RESPONSE_CODE%',
    response_flags: '%RESPONSE_FLAGS%',
    bytes_received: '%BYTES_RECEIVED%',
    bytes_sent: '%BYTES_SENT%',
    duration: '%DURATION%',
    upstream_service_time: '%RESP(X-ENVOY-UPSTREAM-SERVICE-TIME)%',
    x_forwarded_for: '%REQ(X-FORWARDED-FOR)%',
    user_agent: '%REQ(USER-AGENT)%',
    request_id: '%REQ(X-REQUEST-ID)%',
    authority: '%REQ(:AUTHORITY)%',
    upstream_host: '%UPSTREAM_HOST%',
    upstream_cluster: '%UPSTREAM_CLUSTER%',
    envoy_original_path: '%REQ(X-ENVOY-ORIGINAL-PATH)%',
  },
};

local HealthCheck(path) = {
  timeout: '3s',
  interval: '5s',
  unhealthy_threshold: 3,
  healthy_threshold: 2,
  http_health_check: {
    path: path,
    codec_client_type: 'HTTP1',
  },
};

local LoadBalancer(upstream_host, service_name, health_check_path) = {
  name: service_name,
  connect_timeout: '0.25s',
  type: 'STRICT_DNS',
  lb_policy: 'ROUND_ROBIN',
  health_checks: [
    HealthCheck(health_check_path),
  ],
  load_assignment: {
    cluster_name: service_name,
    endpoints: [
      {
        lb_endpoints: [
          {
            endpoint: {
              address: {
                socket_address: {
                  address: upstream_host,
                  port_value: 3000,
                },
              },
            },
          },
        ],
      },
    ],
  },
};

local lbConfig = {
  pizza_service: {
    name: 'pizza_service',
    connect_timeout: '0.25s',
    type: 'STRICT_DNS',
    lb_policy: 'ROUND_ROBIN',
    health_checks: [
      HealthCheck('/health'),
    ],
    load_assignment: {
      cluster_name: 'pizza_service',
      endpoints: [
        {
          lb_endpoints: [
            {
              endpoint: {
                address: {
                  socket_address: {
                    address: 'pizzas',
                    port_value: 3000,
                  },
                },
              },
            },
          ],
        },
      ],
    },
  },
};

local pizzasVHost = {
  name: lbConfig.pizza_service.name,
  domains: ['pizzas.localhost'],
  routes: [
    {
      match: { prefix: '/' },
      route: { cluster: lbConfig.pizza_service.name },
    },
  ],
};

local connectionManagerFilter = {
  name: 'envoy.filters.network.http_connection_manager',
  typed_config: {
    '@type': 'type.googleapis.com/envoy.extensions.filters.network.http_connection_manager.v3.HttpConnectionManager',
    stat_prefix: 'ingress_http',
    access_log: [
      {
        name: 'envoy.access_loggers.file',
        typed_config: {
          '@type': 'type.googleapis.com/envoy.extensions.access_loggers.file.v3.FileAccessLog',
          path: '/dev/stdout',
          log_format: logFormat,
        },
      },
    ],
    route_config: {
      name: 'local_route',
      virtual_hosts: [
        pizzasVHost,
      ],
    },
    http_filters: [
      {
        name: 'envoy.filters.http.router',
        typed_config: {
          '@type': 'type.googleapis.com/envoy.extensions.filters.http.router.v3.Router',
        },
      },
    ],
  },
};

local baseConfig = {
  static_resources: {
    listeners: [
      {
        address: {
          socket_address: {
            address: '0.0.0.0',
            port_value: 8080,
          },
        },
        filter_chains: [
          {
            filters: [
              connectionManagerFilter,
            ],
          },
        ],
      },
    ],
    clusters: [
      LoadBalancer(pizzaService.upstream_host, pizzaService.name, pizzaService.health_endpoint),
    ],
  },
};

std.manifestYamlDoc(baseConfig, indent_array_in_object=true, quote_keys=false)
