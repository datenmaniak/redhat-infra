# Roadmap 

El roadmap sugerido  para desplegar un laboratorio y aprender  a implementar las nuevas tecnologías de los sistemas `Red Hat-based`  con la finalidad de alcanzar el nivel de  conocimientos  para cualquiera de los  exámenes con miras a obtener una certificación.

Considerando los siguientes puntos:

1. Áreas de conocimientos esenciales a  dominar para cada una de estas certificaciones:
	- RHCSA (EX200)
	- RHCE (EX294) 
	- RHCSS (EX415) 
3. Recomendaciones
4. Alternativas para el despliegue si no quiero utilizar Proxmox.



## 🎯 Roadmap y Plan de Estudio: De Cero a Empleable en Linux Enterprise

------

## 1. Roadmap del Laboratorio: Enfocado al Empleo

Este roadmap asume que puedes dedicarle **15-20 horas semanales**. Está diseñado para que en **16 semanas** tengas un perfil que un reclutador de infraestructura Linux no pueda ignorar.

### Fase 0: Infraestructura (Semana 1)

**Objetivo:** Tener el lab operativo y repetible.



| Tarea                                   | Entregable                                                   |
| :-------------------------------------- | :----------------------------------------------------------- |
| Instalar Proxmox (o alternativa)        | Host hardeneado con acceso SSH key-only                      |
| Crear template AlmaLinux 9 + cloud-init | VM template lista para clonar en < 2 min                     |
| Crear 3 VMs base                        | `alma-rhcsa`, `alma-rhce-target-01`, `alma-rhce-target-02`   |
| Configurar snapshots estratégicos       | `fresh`, `pre-exam`, `broken` (para practicar troubleshooting) |
| Documentar todo en Git                  | Repo con notas, comandos y scripts propios                   |

> **Consejo de empleabilidad:** Documenta todo en Markdown en un repositorio de GitHub. Los reclutadores valoran más un repo con 50 commits de aprendizaje que un certificado sin evidencia práctica.

------

### Fase 1: RHCSA — Operar un Sistema Linux (Semanas 2-6)

**Objetivo:** Ser capaz de instalar, configurar y resolver problemas en un servidor RHEL/AlmaLinux sin ayuda.



| Semana | Tema                                                  | Práctica en Lab                                              |
| :----- | :---------------------------------------------------- | :----------------------------------------------------------- |
| 2      | Gestión de archivos, permisos, ACLs, SELinux básico   | Romper permisos de `/var/www` y recuperar con `restorecon`   |
| 3      | Usuarios, grupos, PAM, sudo, políticas de contraseñas | Crear 5 usuarios con restricciones distintas vía PAM         |
| 4      | Almacenamiento: LVM, RAID, Stratis, VDO, NFS, autofs  | Crear VG, LV, snapshot, extender, reducir, montar NFS        |
| 5      | Redes: nmcli, teaming, firewall, DNS cliente, chrony  | Configurar bond/teaming + VLAN + firewalld zones             |
| 6      | Procesos, systemd, logs, cron, contenedores Podman    | Crear un timer de systemd que limpie logs; desplegar app en Podman rootless |

**Simulacro de examen RHCSA:** Semana 6. Tómate un día completo. Tienes **2.5 horas** para resolver 15-20 tareas en una VM que no conoces. Ponte el cronómetro.

------

### Fase 2: RHCE — Automatización con Ansible (Semanas 7-11)

**Objetivo:** Gestionar 10, 50 o 500 servidores con código, no con SSH manual.



| Semana | Tema                                                         | Práctica en Lab                                              |
| :----- | :----------------------------------------------------------- | :----------------------------------------------------------- |
| 7      | Inventarios, ad-hoc commands, primer playbook                | Inventario dinámico de tus 3 VMs; ping, facts, setup         |
| 8      | Variables, facts, condicionales, loops, handlers             | Playbook que instala nginx o apache según la variable `web_server` |
| 9      | Roles, Ansible Galaxy, estructura de proyecto                | Crear un role `common` que hardene el sistema (STIG básico)  |
| 10     | Ansible Vault, templates Jinja2, files                       | Encriptar contraseñas de DB; template de `nginx.conf`        |
| 11     | Módulos específicos RHEL: `firewalld`, `sefcontext`, `lvol`, `parted` | Playbook completo: provisiona servidor web + DB + firewall + SELinux |

**Proyecto integrador:** Escribe un playbook que, dada una IP, deje un servidor AlmaLinux listo para producción con:

- SELinux enforcing
- firewalld solo con puertos necesarios
- Usuarios administrativos con sudo
- Disco adicional cifrado con LUKS
- Aplicación web en Podman rootless

**Simulacro de examen RHCE:** Semana 11. Examen de **4 horas**. Necesitarás 4-5 VMs como targets.

------

### Fase 3: RHCSS — Seguridad Enterprise (Semanas 12-15)

**Objetivo:** Hacer que un servidor pase una auditoría de seguridad sin tocar un mouse.



