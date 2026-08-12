# Misión 2

Excelente avance. La Misión 1 te dio una base sólida: usuarios, SSH, SELinux y servicios. Ahora estás en el punto donde el RHCSA se bifurca en tres caminos igualmente importantes. Te los presento para que elijas.

------

## 🗺️ Dónde Estamos en el Mapa

Ya cubriste ~40% del examen RHCSA:

- ✅ Gestión de usuarios, grupos y sudo
- ✅ Configuración de SSH
- ✅ SELinux básico (contextos, booleans)
- ✅ Servicios systemd (start, enable, restart)

Te faltan tres bloques grandes. Cada uno puede ser tu **Misión 2**.

------

## Alternativa A: "El Servidor de Archivos Heredado" (Almacenamiento)

**Áreas del RHCSA:** LVM, particiones, sistemas de archivos, NFS, autofs, ACLs extendidas, quotas.

**El escenario:** El equipo de desarrollo necesita un servidor de archivos compartido. Heredas un disco de 20 GB sin particionar y te piden:

- Crear un volumen lógico de 10 GB para datos web (extensible a 15 GB sin downtime).
- Un volumen de 5 GB para logs (con compresión transparente).
- Un volumen de 3 GB para backups temporales (reducirlo a 2 GB cuando se libere espacio).
- Exportar `/shared/dev` por NFS solo a la subred de desarrollo.
- Configurar autofs para que los usuarios vean `/net/server/docs` solo cuando acceden a él.
- Aplicar ACLs extendidas para que `dev01` tenga permisos distintos a los del grupo `webdev` sobre el mismo directorio.

**Por qué elegirla:** Es el bloque donde más se atascan los candidatos en el examen. LVM es específico de RHEL y sus derivados; no existe igual en Debian/Ubuntu. Dominarlo te diferencia inmediatamente en una entrevista.

**Requiere:** Agregar un disco virtual extra a tu VM `alma-rhcsa` (20 GB). Es fácil en KVM: apagas la VM, `virsh edit alma-rhcsa`, agregas un `<disk>`, y arrancas.

------

## Alternativa B: "La Gran Migración de Red" (Redes y Firewall)

**Áreas del RHCSA:** nmcli, bonding/teaming, VLANs, firewalld zones, DNS cliente, NTP (chrony), port forwarding.

**El escenario:** La empresa migra su rack de servidores a un nuevo datacenter. Tu servidor `alma-rhcsa` debe:

- Tener dos interfaces de red en bonding (balanceo de carga) con IP estática.
- Una subinterfaz VLAN para tráfico de management (acceso SSH solo por esta VLAN).
- firewalld con tres zonas: `public` (Nginx), `internal` (SSH solo desde tu Bazzite), `dmz` (puerto 8080 para una app futura).
- Redirección de puertos: peticiones al puerto 8080 del exterior se redirigen al puerto 80 interno.
- Sincronización horaria con chrony contra servidores internos.
- Resolver nombres internos (`db.intra.local`, `backup.intra.local`) sin tocar `/etc/hosts`.

**Por qué elegirla:** Conecta directamente con lo que ya hiciste (SSH en puerto 22, Nginx en 80). Te permite entender por qué firewalld es más que "abrir un puerto": es una máquina de estados con políticas de zona. Es el bloque que más se parece a la vida real de un sysadmin.

**Requiere:** Agregar una segunda interfaz de red a `alma-rhcsa` en KVM. También fácil.

------

## Alternativa C: "El Administrador de Tareas y Contenedores" (Procesos y Podman)

**Áreas del RHCSA:** systemd timers, cron, journalctl, logrotate, Podman rootless, imágenes, volúmenes, mapeo de puertos.

**El escenario:** Necesitas automatizar tareas de mantenimiento sin intervención humana:

- Un timer de systemd que limpie logs mayores a 30 días todos los domingos a las 3 AM.
- Un cron que verifique el espacio en disco y envíe una alerta si supera el 85%.
- Un contenedor Podman (rootless) que sirva una aplicación Python en el puerto 5000.
- El contenedor debe persistir datos en `/opt/app-data` del host.
- SELinux debe permitir que el contenedor acceda a ese directorio sin desactivarse.
- El contenedor debe arrancar automáticamente al boot del sistema (systemd user service).

**Por qué elegirla:** Si tu objetivo final es DevOps/SRE, esta alternativa acelera tu camino hacia RHCE y OpenShift. Podman es el reemplazo de Docker en RHEL y es pregunta fija en el RHCSA moderno.

**Requiere:** Nada extra en hardware. Todo se hace dentro de la VM existente.

------

## Mi Recomendación como Tutor



