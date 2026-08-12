# 🎓 SIMULACRO EX200 — RHCSA

**Duración:** 2 horas 30 minutos
**Sistema:** `alma-rhcsa` (1 VM, 3 GB RAM, 2 vCPU)
**Formato:** 100% práctico, sin acceso a internet, documentación local permitida (`man`, `info`, `/usr/share/doc`)
**Puntuación:** 150 puntos | **Aprobado:** 105 puntos (70%)

------

## ⚙️ Preparación del Entorno de Examen

**Antes de empezar el cronómetro:**



```bash
# En tu Bazzite host
virsh snapshot-revert alma-rhcsa ready
# Espera a que arranque y conecta por SSH

# Dentro de alma-rhcsa, verifica que estás limpio
sudo df -h
sudo lsblk
sudo ip addr
```

**Reglas del simulacro:**

- No uses Google, ChatGPT, ni este chat durante las 2.5 horas.
- Puedes usar `man`, `info`, `--help`, y la documentación instalada en la VM.
- No reinicies la VM a menos que una tarea lo exija explícitamente.
- Si rompes algo irremediablemente, anota qué hiciste y sigue con la siguiente tarea. En el examen real no hay "undo".
- Toma nota del tiempo que te toma cada tarea.

**Entregable:** Al final, ejecuta `history > ~/exam-history.txt` y guárdalo. Eso será tu bitácora de autoevaluación.

------

## 📖 Escenario del Examen

Eres contratado como administrador de sistemas en **LogiTech Industries**. El administrador anterior dejó la empresa abruptamente y dejó el servidor `srv01.logitech.local` en un estado inconsistente. Tu jefe te entrega este listado de pendientes que debes resolver **hoy** antes de que el equipo de desarrollo comience su sprint mañana a las 8:00 AM.

El servidor es una máquina virtual AlmaLinux 9 que ya tiene:

- Acceso SSH funcionando (pero inseguro).
- Un disco secundario `/dev/vdb` de 20 GB sin usar.
- SELinux en modo `Enforcing`.
- firewalld activo.
- Nginx instalado pero mal configurado.

------

## 📝 Lista de Tareas

### Tarea 1: Identidad del Servidor (10 pts)

Configure el hostname del servidor como `srv01.logitech.local`.
Configure la interfaz de red principal con una IP estática `192.168.122.50/24`, gateway `192.168.122.1`, y DNS `192.168.122.1`.
Asegúrese de que la configuración persista tras reinicios.
*Nota: No reinicie el sistema. Aplique los cambios en caliente.*

------

### Tarea 2: Gestión de Identidades (10 pts)

Cree los siguientes usuarios y grupos:

- Grupo `developers` (GID 3000).
- Grupo `operators` (GID 3001).
- Usuario `ana` (UID 3001), miembro de `developers`, shell `/bin/bash`, home en `/home/ana`.
- Usuario `luis` (UID 3002), miembro de `operators`, shell `/bin/bash`, home en `/home/luis`.
- Ambos usuarios deben tener contraseñas que expiren en 60 días. Establezca la contraseña inicial como `InitPass2026!`.

------

### Tarea 3: Políticas de Sudo (10 pts)

Configure `sudoers` de forma segura:

- `ana` puede ejecutar **cualquier comando** como root **sin contraseña**.
- `luis` solo puede ejecutar `/usr/bin/systemctl restart nginx` y `/usr/bin/systemctl status nginx`. No puede ejecutar ningún otro comando con `sudo`.

------

### Tarea 4: Hardening de SSH (10 pts)

El acceso SSH actual es inseguro. Aplique las siguientes restricciones:

- El usuario `root` no puede autenticarse por SSH (ni por clave ni por contraseña).
- Solo los usuarios `labadmin`, `ana` y `luis` pueden conectarse por SSH.
- La autenticación por contraseña está deshabilitada; solo se permite autenticación por clave pública.
- El puerto SSH sigue siendo el 22.
- Aplique los cambios sin reiniciar el servicio SSH.

------

### Tarea 5: Almacenamiento con LVM (15 pts)

Utilice el disco `/dev/vdb` (20 GB) para crear la siguiente infraestructura:

- Volume Group: `vg_production`.
- Logical Volumes:
  - `lv_apps` → 8 GB, formateado en **ext4**, montado en `/data/apps`.
  - `lv_db` → 6 GB, formateado en **XFS**, montado en `/data/db`.
  - `lv_archive` → 4 GB, formateado en **ext4**, montado en `/data/archive`.
- Todos los montajes deben ser persistentes en `/etc/fstab` usando **UUID**.
- Los directorios de montaje deben tener permisos `755` y pertenecer a `root:root`.

------

### Tarea 6: Servidor NFS (10 pts)

Configure el servidor NFS para exportar `/data/apps` con las siguientes características:

- Accesible solo desde la red `192.168.122.0/24`.
- Permisos de lectura y escritura (`rw`).
- Sincronización de escrituras (`sync`).
- Sin escalado de privilegios para root (`no_root_squash`).
- Configure `firewalld` para permitir el tráfico NFS necesario.
- El servicio debe iniciar automáticamente.

------

### Tarea 7: Cliente NFS con autofs (10 pts)

En el **mismo servidor** (simulando un cliente local), configure `autofs` para que:

- Al acceder al directorio `/shares/apps`, se monte automáticamente el export NFS `srv01.logitech.local:/data/apps`.
- Si no hay acceso durante 120 segundos, el montaje se desmonte automáticamente.
- Verifique que el montaje funciona listando `/shares/apps`.

------

### Tarea 8: ACLs Extendidas y Quotas (10 pts)

En `/data/apps`:

- El usuario `ana` debe tener permisos **rwx**.
- El usuario `luis` debe tener permisos **r-x**.
- Los archivos y directorios creados **futuros** dentro de `/data/apps` deben heredar automáticamente estos permisos (default ACLs).
- Habilite quotas de usuario en `/data/apps`.
- Establezca para `ana`: límite soft de 50 MB (bloques), límite hard de 80 MB (bloques).
- Active las quotas y verifique con `repquota`.

------

### Tarea 9: SELinux y Nginx (10 pts)

El administrador anterior intentó mover el document root de Nginx a `/data/apps/web` pero el sitio no sirve contenido por denegaciones de SELinux. Corrija esto:

- Cree el directorio `/data/apps/web` con un archivo `index.html` que contenga: `<h1>LogiTech Industries</h1>`.
- Configure Nginx para servir desde `/data/apps/web` en el puerto 80.
- **No desactive SELinux.** El modo debe permanecer `Enforcing`.
- Asegúrese de que el contexto SELinux permita a Nginx leer el contenido.
- El servicio Nginx debe iniciar automáticamente y responder a `curl http://localhost`.

------

### Tarea 10: Automatización de Tareas (10 pts)

- Cree un **timer de systemd** que ejecute un script cada día a las 02:30 AM.
- El script debe estar en `/usr/local/bin/cleanup-logs.sh` y debe eliminar archivos `.log` mayores a 30 días en `/var/log/custom/` (cree el directorio si no existe).
- El timer debe estar habilitado para iniciar automáticamente.
- Adicionalmente, configure un **job de cron** para el usuario `ana` que ejecute `/usr/local/bin/backup-check.sh` (puede ser un script vacío, solo créelo) cada lunes a las 06:00 AM.

------

### Tarea 11: Contenedores Rootless (15 pts)

- Como usuario `ana`, descargue la imagen `docker.io/library/httpd:2.4` usando Podman.
- Ejecute un contenedor rootless llamado `web-test` que:
  - Escuche en el puerto **8080** del host.
  - Mapee al puerto 80 del contenedor.
  - Monte un volumen persistente: `/home/ana/web-content` del host → `/usr/local/apache2/htdocs` del contenedor.
  - Cree un archivo `index.html` en `/home/ana/web-content` con el texto `Container OK`.
- Verifique que `curl http://localhost:8080` responda desde dentro de la sesión de `ana`.
- Asegúrese de que SELinux en el host no bloquee el acceso del contenedor al volumen montado.

------

### Tarea 12: Gestión de Logs (5 pts)

- Configure `logrotate` para el directorio `/var/log/custom/` con las siguientes reglas:
  - Rotación semanal.
  - Conservar 4 copias de respaldo.
  - Comprimir las rotaciones.
  - Crear el archivo de configuración en `/etc/logrotate.d/custom-app`.