| Semana | Tema                                                    | Práctica en Lab                                              |
| :----- | :------------------------------------------------------ | :----------------------------------------------------------- |
| 12     | OpenSCAP, STIG, CIS, oscap, remediate                   | Aplicar STIG DISA a una VM; generar reporte HTML; remediar   |
| 13     | SELinux avanzado: booleans, contextos, políticas custom | Crear un módulo `.te` para una app Python; troubleshooting con `audit2allow` |
| 14     | Criptografía: LUKS2, TPM2, FIPS, certificados           | Encriptar `/home` con LUKS + vTPM; habilitar FIPS; crear PKI con OpenSSL |
| 15     | Auditoría: auditd, AIDE, fapolicyd, sudoers avanzados   | Reglas auditd para privilegios; AIDE scheduleado; fapolicyd para whitelist de binarios |

**Proyecto integrador:** Toma una VM "vulnerable" (STIG no aplicado, SELinux disabled, root con password débil, servicios innecesarios activos). Documenta y aplícale hardening completo en 3 horas.

------

### Fase 4: Empleabilidad (Semana 16+)

**Ya no estudias para un examen. Estudias para una entrevista.**



| Actividad                            | Propósito                                                    |
| :----------------------------------- | :----------------------------------------------------------- |
| **Simulacros de entrevista técnica** | Busca en Glassdoor preguntas de "Linux System Administrator" y practica responder en voz alta |
| **Contribución open source**         | Reporta un bug en AlmaLinux, o mejora la documentación de SCAP Security Guide |
| **Blog técnico**                     | Escribe 3 artículos: "Cómo aplicar STIG a AlmaLinux", "Ansible para hardening", "SELinux para mortales" |
| **LinkedIn**                         | Actualiza tu perfil con: RHCSA, RHCE, RHCSS (o "en preparación"), y el enlace a tu repo de GitHub |
| **HomeLab público**                  | Si puedes, expón un servicio seguro (con WireGuard o Cloudflare Tunnel) y documenta cómo lo hardenaste |

------

## 2. Áreas de Conocimiento por Certificación

### 🔷 RHCSA (EX200) — *Red Hat Certified System Administrator*

> **Duración del examen:** 2.5 horas | **Formato:** 100% práctico, sin múltiple choice | **Puntuación:** 210/300 para aprobar



| Área                                       | Peso aprox. | Qué debes dominar                                            |
| :----------------------------------------- | :---------- | :----------------------------------------------------------- |
| **Gestión de archivos y permisos**         | 15%         | `chmod`, `chown`, ACLs (`setfacl`), `umask`, atributos extendidos (`chattr`) |
| **SELinux básico**                         | 15%         | Modos (enforcing/permissive), `restorecon`, `chcon`, booleans (`getsebool`, `setsebool`), contextos (`ls -Z`, `ps -Z`) |
| **Almacenamiento**                         | 15%         | Particionado (`parted`, `fdisk`), LVM (PV, VG, LV, snapshot, extend), Stratis, VDO, NFS cliente, autofs |
| **Redes**                                  | 15%         | `nmcli`, `nmtui`, teaming/bonding, IPv4/IPv6 básico, `firewalld` (zones, services, ports), DNS cliente, NTP (`chronyc`) |
| **Gestión de usuarios y seguridad básica** | 10%         | `useradd`, `usermod`, `groupadd`, PAM (`pwquality`), `sudoers`, `sshd_config` |
| **Procesos y servicios**                   | 10%         | `systemctl`, targets (runlevels), timers, `journalctl`, `logrotate`, `rsyslog` |
| **Contenedores**                           | 10%         | Podman: imágenes, contenedores, rootless, `podman-compose`, mapeo de puertos, volúmenes |
| **Arranque y kernel**                      | 10%         | GRUB2, `dracut`, `modprobe`, parámetros de kernel (`sysctl`, `/etc/sysctl.conf`), `tuned` |

**La regla del EX200:** No hay teoría. Si no sabes cómo hacer algo, la documentación está instalada en el sistema (`man`, `info`, `/usr/share/doc`). Aprende a buscar rápido.

------

### 🔶 RHCE (EX294) — *Red Hat Certified Engineer*

> **Duración del examen:** 4 horas | **Prerrequisito:** RHCSA vigente | **Enfoque:** Automatización con Ansible



| Área                               | Peso aprox. | Qué debes dominar                                            |
| :--------------------------------- | :---------- | :----------------------------------------------------------- |
| **Inventarios**                    | 10%         | Estático (`ini`, `yaml`), dinámico, grupos, variables de host/group, `ansible.cfg` |
| **Playbooks**                      | 25%         | Sintaxis YAML, idempotencia, `ansible-playbook`, check mode (`--check`), diff (`--diff`) |
| **Variables y facts**              | 15%         | `vars`, `vars_files`, `host_vars`, `group_vars`, `ansible_facts`, `setup` module |
| **Control de flujo**               | 15%         | `when`, `loop`, `handlers`, `tags`, `block/rescue/always`, `ignore_errors` |
| **Roles y reutilización**          | 15%         | Estructura de roles (`tasks/`, `vars/`, `templates/`, `files/`), `ansible-galaxy`, dependencias |
| **Ansible Vault**                  | 10%         | Encriptar variables y archivos (`ansible-vault encrypt/decrypt/edit/rekey`) |
| **Módulos específicos de sistema** | 10%         | `user`, `group`, `firewalld`, `sefcontext`, `lvol`, `parted`, `dnf`, `service`, `template`, `copy`, `lineinfile`, `mount` |