| Si tu objetivo es...                                         | Elige...                           |
| :----------------------------------------------------------- | :--------------------------------- |
| **Solidificar la base sysadmin clásica** (el perfil más contratado) | **Alternativa A (Almacenamiento)** |
| **Entender redes enterprise y seguridad perimetral**         | **Alternativa B (Redes)**          |
| **Ir rápido hacia DevOps/contenedores**                      | **Alternativa C (Podman)**         |

**Mi consejo personal:** Ve por la **Alternativa A**. El almacenamiento es el "músculo" del sysadmin. Cuando en una entrevista te pregunten *"¿Cómo extiendes un filesystem sin apagar el servidor?"* y respondas con LVM + resize2fs + xfs_growfs, el entrevistador asiente. Es una pregunta clásica que separa a quienes han tocado producción de quienes solo han leído manuales.

Además, ya tienes SELinux y usuarios dominados. El almacenamiento es el siguiente pilar natural antes de saltar a redes (que es más abstracto) o contenedores (que es más moderno).

------

## ¿Cuál te llama más?

Dime **A, B o C** y armo la Misión 2 completa con:

- El escenario narrativo
- Las tareas desglosadas
- Las pistas (ocultas)
- La solución paso a paso (oculta)
- Qué áreas del RHCSA cubre

¿Tienes preferencia, o confías en la recomendación del tutor?



---



> ## Es importante dominar la parte de Almacenamiento. Avancemos con la alternativa A



# 🎯 Misión 2: "El Servidor de Archivos Heredado"

## El Escenario

La empresa adquirió un nuevo servidor de almacenamiento. Te entregan un disco virtual de 20 GB sin tocar y te piden que lo pongas en producción antes del viernes. Los requisitos son específicos:

> 1. *"Necesitamos tres áreas de datos: web (10 GB), logs (5 GB) y backups (3 GB). El área web debe poder crecer sin apagar el servidor."*
> 2. *"El área web debe compartirse por NFS para que el equipo de desarrollo monte sus proyectos."*
> 3. *"Los accesos NFS deben aparecer automáticamente cuando un usuario entra a `/shares/web`, no antes."*
> 4. *"`dev01` necesita control total sobre `/data/web`, pero `operator` solo debe leer. Los permisos tradicionales de Unix no sirven porque ambos están en grupos distintos."*
> 5. *"`dev01` no debe poder consumir más de 150 MB en `/data/web`, o nos quedamos sin espacio para los logs."*

------

## 🔧 Preparación: Agregar el Disco Virtual

Antes de tocar la VM, apágala y crea el nuevo disco desde tu Bazzite host:



```bash
# 1. Apagar la VM limpiamente
virsh shutdown alma-rhcsa

# 2. Crear el disco virtual de 20 GB
qemu-img create -f qcow2 ~/VMs/alma-rhcsa-disk2.qcow2 20G

# 3. Adjuntarlo a la VM como /dev/vdb
virsh attach-disk alma-rhcsa \
  ~/VMs/alma-rhcsa-disk2.qcow2 vdb \
  --persistent --subdriver qcow2

# 4. Encender
virsh start alma-rhcsa

# 5. Verificar desde dentro de la VM (espera 10 segundos y conecta)
ssh labadmin@<ip-de-alma-rhcsa>
lsblk
# Debes ver vdb de 20G sin particiones
```

> **Snapshot antes de empezar:** `virsh snapshot-create-as alma-rhcsa pre-mision2`



## Prerequisitos

Necesita uno o más discos sin particionar o particiones sin usar. Compruebe lo que está disponible:

```bash
# List all block devices

lsblk

# Check for unused disks
lsblk -f
```



## Instalar herrramientas LVM

Las herramientas LVM se incluyen en la instalación base de RHEL, pero verifique si existe:

```bash
# Ensure LVM packages are installed
sudo yum list installed | grep lvm2
```
```text
Si el paquete está instalado: Verás una línea que 
contiene lvm2.x86_64 o similar, indicando que las 
herramientas están en el sistema.

Si no está instalado: El comando no mostrará
ningún resultado. En ese caso, puedes instalarlo
fácilmente con:
```
```bash
sudo dnf install lvm2 -y
```



---

## 🧩 Las 5 Tareas de la Misión

### Tarea 1: Infraestructura LVM

Usa el disco `/dev/vdb` completo (sin particionar) para crear:

- **VG:** `vg_data`
- **LVs:**
  - `lv_web` → 10 GB
  - `lv_logs` → 5 GB
  - `lv_backup` → 3 GB

Formatea y monta:

- `lv_web` → **ext4** → `/data/web`
- `lv_logs` → **XFS** → `/data/logs`
- `lv_backup` → **ext4** → `/data/backup`

Persiste los montajes en `/etc/fstab` usando **UUID** (no `/dev/mapper`).

### Tarea 2: Operaciones en Caliente (Sin Downtime)

