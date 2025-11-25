# 📘 Guía de Despliegue en Kubernetes

## 🎯 Requisitos previos

1. **Kubernetes cluster** (Minikube, Docker Desktop, GKE, EKS, AKS, etc.)
2. **kubectl** instalado y configurado
3. **Docker** instalado
4. **Cuenta en Docker Hub** (o registro privado)

## 🚀 Despliegue paso a paso

### 1. Construir y subir imagen Docker

```bash
# Hacer ejecutable el script
chmod +x scripts/build-and-push.sh

# Editar variables en el script (DOCKER_USERNAME, IMAGE_NAME)
nano scripts/build-and-push.sh

# Ejecutar
./scripts/build-and-push.sh
```

### 2. Actualizar manifiestos de Kubernetes

Editar `k8s/backend-deployment.yaml`:
```yaml
image: ezequielrd/my-backend-test:latest  # CAMBIAR
```

Editar `k8s/ingress.yaml`:
```yaml
host: api.tudominio.com  # CAMBIAR o usar IP
```

### 3. Generar secrets seguros (PRODUCCIÓN)

```bash
# Generar JWT secret aleatorio
openssl rand -base64 32

# Codificar en base64
echo -n 'tu-password' | base64

# Actualizar k8s/secrets.yaml con los valores generados
```

### 4. Desplegar en Kubernetes

```bash
# Hacer ejecutable
chmod +x scripts/deploy-k8s.sh

# Ejecutar
./scripts/deploy-k8s.sh
```

### 5. Verificar despliegue

```bash
# Ver pods
kubectl get pods -n springboot-products

# Ver logs del backend
kubectl logs -f deployment/backend-products -n springboot-products

# Ver logs de MySQL
kubectl logs -f deployment/mysql -n springboot-products

# Verificar servicios
kubectl get svc -n springboot-products

# Verificar ingress
kubectl get ingress -n springboot-products
```

### 6. Acceder a la aplicación

```bash
# Si usas Minikube
minikube service backend-service -n springboot-products

# Si usas Ingress
curl http://api.tudominio.com/actuator/health

# Port-forward (desarrollo)
kubectl port-forward svc/backend-service 8080:80 -n springboot-products
# Acceder: http://localhost:8080
```

## 🔧 Comandos útiles

### Ver estado general
```bash
kubectl get all -n springboot-products
```

### Escalar manualmente
```bash
kubectl scale deployment backend-products --replicas=5 -n springboot-products
```

### Ver métricas de HPA
```bash
kubectl get hpa -n springboot-products -w
```

### Actualizar imagen (rolling update)
```bash
kubectl set image deployment/backend-products backend=tu-usuario/springboot-products:v2 -n springboot-products
```

### Rollback
```bash
kubectl rollout undo deployment/backend-products -n springboot-products
```

### Ver histórico de deployments
```bash
kubectl rollout history deployment/backend-products -n springboot-products
```

### Conectar a MySQL desde un pod temporal
```bash
kubectl run -it --rm mysql-client --image=mysql:8.0 --restart=Never -n springboot-products -- mysql -h mysql-service -u springboot -p
```

### Ver logs en tiempo real
```bash
kubectl logs -f -l app=backend-products -n springboot-products
```

## 🗑️ Eliminar todo

```bash
chmod +x scripts/delete-k8s.sh
./scripts/delete-k8s.sh
```

## 🐛 Troubleshooting

### Pod no arranca
```bash
kubectl describe pod <pod-name> -n springboot-products
kubectl logs <pod-name> -n springboot-products
```

### Error de conexión a MySQL
```bash
# Verificar que MySQL esté running
kubectl get pods -l app=mysql -n springboot-products

# Ver logs de MySQL
kubectl logs -l app=mysql -n springboot-products

# Verificar variables de entorno del backend
kubectl exec -it <backend-pod> -n springboot-products -- env | grep SPRING
```

### Ingress no funciona
```bash
# Verificar que el Ingress Controller esté instalado
kubectl get pods -n ingress-nginx

# Instalar NGINX Ingress (si no está)
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.8.1/deploy/static/provider/cloud/deploy.yaml
```

## 🔒 Seguridad en Producción

1. **Cambiar todos los secrets** en `k8s/secrets.yaml`
2. **Usar un registry privado** para imágenes Docker
3. **Configurar HTTPS/TLS** en Ingress (cert-manager)
4. **Network Policies** para restringir tráfico entre pods
5. **RBAC** con permisos mínimos
6. **Scanear imágenes** con herramientas como Trivy
7. **Secrets management** con HashiCorp Vault o Sealed Secrets

## 📊 Monitoreo

### Instalar Prometheus + Grafana (opcional)
```bash
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm install prometheus prometheus-community/kube-prometheus-stack -n monitoring --create-namespace
```

### Métricas de Spring Boot
Spring Actuator ya expone métricas en formato Prometheus:
- Endpoint: `/actuator/prometheus`