**La regla del EX294:** El examen te da 5-6 nodos managed. Tu nodo de control tiene Ansible instalado. Debes escribir playbooks que configuren esos nodos según requerimientos específicos. No escribas 10 playbooks separados; usa **roles** y **variables**.

------

### 🔴 RHCSS — Security (EX415) — *Red Hat Certified Specialist in Security: Linux*

> **Duración del examen:** 4 horas | **Prerrequisito:** RHCSA vigente | **Enfoque:** Hardening, auditoría, cumplimiento



| Área                            | Peso aprox. | Qué debes dominar                                            |
| :------------------------------ | :---------- | :----------------------------------------------------------- |
| **SELinux avanzado**            | 25%         | Booleans, contextos persistentes (`semanage fcontext`), puertos (`semanage port`), troubleshooting (`audit2why`, `audit2allow`), módulos custom |
| **OpenSCAP y compliance**       | 20%         | `oscap xccdf eval`, perfiles STIG/CIS, generación de reportes, `oscap-ssh`, remediación |
| **Cifrado y PKI**               | 15%         | LUKS2 (`cryptsetup`), `systemd-cryptenroll`, FIPS mode, certificados SSL/TLS (`openssl`), `certmonger` |
| **Auditoría del sistema**       | 15%         | `auditd`, reglas permanentes (`/etc/audit/rules.d/`), `ausearch`, `aureport`, AIDE (`aide --init/check`) |
| **Control de acceso**           | 15%         | PAM (`pam_faillock`, `pam_time`, `pam_pwquality`), `sudoers` avanzado, `polkit`, `sssd` básico |
| **Firewall y hardening de red** | 10%         | `firewalld` avanzado (rich rules, masquerade, port forwarding), `nftables` básico, `fapolicyd` |

**La regla del EX415:** Este examen asume que ya eres un administrador senior. No te pregunta "cómo se habilita SELinux", te pregunta "esta aplicación no arranca por SELinux, diagnostica y crea una política que lo permita sin desactivar SELinux".

------

## 3. Recomendaciones Adicionales

### Sobre el estudio

1. **No memorices comandos. Memoriza el \*problema\* y la \*herramienta\*.** En el examen no necesitas saber la sintaxis exacta de `semanage fcontext -a -t httpd_sys_content_t "/web(/.*)?"`; necesitas saber que `semanage` es la herramienta para hacer cambios SELinux persistentes.
2. **Practica en condiciones de estrés.** Pon un cronómetro. Apaga la VM a mitad de una tarea. Simula un kernel panic. El EX200 y EX294 premian la calma bajo presión.
3. **Lee la documentación de Red Hat.** Es gratuita y es la fuente oficial: access.redhat.com/documentation. Lee los Release Notes de RHEL 9.5; ahí descubrirás cambios que los libros de hace 2 años no cubren.
4. **Usa `tmux` o `screen` en el examen.** Si tu sesión SSH se cae, no pierdes el trabajo. Es válido y los examinadores lo esperan.
5. **Para RHCE, aprende `ansible-doc` antes que Google.** En el examen no tienes internet, pero sí `ansible-doc -s firewalld`. Esa herramienta es tu biblioteca.

### Sobre el empleo

1. **El certificado abre la puerta; el proyecto personal te hace pasar.** Cuando apliques a un puesto de "Linux System Administrator", el RHCSA te da la entrevista. Tu repo de GitHub con playbooks de Ansible y un blog sobre STIG te da la oferta.
2. **Aprende una nube pública básica.** AWS EC2 + S3 + IAM. No necesitas ser arquitecto cloud, pero el 80% de los trabajos Linux hoy son "on-prem + cloud híbrida". Saber lanzar una instancia RHEL en AWS y hardenearla con Ansible es un diferenciador enorme.
3. **El inglés técnico escrito es no negociable.** La documentación de Red Hat, los foros de Stack Overflow, los CVEs, todo está en inglés. Si tu inglés es débil, dedica 30 min diarios a leer documentación técnica en inglés.
4. **Networking no es opcional.** Un administrador Linux que no entiende subnetting, VLANs, TCP/IP, DNS y TLS es un técnico, no un administrador. Si tienes huecos ahí, complementa con CCNA o al menos con el libro "TCP/IP Illustrated".
5. **Documenta tus fracasos.** Cuando rompas el sistema (y lo harás), escribe qué hiciste, qué salió mal y cómo lo arreglaste. Esa bitácora de errores es oro puro en una entrevista técnica.

------

## 4. Alternativas a Proxmox

Si no quieres o no puedes usar Proxmox, aquí tienes opciones ordenadas por recomendación para tu caso específico (lab de certificación Red Hat):

### Opción A: KVM/QEMU + virt-manager (Linux nativo)

**Ideal si tu host principal corre Linux (Ubuntu, Fedora, Debian).**



