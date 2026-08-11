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