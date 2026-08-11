# Laboratorio  Red Hat-based   

El tema central son los sistemas operativos basados en Red Hat Linux Enterprise.  Los cuales fueron evaluados por ser ampliamente utilizados en el sector gobierno, empresarial y de interés especial para la formación complementaria en infraestructura de IT.

Eso me conduce a tomar en consideración  para  el estudio de `RHCSA/RHCE/RHCSS`  y obtención de alguna de las certificaciones. 

En este sentido, la documentaciones descritas en este repositorio ampliaran la base de conocimientos que  conducen a una ruta de despliegue de la **infraestructura para el laboratorio de estudios** de las áreas de conocimientos esenciales  para cada una de las certificaciones.

Sí se quiere y sí el lector se inclina por la lectura, la *clase rápida* y el resto de este documento explicará las razones para el escenario elegido en la implementación. 

Siendo breve, los  enlaces a la acción inmediata.

- [Hoja de Ruta / Roadmap](docs/roadmap.md)
- [Despliegue elegido](docs/deployment.md)
- [Alternativa Proxmox](docs/proxmox-deploy.md)
- [Ansible](./ansible-lab/ansible.md)
- [Post Install / Primera Misión ](docs/post-install.md)
- [Misión 2](docs/mision-2.md)


---


## 🎓 Clase Rápida: Ecosistema Linux Basado en Red Hat



## 1. Contexto Histórico: ¿Qué Pasó con CentOS?

Para entender el panorama actual, primero hay que saber qué ocurrió en **diciembre de 2020**:

> **CentOS Linux** era la distribución gratuita y 100% compatible con RHEL que usaban millones de servidores en empresas, universidades y gobiernos. Red Hat (propiedad de IBM) anunció que **CentOS Linux dejaría de existir** como clon estable de RHEL, y en su lugar surgiría **CentOS Stream**: una versión de desarrollo continuo (rolling release), no una copia estable de RHEL.

Esto dejó a miles de organizaciones sin una alternativa gratuita y estable. De esa necesidad nacieron las distribuciones que dominan hoy el mercado.



## 2. Los 5 Sistemas Principales del Ecosistema




| Sistema           | Tipo                         | Costo del SO     | Soporte Comercial             |
| :---------------- | :--------------------------- | :--------------- | :---------------------------- |
| **RHEL**          | Comercial (el original)      | Suscripción paga | Red Hat (IBM)                 |
| **AlmaLinux**     | Comunitario / Enterprise     | Gratuito         | TuxCare, CloudLinux, terceros |
| **Rocky Linux**   | Comunitario / Enterprise     | Gratuito         | CIQ, terceros                 |
| **Oracle Linux**  | Comercial (fork de RHEL)     | Gratuito         | Oracle (pago)                 |
| **CentOS Stream** | Rolling release (desarrollo) | Gratuito         | Red Hat (limitado)            |



## 3. Comparativa Detallada

### 🔹 Red Hat Enterprise Linux (RHEL) — El Estándar de Oro

- **Quién lo usa:** Grandes corporaciones del Fortune 500, bancos, agencias gubernamentales federales (EE.UU., Europa), defensa.
- **Ventaja clave:** Es el estándar de certificación. Si un software empresarial dice "certificado para Linux", casi siempre significa RHEL.
- **Soporte:** 10-14 años de ciclo de vida. Parches de seguridad con SLA garantizado.
- **Desventaja:** Costo de suscripción elevado. Requiere contrato comercial.
- **Casos de uso:** Entornos regulados (HIPAA, PCI-DSS, FedRAMP), SAP, Oracle DB, mainframes.

### 🔹 AlmaLinux — El Favorito de la Nube y la Ciencia

- **Origen:** Creado por CloudLinux en 2021. Gobernado por la **AlmaLinux OS Foundation**, una organización sin fines de lucro 501(c)(6).
- **Compatibilidad:****ABI-compatible** con RHEL (garantiza que todo lo compilado para RHEL funcione), pero no es clon byte-por-byte. 
- **Ventajas:**
  - **Parches proactivos:** Aplica CVEs críticos **antes** que RHEL en muchos casos. 
  - **Soporte extendido:** TuxCare ofrece hasta **16 años** de soporte de ciclo de vida.
  - **Certificaciones:** FIPS 140-3, DISA STIG, CIS Benchmarks.
  - Adoptado por **CERN y Fermilab** para computación científica. 
- **Casos de uso:** SaaS, e-commerce (PCI-DSS), healthcare, nube híbrida, Kubernetes.

### 🔹 Rocky Linux — El Heredero Espiritual de CentOS

- **Origen:** Fundado por **Gregory Kurtzer**, co-creador original de CentOS, en 2021.
- **Compatibilidad:****Bug-for-bug compatible** con RHEL. Es un rebuild 1:1 de los paquetes fuente de RHEL. 
- **Ventajas:**
  - Máxima predictabilidad para software certificado para RHEL.
  - Gobernanza comunitaria bajo la Rocky Enterprise Software Foundation (B-Corp).
  - CIQ (el patrocinador comercial) ha levantado **$26 millones** en financiación. 
- **Desventajas:** Menor velocidad de parches que AlmaLinux. Menos espejos (151 vs 395 de AlmaLinux). 
- **Casos de uso:** Entornos con software ISV certificado para RHEL, hosting, HPC (computación de alto rendimiento).

### 🔹 Oracle Linux — La Apuesta de la Base de Datos

- **Origen:** Fork de RHEL desde **2006** por Oracle.
- **Diferenciador clave:****Unbreakable Enterprise Kernel (UEK)** — un kernel alternativo optimizado para cargas de Oracle DB, cloud y rendimiento de red. También puedes usar el kernel estándar de RHEL (RHCK). 
- **Ventajas:**
  - **Ksplice:** Parcheo de kernel **sin reiniciar** (con suscripción Premier).
  - Gratuito para descargar y usar; solo pagas por soporte.
  - Binario compatible con RHEL.
- **Desventajas:** Ecosistema cerrado. Dependencia de Oracle.
- **Casos de uso:** Oracle Database, Oracle Cloud Infrastructure (OCI), Exadata, grandes empresas que ya usan Oracle.

### 🔹 CentOS Stream — El Laboratorio de Desarrollo

- **Qué es:** Ahora es la **rama de desarrollo upstream** de RHEL. Lo que entra a CentOS Stream eventualmente llega a RHEL.
- **No es estable:** Es rolling release. No recomendado para producción crítica.
- **Ciclo de vida:** ~5.5 años (vs 10 de los demás).
- **Uso:** Desarrollo, pruebas, labs, contribución upstream a RHEL.


## 4. Tabla Comparativa Rápida