| Pros                                                         | Contras                                              |
| :----------------------------------------------------------- | :--------------------------------------------------- |
| Es la misma tecnología de virtualización que usa RHEL (KVM es de Red Hat) | Solo disponible en Linux como host                   |
| Rendimiento nativo, sin capas intermedias                    | Requiere habilitar VT-x/AMD-V en BIOS                |
| Soporte completo de vTPM 2.0 y UEFI (OVMF)                   | La UI (virt-manager) es menos pulida que Proxmox     |
| Totalmente gratis y open source                              | No tiene clustering ni backup integrado como Proxmox |

**Cómo empezar:**

```bash
# En Fedora/AlmaLinux/RHEL:
sudo dnf install @virtualization
sudo systemctl enable --now libvirtd
# Luego abre virt-manager y crea VMs gráficamente
```

------

### Opción B: VMware Workstation Pro / Fusion Pro

**Ideal si tu host es Windows o macOS y tienes presupuesto (o acceso gratuito vía VMUG).**



| Pros                                              | Contras                                            |
| :------------------------------------------------ | :------------------------------------------------- |
| Estabilidad legendaria, drivers optimizados       | **De pago** (~$200) o suscripción VMUG (~$200/año) |
| Snapshots rápidos y confiables                    | No es open source                                  |
| Excelente soporte de vTPM, UEFI, Secure Boot      | En Windows, consume más recursos que KVM           |
| Clones vinculados (linked clones) ahorran espacio |                                                    |

**Nota:** VMware ofrece licencias gratuitas para evaluación y a veces para uso personal. También existe **VMware Workstation Player** (gratis para uso no comercial) pero es muy limitado (no permite snapshots múltiples ni vTPM).

------

### Opción C: VirtualBox

**Ideal si necesitas algo gratis en Windows/macOS/Linux y no te importa un rendimiento ligeramente inferior.**



| Pros                                 | Contras                                          |
| :----------------------------------- | :----------------------------------------------- |
| 100% gratuito y multiplataforma      | Rendimiento inferior a KVM/VMware                |
| Fácil de instalar y usar             | vTPM 2.0 es experimental y problemático          |
| Buena comunidad y documentación      | Snapshots más lentos y propensos a corrupción    |
| Extension Pack añade funcionalidades | No recomendado para labs intensivos de snapshots |

**Veredicto:** Funciona para RHCSA básico, pero para EX415 (vTPM, UEFI, Secure Boot) te dará dolores de cabeza.

------

### Opción D: Microsoft Hyper-V (Windows Pro/Enterprise/Education)

**Ideal si ya tienes Windows Pro y no quieres instalar nada más.**



| Pros                                 | Contras                                                      |
| :----------------------------------- | :----------------------------------------------------------- |
| Nativo en Windows Pro/Enterprise     | No disponible en Windows Home                                |
| Buen rendimiento para ser tipo-2     | Interfaz de gestión poco intuitiva                           |
| Soporte de TPM virtual y Secure Boot | Mejor para Windows guests; Linux guests necesitan Integration Services |
| Gratis si ya tienes Windows Pro      |                                                              |

**Cómo habilitar:**



```powershell
# PowerShell como administrador
Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V -All
```

------

### Opción E: Nube Pública (AWS, Azure, GCP)

**Ideal si no tienes hardware potente o quieres practicar en "infraestructura real".**



| Pros                                  | Contras                                                      |
| :------------------------------------ | :----------------------------------------------------------- |
| No necesitas hardware                 | **De pago** (aunque hay free tiers limitados)                |
| Practican en entornos "de verdad"     | No puedes practicar vTPM/UEFI/Secure Boot de la misma manera |
| Puedes destruir y recrear en segundos | Latencia de red para labs interactivos                       |
| AWS ofrece RHEL como AMI oficial      | Sin snapshots instantáneos tipo VM local                     |

**Truco para ahorrar:** AWS Free Tier te da 750 horas/mes de t2.micro gratis. Pero para RHCE/RHCSS necesitas instancias más grandes. Usa **spot instances** (hasta 90% de descuento) y destrúyelas cuando no uses.

------

### Opción F: UTM (macOS, especialmente Apple Silicon M1/M2/M3)

**Ideal si tienes Mac moderno con chip ARM.**



| Pros                          | Contras                                                      |
| :---------------------------- | :----------------------------------------------------------- |
| Optimizado para Apple Silicon | Las VMs son ARM64, no x86_64                                 |
| Gratuito (open source)        | No puedes usar las ISOs x86_64 de AlmaLinux/RHEL             |
| Fácil de usar                 | Necesitas imágenes ARM específicas (AlmaLinux tiene ARM cloud images) |

------

### Tabla Resumen de Alternativas



