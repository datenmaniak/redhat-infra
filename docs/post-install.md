# 🎯 El Próximo Paso: De "Tengo VMs" a "Tengo un Laboratorio"

Tus máquinas están encendidas, pero aún no es un laboratorio. Es como tener un coche nuevo en el garage con el plástico en los asientos. Hay que hacer el **checklist de entrega**, tomar **fotos del seguro** (snapshots), y decidir **quién conduce primero**.

Aquí va el orden exacto:

------

## Paso 1: Verificación de Humo (Smoke Test)

Antes de tocar una tecla de configuración, confirma que cada VM nació sana. Conéctate a cada una y verifica:

1. **¿Responde al SSH?** Desde tu Bazzite host, cada VM debe contestar con la clave que inyectaste.
2. **¿Cloud-init terminó?** Revisa que no haya errores en `/var/log/cloud-init.log`. A veces el resize del disco falla silenciosamente.
3. **¿El disco creció?** La imagen cloud viene con ~10 GB. Si no creció a los 40 GB que le asignaste, `growpart` falló.
4. **¿Tiene salida a internet?** `ping 1.1.1.1` y resolución DNS.
5. **¿El repositorio de AlmaLinux funciona?** `dnf repolist` debe mostrar los repos BaseOS y AppStream.

Si alguna VM falla en alguno de estos cinco puntos, **no sigas**. Arréglala o recréala. Es barato ahora; será caro cuando tengas tres semanas de configuración encima.

------

## Paso 2: El Ritual de los Snapshots Base

Este es el momento más importante de todo tu lab. Antes de instalar un solo paquete extra, antes de cambiar un archivo de configuración, **crea los snapshots de retorno**.

Para cada VM, necesitas al menos dos snapshots:



| Snapshot  | Momento                                               | Para qué sirve                                     |
| :-------- | :---------------------------------------------------- | :------------------------------------------------- |
| `factory` | Ahora, recién creada                                  | Si rompes todo irreparablemente, vuelves aquí.     |
| `ready`   | Después de actualizar e instalar herramientas básicas | Punto de partida limpio para cada fase de estudio. |

La regla de oro del laboratorio: **nunca practiques hardening o remediación sin un snapshot previo**. Especialmente en `alma-security`, donde vas a aplicar STIG, habilitar FIPS y tocar SELinux. Un error en FIPS puede dejarte sin acceso SSH si no está bien configurado.

------

## Paso 3: Post-Instalación Mínima (Las Herramientas del Oficio)

Actualiza el sistema e instala lo que vas a usar en **todas** las VMs. No esperes a necesitarlo:

- `vim` o `nano` (editor)
- `tmux` (sesiones persistentes, crítico para exámenes y labs largos)
- `bash-completion` (tab completion para comandos largos)
- `bind-utils` (`dig`, `nslookup`)
- `net-tools` (`ifconfig`, `netstat`, aunque estén legacy, aparecen en exámenes antiguos)
- `bash-completion` (para no escribir todo a mano)

En `alma-rhcsa` y `alma-target-02`, esto es suficiente por ahora.

En `alma-security`, además instala el stack de seguridad:

- `openscap-scanner`, `scap-security-guide` (para STIG)
- `aide`, `audit` (auditoría)
- `policycoreutils-python-utils`, `setools-console` (SELinux)
- `fapolicyd` (control de ejecución de binarios)

------

## Paso 4: Decide Tu Primera Batalla

Tienes tres certificaciones en el horizonte. No empieces por el más difícil. Empieza por el que te da **autonomía operativa**.

### Mi recomendación como tutor:

**Semana 1-2: RHCSA puro en `alma-rhcsa`**

No toques Ansible todavía. No toques SELinux avanzado. Aprende a caminar antes de correr.

El primer ejercicio no es un script gigante. Es esto:

> **"Dame acceso root a esta máquina, pero solo desde tu Bazzite host, solo con clave SSH, y bloquea el acceso root por contraseña. Luego crea un usuario `operator` que pueda reiniciar nginx y editar `/etc/hosts` sin ser root."**

Eso suena simple, pero toca:

- SSH (`sshd_config`)
- PAM (autenticación)
- `sudoers` (autorización)
- Permisos de archivos (`/etc/hosts`)
- `systemctl` (gestión de servicios)
- SELinux básico (si nginx no sirve contenido por contextos)

Cuando domines eso sin mirar documentación, estás listo para la siguiente semana.

------

## Paso 5: Documenta Tu Primer Día

Abre un archivo de texto. Escribe:

- Qué funcionó
- Qué no funcionó
- Qué comando usaste para arreglarlo
- Qué aprendiste

No para Instagram. Para ti. En tres meses, cuando estés en la entrevista técnica y te pregunten *"¿cómo hardenearías un servidor Linux?"*, vas a abrir ese archivo y vas a tener 50 respuestas reales, no teoría de libro.

------

## ¿Cuál es tu situación ahora?

Dime:

1. **¿Las 4 VMs pasaron el smoke test?** (SSH, internet, disco resize, repos)
2. **¿Ya creaste los snapshots base?**
3. **¿Quieres que te sugiera el primer ejercicio detallado de RHCSA**, o prefieres saltar directo a configurar `alma-security` para el módulo de hardening?



> ## Todas pasaron el smoke test y  snapshots creados. Prosigamos con el plan. Adelante con el primer ejercicio de RHCSA.



# 🎯 Misión 1: "El Administrador Heredó un Servidor"

## El Escenario

Llegas el lunes a tu nuevo trabajo. El administrador anterior renunció el viernes y dejó una VM `alma-rhcsa` con un servidor web Nginx instalado pero **sin configurar seguridad**. Tu jefe te da 3 requisitos:

> 1. *"Solo el equipo de desarrollo puede publicar contenido web."*
> 2. *"Nadie entra como root por SSH, y solo desde nuestra estación de administración."*
> 3. *"El servidor web debe servir contenido desde `/webdata`, no desde `/usr/share/nginx/html`."*

Este ejercicio no es un tutorial de Nginx. Es un ejercicio de **administración Linux integrada**. Toca 6 áreas del RHCSA en una sola sesión.

------

## 📋 Checklist Antes de Empezar



```bash
# En tu Bazzite host, verifica que estás en el snapshot limpio
virsh snapshot-list alma-rhcsa
# Debe mostrar: factory, ready

# Si no estás en 'ready', vuelve a él
virsh snapshot-revert alma-rhcsa ready
```

**Tiempo estimado:** 60-90 minutos.
**Si te atascas más de 20 minutos en un paso:** lee la pista. No mires la solución completa de inmediato.

------

## 🧩 Las 5 Tareas de la Misión

### Tarea 1: Usuarios y Grupos

Crea la estructura de acceso:

- Grupo `webdev` (los que publican)
- Usuario `dev01` (miembro de `webdev`)
- Usuario `operator` (no es miembro de `webdev`, solo opera servicios)
- Contraseñas: `Changeme2026!` para ambos (expiran en 90 días)

### Tarea 2: Directiva de Sudo

- `dev01` puede ejecutar **cualquier comando** como root (desarrollador senior).
- `operator` solo puede reiniciar y recargar Nginx. Nada más.

### Tarea 3: Hardening de SSH

- Root no puede entrar por SSH (ni por clave ni por password).
- Solo el usuario `labadmin` (el que creó cloud-init) y `dev01` pueden entrar.
- Autenticación por clave pública **obligatoria** para todos (deshabilita password auth).

### Tarea 4: Nginx en `/webdata` con SELinux

- Crea el directorio `/webdata` con permisos correctos.
- Configura Nginx para servir desde `/webdata` en lugar de `/usr/share/nginx/html`.
- **No desactives SELinux.** Enforcing debe permanecer activo. El sitio debe servirse sin errores de denegación.

