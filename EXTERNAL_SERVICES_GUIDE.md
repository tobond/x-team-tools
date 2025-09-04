# External Services Usage Guide

This guide explains how to use the external services and dependency management features implemented in Task 9.

## Quick Start

Deploy external services along with your applications:

```bash
# Deploy with database and cache
tilt up -- --services=database,redis,ai-agentic-mdr-oscar

# Deploy with message queue
tilt up -- --services=database,redis,rabbitmq,ai-agentic-mdr-oscar

# Deploy with mock services for external API testing
tilt up -- --services=database,mock-payment-api,mock-user-api,ai-agentic-mdr-oscar
```

## Available External Services

### Database Services

#### PostgreSQL Database
- **Service**: `database`
- **Type**: `postgres`
- **Port**: 5432
- **Connection**: `psql -h localhost -p 5432 -U devuser_{your_id} -d devdb_{your_id}`
- **Features**: 
  - Developer-isolated databases
  - Automatic test data creation
  - Persistent storage

### Cache and Queue Services

#### Redis Cache
- **Service**: `redis`
- **Type**: `redis`
- **Port**: 6379
- **Connection**: `redis-cli -h localhost -p 6379 -a devpass_{your_id}`
- **Features**:
  - Cache and simple queuing
  - Developer-isolated passwords
  - Persistent storage

#### RabbitMQ Message Queue
- **Service**: `rabbitmq`
- **Type**: `rabbitmq`
- **Ports**: 5672 (AMQP), 15672 (Management UI)
- **Management UI**: http://localhost:15672
- **Credentials**: `devuser_{your_id}` / `devpass_{your_id}`
- **Features**:
  - Full message queuing with exchanges
  - Developer-isolated virtual hosts
  - Pre-configured test queues

### Mock Services

#### Mock Payment API
- **Service**: `mock-payment-api`
- **Port**: 8090
- **Base URL**: http://localhost:8090
- **Endpoints**:
  - `POST /api/v1/payments` - Create payment
  - `GET /api/v1/payments/{id}` - Get payment details
  - `POST /api/v1/payments/{id}/refund` - Process refund

#### Mock User API
- **Service**: `mock-user-api`
- **Port**: 8091
- **Base URL**: http://localhost:8091
- **Endpoints**:
  - `GET /api/v1/users` - List users
  - `POST /api/v1/users` - Create user
  - `GET /api/v1/users/{id}` - Get user details

#### Mock Notification Service
- **Service**: `mock-notification-service`
- **Port**: 8092
- **Base URL**: http://localhost:8092
- **Endpoints**:
  - `POST /api/v1/notifications/send` - Send notification
  - `GET /api/v1/notifications/{id}/status` - Get notification status

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
    dependencies: ["database", "redis", "mock-payment-api"]
    # ... other configuration
```

## Developer Isolation

All external services are automatically isolated per developer:

- **Databases**: `devdb_{developer_id}`, `devuser_{developer_id}`
- **Passwords**: `devpass_{developer_id}`
- **Virtual Hosts**: `dev_{developer_id}` (RabbitMQ)
- **Namespaces**: `dev-{developer_id}`

## Monitoring and Management

### Tilt UI Resources

- **External Services Dashboard**: Overview of all external services
- **Service-specific monitors**: Detailed health checks for each service
- **Endpoint documentation**: API documentation for mock services

### Manual Commands

```bash
# Check service status
kubectl get pods -n dev-{your_id}

# View service logs
kubectl logs -f deployment/database -n dev-{your_id}

# Test database connection
kubectl exec -it deployment/database -n dev-{your_id} -- psql -U devuser_{your_id} -d devdb_{your_id}

# Test Redis connection
kubectl exec -it deployment/redis -n dev-{your_id} -- redis-cli -a devpass_{your_id}
```

### Health Checks

All services include health endpoints:

```bash
# Mock service health
curl http://localhost:8090/health

# Database health (via kubectl)
kubectl exec deployment/database -n dev-{your_id} -- pg_isready

# Redis health (via kubectl)  
kubectl exec deployment/redis -n dev-{your_id} -- redis-cli -a devpass_{your_id} ping
```

## Secret Management

### Developer Secret Templates

Create custom secrets in `.tilt/secrets/{your_id}.yaml`:

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
# Test mock payment API
curl -X POST http://localhost:8090/api/v1/payments \
  -H "Content-Type: application/json" \
  -d '{"amount": 100.00, "currency": "USD"}'

# Test database
psql -h localhost -p 5432 -U devuser_{your_id} -d devdb_{your_id} -c "SELECT * FROM users;"

# Test Redis
redis-cli -h localhost -p 6379 -a devpass_{your_id} SET test_key "test_value"
redis-cli -h localhost -p 6379 -a devpass_{your_id} GET test_key

# Test RabbitMQ
# Access management UI at http://localhost:15672
```

## Troubleshooting

### Common Issues

1. **Service not starting**: Check resource limits and cluster capacity
2. **Connection refused**: Verify port-forwards are active in Tilt UI
3. **Authentication failed**: Check developer-specific credentials
4. **Data not persisting**: Verify PVC creation and mounting

### Debug Commands

```bash
# Check service status
kubectl describe pod -l app=database -n dev-{your_id}

# View service events
kubectl get events -n dev-{your_id} --sort-by='.lastTimestamp'

# Check persistent volumes
kubectl get pvc -n dev-{your_id}

# Test network connectivity
kubectl exec -it deployment/my-app -n dev-{your_id} -- nc -zv database 5432
```

## Best Practices

1. **Use Dependencies**: Always specify service dependencies in your configuration
2. **Monitor Resources**: Check resource usage in Tilt UI
3. **Test Isolation**: Verify your services work with developer-specific data
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
response = requests.post(
    "http://mock-payment-api:8090/api/v1/payments",
    json={"amount": 100.00, "currency": "USD"}
)
```

This guide covers all the external services features implemented in Task 9. For more detailed information, see the implementation summary and test files.