| Alternativa            | Host OS         | Costo   | vTPM/UEFI         | Recomendado para tu lab          |
| :--------------------- | :-------------- | :------ | :---------------- | :------------------------------- |
| **Proxmox**            | Bare metal      | Gratis  | ✅ Excelente       | ⭐⭐⭐ Primera opción               |
| **KVM + virt-manager** | Linux           | Gratis  | ✅ Excelente       | ⭐⭐⭐ Si tu host es Linux          |
| **VMware Workstation** | Windows/macOS   | $$$     | ✅ Excelente       | ⭐⭐⭐ Si tienes presupuesto        |
| **Hyper-V**            | Windows Pro     | Gratis* | ✅ Bueno           | ⭐⭐☆ Si ya tienes Windows Pro     |
| **VirtualBox**         | Multiplataforma | Gratis  | ⚠️ Experimental    | ⭐⭐☆ Solo si no hay otra opción   |
| **Nube (AWS/Azure)**   | N/A             | $$      | ❌ No aplica igual | ⭐⭐☆ Complementario, no principal |
| **UTM**                | macOS ARM       | Gratis  | ✅ Bueno           | ⭐⭐☆ Solo para Mac ARM            |

------

## Mi Recomendación Final

Si tienes una máquina física dedicada (incluso un i5 con 16GB RAM): **Proxmox o KVM+virt-manager.**

Si no tienes máquina dedicada y tu laptop es tu único recurso:

- **Windows:** VMware Workstation Pro (si puedes pagar) o Hyper-V (si tienes Pro).
- **Linux:** KVM + virt-manager (nativo, rápido, sin fronteras).
- **macOS Intel:** VMware Fusion o VirtualBox.
- **macOS ARM (M1/M2/M3):** UTM.

**Lo importante no es el hypervisor. Lo importante es que tengas 3-5 VMs AlmaLinux 9 corriendo simultáneamente para poder practicar Ansible (RHCE) y hardening (RHCSS).**

¿Con qué hardware cuentas? Te puedo ajustar la arquitectura del lab a tus recursos exactos (RAM, CPU, disco).



---

## Evaluación del Hardware



## Escenario 1: 
### Especificaciones: Thinkcentre m700,  i5-6500T 16 GB. 

Actualmente corriendo un bastion de Rockylinux, un firewall pfsense, un master k3s y dos workers.



Con ese hardware y carga actual, debo ser directo: **no instales Proxmox**. Migrar un bastion productivo, pfSense y un cluster K3s a un hypervisor nuevo en una máquina con 4 cores/4 hilos y 16 GB es un proyecto de fin de semana con alto riesgo de dejar todo roto. Tu hardware ya está comprometido.

Aquí tienes la estrategia realista para tu ThinkCentre M700.

------

## 1. Diagnóstico de Recursos Actuales



| Servicio                   | RAM estimada  | vCPU          |
| :------------------------- | :------------ | :------------ |
| Rocky Linux (host/bastion) | ~1 GB         | baseline      |
| pfSense (si es VM)         | ~1.5 GB       | ~1            |
| K3s Master                 | ~2-4 GB       | ~1-2          |
| K3s Worker 1               | ~2 GB         | ~1            |
| K3s Worker 2               | ~2 GB         | ~1            |
| **Total comprometido**     | **~10-12 GB** | **4/4**       |
| **Libre para lab**         | **~4-6 GB**   | **0 (colas)** |

**Veredicto:** Tienes RAM justa para **1-2 VMs de estudio** simultáneas, no para 5. Y los 4 cores físicos del i5-6500T (sin Hyper-Threading real) ya están repartidos.

------

## 2. Recomendación: KVM Nativo sobre tu Rocky Linux

Usa el stack de virtualización que ya viene en Rocky 9. Es el mismo KVM que usa RHEL/Proxmox, sin overhead de hypervisor adicional.

### Por qué esta opción en tu caso:

- **Sin migración de producción:** Tu pfSense y K3s siguen igual.
- **Zero costo:** Ya lo tienes instalado o es un `dnf install` away.
- **vTPM funciona:** Rocky 9 tiene `swtpm` en repos.
- **Snapshot/restore:** `virsh snapshot-create-as` funciona perfecto para tu lab.

### Instalación en tu Rocky Linux existente:



```bash
sudo dnf install -y @virtualization
sudo systemctl enable --now libvirtd
sudo usermod -aG libvirt $USER
# Relogear para que tome el grupo
```

------

## 3. Arquitectura de Lab para 16 GB (Optimizada)

No intentes correr 4 VMs. Diseña **3 VMs con roles rotativos**:



| VM               | RAM  | vCPU | Uso                              | Encendida                      |
| :--------------- | :--- | :--- | :------------------------------- | :----------------------------- |
| `alma-target-01` | 2 GB | 1    | RHCSA + target RHCE              | Siempre                        |
| `alma-target-02` | 2 GB | 1    | Target RHCE (2do nodo)           | Solo para RHCE                 |
| `alma-security`  | 3 GB | 2    | RHCSS: STIG, SELinux, FIPS, LUKS | Solo para módulos de seguridad |

**El nodo de control Ansible** no es una VM: **usa tu Rocky Linux host**. Ahorras 2 GB.

### Diagrama de recursos:



```plain
ThinkCentre M700 (16 GB)
├─ Rocky Linux Host (bastion + Ansible control)
│  ├─ libvirtd/KVM
│  │  ├─ alma-target-01 (2 GB) ───────► RHCSA diario
│  │  └─ alma-security (3 GB) ────────► RHCSS (bajo demanda)
│  ├─ pfSense (si es VM) ─────────────► Producción
│  └─ K3s master + workers ───────────► Producción
```