### Tarea 5: Verificación Final

Desde tu Bazzite host:

1. `ssh dev01@<ip>` → debe funcionar con clave.
2. `sudo systemctl restart nginx` → debe funcionar sin pedir password (si configuraste NOPASSWD).
3. `curl http://<ip>` → debe mostrar el contenido de `/webdata/index.html`.
4. `ssh root@<ip>` → debe **rechazar** inmediatamente.
5. `ssh operator@<ip>` → `sudo systemctl restart nginx` funciona, pero `sudo whoami` **debe fallar**.

------



## 💡 Pistas por Tarea (Léelas solo si te atascas)

<details> <summary><b>Pista Tarea 1: Usuarios</b></summary>

- `groupadd`, `useradd -G`, `passwd`, `chage`
- El parámetro de expiración de contraseña se configura con `chage -M 90 <usuario>` o en `/etc/login.defs` (pero `chage` es inmediato para usuarios existentes).

</details>

<details> <summary><b>Pista Tarea 2: Sudo</b></summary>

- Crea archivos en `/etc/sudoers.d/`, no edites `/etc/sudoers` directamente.
- Para `operator`, necesitas restringir los argumentos de `systemctl`. Investiga la sintaxis `Cmnd_Alias` o la línea directa: `operator ALL=(ALL) /usr/bin/systemctl restart nginx, /usr/bin/systemctl reload nginx`
- `visudo -f /etc/sudoers.d/operator` valida sintaxis al guardar.

</details>

<details> <summary><b>Pista Tarea 3: SSH</b></summary>

- Archivo: `/etc/ssh/sshd_config`
- Directivas clave: `PermitRootLogin`, `PasswordAuthentication`, `AllowUsers`
- Después de editar: `systemctl restart sshd` (o `sshd` se reinicia solo en algunas configs, pero mejor forzar).
- **Trampa:** Si bloqueas a `labadmin` en `AllowUsers` y estás conectado como `labadmin`, tu sesión actual no se cae, pero la siguiente sí. Ten cuidado.

</details>

<details> <summary><b>Pista Tarea 4: SELinux + Nginx</b></summary>

- `semanage fcontext -a -t httpd_sys_content_t "/webdata(/.*)?"` → hace el cambio persistente.
- `restorecon -Rv /webdata` → aplica el contexto ahora.
- `setsebool -P httpd_enable_homedirs on` no es necesario aquí, pero investiga `httpd_sys_content_t`.
- Para mover el root de Nginx: edita `/etc/nginx/nginx.conf` o el default server block en `/etc/nginx/conf.d/default.conf`.
- No olvides `systemctl restart nginx` y revisar `journalctl -u nginx` si falla.

</details>



## ✅ Solución Paso a Paso (Lee solo al final)

<details> <summary><b>Desplegar solución completa</b></summary>

### Tarea 1



```bash
sudo groupadd webdev
sudo useradd -G webdev -m -s /bin/bash dev01
sudo useradd -m -s /bin/bash operator
echo "Changeme2026!" | sudo passwd --stdin dev01
echo "Changeme2026!" | sudo passwd --stdin operator
sudo chage -M 90 dev01
sudo chage -M 90 operator
```

### Tarea 2



```bash
sudo visudo -f /etc/sudoers.d/dev01
# Contenido:
dev01 ALL=(ALL) NOPASSWD: ALL

sudo visudo -f /etc/sudoers.d/operator
# Contenido:
operator ALL=(ALL) NOPASSWD: /usr/bin/systemctl restart nginx, /usr/bin/systemctl reload nginx
```

### Tarea 3

