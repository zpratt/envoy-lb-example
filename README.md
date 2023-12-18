# envoy-lb-example

## Generate Envoy Configuration

```shell
jsonnet -S envoy.jsonnet -o envoy.yaml
```

## Test Configuration

```shell
docker-compose up -d --build
curl -v -H 'Host: pizzas.localhost' http://localhost:8080/pizzas
```
