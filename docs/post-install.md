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