- **Extender** `lv_web` de 10 GB a **12 GB** sin desmontar `/data/web`.
- **Reducir** `lv_backup` de 3 GB a **2 GB** (puedes desmontar para esto).
- Crear un **snapshot** de `lv_web` de 1 GB, montarlo en `/mnt/snapshot`, verifica que ves los mismos archivos, luego desmóntalo y elimínalo.

### Tarea 3: Servidor NFS

- Instala el servidor NFS.
- Exporta `/data/web` a toda tu subred `192.168.122.0/24` con permisos de lectura/escritura.
- Configura `firewalld` para permitir el tráfico NFS (`nfs`, `rpc-bind`, `mountd`).
- Verifica con `exportfs -v`.

### Tarea 4: Cliente NFS + autofs

- Configura `autofs` en la **misma VM** (simulando un cliente local) o en `alma-target-02` si la tienes encendida.
- El objetivo: al acceder a `/shares/web`, se monte automáticamente el export NFS.
- Si no hay actividad en 60 segundos, se desmonta solo.

### Tarea 5: ACLs Extendidas y Quotas

En `/data/web`:

- `dev01` tiene permisos **rwx** (lectura, escritura, ejecución).
- `operator` tiene permisos **r-x** (solo lectura y ejecución).
- Los **nuevos archivos** creados dentro de `/data/web` deben heredar automáticamente estos permisos (default ACLs).
- Habilita **quotas de usuario** en `/data/web`.
- Asigna a `dev01`: límite **soft** de 100 MB, límite **hard** de 150 MB.
- Verifica con `repquota`.

------

## 💡 Pistas por Tarea (Léelas solo si te atascas)

<details> <summary><b>Pista Tarea 1: LVM y /etc/fstab</b></summary>

- `pvcreate /dev/vdb`
- `vgcreate vg_data /dev/vdb`
- `lvcreate -L 10G -n lv_web vg_data`
- `mkfs.ext4 /dev/vg_data/lv_web`
- `mkfs.xfs /dev/vg_data/lv_logs`
- `mkfs.ext4 /dev/vg_data/lv_backup`
- Usa `blkid` para obtener los UUIDs. En `/etc/fstab`, la línea se ve así: `UUID=xxxxx-xxxxx /data/web ext4 defaults 0 0`
- Crea los directorios `/data/web`, `/data/logs`, `/data/backup` antes de montar.

</details>

<details> <summary><b>Pista Tarea 2: Extender, Reducir, Snapshot</b></summary>

- Extender online: `lvextend -L +2G /dev/vg_data/lv_web` → `resize2fs /dev/vg_data/lv_web`
- Reducir (requiere desmontar): `umount /data/backup` → `e2fsck -f /dev/vg_data/lv_backup` → `resize2fs /dev/vg_data/lv_backup 2G` → `lvreduce -L 2G /dev/vg_data/lv_backup` → `mount -a`
- Snapshot: `lvcreate -s -L 1G -n lv_web_snap /dev/vg_data/lv_web` → `mkdir /mnt/snapshot` → `mount /dev/vg_data/lv_web_snap /mnt/snapshot` → `umount /mnt/snapshot` → `lvremove /dev/vg_data/lv_web_snap`

</details>

<details> <summary><b>Pista Tarea 3: NFS y Firewall</b></summary>

- `dnf install nfs-utils`
- `/etc/exports`: `/data/web 192.168.122.0/24(rw,sync,no_root_squash)`
- `exportfs -a`
- `systemctl enable --now nfs-server`
- sudo dnf install firewalld -y
- `firewall-cmd --permanent --add-service=nfs`
- `firewall-cmd --permanent --add-service=rpc-bind`
- `firewall-cmd --permanent --add-service=mountd`
- `firewall-cmd --reload`

</details>

<details> <summary><b>Pista Tarea 4: autofs</b></summary>

- `dnf install nfs-utils autofs`
- `/etc/auto.master`: `/shares /etc/auto.shares --timeout=60`
- `/etc/auto.shares`: `web -rw,sync <ip-del-servidor>:/data/web`
- `systemctl enable --now autofs`
- Prueba: `ls /shares/web` debe montar automáticamente.

</details>

<details> <summary><b>Pista Tarea 5: ACLs y Quotas</b></summary>

- ACLs: `setfacl -m u:dev01:rwx /data/web` y `setfacl -m u:operator:r-x /data/web`
- Default ACLs (herencia): `setfacl -d -m u:dev01:rwx /data/web` y `setfacl -d -m u:operator:r-x /data/web`
- Verificar: `getfacl /data/web`
- Quotas: Edita `/etc/fstab` y añade `usrquota,grpquota` a la línea de `/data/web`. Luego `mount -o remount /data/web`
- `quotacheck -cug /data/web`
- `edquota -u dev01` (edita los bloques: soft = 102400, hard = 153600 para 100MB/150MB aprox)
- `quotaon -v /data/web`
- `repquota -a`

</details>