| Característica          | RHEL          | AlmaLinux                    | Rocky Linux      | Oracle Linux            | CentOS Stream |
| :---------------------- | :------------ | :--------------------------- | :--------------- | :---------------------- | :------------ |
| **Costo**               | 💰 Suscripción | 🆓 Gratis                     | 🆓 Gratis         | 🆓 Gratis (soporte pago) | 🆓 Gratis      |
| **Compatibilidad RHEL** | Original      | ABI                          | Binaria 1:1      | Binaria + UEK           | Mayor versión |
| **Parches CVE**         | Estándar      | **Proactivos** (más rápido)  | Espejo de RHEL   | Estándar                | Variable      |
| **Ciclo de vida**       | 10-14 años    | 10 años                      | 10 años          | 10 años                 | ~5.5 años     |
| **Soporte extendido**   | Sí (pago)     | 16 años (TuxCare)            | Limitado         | Sí (pago)               | No            |
| **FIPS 140-3**          | ✅ Nativo      | ✅                            | ✅ (vía terceros) | ✅ Nativo                | ❌             |
| **Live Patching**       | kpatch        | KernelCare                   | KernelCare       | Ksplice                 | ❌             |
| **Gobernanza**          | IBM/Red Hat   | Fundación sin fines de lucro | B-Corp           | Oracle Corp             | Red Hat       |
| **Retraso vs RHEL**     | N/A           | ~5-7 días                    | ~8-23 días       | ~47 días                | N/A           |

Datos de comparación de versiones menores: 


## 5. ¿Qué Elegir? Guía por Escenario



| Escenario                          | Recomendación                                       | Razón                                             |
| :--------------------------------- | :-------------------------------------------------- | :------------------------------------------------ |
| **Banco / Finanzas regulado**      | **RHEL** o **AlmaLinux + TuxCare**                  | Certificaciones FIPS, soporte con SLA, auditorías |
| **Gobierno / Defensa**             | **RHEL** o **AlmaLinux** (DISA STIG)                | Cumplimiento normativo, hardening automatizado    |
| **Startup / SaaS / Cloud**         | **AlmaLinux**                                       | Parches rápidos, Kubernetes, costo cero           |
| **Software certificado para RHEL** | **Rocky Linux**                                     | Bug-for-bug compatible, sin sorpresas             |
| **Oracle Database / OCI**          | **Oracle Linux**                                    | UEK optimizado, Ksplice, integración nativa       |
| **Lab / Desarrollo / Testing**     | **CentOS Stream**                                   | Acceso temprano a lo que vendrá en RHEL           |
| **Migración desde CentOS 7**       | **AlmaLinux** (ELevate) o **Rocky** (migrate2rocky) | Scripts de migración automatizados                |


## 6. Tendencias 2026

- **RHEL 10** ya está en el mercado y **RHEL 7 llegó a fin de soporte extendido en abril de 2026**, generando una **ola masiva de migraciones**. 
- **AlmaLinux** ha ganado terreno en nube y ciencia gracias a su modelo de parches proactivos.
- **Rocky Linux** mantiene la confianza de quienes necesitan máxima compatibilidad con stacks certificados.
- **Oracle Linux 10** compite agresivamente con Ksplice y UEK para quienes buscan reducir costos de suscripción.
- Ambos (AlmaLinux y Rocky) soportan contenedores (Podman, CRI-O, containerd) y Kubernetes de forma nativa.


## 📝 Resumen para el Examen

> **RHEL** es el estándar de la industria, pero caro. **AlmaLinux** es la alternativa más ágil para entornos de nube y compliance. **Rocky Linux** es el CentOS "puro" para máxima compatibilidad. **Oracle Linux** brilla si ya vives en el ecosistema Oracle. **CentOS Stream** es solo para desarrollo.

¿Te gustaría que profundice en algún tema específico, como la migración desde CentOS 7, la configuración de SELinux, o el despliegue de Kubernetes en alguna de estas plataformas?





> ### Si se quiero profundizar en el tema más exigente de este sistema operativo. Qué se necesita para dominar la administración en termino de seguridad para llegar al nivel experto?





## 🛡️ Clase Maestra: Dominio de Seguridad en RHEL y Derivados


Estructurar un **plan de estudios de nivel experto**. No es memorizar comandos: es entender el **modelo de seguridad en capas** que Red Hat ha construido durante 20 años.


## 1. La Filosofía: Defense in Depth

Red Hat no se basa en una sola muralla. Se basa en **7 capas de defensa**:



```plain
┌─────────────────────────────────────┐
│  7. Aplicación (SELinux, seccomp)   │
│  6. Datos (LUKS, ACLs, fscrypt)     │
│  5. Sesión (PAM, sudo, polkit)      │
│  4. Red (firewalld, nftables, TLS)  │
│  3. Host (AIDE, IMA, TPM2)          │
│  2. Kernel (SELinux, namespaces)    │
│  1. Físico/Virtual (Secure Boot,    │
│     measured boot, vTPM)            │
└─────────────────────────────────────┘
```

Tu trabajo como experto no es configurar una capa. Es **orquestar las 7 capas simultáneamente sin romper la operación**.



## 2. SELinux: El Gran Diferenciador

Esto es lo que separa a un administrador Linux común de un experto en RHEL. **SELinux no es opcional en entornos seguros**.

### 2.1 Arquitectura Interna



```bash
# Los 3 modos fundamentales
Enforcing   → Política activa, denegaciones loggeadas y bloqueadas
Permissive  → Política evaluada pero NO bloquea (solo audita)
Disabled    → Sin SELinux (requiere reinicio)

# Los tipos de política
targeted    → 95% de servicios protegidos, el resto unconstrained (default)
minimum     → Solo servicios esenciales
mls         → Multi-Level Security (gobierno/defensa, Top Secret)
```

### 2.2 Los 4 Pilares de SELinux



| Pilar                                | Qué controla                                            | Comando clave                                        |
| :----------------------------------- | :------------------------------------------------------ | :--------------------------------------------------- |
| **Type Enforcement (TE)**            | Qué tipo de proceso puede acceder a qué tipo de recurso | `ls -Z`, `ps -eZ`                                    |
| **Role-Based Access Control (RBAC)** | Qué roles pueden asumir qué dominios                    | `semanage login -l`                                  |
| **Multi-Level Security (MLS)**       | Flujo de información entre niveles de clasificación     | `chcon -l s0:c0,c1`                                  |
| **Multi-Category Security (MCS)**    | Separación entre recursos del mismo tipo (contenedores) | `podman run --security-opt label=level:s0:c100,c200` |

### 2.3 Flujo de Troubleshooting Experto

Cuando una aplicación falla por SELinux, un novato lo desactiva. Un experto ejecuta este flujo:



```bash
# Paso 1: Identificar el AVC denial
ausearch -m avc -ts recent

# Paso 2: Ver la sugerencia de audit2why
cat /var/log/audit/audit.log | audit2why

# Paso 3: Generar un módulo temporal (solo si es legítimo)
ausearch -c 'nginx' --raw | audit2allow -M mynginx
semodule -i mynginx.pp

# Paso 4: Refinar la política (nunca dejar módulos temporales)
# Editar el .te, compilar e instalar la versión final
```

### 2.4 Políticas Custom (Nivel Avanzado)

Para ser experto, debes escribir tu propia política:



```bash
# Estructura de un módulo .te
policy_module(myservice, 1.0.0)

require {
    type httpd_t;
    class file { read write };
}

# Declarar un nuevo tipo
type myapp_t;
type myapp_exec_t;
domain_type(myapp_t)
domain_entry_file(myapp_t, myapp_exec_t)

# Permitir transición desde init
init_daemon_domain(myapp_t, myapp_exec_t)

# Reglas de acceso
allow myapp_t httpd_sys_content_t:file read;
```