------

### Tarea 13: Troubleshooting (15 pts)

El servicio `custom-app.service` está instalado pero no inicia. Diagnostique y repare:

- El servicio intenta ejecutar `/usr/local/bin/custom-app` (cree un script bash simple que haga `echo "Running"` y `sleep 60` si no existe).
- Investigue por qué `systemctl start custom-app` falla.
- Corrija el problema (puede ser un permiso, un contexto SELinux, un path, o una dependencia).
- El servicio debe iniciar correctamente y quedar habilitado.

*Pista: Revise los logs con `journalctl -u custom-app` y los permisos/SELinux del ejecutable.*

------

### Tarea 14: Sincronización de Tiempo (5 pts)

- Configure `chronyd` para sincronizar contra los servidores del pool `pool.ntp.org`.
- Asegúrese de que el servicio esté activo y que el reloj del sistema esté sincronizado.
- Verifique con `chronyc tracking`.

------

### Tarea 15: Cumplimiento de Seguridad (10 pts)

- Ejecute un escaneo básico de OpenSCAP usando el perfil `xccdf_org.ssgproject.content_profile_cis_server_l1`.
- Genere un reporte HTML en `/root/scap-report.html`.
- Aplique la remediación automática del perfil CIS Level 1.
- Verifique que el reporte se haya generado correctamente.

------

## ⏱️ Instrucciones de Inicio

1. **Toma snapshot ahora:** `virsh snapshot-create-as alma-rhcsa simulacro-ex200-inicio`

2. **Anota la hora de inicio.**

3. **Cierra este chat, tu navegador, y cualquier otra ventana de ayuda.**

4. **Conecta por SSH a la VM y empieza.**

5. **Al finalizar (o al cumplirse 2.5 horas), ejecuta:**

   

   ```bash
   history > ~/exam-history.txt
   sudo df -h > ~/exam-df.txt
   sudo lsblk > ~/exam-lsblk.txt
   sudo ip addr > ~/exam-ip.txt
   sudo getenforce > ~/exam-selinux.txt
   ```

   

------

## ✅ Auto-evaluación (Haz esto DESPUÉS de las 2.5 horas)

Comprueba cada tarea objetivamente:



| Tarea | Verificación Rápida                                          |
| :---- | :----------------------------------------------------------- |
| 1     | `hostnamectl`, `ip addr`, `cat /etc/resolv.conf`             |
| 2     | `id ana`, `id luis`, `chage -l ana`                          |
| 3     | `sudo -l -U ana`, `sudo -l -U luis`                          |
| 4     | `ssh root@localhost` (debe fallar), `sshd -t`                |
| 5     | `lsblk`, `df -h`, `cat /etc/fstab`                           |
| 6     | `exportfs -v`, `showmount -e localhost`                      |
| 7     | `ls /shares/apps`, `mount | grep shares`                     |
| 8     | `getfacl /data/apps`, `repquota -a`                          |
| 9     | `curl -s http://localhost`, `getenforce`, `ls -Z /data/apps/web` |
| 10    | `systemctl list-timers`, `crontab -u ana -l`                 |
| 11    | `su - ana -c 'podman ps; curl -s http://localhost:8080'`     |
| 12    | `cat /etc/logrotate.d/custom-app`                            |
| 13    | `systemctl is-active custom-app`, `systemctl is-enabled custom-app` |
| 14    | `chronyc tracking`                                           |
| 15    | `ls -lh /root/scap-report.html`                              |

**Puntúate con honestidad.** Si una tarea "casi funcionó" pero falla una verificación, es **0 puntos**. El examen real no da medias.

------

## 📤 Entrega de Resultados

Cuando termines (independientemente de si aprobaste o no), vuelve aquí y dime:

1. **¿Cuánto tiempo te tomó en total?**
2. **¿Qué tarea te atascó más y por qué?**
3. **¿Qué tarea(s) no pudiste completar?**
4. **¿Qué error cometiste que te costó más tiempo revertir?**

Con esos datos, revisamos juntos las soluciones de lo que falló, y luego pasamos a la **Misión 3** (Redes avanzadas o Contenedores, tú eliges).

**¡Mucha suerte! Empieza cuando estés listo.**