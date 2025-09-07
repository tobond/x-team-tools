# External Services Usage Guide

This guide explains how to use the external services and dependency management features.

## Quick Start

Deploy external services along with your applications:

```bash
# Deploy with database and cache
tilt up -- --services=database,redis,ai-agentic-mdr-oscar

# Deploy with mock services for external API testing
tilt up -- --services=database,mock-service,ai-agentic-mdr-oscar
```

## Available External Services

### Database Services

#### PostgreSQL Database
- **Service**: `database`
- **Type**: `postgres`
- **Port**: 5432
- **Connection**: `psql -h localhost -p 5432 -U testuser -d testdb`
- **Features**: 
  - Standard credentials for local development
  - Automatic test data creation
  - Persistent storage

### Cache and Queue Services

#### Redis Cache
- **Service**: `redis`
- **Type**: `redis`
- **Port**: 6379
- **Connection**: `redis-cli -h localhost -p 6379 -a testpass`
- **Features**:
  - Cache and simple queuing
  - Standard credentials for local development
  - Persistent storage


### Mock Services

#### Mock Services
- **Type**: `mock`
- **Configurable Ports**: Default 8080
- **Features**:
  - Fully configurable mock endpoints
  - Support for any HTTP method
  - Custom response data and status codes
  - Standard credentials for local development
  - Health check endpoints

## Service Configuration

### Adding New Mock Services

Add to `.tilt/service-config.yaml`:

```yaml
services:
  my-mock-service:
    type: "mock"
    ports: [8093]
    resources:
      cpu: "100m"
      memory: "128Mi"
    mock_endpoints:
      - path: "/api/v1/my-endpoint"
        method: "GET"
        response:
          message: "Hello from mock service"
          data: []
        status_code: 200
        description: "My custom endpoint"
```

### Service Dependencies

Configure service dependencies in your application services:

```yaml
services:
  my-app:
    type: "python"
    dependencies: ["database", "redis", "mock-service"]
    # ... other configuration
```

## Local Development Configuration

All external services use standard credentials for local development:

- **Database**: `testdb`, **User**: `testuser`
- **Password**: `testpass`
- **Namespace**: `default`

## Monitoring and Management

### Tilt UI Resources

- **External Services Dashboard**: Overview of all external services
- **Service-specific monitors**: Detailed health checks for each service
- **Endpoint documentation**: API documentation for mock services

### Manual Commands

```bash
# Check service status
kubectl get pods

# View service logs
kubectl logs -f deployment/database

# Test database connection
kubectl exec -it deployment/database -- psql -U testuser -d testdb

# Test Redis connection
kubectl exec -it deployment/redis -- redis-cli -a testpass
```

### Health Checks

All services include health endpoints:

```bash
# Mock service health
curl http://localhost:8090/health

# Database health (via kubectl)
kubectl exec deployment/database -- pg_isready

# Redis health (via kubectl)  
kubectl exec deployment/redis -- redis-cli -a testpass ping
```

## Secret Management

### Developer Secret Templates

Create custom secrets in `.tilt/secrets/local-dev.yaml`:

```yaml
secrets:
  # Database credentials
  database_password: "your_custom_db_password"
  
  # API keys
  external_api_key: "your_api_key"
  
  # Custom application secrets
  jwt_secret: "your_jwt_secret"
  encryption_key: "your_encryption_key"
```

### Accessing Secrets in Applications

Secrets are automatically mounted as Kubernetes secrets:

```yaml
# In your application deployment
env:
- name: DATABASE_PASSWORD
  valueFrom:
    secretKeyRef:
      name: my-app-secret
      key: database_password
```

## Testing External Services

### Automated Testing

Run the external services test suite:

```bash
python3 .tilt/test-external-services.py
```

### Manual Testing

```bash
# Test mock service
curl http://localhost:8080/health

# Test database
psql -h localhost -p 5432 -U testuser -d testdb -c "SELECT * FROM users;"

# Test Redis
redis-cli -h localhost -p 6379 -a testpass SET test_key "test_value"
redis-cli -h localhost -p 6379 -a testpass GET test_key

```

## Adding New External Services

### Service-Agnostic Framework

The external services framework is completely service-agnostic. You can add **any Docker-based external service** without code changes by simply adding it to `.tilt/service-config.yaml`.

### Quick Examples