## 3. Hardening: STIG, CIS y FIPS

### 3.1 DISA STIG (Defense Information Systems Agency)

Es el estándar del Departamento de Defensa de EE.UU. y muchos gobiernos latinoamericanos lo adoptan.



```bash
# Instalar la herramienta de hardening
dnf install scap-security-guide openscap-scanner

# Generar un reporte de compliance STIG
oscap xccdf eval --profile xccdf_org.ssgproject.content_profile_stig \
  --results-arf /tmp/arf.xml \
  --report /tmp/report.html \
  /usr/share/xml/scap/ssg/content/ssg-rhel10-ds.xml

# Aplicar remediations automáticamente (¡en lab primero!)
oscap xccdf eval --remediate --profile stig \
  /usr/share/xml/scap/ssg/content/ssg-rhel10-ds.xml
```

**Lo que STIG exige (y tú debes dominar):**

- Contraseñas con complejidad (libpwquality)
- Tiempo máximo de inactividad (TMOUT)
- Desactivación de servicios innecesarios
- Configuración de auditd con reglas específicas
- FIPS 140-3 habilitado
- SELinux en enforcing
- Particiones separadas (/tmp, /var, /var/log, /home)
- Kernel parameters seguros (sysctl)

### 3.2 FIPS 140-3: Criptografía Aprobada



```bash
# Habilitar modo FIPS (irreversible en muchos casos)
fips-mode-setup --enable

# Verificar estado
fips-mode-setup --check
cat /proc/sys/crypto/fips_enabled  # Debe devolver 1

# Impacto: solo algoritmos aprobados por NIST
# MD5 está prohibido, SHA-1 limitado, solo TLS 1.2+
```



## 4. Auditoría y Detección de Intrusos

### 4.1 auditd: El Sistema de Auditoría del Kernel



```bash
# Reglas permanentes (en /etc/audit/rules.d/)
-w /etc/passwd -p wa -k identity_changes
-w /etc/shadow -p wa -k identity_changes
-w /etc/sudoers -p wa -k sudoers_changes
-w /sbin/insmod -p x -k module_insertion
-a always,exit -F arch=b64 -S setuid -k privilege_escalation

# Búsqueda forense
ausearch -k identity_changes -ts today
aureport --login --summary -i
```

### 4.2 AIDE (Advanced Intrusion Detection Environment)



```bash
# Inicializar la base de datos de integridad
aide --init
mv /var/lib/aide/aide.db.new.gz /var/lib/aide/aide.db.gz

# Verificar integridad (poner en cron)
aide --check

# El experto automatiza esto y envía alertas a SIEM
```

### 4.3 IMA/EVM (Integrity Measurement Architecture)

Nivel avanzado: medición de integridad del kernel hacia arriba.



```bash
# Habilitar en el kernel
ima_policy=tcb evm=fix

# Verificar mediciones
cat /sys/kernel/security/ima/ascii_runtime_measurements
```


## 5. Gestión de Identidades y Accesos

### 5.1 PAM (Pluggable Authentication Modules)

Domina estos 4 archivos:



| Archivo                        | Controla                          |
| :----------------------------- | :-------------------------------- |
| `/etc/pam.d/system-auth`       | Autenticación general del sistema |
| `/etc/pam.d/password-auth`     | Autenticación de contraseñas      |
| `/etc/pam.d/sudo`              | Reglas específicas de sudo        |
| `/etc/security/pwquality.conf` | Complejidad de contraseñas        |



```bash
# Ejemplo: bloquear cuenta tras 3 intentos fallidos
auth required pam_faillock.so preauth silent audit deny=3 unlock_time=900
auth required pam_faillock.so authfail audit deny=3 unlock_time=900
```

### 5.2 SSSD + FreeIPA / Active Directory



```bash
# Unirse a un dominio FreeIPA (el estándar en gobiernos)
ipa-client-install --domain=gov.example --realm=GOV.EXAMPLE \
  --principal=admin --password=********

# Unirse a Active Directory
realm join -U admin ad.example.com

# Configurar SSSD para caching offline
# /etc/sssd/sssd.conf
[sssd]
domains = gov.example
services = nss, pam, sudo, ssh

[domain/gov.example]
id_provider = ipa
auth_provider = ipa
sudo_provider = ipa
cache_credentials = true
entry_cache_timeout = 5400
```

### 5.3 sudoers Avanzado



```bash
# /etc/sudoers.d/webadmins
%webadmins ALL=(root) NOPASSWD: /usr/bin/systemctl restart httpd
%webadmins ALL=(root) NOPASSWD: /usr/bin/systemctl reload httpd

# Con registro de comandos (audit trail)
Defaults log_input, log_output
Defaults logfile="/var/log/sudo.log"
```


## 6. Firewall y Seguridad de Red

### 6.1 firewalld (La Abstracción de nftables)



```bash
# Zonas: drop, block, public, external, dmz, work, home, internal, trusted
firewall-cmd --set-default-zone=drop

# Reglas enriquecidas (lo que domina un experto)
firewall-cmd --permanent --zone=public \
  --add-rich-rule='rule family="ipv4" source address="10.0.0.0/24" \
  service name="ssh" accept'

# Rate limiting contra fuerza bruta
firewall-cmd --permanent --add-rich-rule='rule family="ipv4" \
  service name="ssh" accept limit value="3/m"'

# IPSec con libreswan (VPN site-to-site)
firewall-cmd --permanent --add-service=ipsec
```

### 6.2 nftables (El Motor Real)



```bash
# Ver las reglas reales que firewalld genera
nft list ruleset

# Tabla custom para un IDS básico
nft add table inet filter
nft add chain inet filter input { type filter hook input priority 0 \; }
nft add rule inet filter input tcp dport 22 ct state new \
  limit rate 3/second burst 5 packets counter accept
```


## 7. Cifrado y Gestión de Secretos

### 7.1 LUKS2 + TPM2 (Encrypted Disk sin Intervención)



```bash
# Verificar TPM2 disponible
systemd-cryptenroll --tpm2-device=list

# Enrollar el disco con TPM2 (auto-desbloqueo seguro)
systemd-cryptenroll --tpm2-device=auto --tpm2-pcrs=0+2+7+12 /dev/sda3

# PCRs: 0 (BIOS), 2 (UEFI), 7 (Secure Boot), 12 (kernel cmdline)
# Si cambia cualquiera, el disco NO se desbloquea (anti-tampering)
```

### 7.2 Clevis + Tang (Network-Bound Disk Encryption)

Para servidores en datacenter: el disco solo se desbloquea si puede contactar al servidor Tang.



```bash
# Cliente
clevis luks bind -d /dev/sda3 tang '{"url":"http://tang-server"}'

# Servidor Tang
jose jwk gen -i '{"alg":"ES512"}' -o /var/db/tang/newsig.jwk
```

### 7.3 HashiCorp Vault / CyberArk

En producción empresarial, las credenciales NUNCA van en archivos. Usa:



```bash
# Vault Agent inyecta secretos como variables de entorno
vault kv get -format=json secret/db/password | jq -r .data.data.value

# O con templates:
vault agent -config=/etc/vault/agent.hcl
# Genera /etc/myapp/db.conf con credenciales dinámicas
```



## 8. Contenedores Seguros

### 8.1 Podman (Rootless por Diseño)



```bash
# Ejecutar contenedor sin root
podman run -d --name web --user 1000:1000 \
  --security-opt no-new-privileges:true \
  --cap-drop ALL --cap-add NET_BIND_SERVICE \
  --read-only --tmpfs /tmp:rw,noexec,nosuid,size=100m \
  nginx:alpine

# SELinux automático: cada contenedor tiene su propio label MCS
podman run -d --security-opt label=level:s0:c100,c200 nginx
```

### 8.2 User Namespaces



```bash
# Mapeo de UID/GID: el root del contenedor es el UID 100000 en el host
podman run --uidmap 0:100000:65536 -it alpine sh
# Dentro: whoami = root
# En host: ps muestra UID 100000
```



## 9. Parcheo y Gestión de Vulnerabilidades

### 9.1 Live Kernel Patching



```bash
# RHEL: kpatch
kpatch list
kpatch install kpatch-5.14.0-xxx

# AlmaLinux/Rocky: KernelCare (TuxCare)
kcarectl --patch-info
kcarectl --update

# Oracle Linux: Ksplice (el más maduro)
uptrack-upgrade -y
uptrack-show
```

### 9.2 OVAL y CVE Scanning



```bash
# Con oscap
oscap oval eval --results /tmp/oval-results.xml \
  com.redhat.rhsa-all.xml

# Generar reporte de vulnerabilidades
oscap oval generate report /tmp/oval-results.xml > /tmp/vuln-report.html
```


## 10. Ruta de Certificación para Ser Experto



| Nivel          | Certificación                  | Qué demuestras                     |
| :------------- | :----------------------------- | :--------------------------------- |
| **Junior**     | RHCSA (EX200)                  | Administra un sistema RHEL básico  |
| **Senior**     | RHCE (EX294)                   | Automatización con Ansible en RHEL |
| **Experto**    | **RHCSS** (EX415)              | **Security: Hardening**            |
| **Experto**    | **RHCSA** en OpenShift (EX280) | Seguridad de contenedores          |
| **Arquitecto** | **RHCA**                       | Combinación de 5 especialidades    |

**El EX415 (Red Hat Certified Specialist in Security)** es tu objetivo. Cubre:

- SELinux troubleshooting y custom policies
- AIDE y auditd
- firewalld avanzado
- LUKS y cifrado de disco
- PAM y autenticación
- OpenSSL y certificados



## 11. Laboratorio Práctico: Tu Primera Misión

Para consolidar esto, haz este ejercicio:

> **Escenario:** Tienes un servidor RHEL 10 que aloja una aplicación web Python (Gunicorn + Nginx). Debe cumplir STIG, usar SELinux custom, cifrado de disco con TPM2, autenticación contra FreeIPA, y solo el puerto 443 abierto.

**Checklist:**

1. Instala con FIPS habilitado y particiones separadas.
2. Aplica STIG con `oscap` y remedia.
3. Crea una política SELinux `myapp_t` para Gunicorn.
4. Configura auditd para registrar todos los accesos a `/opt/myapp/config/`.
5. Enrolla LUKS con TPM2 y PCRs 0+2+7.
6. Une el servidor a FreeIPA.
7. Configura sudoers para que `myapp-admins` solo puedan reiniciar el servicio.
8. Despliega Nginx en Podman rootless con SELinux MCS.
9. Configura firewalld: solo 443 desde la DMZ.
10. Instala AIDE y programa verificación diaria.

------

## 📚 Recursos de Estudio

- **Documentación oficial:** access.redhat.com/documentation
- **SELinux Coloring Book:** (sí, existe, y es excelente)
- **SCAP Security Guide:** github.com/ComplianceAsCode/content
- **Libro de referencia:** *"SELinux by Example"* (Mayer, MacMillan, Caplan)



#### ¿Por dónde quieres empezar? Puedo profundizar en:

- **Escritura de políticas SELinux custom** (módulos .te/.fc/.if)
- **Automatización de hardening STIG con Ansible**
- **Forense con auditd y ausearch**
- **Arquitectura de FreeIPA para gobierno**



-----

## Preguntas



1) Todas las capas que has mencionado puede ser implementadas  en AlmaLinux como si se tratara de Red Hat Linux Enterprise.  
2) Se puede desplegar una VM en Proxmox basado en AlmaLinux con una configuración parecida y recomendada en producción para usarla como mi laboratorio de practicas. ?



## Respuestas

## 1. ¿Todas las capas de seguridad se pueden implementar en AlmaLinux igual que en RHEL?



> **La respuesta corta es: Sí, en su inmensa mayoría.** AlmaLinux puede replicar el 95% del stack de seguridad de RHEL. Pero hay diferencias críticas que un experto debe conocer.



### Tabla Comparativa Capa por Capa