------

## 4. Script para Crear las VMs en Rocky Linux



```bash
#!/bin/bash
# create-lab-vms-rocky.sh
# Ejecutar en tu Rocky Linux host

VM_DIR="/var/lib/libvirt/images"
ALMA_URL="https://repo.almalinux.org/almalinux/9/cloud/x86_64/images/AlmaLinux-9-GenericCloud-latest.x86_64.qcow2"

mkdir -p $VM_DIR
cd $VM_DIR

# Descargar imagen cloud si no existe
[ ! -f alma9-base.qcow2 ] && wget -O alma9-base.qcow2 $ALMA_URL

# Crear imagen base con cloud-init
cp alma9-base.qcow2 alma9-ci.qcow2
virt-sysprep -a alma9-ci.qcow2
virt-customize -a alma9-ci.qcow2 \
  --install qemu-guest-agent \
  --ssh-inject root:file:/root/.ssh/id_rsa.pub \
  --firstboot-command 'dnf install -y cloud-init'

# Función crear VM
create_vm() {
  local name=$1
  local ram=$2
  local vcpu=$3
  local disk=$4
  
  qemu-img create -f qcow2 -b alma9-ci.qcow2 -F qcow2 $VM_DIR/${name}.qcow2 ${disk}G
  
  virt-install \
    --name $name \
    --ram $ram \
    --vcpus $vcpu \
    --disk path=$VM_DIR/${name}.qcow2,format=qcow2,bus=virtio,cache=none,discard=unmap \
    --network bridge=virbr0,model=virtio \
    --os-variant almalinux9 \
    --graphics none \
    --console pty,target_type=serial \
    --import \
    --noautoconsole \
    --tpm emulator,model=tpm-crb,version=2.0 \
    --boot uefi
}

# Crear VMs
create_vm alma-target-01 2048 1 20
create_vm alma-target-02 2048 1 20
create_vm alma-security 3072 2 30

echo "VMs creadas. Conectar: virsh console alma-target-01"
echo "Ver IPs: virsh domifaddr alma-target-01"
```

### Comandos esenciales de virsh para tu día a día:



```bash
# Ver VMs
virsh list --all

# Encender/apagar
virsh start alma-security
virsh shutdown alma-security

# Snapshot (antes de romper algo)
virsh snapshot-create-as alma-security pre-stig --description "Limpio antes de STIG"

# Rollback
virsh snapshot-revert alma-security pre-stig

# Liberar RAM apagando la VM de seguridad cuando no la uses
virsh destroy alma-security  # fuerza, como pull del cable
```

------

## 5. Cómo Liberar RAM de tu K3s Actual

Para estudiar RHCE necesitas 2 targets + control. Apaga tu K3s temporalmente:



```bash
# En los workers (si son VMs/containers en el mismo host)
sudo systemctl stop k3s-agent
# En el master
sudo systemctl stop k3s

# O si son contenedores systemd
sudo systemctl stop k3s-worker-1
sudo systemctl stop k3s-worker-2
```

**Si tu K3s es productivo y no puedes apagarlo**, considera reducir los workers a **1 solo worker** o mover todo a **1 master + 1 worker**. Un cluster K3s de 3 nodos en 16 GB es overkill para un homelab; 2 nodos (master+worker) son suficientes para casi todo.

------

## 6. Inversión Inteligente: Más RAM

El ThinkCentre M700 tiene **2 slots SO-DIMM DDR4**. Soporta hasta **32 GB** (2x16GB).

- **Costo:** ~$35-50 por un módulo de 16GB DDR4 SO-DIMM 2400MHz (usado/refurbished).
- **Impacto:** Pasar a 32 GB te permite tener tus 3 VMs de lab **más** tu K3s **más** pfSense sin tocar nada.

Si puedes gastar $40, es la mejora con mayor retorno para tu estudio.

------

## 7. Alternativa si No Quieres Tocar tu Rocky Linux

Si tu Rocky Linux es sagrado y no quieres instalar KVM ahí:



| Opción                        | Viabilidad en tu hardware                                    |
| :---------------------------- | :----------------------------------------------------------- |
| **Proxmox en dual-boot**      | ❌ Impráctico. Rebootear para estudiar mata el ritmo.         |
| **Proxmox reemplazando todo** | ⚠️ Posible, pero migrar K3s + pfSense es 2-3 días de trabajo. |
| **Laptop secundaria**         | ✅ Ideal si tienes una vieja con 8GB+. Instala AlmaLinux directo y practica ahí. |
| **Nube (AWS/Azure)**          | ✅ Para RHCE/RHCSS, 3 instancias t3.medium (~$0.04/hr cada una). $5-10/mes si usas spot instances y destruyes al terminar. |
| **Raspberry Pi 4/5**          | ❌ No sirve para certificación RHEL (arquitectura ARM64).     |

------

## 8. Mi Recomendación Final para Tu Setup

**Semana 1 (ya):**