```bash
sudo sed -i 's/^#*PermitRootLogin.*/PermitRootLogin no/' /etc/ssh/sshd_config
sudo sed -i 's/^#*PasswordAuthentication.*/PasswordAuthentication no/' /etc/ssh/sshd_config
sudo sed -i 's/^#*PubkeyAuthentication.*/PubkeyAuthentication yes/' /etc/ssh/sshd_config
echo "AllowUsers labadmin dev01" | sudo tee -a /etc/ssh/sshd_config
sudo systemctl restart sshd
```

### Tarea 4

```bash
sudo mkdir -p /webdata
sudo tee /webdata/index.html << 'EOF'
<html><body><h1>Mision 1: Completada</h1></body></html>
EOF
sudo chown -R root:webdev /webdata
sudo chmod 2775 /webdata  # SGID para que archivos nuevos hereden grupo webdev
sudo semanage fcontext -a -t httpd_sys_content_t "/webdata(/.*)?"
sudo restorecon -Rv /webdata

# Editar Nginx
sudo sed -i 's|/usr/share/nginx/html|/webdata|g' /etc/nginx/nginx.conf
sudo sed -i 's|/usr/share/nginx/html|/webdata|g' /etc/nginx/conf.d/default.conf 2>/dev/null || true
sudo systemctl restart nginx
sudo systemctl enable nginx
```

### Tarea 5 (Verificación)



```bash
# Desde Bazzite:
ssh dev01@<ip> "sudo systemctl status nginx --no-pager"
curl http://<ip>
ssh root@<ip>  # Debe fallar
ssh operator@<ip> "sudo whoami"  # Debe fallar
ssh operator@<ip> "sudo systemctl restart nginx"  # Debe funcionar
```

</details>

------

## 📊 ¿Qué Áreas del RHCSA Cubriste Aquí?



| Área del Examen                     | Peso Aprox. | Tarea donde la practicaste |
| :---------------------------------- | :---------- | :------------------------- |
| Gestión de usuarios y grupos        | 10%         | Tarea 1                    |
| Sudoers avanzado                    | 10%         | Tarea 2                    |
| Configuración de SSH                | 10%         | Tarea 3                    |
| SELinux (contextos, booleans)       | 15%         | Tarea 4                    |
| Gestión de servicios (systemd)      | 10%         | Tarea 4                    |
| Permisos de archivos (SGID, grupos) | 10%         | Tarea 4                    |

**Total cubierto en una sola sesión:** ~65% de los objetivos operativos del RHCSA.

------

## 📝 Bitácora del Día 1

Escribe en tu archivo de notas:

1. ¿Qué comando te costó más recordar?
2. ¿Qué error te dio Nginx antes de funcionar? (`journalctl -u nginx` te lo dijo)
3. ¿Por qué `restorecon` fue necesario aunque `semanage fcontext` ya había configurado el tipo?

------

## 🚀 Próximo Paso

Cuando termines esta misión y la documentes, hay dos caminos:

- **Camino A (profundidad):** Misión 2 — Almacenamiento. LVM, particiones, montajes persistentes, ACLs extendidas, y quotas de disco.
- **Camino B (amplitud):** Misión 2 — Redes. `nmcli`, bonding, VLANs, `firewalld` zones, y port forwarding.

¿Cuál prefieres? O si quieres, te doy **ambas** y tú eliges el orden.



###  Antes de avanzar a la siguiente misión. 

---



> 1. Es necesario comprender la parte de semanage y restorecon. 
> 2. El acceso SSH con el usuario no es posible. se produce este mensaje: **operator@192.168.122.193: Permission denied (publickey,gssapi-keyex,gssapi-with-mic)**.



Hay **dos temas distintos** aquí. Vamos despacio, uno por uno, porque entenderlos te ahorrará horas de frustración en el futuro.

------

## 1. El Usuario `operator` y el Error de SSH

### ¿Qué está pasando exactamente?

Tu servidor SSH está configurado con tres restricciones que actúan como filtros en serie. Cuando intentas entrar como `operator`, la conexión muere antes de siquiera preguntarte por una contraseña. Esto es **por diseño**, no por bug.