| Capa de Seguridad                  | RHEL                   | AlmaLinux                                                  | ¿Diferencias?                                                |
| :--------------------------------- | :--------------------- | :--------------------------------------------------------- | :----------------------------------------------------------- |
| **SELinux (TE, RBAC, MLS, MCS)**   | ✅ Nativo               | ✅ Idéntico                                                 | Ninguna. Mismas políticas, mismos comandos.                  |
| **auditd + ausearch**              | ✅ Nativo               | ✅ Idéntico                                                 | Ninguna.                                                     |
| **AIDE**                           | ✅ Repos oficiales      | ✅ Repos oficiales                                          | Ninguna.                                                     |
| **IMA/EVM**                        | ✅ Kernel               | ✅ Kernel                                                   | Ninguna.                                                     |
| **PAM + libpwquality**             | ✅ Nativo               | ✅ Idéntico                                                 | Ninguna.                                                     |
| **SSSD + FreeIPA/AD**              | ✅ Nativo               | ✅ Idéntico                                                 | Ninguna.                                                     |
| **firewalld / nftables**           | ✅ Nativo               | ✅ Idéntico                                                 | Ninguna.                                                     |
| **LUKS2 + TPM2**                   | ✅ systemd-cryptenroll  | ✅ Idéntico                                                 | Ninguna.                                                     |
| **Clevis + Tang (NBDE)**           | ✅ Repos oficiales      | ✅ Repos oficiales                                          | Ninguna.                                                     |
| **Podman rootless + SELinux MCS**  | ✅ Nativo               | ✅ Idéntico                                                 | Ninguna.                                                     |
| **OpenSCAP + STIG/CIS**            | ✅ scap-security-guide  | ✅ scap-security-guide + STIG propio                        | AlmaLinux tiene **STIG propio publicado por DISA** y CIS Benchmark v2.0.0. |
| **OVAL (vulnerability scanning)**  | ✅ Red Hat OVAL         | ✅ **AlmaLinux OVAL streams propios**                       | AlmaLinux publica sus propios feeds OVAL.                    |
| **FIPS 140-3**                     | ✅ Validado por Red Hat | ✅ **Validado por NIST** (kernel cert #4750, OpenSSL #4823) | **Diferencia crítica:** Gratis para uso no comercial. Para uso comercial y parches continuos, requiere TuxCare. |
| **Live Kernel Patching**           | ✅ kpatch (Red Hat)     | ✅ **KernelCare** (TuxCare)                                 | Tecnología diferente. KernelCare es de pago para producción. |
| **User Namespaces (contenedores)** | ✅ Nativo               | ✅ Nativo                                                   | Ninguna.                                                     |
| **fapolicyd**                      | ✅ Nativo               | ✅ Repos EPEL/AlmaLinux                                     | Disponible, aunque menos documentado.                        |

### ⚠️ Las 3 Diferencias Críticas que Debes Conocer

**1. FIPS 140-3: Validado, pero con "trampa de versión"**

AlmaLinux 9.2 fue el **primer EL9 del mundo** con kernel FIPS 140-3 validado por NIST. 

 Eso es una hazaña técnica enorme.

PERO: los módulos validados están atados a la versión minor (ej. 9.2). Cuando AlmaLinux 9.3 salió, la Foundation dejó de publicar updates para 9.2. Para seguir recibiendo parches de seguridad **sin romper la certificación FIPS**, necesitas **TuxCare Extended Security Updates (ESU)**. 

En RHEL, Red Hat mantiene los canales FIPS dentro de la misma suscripción.

**2. Live Patching: KernelCare vs kpatch**

RHEL usa `kpatch` (desarrollado por Red Hat). AlmaLinux no tiene kpatch nativo; usa **KernelCare** de TuxCare. Funciona igual (aplica parches en caliente al kernel), pero es un producto de terceros con suscripción.

**3. Soporte Comercial y SLA**

En RHEL, si un parche CVE crítico rompe tu aplicación certificada, tienes un número de teléfono con SLA. En AlmaLinux, el soporte comercial es a través de TuxCare u otros terceros. La comunidad es excelente, pero no hay SLA garantizado por la Foundation.



## 2. ¿Puedo desplegar una VM en Proxmox con AlmaLinux para mi laboratorio de seguridad?

**Sí, absolutamente.** Es una de las combinaciones más usadas en homelabs y pequeños datacenters. Te doy la configuración recomendada.

### Especificaciones de VM Recomendadas (Laboratorio de Seguridad)



| Recurso                      | Valor Recomendado                         | Justificación                                                |
| :--------------------------- | :---------------------------------------- | :----------------------------------------------------------- |
| **CPU**                      | 4 vCPUs                                   | Necesitas poder compilar políticas SELinux, correr OpenSCAP, y levantar contenedores. |
| **Tipo de CPU**              | `host` o `x86-64-v2-AES`                  | `host` pasa todas las flags (incluido AES-NI para cifrado). `x86-64-v2-AES` si harás live migration. |
| **RAM**                      | 8 GB mínimo, 16 GB ideal                  | SELinux + auditd + contenedores consumen memoria. STIG remediation también es pesado. |
| **Disco 1 (OS)**             | 60 GB, thin provisioned, **VirtIO SCSI**  | VirtIO es el driver más rápido en Proxmox.                   |
| **Disco 2 (Datos cifrados)** | 40 GB, **VirtIO SCSI**                    | Para practicar LUKS2 + TPM2 (aunque en VM el TPM es vTPM).   |
| **Red**                      | VirtIO (paravirtualized), bridge a tu LAN | Para practicar firewalld zones desde fuera.                  |
| **TPM**                      | **vTPM 2.0**                              | Esencial para practicar `systemd-cryptenroll` con TPM2. Proxmox 7.3+ lo soporta nativamente. |
| **BIOS**                     | UEFI (OVMF)                               | Necesario para Secure Boot y TPM2.                           |

### Pasos de Instalación en Proxmox

**Paso 1: Descargar la imagen correcta**



```plain
# Usa la imagen ISO estándar de AlmaLinux 9
# O mejor aún, la imagen GenericCloud (qcow2) para importar directamente:
wget https://repo.almalinux.org/almalinux/9/cloud/x86_64/images/AlmaLinux-9-GenericCloud-latest.x86_64.qcow2
```

**Paso 2: Crear la VM en Proxmox**



```bash
# En el nodo Proxmox, como root:
qm create 9000 --name alma-security-lab --memory 16384 --cores 4 --cpu host \
  --net0 virtio,bridge=vmbr0 --bios ovmf --efidisk0 local-lvm:1 \
  --tpmstate0 local-lvm:1,version=v2.0

# Importar el disco cloud
qm importdisk 9000 AlmaLinux-9-GenericCloud-latest.x86_64.qcow2 local-lvm
qm set 9000 --scsi0 local-lvm:vm-9000-disk-1,discard=on,iothread=1

# Agregar cloud-init drive (para configurar usuario/SSH keys)
qm set 9000 --ide2 local-lvm:cloudinit
qm set 9000 --serial0 socket --vga serial0
```

**Paso 3: Configurar cloud-init (desde la UI de Proxmox)**

- Usuario: `labadmin`
- SSH public key: tu clave pública
- IP estática recomendada para el lab

**Paso 4: Post-instalación (seguridad)**



```bash
# 1. Actualizar todo
dnf update -y

# 2. Instalar el stack de seguridad
dnf install -y openscap-scanner scap-security-guide aide audit \
  policycoreutils-python-utils setools-console \
  podman buildah skopeo clevis clevis-luks clevis-systemd \
  fapolicyd usbguard

# 3. Habilitar SELinux enforcing (debería venir así, pero verifica)
setenforce 1
sed -i 's/SELINUX=.*/SELINUX=enforcing/' /etc/selinux/config

# 4. Verificar que el vTPM está visible
dmesg | grep -i tpm
# Debería mostrar: tpm_tis STM TPM 2.0

# 5. Configurar AIDE
aide --init
mv /var/lib/aide/aide.db.new.gz /var/lib/aide/aide.db.gz
```

### Configuración de Red para el Lab

Para practicar firewalld como si fuera un servidor real con DMZ:



```bash
# En Proxmox, crea una segunda interfaz de red para la VM (vmbr1 = "DMZ")
# Dentro de AlmaLinux:
nmcli connection add type ethernet ifname eth1 con-name dmz
nmcli connection modify dmz ipv4.method manual ipv4.addresses 192.168.100.10/24

# Configurar firewalld con zona dmz
firewall-cmd --permanent --zone=dmz --add-interface=eth1
firewall-cmd --permanent --zone=dmz --add-service=https
firewall-cmd --permanent --zone=dmz --remove-service=ssh
firewall-cmd --reload
```

### Snapshot Estratégicos (Crucial para un Lab de Seguridad)

Antes de aplicar cualquier hardening agresivo (STIG remediation, FIPS mode, SELinux custom policies), **crea snapshots en Proxmox**:



| Snapshot             | Momento                                   | Para qué                                      |
| :------------------- | :---------------------------------------- | :-------------------------------------------- |
| `fresh-install`      | Después del primer boot + update          | Punto de retorno limpio.                      |
| `pre-stig`           | Antes de correr `oscap --remediate`       | STIG puede romper cosas.                      |
| `pre-fips`           | Antes de `fips-mode-setup --enable`       | FIPS es irreversible sin reinstalar.          |
| `pre-selinux-custom` | Antes de compilar tu primera política .te | Un módulo mal escrito puede bloquear el boot. |

------

## Mi Recomendación Final

**Para tu laboratorio de experto en seguridad, AlmaLinux en Proxmox es perfecto.** Te permite practicar el 95% de lo que harías en RHEL sin pagar suscripción.

**Arquitectura de Laboratorio que te sugiero:**



```plain
┌─────────────────────────────────────────────┐
│  Proxmox Host (no tocar, solo virtualizar)  │
│  ┌───────────────────────────────────────┐  │
│  │  VM: alma-security-lab (16GB, 4vCPU)  │  │
│  │  ├─ AlmaLinux 9 + SELinux Enforcing   │  │
│  │  ├─ vTPM 2.0 + LUKS2 en /home y /var  │  │
│  │  ├─ STIG aplicado vía oscap           │  │
│  │  ├─ FreeIPA client (contra otra VM)   │  │
│  │  ├─ Podman rootless + SELinux MCS     │  │
│  │  └─ auditd + AIDE + fapolicyd         │  │
│  └───────────────────────────────────────┘  │
│  ┌───────────────────────────────────────┐  │
│  │  VM: alma-target (8GB, 2vCPU)         │  │
│  │  ├─ AlmaLinux 9 "vulnerable"          │  │
│  │  └─ Para practicar hardening/remediate│  │
│  └───────────────────────────────────────┘  │
│  ┌───────────────────────────────────────┐  │
│  │  VM: freeipa-server (4GB, 2vCPU)      │  │
│  │  └─ FreeIPA para autenticación central│  │
│  └───────────────────────────────────────┘  │
└─────────────────────────────────────────────┘
```

Con esa arquitectura puedes practicar:

- Hardening STIG en la VM target y verificar desde la VM lab.
- Autenticación centralizada contra FreeIPA.
- Cifrado de disco con vTPM.
- Contenedores seguros con SELinux MCS.
- Forense con auditd entre VMs.

¿Quieres que te arme un script de Kickstart para la instalación automatizada de AlmaLinux con FIPS + STIG + LUKS desde el primer boot? Eso te ahorraría horas de configuración manual en cada snapshot.



> ##  Qué impide considerar a Rocky Linux como una alternativa?...
>
> ##  y  cuál es el  análisis y comparativa con RHLE?



## 🎓 Análisis Comparativo en Profundidad: RHEL vs AlmaLinux vs Rocky Linux

## 1. Resumen Ejecutivo: Las 3 Filosofías



|                              | **RHEL**                       | **AlmaLinux**                                                | **Rocky Linux**                                              |
| :--------------------------- | :----------------------------- | :----------------------------------------------------------- | :----------------------------------------------------------- |
| **Razón de ser**             | El producto comercial original | Reemplazar CentOS para la nube y la ciencia                  | Reemplazar CentOS "puro"                                     |
| **Modelo de compatibilidad** | El estándar de referencia      | **ABI-compatible** (garantiza que todo lo compilado para RHEL funciona) | **Bug-for-bug / binario 1:1** (rebuild exacto de los SRPMs de RHEL) |
| **Velocidad de parches**     | Controlada por Red Hat         | **Proactiva** (a veces antes que RHEL)                       | **Conservadora** (espera a RHEL, luego rebuild)              |
| **Gobernanza**               | IBM / Red Hat, Inc.            | **AlmaLinux OS Foundation** (501(c)(6) sin fines de lucro)   | **RESF** (B-Corp) con CIQ como patrocinador comercial        |
| **Financiación**             | Ingresos por suscripción       | CloudLinux (base) + donaciones + TuxCare                     | CIQ ($26M en funding) + donaciones                           |

> **La diferencia filosófica clave:** AlmaLinux prioriza **velocidad y características enterprise** (por eso tiene STIG propio y FIPS validado). Rocky prioriza **fidelidad absoluta** a RHEL (por eso es más lento pero más predecible para software ISV certificado).



## 2. Comparativa Capa por Capa de Seguridad

### 🔐 Capa 1: Criptografía y FIPS 140-3



| Característica               | **RHEL**                                       | **AlmaLinux**                                                | **Rocky Linux**                                              |
| :--------------------------- | :--------------------------------------------- | :----------------------------------------------------------- | :----------------------------------------------------------- |
| **FIPS 140-3 Validado**      | ✅ Sí, por Red Hat (kernel, OpenSSL, libgcrypt) | ✅ **Sí, por NIST** (kernel #4750, OpenSSL #4823) — *primero en EL9* | ❌ **No**                                                     |
| **Modo FIPS nativo**         | `fips-mode-setup --enable`                     | `fips-mode-setup --enable` (usa los mismos módulos validados) | `fips-mode-setup` disponible, pero **sin certificación NIST** |
| **Cumplimiento regulatorio** | FedRAMP, DoD, HIPAA nativo                     | Cumple si usas los módulos validados + TuxCare para continuidad | **No apto para entornos que exijan FIPS validado**           |

**Análisis experto:**

- **RHEL** es la opción si tu contrato gubernamental o bancario exige explícitamente "FIPS 140-3 validado por el vendor del OS". Algunos auditorios son estrictos con esto.
- **AlmaLinux** rompió el mercado al ser el primer EL9 con FIPS validado por NIST. Es técnicamente idéntico, pero el auditor conservador puede preguntar por el soporte comercial continuo (ahí entra TuxCare).
- **Rocky Linux** no tiene certificación FIPS propia. Si necesitas FIPS en Rocky, dependes de terceros como CIQ o de usar los módulos de RHEL (lo cual entra en un área gris legal/comercial). **Para gobierno y defensa, Rocky no es opción hoy.**



### 🛡️ Capa 2: Hardening y Compliance (STIG / CIS)



| Característica                     | **RHEL**                 | **AlmaLinux**                                 | **Rocky Linux**                         |
| :--------------------------------- | :----------------------- | :-------------------------------------------- | :-------------------------------------- |
| **STIG DISA propio**               | ✅ Sí, publicado por DISA | ✅ **Sí, STIG DISA propio** publicado en 2024  | ❌ No. Usa STIG genérico de RHEL o CIS   |
| **CIS Benchmark**                  | ✅ Sí                     | ✅ **CIS Benchmark v2.0.0** propio             | ✅ CIS Benchmark                         |
| **OpenSCAP / scap-security-guide** | ✅ Nativo, optimizado     | ✅ scap-security-guide + STIG AlmaLinux propio | ✅ scap-security-guide (perfil genérico) |
| **OVAL Streams**                   | Red Hat OVAL             | **AlmaLinux OVAL propios**                    | Rocky Linux OVAL propios                |

**Análisis experto:**

- **AlmaLinux** invirtió recursos para tener su propio STIG DISA. Esto significa que cuando ejecutas `oscap` en AlmaLinux, el perfil sabe exactamente qué paquetes, rutas y versiones esperar. En Rocky, el perfil genérico de RHEL puede generar falsos positivos o negativos porque las versiones minor pueden divergir levemente.
- **Rocky** es "bug-for-bug compatible", pero DISA no ha publicado un STIG específico para Rocky. Si tu auditoría exige "STIG DISA para el sistema operativo instalado", Rocky queda descalificado en entornos federales estrictos.



### 🧩 Capa 3: SELinux y Políticas de Seguridad



| Característica                | **RHEL**                     | **AlmaLinux**    | **Rocky Linux**  |
| :---------------------------- | :--------------------------- | :--------------- | :--------------- |
| **Políticas SELinux**         | `targeted`, `mls`, `minimum` | Idénticas a RHEL | Idénticas a RHEL |
| **setools / policycoreutils** | Repos oficiales              | Repos oficiales  | Repos oficiales  |
| **Módulos custom (.te)**      | ✅ Compila e instala nativo   | ✅ Idéntico       | ✅ Idéntico       |
| **MCS para contenedores**     | ✅ `podman` nativo            | ✅ Idéntico       | ✅ Idéntico       |

**Análisis experto:** En esta capa **los tres son idénticos**. Todos usan el mismo kernel, las mismas bibliotecas de políticas y las mismas herramientas. Si tu objetivo es aprender SELinux a nivel de desarrollo de políticas, cualquiera de los tres sirve perfectamente.



### 🔄 Capa 4: Parcheo y Live Kernel Patching



| Característica               | **RHEL**                              | **AlmaLinux**                          | **Rocky Linux**                                  |
| :--------------------------- | :------------------------------------ | :------------------------------------- | :----------------------------------------------- |
| **Live Patching nativo**     | ✅ `kpatch` (desarrollado por Red Hat) | ✅ **KernelCare** (TuxCare)             | ✅ **KernelCare** (TuxCare) o kpatch vía terceros |
| **Velocidad de parches CVE** | Estándar (SLA definido por severidad) | **Proactivo** (a veces antes que RHEL) | Espejo de RHEL (más lento)                       |
| **Ciclo de vida base**       | 10 años                               | 10 años                                | 10 años                                          |
| **Soporte extendido**        | ELS (pago, hasta 14 años)             | **TuxCare ESU hasta 16 años**          | Limitado (CIQ ofrece extensiones)                |
| **Retraso vs RHEL**          | 0 días                                | ~5-7 días                              | ~8-23 días                                       |

**Análisis experto:**

- **AlmaLinux** es más ágil. Su modelo ABI-compatible les permite aplicar parches de seguridad sin esperar el rebuild completo de RHEL. Esto es crítico en entornos expuestos a Internet (SaaS, e-commerce).
- **Rocky** es más conservador. Prefieren la fidelidad absoluta, lo cual tiene sentido si ejecutas software ISV que fue certificado en un RHEL específico y cualquier desviación podría invalidar el soporte del vendor de aplicaciones.
- **RHEL** tiene el mejor SLA contractual. Si un parche rompe SAP, Oracle o tu app crítica, Red Hat te debe una solución. En los otros dos, el soporte comercial es a través de terceros.



### 🌐 Capa 5: Red y Firewall



| Característica                                  | **RHEL**          | **AlmaLinux**     | **Rocky Linux**   |
| :---------------------------------------------- | :---------------- | :---------------- | :---------------- |
| **firewalld / nftables**                        | ✅ Nativo          | ✅ Idéntico        | ✅ Idéntico        |
| **IPSec (libreswan)**                           | ✅ Repos oficiales | ✅ Repos oficiales | ✅ Repos oficiales |
| **Network Bound Disk Encryption (Clevis+Tang)** | ✅ Nativo          | ✅ Nativo          | ✅ Nativo          |

**Análisis experto:** Sin diferencias significativas. Todos usan el mismo stack de red del kernel.



### 👤 Capa 6: Identidad y Acceso



| Característica                    | **RHEL** | **AlmaLinux** | **Rocky Linux** |
| :-------------------------------- | :------- | :------------ | :-------------- |
| **SSSD + FreeIPA client**         | ✅ Nativo | ✅ Idéntico    | ✅ Idéntico      |
| **Active Directory (realm join)** | ✅ Nativo | ✅ Idéntico    | ✅ Idéntico      |
| **PAM / sudo / polkit**           | ✅ Nativo | ✅ Idéntico    | ✅ Idéntico      |

**Análisis experto:** Sin diferencias. Todos comparten el mismo código de SSSD y PAM.



### 💾 Capa 7: Cifrado de Disco y TPM



| Característica                    | **RHEL** | **AlmaLinux** | **Rocky Linux** |
| :-------------------------------- | :------- | :------------ | :-------------- |
| **LUKS2 + `systemd-cryptenroll`** | ✅ Nativo | ✅ Idéntico    | ✅ Idéntico      |
| **TPM2 + PCR binding**            | ✅ Nativo | ✅ Idéntico    | ✅ Idéntico      |
| **Clevis + Tang (NBDE)**          | ✅ Nativo | ✅ Nativo      | ✅ Nativo        |

**Análisis experto:** Sin diferencias. El stack de cifrado está en systemd y el kernel, no en la distribución.



## 3. Tabla Comparativa Consolidada para el Experto



| Criterio                            | **RHEL** ⭐                   | **AlmaLinux** 🚀                            | **Rocky Linux** 🏔️                  |
| :---------------------------------- | :--------------------------- | :----------------------------------------- | :--------------------------------- |
| **Costo de licencia**               | $$$ Suscripción anual        | $ Gratis                                   | $ Gratis                           |
| **Costo total de propiedad (TCO)**  | Alto (licencia + soporte)    | Medio (gratis, pero TuxCare para FIPS/ESU) | Medio-Bajo                         |
| **Certificaciones regulatorias**    | ⭐⭐⭐ Máximo                   | ⭐⭐☆ FIPS + STIG DISA propios               | ⭐☆☆ Sin FIPS ni STIG DISA propio   |
| **Velocidad de seguridad**          | ⭐⭐⭐ Rápida (con SLA)         | ⭐⭐⭐ Muy rápida (proactiva)                 | ⭐⭐☆ Estándar (conservadora)        |
| **Compatibilidad con software ISV** | ⭐⭐⭐ Nativa                   | ⭐⭐☆ ABI-compatible (99.9%)                 | ⭐⭐⭐ Bug-for-bug (99.99%)           |
| **Soporte comercial con SLA**       | ⭐⭐⭐ Red Hat directo          | ⭐⭐☆ TuxCare / CloudLinux                   | ⭐⭐☆ CIQ / terceros                 |
| **Gobernanza / vendor lock-in**     | ⭐☆☆ IBM propietario          | ⭐⭐⭐ Fundación sin fines de lucro           | ⭐⭐☆ B-Corp con inversores          |
| **Ecosistema de mirrors / CDN**     | ⭐⭐⭐ Global                   | ⭐⭐⭐ 395 mirrors                            | ⭐⭐☆ 151 mirrors                    |
| **Ideal para**                      | Bancos, defensa, SAP, Oracle | SaaS, nube, healthcare, CERN/ciencia       | Hosting, HPC, software certificado |
| **Tu laboratorio de seguridad**     | ⭐⭐⭐ Referencia perfecta      | ⭐⭐⭐ Excelente (FIPS + STIG)                | ⭐⭐☆ Bueno (SELinux, auditd, etc.)  |



## 4. Análisis de Escenarios: ¿Cuál Elegir y Por Qué?

### Escenario A: Gobierno / Defensa / Contrato Federal

**Ganador: RHEL o AlmaLinux**

> *"Si el RFP exige FIPS 140-3 validado y STIG DISA publicado, Rocky Linux no califica."*

- **RHEL** si el contrato especifica "sistema operativo con soporte del vendor".
- **AlmaLinux** si buscas reducir costos de licencia pero mantener compliance. TuxCare cubre el soporte extendido y FIPS.

### Escenario B: Banco / Fintech / PCI-DSS

**Ganador: RHEL o AlmaLinux**

- PCI-DSS no exige FIPS, pero sí hardening documentado. AlmaLinux con CIS Benchmark o STIG cumple perfectamente.
- **RHEL** si ya tienes contrato con Red Hat para JBoss, OpenShift, etc.
- **AlmaLinux** si tu infraestructura es cloud-native y necesitas parches rápidos.

### Escenario C: SaaS / E-commerce / Startup

**Ganador: AlmaLinux**

- Parches proactivos de CVEs críticos antes que RHEL.
- Soporte extendido de 16 años con TuxCare (ideal para startups que no quieren migraciones forzadas).
- Kubernetes, Podman, contenedores rootless: todo funciona idéntico.

### Escenario D: Hosting / HPC / Software ISV Certificado

**Ganador: Rocky Linux**

- Si tu software fue compilado y certificado en RHEL 9.2 exacto, Rocky Linux garantiza que los binarios se comportan idénticamente.
- Bug-for-bug compatibility elimina el riesgo de "funciona en RHEL pero no en el clon".
- CIQ ofrece soporte comercial para HPC y hosting.

### Escenario E: Tu Laboratorio de Aprendizaje

### **Ganador: AlmaLinux (con Rocky como secundario)**



| Para aprender...                          | Usa...                                | Razón                                                        |
| :---------------------------------------- | :------------------------------------ | :----------------------------------------------------------- |
| SELinux, auditd, PAM, LUKS                | Cualquiera de los 3                   | Son idénticos                                                |
| STIG remediation y compliance             | **AlmaLinux**                         | Tiene STIG DISA propio; Rocky no                             |
| FIPS 140-3                                | **AlmaLinux**                         | Rocky no tiene certificación                                 |
| Ansible + hardening automatizado          | **AlmaLinux**                         | Perfiles de OpenSCAP más maduros                             |
| Compilación de políticas SELinux custom   | Cualquiera                            | Mismo toolchain                                              |
| Preparación para certificación RHCE/RHCSA | **RHEL** (si puedes) o **Rocky/Alma** | Los exámenes de Red Hat usan RHEL, pero los comandos son idénticos |



## 5. Veredicto para Tu Proyecto de Laboratorio

Dado que tu objetivo es **dominar la administración de seguridad en sistemas Red Hat-based**, mi recomendación es:

### Arquitectura de Laboratorio Óptima



```plain
┌─────────────────────────────────────────────────────────────┐
│                    PROXMOX HOST                             │
│  ┌─────────────────────────────────────────────────────┐    │
│  │  VM-01: rhel-reference (evaluación de 60 días)      │    │
│  │  • RHEL 9.5 con suscripción de desarrollador        │    │
│  │  • Uso: Comparar resultados, "source of truth"      │    │
│  │  • 4 vCPU / 8 GB RAM / 40 GB                        │    │
│  └─────────────────────────────────────────────────────┘    │
│  ┌─────────────────────────────────────────────────────┐    │
│  │  VM-02: alma-security-master ⭐ PRINCIPAL           │    │
│  │  • AlmaLinux 9 + STIG DISA + FIPS 140-3             │    │
│  │  • vTPM 2.0 + LUKS2 + auditd + AIDE + fapolicyd     │    │
│  │  • FreeIPA client + SSSD                            │    │
│  │  • Podman rootless + SELinux custom policies        │    │
│  │  • 4 vCPU / 16 GB RAM / 60 GB + 40 GB (datos)       │    │
│  └─────────────────────────────────────────────────────┘    │
│  ┌─────────────────────────────────────────────────────┐    │
│  │  VM-03: rocky-hardening-lab                         │    │
│  │  • Rocky Linux 9 + CIS Benchmark                    │    │
│  │  • Uso: Comparar comportamiento SELinux vs Alma     │    │
│  │  • Identificar divergencias en parches y versiones  │    │
│  │  • 2 vCPU / 4 GB RAM / 40 GB                        │    │
│  └─────────────────────────────────────────────────────┘    │
│  ┌─────────────────────────────────────────────────────┐    │
│  │  VM-04: freeipa-server                              │    │
│  │  • AlmaLinux 9 (o RHEL si prefieres)                │    │
│  │  • IdM central para autenticación de todas las VMs  │    │
│  │  • 2 vCPU / 4 GB RAM / 30 GB                        │    │
│  └─────────────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────────────┘
```

### ¿Por qué AlmaLinux como principal y no Rocky?

1. **FIPS 140-3 validado:** Puedes practicar `fips-mode-setup` en un sistema con certificación real. En Rocky es un ejercicio teórico.
2. **STIG DISA propio:** Puedes ejecutar `oscap` con un perfil que reconoce tu sistema operativo. En Rocky usarías un perfil genérico.
3. **Parches proactivos:** Verás en la práctica cómo AlmaLinux puede estar adelantada a RHEL en CVEs críticos. Es una ventaja competitiva real que muchos administradores ignoran.
4. **Rocky como secundario:** Te permite validar que lo que aprendes en AlmaLinux aplica igual en Rocky (y detectar las pocas excepciones).

### ¿Y RHEL de referencia?

Red Hat ofrece una **suscripción de desarrollador gratuita** (hasta 16 sistemas) para uso no productivo. Regístrate en developers.redhat.com y úsala para:

- Validar que un comando de AlmaLinux produce exactamente el mismo resultado en RHEL.
- Prepararte para los exámenes de certificación RHCSA/RHCE.
- Acceder a la documentación premium de Red Hat.

------

## 6. Conclusión del Tutor



|                                                              |                                                              |
| :----------------------------------------------------------- | :----------------------------------------------------------- |
| **Si tu carrera va hacia gobierno, defensa o banca regulada** | AlmaLinux te da el 95% del camino gratis; RHEL te da el 5% restante de "vendor backing" para auditorías extremas. |
| **Si tu carrera va hacia DevOps, cloud o SaaS**              | AlmaLinux es la elección óptima. Más rápida, más mirrors, y el soporte extendido de TuxCare es un superpoder para infraestructura de larga vida. |
| **Rocky Linux**                                              | Es excelente, pero su nicho es la compatibilidad binaria extrema para software ISV. En seguridad enterprise (FIPS, STIG DISA), hoy está por detrás. |
| **Para tu lab**                                              | AlmaLinux principal + RHEL de referencia. Rocky como "control de compatibilidad". |

---
Por *Willians Patiño* bajo la firma **datenmaniak**