1. No toques Proxmox ni tu producción.
2. Instala KVM en tu Rocky Linux: `dnf install @virtualization`.
3. Crea solo **2 VMs**: `alma-target-01` (2GB) y `alma-security` (3GB).
4. Apaga un worker de K3s si necesitas RAM.

**Semana 2-6 (RHCSA):**

- Estudia solo con `alma-target-01`. Rompe y restaure snapshots.

**Semana 7-11 (RHCE):**

- Enciende `alma-target-02` (2GB) cuando practiques Ansible.
- Usa tu Rocky host como control node.

**Semana 12-15 (RHCSS):**

- Apaga temporalmente `alma-target-02` y sube `alma-security` a 4GB si puedes.
- Practica STIG, FIPS, SELinux.

**Inversión opcional:** Compra 16GB más de RAM ($40) y olvídate de apagar nada.

------



## Escenario 2: 

### Especificaciones: CPU Ryzen 5, 5600GT, 16 Gb RAM 

Estacion de trabajo basado en Fedora Bazzite. Actualmente, se utiliza para correr monitoreo basado en Prometheus + Grafana y Zabbix.

También, se corren agentes locales de IA basado en Ollama, OpenCode utilizando una GPU RTX-3060.



## 🎯 Laboratorio en tu Estación Bazzite: Ryzen 5 5600GT + 16 GB

Esto cambia todo. Tienes **hardware fresco y dedicado** para estudiar. El Ryzen 5 5600GT (6c/12t) con 16 GB es perfecto para 3-4 VMs simultáneas. Y al ser una máquina separada, no tocas tu producción en Proxmox.

------

## 1. Preparar Fedora Bazzite para Virtualización

Bazzite es un sistema **inmutable (ostree)**. No usas `dnf install` en el host; usas `rpm-ostree`.

### Paso 1: Instalar el stack de virtualización



```bash
# En Bazzite, como usuario con privilegios (usa sudo o pkexec)
rpm-ostree install libvirt-daemon-kvm qemu-kvm virt-manager virt-install \
  virt-viewer swtpm swtpm-tools edk2-ovmf

# Reiniciar para aplicar la capa ostree
systemctl reboot
```

### Paso 2: Habilitar servicios



```bash
sudo systemctl enable --now libvirtd
sudo usermod -aG libvirt,kvm $USER

# Relogear (cerrar sesión y volver a entrar) para que tome los grupos
```

### Paso 3: Verificar que KVM funciona



```bash
# Debe decir "KVM acceleration can be used"
virt-host-validate qemu

# O más simple:
lsmod | grep kvm
# Debe mostrar kvm y kvm_amd
```

------

## 2. Arquitectura de VMs para 16 GB RAM / 6 Cores



| VM               | RAM  | vCPU | Disco | Rol                                         | Estado                |
| :--------------- | :--- | :--- | :---- | :------------------------------------------ | :-------------------- |
| `alma-rhcsa`     | 3 GB | 2    | 40 GB | RHCSA diario + target RHCE                  | **Siempre encendida** |
| `alma-target-02` | 2 GB | 1    | 30 GB | 2do nodo para Ansible                       | Solo para RHCE        |
| `alma-security`  | 4 GB | 2    | 50 GB | RHCSS: STIG, FIPS, SELinux custom           | Bajo demanda          |
| `freeipa-lab`    | 2 GB | 1    | 20 GB | Servidor FreeIPA para autenticación central | Solo para RHCSS       |

**Total asignado:** 11 GB (dejando 5 GB para Bazzite).
**Alternativa sin FreeIPA:** Usa el host Bazzite como nodo de control Ansible y ahorra 2 GB.

### Red recomendada

Crea dos redes virtuales en libvirt:



| Red             | Tipo        | Propósito                                |
| :-------------- | :---------- | :--------------------------------------- |
| `default` (NAT) | Ya existe   | Salida a internet, gestión               |
| `lab-internal`  | Red aislada | Practicar firewalld entre VMs sin salida |



```bash
# Crear red interna aislada
cat > /tmp/lab-internal.xml << 'EOF'
<network>
  <name>lab-internal</name>
  <bridge name='virbr1' stp='on' delay='0'/>
  <ip address='10.10.10.1' netmask='255.255.255.0'>
    <dhcp>
      <range start='10.10.10.10' end='10.10.10.50'/>
    </dhcp>
  </ip>
</network>
EOF

sudo virsh net-define /tmp/lab-internal.xml
sudo virsh net-start lab-internal
sudo virsh net-autostart lab-internal
```

------

## 3. Script de Creación de VMs (Copiar y Pegar)

### Deployment en:



**Instalar dependencias del script primero:**

```bash
rpm-ostree install genisoimage
# o si no está disponible:
# sudo dnf install genisoimage  # dentro de un toolbox, o buscar alternativa
```

------

## 4. Gestión Diaria con virsh