Imagina la entrada de un edificio con tres guardias:

1. **Guardia "AllowUsers":** Tiene una lista de nombres. Si no estás en la lista, ni te deja pasar al vestíbulo. En tu configuración, la lista solo dice `labadmin` y `dev01`. `operator` no está.
2. **Guardia "PasswordAuthentication no":** Aunque pasaras el primero, este guardia dice "aquí no aceptamos passwords, solo tarjetas de acceso (claves SSH)". Ni siquiera mira passwords.
3. **Guardia "operator no tiene tarjeta":** El usuario `operator` fue creado con `useradd`, pero nunca se le generó un par de claves SSH ni se le copió una clave pública a su directorio `~/.ssh/authorized_keys`. No tiene "tarjeta de acceso".

El mensaje `Permission denied (publickey,gssapi-keyex,gssapi-with-mic)` es el servidor diciendo: *"Te ofrecí estos métodos de autenticación (clave pública, GSSAPI), tú no pudiste presentar una credencial válida, y no te voy a ofrecer password porque está desactivado. Adiós."*

### ¿Cómo se resuelve?

Tienes **dos filosofías** para `operator`:

**Opción A: Operator es remoto (puede entrar por SSH)** Si tu diseño de seguridad permite que `operator` administre el servidor desde tu estación Bazzite, debes hacer dos cosas:

- Añadir `operator` a la directiva `AllowUsers` en `/etc/ssh/sshd_config`.
- Colocar una **clave pública válida** en el archivo `/home/operator/.ssh/authorized_keys` dentro de la VM. Puedes copiar la misma clave pública que usas para `labadmin`, o generar un par nuevo.

**Opción B: Operator es local (más restrictivo, más realista)** En muchas empresas, `operator` es una cuenta de servicio que nunca entra por red. Solo se usa cuando alguien con más privilegios (como `dev01`) hace `su - operator` para ejecutar tareas específicas. En ese caso, `operator` **no debería estar en `AllowUsers`**, y la verificación del ejercicio se hace directamente en la consola de la VM, no desde Bazzite.



> **Mi error de diseño en el ejercicio:** Te pedí verificar `ssh operator@<ip>` en la Tarea 5, pero en la Tarea 3 solo permití `labadmin` y `dev01`. Esa inconsistencia es mía. Elige la opción que prefieras para tu Laboratorio.




------

## 2. `semanage fcontext` vs `restorecon`

Este es el corazón de SELinux. Piensa en SELinux como un **sistema de permisos que no mira usuarios, mira etiquetas**.

### El Problema que Resuelven

Cuando creaste el directorio `/webdata`, el sistema le puso una etiqueta por defecto. Probablemente algo como `unlabeled_t` o `default_t`. Nginx, por su parte, corre con una etiqueta de proceso llamada `httpd_t`.

SELinux tiene una regla interna que dice: *"El proceso `httpd_t` puede leer archivos etiquetados como `httpd_sys_content_t`, pero NO puede leer archivos `default_t` o `unlabeled_t`."*

Entonces, aunque los permisos de Unix (`chmod 777`) digan "todo el mundo puede leer", SELinux dice: *"Yo no conozco a 'todo el mundo'. Conozco etiquetas. Y esta etiqueta me dice que no debo dejar pasar a Nginx."*

### ¿Qué hace `semanage fcontext`?

Es el **urbanizador**. Es la autoridad que cambia la zonificación del terreno.

Cuando ejecutas:

```plain
semanage fcontext -a -t httpd_sys_content_t "/webdata(/.*)?"
```

lo que estás haciendo es escribir en la base de datos permanente de SELinux (el archivo `/etc/selinux/targeted/contexts/files/file_contexts.local`). Estás diciendo:

> *"A partir de ahora, todo archivo o directorio que se cree dentro de `/webdata` debe considerarse territorio de servidores web. Su etiqueta por defecto será `httpd_sys_content_t`."*