```yaml
# Add MySQL Database
mysql:
  type: "external"
  image: "mysql:8.0"
  ports: [3306]
  env_vars:
    - name: "MYSQL_ROOT_PASSWORD"
      value: "testpass"
    - name: "MYSQL_DATABASE"
      value: "testdb"
    - name: "MYSQL_USER"
      value: "testuser"
    - name: "MYSQL_PASSWORD"
      value: "testpass"
  resources:
    cpu: "500m"
    memory: "1Gi"

# Add Elasticsearch
elasticsearch:
  type: "external"
  image: "elasticsearch:8.11.0"
  ports: [9200]
  env_vars:
    - name: "discovery.type"
      value: "single-node"
    - name: "ES_JAVA_OPTS"
      value: "-Xms512m -Xmx512m"
  resources:
    cpu: "1000m"
    memory: "2Gi"

# Add RabbitMQ
rabbitmq:
  type: "external"
  image: "rabbitmq:3-management"
  ports: [5672, 15672]
  env_vars:
    - name: "RABBITMQ_DEFAULT_USER"
      value: "testuser"
    - name: "RABBITMQ_DEFAULT_PASS"
      value: "testpass"
  resources:
    cpu: "250m"
    memory: "512Mi"

# Add Any Docker Service
my-custom-service:
  type: "external"
  image: "my-company/my-service:latest"
  ports: [8080, 9090]
  env_vars:
    - name: "CONFIG_ENV"
      value: "development"
  resources:
    cpu: "500m"
    memory: "512Mi"
  health_check:
    command: ["curl", "-f", "http://localhost:8080/health"]
```

### Usage After Adding

Once you add a service to the configuration, you can immediately use it:

```bash
# Deploy your new services
tilt up -- --services=mysql,elasticsearch,my-app

# Or include in environments
# Add to .tilt/environments.yaml:
# my-environment:
#   services: ["my-app", "mysql", "elasticsearch"]
```

### Supported Service Types

The framework can deploy **any Docker-based service**:
- **Databases**: MySQL, MongoDB, CouchDB, CockroachDB, InfluxDB
- **Caches**: Memcached, Hazelcast, Apache Ignite
- **Message Queues**: Apache Kafka, NATS, Apache Pulsar
- **Search**: OpenSearch, Solr, MeiliSearch
- **Monitoring**: Prometheus, Grafana, Jaeger, Zipkin
- **Custom Services**: Any Docker image from any registry

### Standard Patterns

All external services use consistent patterns:
- **Credentials**: `testuser` / `testpass` for local development
- **Configuration**: Environment variables in YAML
- **Resources**: CPU and memory limits per service
- **Health Checks**: Optional custom health check commands
- **Networking**: Automatic port forwarding and service discovery

## Troubleshooting

### Common Issues

1. **Service not starting**: Check resource limits and cluster capacity
2. **Connection refused**: Verify port-forwards are active in Tilt UI
3. **Authentication failed**: Check standard credentials (testuser/testpass)
4. **Data not persisting**: Verify PVC creation and mounting

### Debug Commands

```bash
# Check service status
kubectl describe pod -l app=database

# View service events
kubectl get events --sort-by='.lastTimestamp'

# Check persistent volumes
kubectl get pvc

# Test network connectivity
kubectl exec -it deployment/my-app -- nc -zv database 5432
```

## Best Practices

1. **Use Dependencies**: Always specify service dependencies in your configuration
2. **Monitor Resources**: Check resource usage in Tilt UI
3. **Test Locally**: Verify your services work with standard local development data
4. **Clean Secrets**: Don't commit real secrets to version control
5. **Health Checks**: Use provided health endpoints for application readiness

## Integration Examples

### Python Application with Database

```python
import psycopg2
import os

# Use environment variables for connection
conn = psycopg2.connect(
    host="database",  # Service name in Kubernetes
    port=5432,
    database=os.environ.get("POSTGRES_DB"),
    user=os.environ.get("POSTGRES_USER"),
    password=os.environ.get("POSTGRES_PASSWORD")
)
```

### Node.js Application with Redis

```javascript
const redis = require('redis');

const client = redis.createClient({
    host: 'redis',  // Service name in Kubernetes
    port: 6379,
    password: process.env.REDIS_PASSWORD
});
```

### Mock API Integration

```python
import requests

# Use mock service for external API calls
response = requests.get(
    "http://mock-service:8080/api/v1/users"
)
```

This guide covers all the external services features implemented in Task 9. For more detailed information, see the implementation summary and test files.