```bash
# Ver estado
virsh list --all

# Encender / apagar
virsh start alma-rhcsa
virsh shutdown alma-rhcsa      # graceful
virsh destroy alma-rhcsa       # fuerza (como pull del cable)

# Consola (salir con Ctrl+] )
virsh console alma-rhcsa

# Ver IP asignada
virsh domifaddr alma-rhcsa

# Snapshot antes de romper algo
virsh snapshot-create-as alma-rhcsa clean-install --description "Post cloud-init"

# Rollback
virsh snapshot-revert alma-rhcsa clean-install

# Liberar RAM para estudiar RHCSS
virsh shutdown alma-rhcsa
virsh shutdown alma-target-02
virsh start alma-security
```

------

## 5. Roadmap Ajustado a Este Hardware



| Fase                   | Semanas | VMs Activas                                 | RAM Usada | Acción                                    |
| :--------------------- | :------ | :------------------------------------------ | :-------- | :---------------------------------------- |
| **0: Infraestructura** | 1       | 0                                           | 0 GB      | Instalar KVM, crear VMs, snapshots base   |
| **1: RHCSA**           | 2-6     | `alma-rhcsa`                                | 3 GB      | Romper y reparar. Un snapshot por semana. |
| **2: RHCE**            | 7-11    | `alma-rhcsa` + `alma-target-02`             | 5 GB      | Host Bazzite = nodo de control Ansible    |
| **3: RHCSS**           | 12-15   | `alma-security` (+ `freeipa-lab` ocasional) | 4-6 GB    | Apagar las otras dos VMs                  |

### Comandos para cambiar de fase rápido:



```bash
# Modo RHCSA
virsh start alma-rhcsa
virsh shutdown alma-target-02 alma-security freeipa-lab

# Modo RHCE
virsh start alma-rhcsa
virsh start alma-target-02
virsh shutdown alma-security freeipa-lab

# Modo RHCSS
virsh shutdown alma-rhcsa alma-target-02
virsh start alma-security
# virsh start freeipa-lab  # solo cuando practiques SSSD/FreeIPA
```

------

## 6. Usar el Host Bazzite como Nodo de Control Ansible

No desperdicies 2 GB en una VM de control. Tu Bazzite host puede ser el control node:



```bash
# En Bazzite, crear un toolbox Fedora para Ansible
# (o instalar en el host vía rpm-ostree si prefieres)

toolbox create ansible-lab
toolbox enter ansible-lab

sudo dnf install -y ansible-core sshpass

# Crear inventario
mkdir -p ~/ansible-lab && cd ~/ansible-lab

cat > inventory.ini << 'EOF'
[targets]
alma-rhcsa ansible_host=192.168.122.XXX
alma-target-02 ansible_host=192.168.122.YYY

[targets:vars]
ansible_user=labadmin
ansible_ssh_private_key_file=~/.ssh/id_ed25519
ansible_python_interpreter=/usr/bin/python3
EOF

# Probar conexión
ansible -i inventory.ini all -m ping
```

> Las IPs las obtienes con `virsh domifaddr <vm-name>`.

------

## 7. Checklist de Verificación

Antes de empezar a estudiar, confirma:



```bash
echo "=== CHECKLIST BAZZITE LAB ==="
echo "[ ] rpm-ostree install aplicado y sistema reiniciado"
echo "[ ] libvirtd activo: $(systemctl is-active libvirtd)"
echo "[ ] Usuario en grupos libvirt,kvm: $(groups | grep -o 'libvirt\|kvm')"
echo "[ ] virsh list funciona sin sudo"
echo "[ ] vTPM disponible: $(ls /usr/share/swtpm/swtpm-create-user-config-files 2>/dev/null && echo 'OK' || echo 'FALTA SWTPM')"
echo "[ ] OVMF disponible: $(ls /usr/share/edk2/ovmf/OVMF_CODE.fd 2>/dev/null && echo 'OK' || echo 'FALTA OVMF')"
echo "[ ] Red lab-internal creada: $(sudo virsh net-list --all | grep lab-internal | awk '{print $2,$3}')"
echo "[ ] alma-rhcsa creada y accesible por SSH"
echo "[ ] Snapshots base creados en todas las VMs"
echo "[ ] Toolbox ansible creado y funcionando"
```

------

## 8. Ventajas de Esta Arquitectura



| Aspecto               | Por qué funciona bien                                        |
| :-------------------- | :----------------------------------------------------------- |
| **Bazzite inmutable** | Tu host no se rompe por instalar paquetes. Las VMs están aisladas en `~/VMs`. |
| **Ryzen 5600GT**      | 6c/12t da margen real. Puedes tener 3 VMs sin que Bazzite se trabe. |
| **Vega integrada**    | Bazzite usa la GPU para el desktop. Las VMs usan virtio (sin GPU), ahorrando recursos. |
| **Separación física** | Tu lab no compite con pfSense/K3s en el ThinkCentre. Estudias sin miedo a romper producción. |
| **KVM nativo**        | Mismo stack que RHEL. Lo que aprendas en `virsh` aplica directo a `qemu-kvm` en empresas. |

------

¿Quieres que te prepare el **script de post-instalación de AlmaLinux** (el que corre dentro de la VM la primera vez) para dejar `alma-rhcsa` lista con SELinux enforcing, firewalld activo, PAM configurado y auditd corriendo? Así empiezas la Fase 1 (RHCSA) en cuanto enciendas la VM.