**Pero aquí está el truco:** `semanage` no toca los archivos que ya existen. Es una regla para el futuro. Es como cambiar la ley de tránsito: la ley nueva no le quita las multas pasadas a los conductores.

### ¿Qué hace `restorecon`?

Es el **inspector que pega etiquetas**. Recorre el directorio y le pregunta a la base de datos de `semanage`: *"¿Qué etiqueta le corresponde a este archivo?"* Y luego pega la etiqueta físicamente en el archivo.

Cuando ejecutas:



```plain
restorecon -Rv /webdata
```

estás diciendo:

> *"Ve a `/webdata`, revisa cada archivo y directorio contra las reglas del urbanizador, y ponles la etiqueta correcta."*

El flag `-R` es **recursivo** (entra en subdirectorios). El flag `-v` es **verbose** (te muestra qué cambió).

### La Analogía del Barrio

Imagina que compras una casa en una calle que antes era industrial y ahora es residencial.

- **`semanage fcontext`** = El ayuntamiento cambia la ley: *"Esta calle es residencial"*. Eso afecta a las casas que se construyan mañana. Pero tu casa, construida ayer, sigue sin número y sin buzón.
- **`restorecon`** = El cartero municipal pasa casa por casa y pone el número y el buzón según la nueva ley. Ahora tu casa tiene la etiqueta correcta.
- **Archivos nuevos después de `semanage`** = Si mañana construyes un garaje, ya sale con número y buzón automáticamente, porque la ley del ayuntamiento está vigente.

### ¿Por qué necesitas ambos?



| Si solo haces `semanage`                                     | Si solo haces `restorecon`                                   |
| :----------------------------------------------------------- | :----------------------------------------------------------- |
| Los archivos nuevos en `/webdata` tendrán la etiqueta correcta. | Los archivos actuales quedan bien.                           |
| Pero `index.html` (que ya existía) sigue con la etiqueta vieja. Nginx sigue sin poder leerlo. | Pero si reinicias y SELinux re-etiqueta todo el sistema (`touch /.autorelabel`), perderás el cambio porque no está en la base de datos permanente. |
| **Resultado:** Nginx falla ahora, pero funcionaría si recrearas el archivo. | **Resultado:** Funciona ahora, pero puede romperse tras un reboot o autorelabel. |

**Por eso el orden siempre es:**

1. Crear el directorio y archivos.
2. `semanage fcontext` (la ley nueva).
3. `restorecon` (aplicar la ley a lo existente).

### ¿Cómo verificas que quedó bien?

Dentro de la VM, ejecuta:

```plain
ls -Z /webdata
```

Debes ver algo como:

```plain
system_u:object_r:httpd_sys_content_t:s0 index.html
```

Y si miras el proceso de Nginx:



```plain
ps -eZ | grep nginx
```

Debes ver:

```plain
system_u:system_r:httpd_t:s0 nginx
```

Cuando el proceso (`httpd_t`) y el archivo (`httpd_sys_content_t`) comparten la "familia" `httpd`, SELinux permite la lectura. Si ves `default_t` o `unlabeled_t` en el archivo, SELinux está bloqueando.

------

## ¿Qué Hacer Ahora?

Te propongo dos caminos:

**Si quieres seguir el ejercicio al pie de la letra:** Arregla el acceso de `operator` añadiéndolo a `AllowUsers` y dándole una clave pública. Luego verifica que `sudo systemctl restart nginx` funcione y `sudo whoami` falle.

**Si quieres entender más antes de tocar:** Dime si la analogía del urbanizador te ayudó a visualizar `semanage`/`restorecon`, y si prefieres que `operator` sea un usuario remoto o local en tu lab. Con eso ajustamos el ejercicio y pasamos a la siguiente misión.

¿Te quedó clara la diferencia entre la "ley" (`semanage`) y el "pegado de etiquetas" (`restorecon`)?

