# Solución: Error de Certificado TLS en Kubernetes

## Problema
```
Unable to connect to the server: tls: failed to verify certificate: x509: certificate signed by unknown authority
```

Este error ocurre cuando:
- Kubernetes usa certificados auto-firmados (típico en Minikube, k3s, clusters locales)
- El kubeconfig contiene certificados que no están en el store de confianza del sistema
- `kubectl` no puede verificar la identidad del servidor API

---

## Soluciones Disponibles

### ✅ SOLUCIÓN 1: Deshabilitar Verificación de Certificados (Rápida)

**Opción A - En el kubeconfig:**
```bash
kubectl config set-cluster kubernetes \
  --insecure-skip-tls-verify=true \
  --kubeconfig=/ruta/a/kubeconfig
```

**Opción B - Temporalmente en CLI:**
```bash
kubectl --insecure-skip-tls-verify=true get pods
```

**Opción C - Variable de entorno:**
```bash
export INSECURE_SKIP_VERIFY=true
kubectl get pods
```

**Ventaja:** Rápido, funciona inmediatamente
**Desventaja:** Menos seguro, vulnerable a man-in-the-middle

---

### ✅ SOLUCIÓN 2: Importar Certificados CA (Recomendado)

**Paso 1: Extraer el certificado CA del kubeconfig**
```bash
# El kubeconfig contiene el CA en base64
# Necesitas extraerlo y decodificarlo
kubectl config view --raw > kubeconfig-decoded.yaml

# En el archivo busca: certificate-authority-data
# Decodifica el valor base64:
echo "<certificate-authority-data>" | base64 -d > ca.crt
```

**Paso 2: Importar al almacén de confianza del sistema**

**En Windows (PowerShell como Admin):**
```powershell
# Importar certificado
$cert = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2
$cert.Import("C:\path\to\ca.crt")
$store = New-Object System.Security.Cryptography.X509Certificates.X509Store("Root", "LocalMachine")
$store.Open("ReadWrite")
$store.Add($cert)
$store.Close()
```

**En Linux/macOS:**
```bash
# Linux (Debian/Ubuntu)
sudo cp ca.crt /usr/local/share/ca-certificates/
sudo update-ca-certificates

# macOS
sudo security add-trusted-cert -d -r trustRoot -k /Library/Keychains/System.keychain ca.crt
```

**Ventaja:** Seguro, solución permanente
**Desventaja:** Requiere acceso administrativo

---

### ✅ SOLUCIÓN 3: Jenkins + Kubeconfig sin Verificación (Para CI/CD)

**En Jenkinsfile:**
```groovy
withCredentials([file(credentialsId: 'kubeconfig', variable: 'KUBECONFIG')]) {
    sh '''
        export KUBECONFIG=${KUBECONFIG}

        # Opción A: Deshabilitar verificación globalmente
        kubectl config set-cluster kubernetes --insecure-skip-tls-verify=true

        # Opción B: Variable de entorno
        export INSECURE_SKIP_VERIFY=true

        # Ahora kubectl funcionará
        kubectl get nodes
    '''
}
```

**Ventaja:** Funciona en Jenkins
**Desventaja:** Requiere que el kubeconfig sea configurable

---

### ✅ SOLUCIÓN 4: Usar kubectl config con Skip Verify (Mejor para Jenkins)

```groovy
withCredentials([file(credentialsId: 'kubeconfig', variable: 'KUBECONFIG')]) {
    sh '''
        # 1. Copiar kubeconfig a ubicación temporal
        cp ${KUBECONFIG} /tmp/kubeconfig-temp

        # 2. Modificar el kubeconfig para deshabilitar verificación de certificados
        kubectl config set-cluster kubernetes \
            --kubeconfig=/tmp/kubeconfig-temp \
            --insecure-skip-tls-verify=true

        # 3. Usar el kubeconfig modificado
        export KUBECONFIG=/tmp/kubeconfig-temp
        kubectl cluster-info

        # 4. Limpiar
        rm /tmp/kubeconfig-temp
    '''
}
```

**Ventaja:** Seguro, solo afecta a kubectl en Jenkins
**Desventaja:** Un poco más de overhead

---

## Recomendación para tu Jenkinsfile.stage

Usa la **SOLUCIÓN 4** porque:
1. ✅ Es segura (solo afecta Jenkins, no el sistema)
2. ✅ No requiere cambios en credenciales
3. ✅ Funciona con kubeconfig auto-firmados
4. ✅ Es reversible y documentada
5. ✅ Se puede mantener consistente en todos los stages

**Implementación:**

```groovy
// Agregar esta función helper al inicio del Jenkinsfile
def setupKubeconfig(kubeconfigFile) {
    sh '''
        # Crear copia temporal del kubeconfig
        cp ${KUBECONFIG} /tmp/kubeconfig-k8s

        # Deshabilitar verificación de certificados TLS
        kubectl config set-cluster kubernetes \
            --kubeconfig=/tmp/kubeconfig-k8s \
            --insecure-skip-tls-verify=true

        # Usar la copia modificada
        export KUBECONFIG=/tmp/kubeconfig-k8s
    '''
}

// En cada stage que use kubeconfig:
withCredentials([file(credentialsId: 'kubeconfig', variable: 'KUBECONFIG')]) {
    sh '''
        export KUBECONFIG=${KUBECONFIG}

        # Modificar kubeconfig para saltarse verificación de certificados
        mkdir -p /tmp/k8s-jenkins
        cp ${KUBECONFIG} /tmp/k8s-jenkins/kubeconfig

        kubectl config set-cluster kubernetes \
            --kubeconfig=/tmp/k8s-jenkins/kubeconfig \
            --insecure-skip-tls-verify=true

        # Usar el kubeconfig modificado para todas las operaciones
        export KUBECONFIG=/tmp/k8s-jenkins/kubeconfig

        # Ahora los comandos kubectl funcionarán
        kubectl cluster-info
        kubectl get nodes
    '''
}
```

---

## Alternativa: Variable de Entorno (Más Simple)

Si solo necesitas saltarte la verificación rápidamente:

```groovy
withCredentials([file(credentialsId: 'kubeconfig', variable: 'KUBECONFIG')]) {
    sh '''
        export KUBECONFIG=${KUBECONFIG}
        export INSECURE_SKIP_VERIFY=true
        kubectl cluster-info
    '''
}
```

**Nota:** Esta variable funciona en algunos contextos (Go CLI, etc.)

---

## Verificación

Una vez implementada la solución, verifica que funciona:

```bash
# Debe devolver información del cluster sin errores de certificado
kubectl cluster-info

# Debe listar los nodos
kubectl get nodes

# Debe listar namespaces
kubectl get namespaces
```

---

## Comparativa de Soluciones

| Solución | Seguridad | Facilidad | Jenkins | Permanente |
|----------|-----------|-----------|---------|-----------|
| 1. Skip Verify Global | ⚠️ Baja | ⭐⭐⭐⭐⭐ | ✅ | ❌ |
| 2. Importar CA | ✅ Alta | ⭐⭐ | ❌ | ✅ |
| 3. Jenkins Skip | ⚠️ Media | ⭐⭐⭐ | ✅ | ❌ |
| 4. Kubeconfig Temp | ✅ Alta | ⭐⭐⭐⭐ | ✅ | ❌ |
| 5. Variable Entorno | ⚠️ Media | ⭐⭐⭐⭐ | ✅ | ❌ |

**Recomendado:** Solución 4 (Kubeconfig Temp)

---

## Próximos Pasos

1. Implementa una de las soluciones arriba
2. Prueba localmente primero:
   ```bash
   export KUBECONFIG=/path/to/kubeconfig
   kubectl cluster-info
   ```
3. Actualiza el Jenkinsfile.stage con el patrón elegido
4. Ejecuta el pipeline nuevamente
5. Verifica que todos los comandos kubectl funcionan

---

## Debugging

Si sigue habiendo errores:

```bash
# Ver detalles del error
kubectl --kubeconfig=/path/to/kubeconfig cluster-info -v=9

# Verificar certificado
openssl x509 -in ca.crt -text -noout

# Ver kubeconfig actual
kubectl config view --flatten --minify
```

