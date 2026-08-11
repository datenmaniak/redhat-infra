# Actualizar sistema y repositorios

Para automatizar las tareas repetitivas, los playbooks adaptados para sistemas basados en Red Hat (RHEL, CentOS, Fedora, Rocky Linux, AlmaLinux).



## 🎯 Propósito de Cada Playbook



### **ACTUALIZACIÓN PREVENTIVA / MANTENIMIENTO LIGERO**

- **Objetivo**: Sincronizar repositorios y limpiar caché **SIN actualizar paquetes**
- **Cuándo usarlo**:
  - Antes de instalar un nuevo paquete
  - Como mantenimiento programado rápido (ej: diario)
  - Para refrescar la lista de paquetes disponibles
  - En entornos de producción donde no quieres cambios en los paquetes
- **Riesgo**: Muy bajo (no modifica paquetes instalados)
- **Tiempo de ejecución**: Rápido (segundos)



```bash
# pega el contenido
nano ./ansible-lab/update_repos.yml
```

 ### Descargar el playbook:

​	  [update_repos.yml](../ansible-lab/update_repos.yml)

```yml
---
- name: Mantenimiento Ligero - Actualizar Repositorios (Red Hat)
  hosts: all
  become: yes
  serial: 1  # Mantenido por consistencia

  tasks:
    - name: 1. Actualizar caché de repositorios
      dnf:
        update_cache: yes
      # Este módulo ya maneja los códigos de retorno correctamente

    - name: 2. Limpieza de caché antigua
      dnf:
        clean: all

    - name: 3. Verificar actualizaciones disponibles
      command: dnf check-update
      register: updates_available
      changed_when: updates_available.rc == 100
      failed_when: updates_available.rc not in [0, 100]

    - name: 4. Reportar estado
      debug:
        msg: |
          {{ inventory_hostname }} - Repositorios sincronizados
          {% if updates_available.rc == 100 %}
          ⚠️ Hay {{ updates_available.stdout_lines | length }} actualizaciones disponibles
          {% else %}
          ✅ Sistema actualizado
          {% endif %}
```

#### Corrida:

```bash 
ansible-playbook -i inventory.ini update_repos.yml
```



---

### **ACTUALIZACIÓN COMPLETA / MANTENIMIENTO PESADO**

- **Objetivo**: Actualizar TODOS los paquetes del sistema
- **Cuándo usarlo**:
  - Parches de seguridad críticos
  - Mantenimiento programado (ej: mensual)
  - Después de un `update_repos.yml` para aplicar actualizaciones
  - En ventanas de mantenimiento planificadas
- **Riesgo**: Medio-Alto (puede reiniciar servicios, romper compatibilidades)
- **Tiempo de ejecución**: Lento (minutos, depende de las actualizaciones)


```bash
# pega el contenido
nano ./ansible-lab/update_system.yml
```

###  Descargar el playbook:

​	   [update_system.yml](../ansible-lab/update_system.yml)

```yaml
---
- name: Mantenimiento Completo - Actualizar Sistema (Red Hat)
  hosts: all
  become: yes
  serial: 1  # ¡CRÍTICO! Proteger el clúster

  tasks:
    - name: 1. Actualizar todos los paquetes
      dnf:
        name: '*'
        state: latest
        update_cache: yes
        autoremove: yes  # Ya integrado en una sola tarea
      register: upgrade_result

    - name: 2. Verificar si requiere reinicio
      command: needs-restarting -r
      register: reboot_check
      failed_when: False
      changed_when: reboot_check.rc == 1

    - name: 3. Alertar sobre reinicio necesario
      debug:
        msg: |
          ⚠️ {{ inventory_hostname }} REQUIERE REINICIO
          Motivo: Actualizaciones de Kernel o bibliotecas críticas
      when: reboot_check.rc == 1

    - name: 4. Limpiar caché (post-actualización)
      dnf:
        clean: all
```

#### Corrida:

```bash 
ansible-playbook -i inventory.ini update_system.yml
```



> ##  La actualización se aplica a todos las VMs  para ambas corridas







---

## 📋 Resumen de funciones principales

| Concepto                | Ubuntu (APT)               | Red Hat (DNF/YUM)             |
| :---------------------- | :------------------------- | :---------------------------- |
| Actualizar repositorios | `apt update_cache: yes`    | `command: dnf check-update`   |
| Actualizar paquetes     | `apt upgrade: yes`         | `dnf name: '*' state: latest` |
| Autoremove              | `apt autoremove: yes`      | `dnf autoremove: yes`         |
| Limpiar caché           | `apt autoclean: yes`       | `dnf clean: all`              |
| Purge configs           | `purge: yes`               | No existe equivalente directo |
| Verificar reinicio      | `/var/run/reboot-required` | `needs-restarting -r`         |

------

## 🔧 Notas adicionales

1. **DNF vs YUM**: En sistemas Red Hat modernos (RHEL 8+, Fedora 22+) se usa DNF. Para versiones antiguas, cambiar `dnf` por `yum`.
2. **Serial: 1**: Mantenido en ambos playbooks para actualizar servidores de uno en uno y proteger el clúster.
3. **Verificación de reinicio**: Añadí dos métodos complementarios para detectar si el sistema necesita reinicio.
4. **Módulo dnf**: Ansible incluye el módulo `dnf` (equivalente al módulo `apt`) que facilita la gestión de paquetes en Red Hat.
5. **cache_valid_time**: No tiene equivalente directo en DNF, por eso realicé el `check-update` como paso separado.
6. **RC Codes en DNF**:
   - `rc=0`: Sin actualizaciones disponibles
   - `rc=100`: Actualizaciones disponibles




---



## 🔄 Flujo de Trabajo Recomendado



```
1. Ejecutar **update_repos.yml** (diario/antes de instalar)
   ↓
2. Evaluar qué paquetes tienen actualizaciones
   ↓
3. Ejecutar **update_system.yml** (en ventana de mantenimiento)
   ↓
4. Validar que todo funciona correctamente
```



> ### Se encuentra alguna  redundancia en estos playbooks o cada uno cumple con su propósito? 





## 📊 Cuándo Usar Cada Playbook

| Escenario                                   | Usar                |
| :------------------------------------------ | :------------------ |
| Instalar un nuevo paquete                   | `update_repos.yml`  |
| Revisar si hay actualizaciones disponibles  | `update_repos.yml`  |
| Mantenimiento diario (no disruptivo)        | `update_repos.yml`  |
| Parche de seguridad crítico                 | `update_system.yml` |
| Mantenimiento mensual planificado           | `update_system.yml` |
| Preparar servidor para nuevo entorno        | `update_system.yml` |
| CI/CD Pipeline (antes de deployments)       | `update_repos.yml`  |
| Post-deployment (verificar actualizaciones) | `update_system.yml` |

------

### 🎯 Conclusión acerca de los playbooks

**NO son redundantes**, pero tienen **solapamiento mínimo** que puede optimizarse:

1. **Redundancia aceptable**: `clean` en ambos (necesario antes/después)
2. **Redundancia eliminable**: `autoremove` duplicado en `update_system.yml`
3. **Redundancia innecesaria**: `check-update` previo a `upgrade`

**Recomendación**: Mantén ambos playbooks, pero **especializa sus funciones**:

- `update_repos.yml`: Solo sincroniza y limpia (rápido, seguro)
- `update_system.yml`: Actualiza todo (pesado, planificado)





> ## Qué se necesita para ejecutar cualquier de los  playbook a determinado host?



**inventory.ini**

```yml
[targets]
alma-rhcsa ansible_host=192.168.122.193
alma-target-02 ansible_host=192.168.122.67
alma-security ansible_host=192.168.122.149
freeipa-lab  ansible_host=192.168.122.143

[targets:vars]
ansible_user=labadmin
ansible_ssh_private_key_file=~/.ssh/datenmaniak
ansible_python_interpreter=/usr/bin/python3

```



## 📋 Análisis del Inventario y Ejecución Selectiva

Tu inventario está bien estructurado. Te explico cómo ejecutar los playbooks en hosts específicos:

------

## 🎯 Formas de Ejecutar Playbooks en Hosts Específicos



### 1. **Usando `--limit` (MÁS COMÚN)**

```
# Ejecutar en un solo host
ansible-playbook -i inventory.ini update_repos.yml --limit alma-rhcsa

# Ejecutar en múltiples hosts específicos
ansible-playbook -i inventory.ini update_repos.yml --limit alma-rhcsa,alma-target-02

# Ejecutar en todos excepto uno
ansible-playbook -i inventory.ini update_repos.yml --limit '!alma-rhcsa'

# Ejecutar en un patrón (ej: todos los que empiezan con alma-)
ansible-playbook -i inventory.ini update_repos.yml --limit 'alma-*'
```



### 2. **Usando `--hosts` (Alternativa menos usada)**

```
# Especificar directamente el host
ansible-playbook -i inventory.ini update_repos.yml --hosts alma-rhcsa
```

### 3. **Usando `-l` (abreviatura de --limit)**



```
# Forma abreviada
ansible-playbook -i inventory.ini update_repos.yml -l alma-rhcsa
```



### 4. **Usando tags (si agregas tags a tus tareas)**

```
# Ejecutar solo tareas con tag específico
ansible-playbook -i inventory.ini update_repos.yml --tags "clean"
```



------

## 🔧 Mejoras para tu Inventario

### **Opción A: Crear Grupos para Mayor Flexibilidad**

#### inventory-grouped.ini      

```
[targets]
alma-rhcsa ansible_host=192.168.122.193
alma-target-02 ansible_host=192.168.122.67
alma-security ansible_host=192.168.122.149
freeipa-lab  ansible_host=192.168.122.143

[rhcsa]
alma-rhcsa

[rhce]
alma-target-02

[security]
alma-security

[production]
alma-rhcsa
alma-target-02

[freeipa]
freeipa-lab

[all:vars]
ansible_user=labadmin
ansible_ssh_private_key_file=~/.ssh/datenmaniak
ansible_python_interpreter=/usr/bin/python3

# Variables específicas por grupo
[production:vars]
update_serial=1  # Actualizar de a uno en producción

[security:vars]
update_serial=3  # En seguridad podemos actualizar de a 3
```



​	📝    **[Explicación de los nombres de host](../docs/roadmap.md#2-arquitectura-de-vms-para-16-gb-ram--6-cores)**



**Actualización de los repositorios usando los  grupos:**

```
# Actualizar solo producción
ansible-playbook -i inventory-grouped.ini update_repos.yml -l production

# Actualizar solo servidores de seguridad
ansible-playbook -i inventory-grouped.ini update_repos.yml -l security  

# Actualizar solo servidor principal
ansible-playbook -i inventory-grouped.ini update_repos.yml -l rhcsa

# Actualizar todos
ansible-playbook -i inventory-grouped.ini update_repos.yml
```



------

### **Opción B: Usar Variables de Host para Control Fino**

#### inventory.ini     

```
[targets]
alma-rhcsa ansible_host=192.168.122.193 update_window=maintenance
alma-target-02 ansible_host=192.168.122.67 update_window=maintenance
alma-alma-security ansible_host=192.168.122.149 update_window=critical

[targets:vars]
ansible_user=labadmin
ansible_ssh_private_key_file=~/.ssh/datenmaniak
ansible_python_interpreter=/usr/bin/python3
```



**En el playbook:**



```
---
- name: Actualizar solo hosts en ventana crítica
  hosts: all
  become: yes
  serial: 1
  when: update_window == 'critical'  # Solo ejecuta en alma-alma-security
  tasks:
    - name: Actualizar sistema
      dnf:
        name: '*'
        state: latest
```



------

## 📝 Playbook Modificado para Soporte de Tags (opcional)

Agrega tags para mayor control:



```
---
- name: Mantenimiento Ligero - Actualizar Repositorios (Red Hat)
  hosts: all
  become: yes

  tasks:
    - name: 1. Actualizar caché de repositorios
      dnf:
        update_cache: yes
      tags: 
        - update
        - cache

    - name: 2. Limpieza de caché antigua
      command: dnf clean all
      register: clean_result
      changed_when: "'0 files removed' not in clean_result.stdout"
      tags:
        - clean
        - maintenance

    - name: 3. Verificar actualizaciones disponibles
      command: dnf check-update
      register: updates_available
      changed_when: updates_available.rc == 100
      failed_when: updates_available.rc not in [0, 100]
      tags:
        - check
        - audit

    - name: 4. Reportar estado
      debug:
        msg: |
          {{ inventory_hostname }} - Repositorios sincronizados
          {% if updates_available.rc == 100 %}
          ⚠️ Hay {{ updates_available.stdout_lines | length }} actualizaciones disponibles
          {% else %}
          ✅ Sistema actualizado
          {% endif %}
      tags:
        - report
        - always
```



**Uso con tags:**

```
# Solo limpiar caché en un host específico
ansible-playbook -i inventory.ini update_repos.yml -l alma-rhcsa --tags clean

# Solo verificar actualizaciones disponibles
ansible-playbook -i inventory.ini update_repos.yml -l alma-target-02 --tags check

# Ejecutar todo excepto limpieza
ansible-playbook -i inventory.ini update_repos.yml --skip-tags clean
```



------

## 🚀 Ejemplos Prácticos de Ejecución

### Escenario 1: Probar en un solo host antes de producción



```
# 1. Verificar sintaxis
ansible-playbook -i inventory-grouped.ini update_repos.yml --limit alma-target-02 --check

# 2. Ejecutar en modo prueba (dry-run)
ansible-playbook -i inventory-grouped.ini update_system.yml --limit alma-target-02 --check

# 3. Si todo OK, ejecutar en producción
ansible-playbook -i inventory-grouped.ini update_system.yml -l production


```



### Escenario 2: Actualizar solo un host específico



```
# Actualizar solo el servidor de seguridad
ansible-playbook -i inventory.ini update_system.yml --limit alma-security
```



### Escenario 3: Ejecutar secuencialmente con confirmación



```
# Con paso a paso (pregunta antes de cada host)
ansible-playbook -i inventory.ini update_system.yml --step --limit alma-rhcsa
```



### Escenario 4: Usar archivo de hosts alternativo



```
# Si tienes diferentes inventarios para diferentes entornos
ansible-playbook -i inventory-prod.ini update_system.yml --limit '!alma-rhcsa'
```



### Escenario 5: Trabajar por grupos

```bash
#  Ejecutar en modo prueba para Produccion (dry-run)
ansible-playbook -i inventory-grouped.ini update_system.yml -l production  --check
# aplicar
ansible-playbook -i inventory-grouped.ini update_system.yml -l production  

# actualizar el repositorio en el host de seguridad
ansible-playbook -i inventory-grouped.ini update_repo.yml -l security  

```
### Escenario 5:  📋 Verificación Rápida



```
# Verificar paquetes instalados en el host
ansible -i inventory-grouped.ini alma-rhcsa \
-m command -a "rpm -q vim nano tmux bash-completion bind-utils net-tools"

# Verificar tmux específicamente
ansible -i inventory-grouped.ini alma-rhcsa -m command -a "tmux -V"

# Verificar si EPEL está instalado en el host alma-rhcsa
ansible -i inventory-grouped.ini alma-rhcsa -m command -a "rpm -q epel-release"

# Ejecutar la instalacion de paquetes esenciales en modo (dry-run) --check
 ansible-playbook -i inventory-grouped.ini -l rhcsa postinstall_essentials_install.yml --check
 
# Verificar previamente antes de instalar paquetes para los grupos: production & security
ansible-playbook -i inventory-grouped.ini -l production,security postinstall_essentials_install.yml --check
 


```



## Playbook: Instalación de paquetes esenciales

#### postinstall_essentials_install.yml

```yml
---
- name: Configuración de Herramientas Esenciales
  hosts: all
  become: yes
  serial: 1

  vars:
    base_tools:
      - vim
      - nano
      - tmux
      - bash-completion
      - bind-utils
      - net-tools
      - tree
      - git
      - wget
      - curl
      - telnet
      - traceroute
      - policycoreutils-python-utils
      - setools-console 

    extra_tools:
      - neovim
      - htop

  tasks:
    # Tarea 1: Actualizar repositorios
    - name: Actualizar caché de repositorios
      dnf:
        update_cache: yes

    # Tarea 2: Instalar herramientas base
    - name: Instalar herramientas base
      dnf:
        name: "{{ base_tools }}"
        state: present
      register: base_result

    # Tarea 3: Intentar instalar EPEL
    - name: Instalar EPEL release (para paquetes extra)
      dnf:
        name: epel-release
        state: present
      register: epel_result
      ignore_errors: yes

    # Tarea 4: Actualizar caché nuevamente (con EPEL)
    - name: Actualizar caché con EPEL
      dnf:
        update_cache: yes
      when: epel_result is success

    # Tarea 5: Instalar paquetes extra (si EPEL está disponible)
    - name: Instalar paquetes extra desde EPEL
      dnf:
        name: "{{ extra_tools }}"
        state: present
      when: epel_result is success
      register: extra_result
      ignore_errors: yes

    # Tarea 6: Verificar instalación de tmux
    - name: Verificar tmux
      command: tmux -V
      register: tmux_check
      changed_when: False
      failed_when: False

    # Tarea 7: Resumen final
    - name: Mostrar resumen de instalación
      debug:
        msg: |
          ✅ {{ inventory_hostname }} - Instalación completada
          ================================================
          
          📦 Herramientas base ({{ base_tools | length }}):
          {% for tool in base_tools %}
          ✅ {{ tool }}
          {% endfor %}
          
          {% if epel_result is success %}
          📦 Herramientas extra (EPEL):
          {% for tool in extra_tools %}
          ✅ {{ tool }}
          {% endfor %}
          {% else %}
          ⚠️ EPEL no disponible - paquetes extra omitidos
          {% endif %}
          
          {% if tmux_check.rc == 0 %}
          ✅ tmux {{ tmux_check.stdout }} - OK
          {% else %}
          ❌ tmux NO INSTALADO
          {% endif %}
```



## 🎓 Explicación del Playbook (Sin Código)

Vamos a imaginar que tienes 3 máquinas virtuales (VMs) recién instaladas con AlmaLinux. Están "vacías": solo tienen el sistema operativo base, sin herramientas adicionales.

Este playbook es como un **"asistente automático de configuración"** que va a entrar a cada VM por SSH y va a hacer lo mismo en todas.

------

### 📋 **Paso 1: ¿A quién va dirigido?**

El playbook tiene una sección que dice "hosts: all". Eso significa que cuando lo ejecutes, Ansible va a buscar en tu archivo de inventario (donde están las direcciones IP de tus VMs) y va a intentar conectarse a **TODAS** las VMs que encuentre ahí.

**En términos simples**: Es como si tuvieras una lista de direcciones y enviaras un mensajero a todas ellas.

------

### 🔐 **Paso 2: Permisos de administrador**

El playbook tiene "become: yes". Esto es como decir: "Cuando entres a la VM, hazlo con permisos de root (administrador)".

**¿Por qué?** Porque instalar software requiere permisos especiales, como cuando en Windows necesitas dar clic en "Sí" para instalar un programa.

------

### ⚙️ **Paso 3: ¿Qué va a instalar?**

El playbook tiene una lista de herramientas que va a instalar en **todas** las VMs. Piensa en esto como una "lista de compras":

- **Editores de texto**: vim y nano (para poder editar archivos de configuración).
- **tmux**: Una herramienta súper importante que te permite tener "sesiones persistentes". Imagina que estás haciendo un laboratorio largo, te tienes que ir, cierras la terminal, y al volver, todo sigue exactamente como lo dejaste. ¡Es mágico!
- **bash-completion**: Cuando escribes comandos largos y presionas "TAB", te autocompleta. Ahorra muchísimo tiempo.
- **Herramientas de red**: Como `dig` y `nslookup` (para consultar DNS) y `net-tools` (para comandos como `ifconfig` que aunque son viejos, aparecen en exámenes).
- **Otras utilidades**: Como `git` para clonar repositorios, `wget` y `curl` para descargar archivos, etc.

**En términos simples**: Es como ir al supermercado con una lista y comprar todo lo que necesitas.

------

### 🔄 **Paso 4: Actualización de repositorios**

Antes de instalar cualquier cosa, el playbook ejecuta un comando que actualiza la "lista de productos disponibles" en la VM.

**Imagina**: Es como si fueras a comprar a una tienda y antes de pedir, revisas el catálogo actualizado para saber qué tienen en stock.

------

### 📦 **Paso 5: Instalación en dos fases**

El playbook divide la instalación en dos grupos:

1. **Paquetes base**: Son los que están en los repositorios "oficiales" de AlmaLinux. Estos siempre se pueden instalar sin problemas.
2. **Paquetes extra**: Como `neovim` y `htop`, que no están en los repositorios oficiales. Para esto, el playbook primero intenta instalar un repositorio adicional llamado **EPEL** (Extra Packages for Enterprise Linux).

**Imagina**: EPEL es como una "tienda especializada" que tiene productos que no venden en la tienda principal.

------

### 🛠️ **Paso 6: Manejo de errores inteligente**

Aquí viene una parte interesante. El playbook está diseñado para **no fallar** si un paquete no se encuentra.

- Si EPEL no está disponible o no se puede instalar, el playbook **ignora ese error** y continúa con el resto.
- Esto es muy útil porque no quieres que todo el proceso falle solo porque un paquete no está disponible en una VM específica.

**En términos simples**: Es como ir a comprar y si no encuentran un producto en la lista, compran todo lo demás y solo te avisan que ese producto no estaba.

------

### 📊 **Paso 7: Resumen final**

Al finalizar, el playbook te muestra un resumen de:

- Qué paquetes se instalaron correctamente.
- Cuáles no se pudieron instalar (si es que hubo alguno).
- El estado de `tmux`, que es una herramienta crítica para laboratorios.

**Es como**: Al salir del supermercado, revisas la factura para ver qué compraste y qué faltó.

------

### 🚦 **Paso 8: Control de ejecución**

El playbook tiene `serial: 1`, que significa que **actualiza una VM a la vez**, no todas en paralelo.

**¿Por qué?** Imagina que tienes 3 servidores que trabajan juntos (un clúster). Si actualizas los 3 al mismo tiempo y algo sale mal, podrías perder todo. En cambio, actualizas uno, verificas que funciona, luego el siguiente, y así sucesivamente.

**Es como**: Cambiar las llantas de un auto: no levantas el auto completo, cambias una llanta a la vez.

------

### 🧪 **Paso 9: Modo "prueba"**

El playbook puede ejecutarse con la bandera `--check`, que significa "simula lo que harías, pero no lo hagas realmente". Es como un **"ensayo general"** sin riesgos.

------

## 🎯 **¿Qué logras al final?**

Al terminar de ejecutar el playbook en todas tus VMs:

1. **Todas tienen exactamente las mismas herramientas**. No importa si es la VM 1, 2 o 3, todas quedan idénticas. ¡Adiós a la inconsistencia!
2. **Ahorraste muchísimo tiempo**. En lugar de instalar herramienta por herramienta manualmente en 3 VMs (lo que tomaría como 30 minutos), el playbook lo hace en **menos de 2 minutos**.
3. **Es repetible**. Si mañana agregas una VM 4, ejecutas el mismo playbook y queda configurada exactamente igual que las demás.
4. **Documentación viva**. El playbook en sí mismo es la documentación de lo que debe tener cada servidor.

------

## 🧠 **Analogía Final**

Imagina que eres el encargado de preparar 10 computadoras para un examen de certificación. Sin Ansible:

1. Enciendes la PC 1.
2. Instalas vim, nano, tmux, etc.
3. Repites en PC 2.
4. Repites en PC 3...
5. ¡Error! En PC 7 te olvidaste de instalar `git`.
6. Ahora tienes computadoras inconsistentes.

**Con Ansible**: Escribes el playbook una vez, lo ejecutas en las 10 PCs al mismo tiempo, y todas quedan **idénticas, perfectamente configuradas, y documentadas**. Si alguien te pregunta "¿qué herramientas tienen las VMs?", solo le muestras el playbook.






------

## 📊 Matriz de Control de Ejecución

| Comando                              | Efecto                                 |
| :----------------------------------- | :------------------------------------- |
| `--limit alma-rhcsa`                 | Solo en alma-rhcsa                     |
| `--limit alma-*`                     | Todos los que empiezan con alma-       |
| `--limit '!alma-rhcsa'`              | Todos EXCEPTO alma-rhcsa               |
| `--limit @hosts.txt`                 | Hosts listados en archivo hosts.txt    |
| `--limit production`                 | Todos los del grupo production         |
| `--limit alma-rhcsa:!alma-target-02` | Alma-rhcsa pero no alma-target-02      |
| `--limit alma-rhcsa,&security`       | Alma-rhcsa Y también en grupo security |
| `-l production,security`       | A los grupos: production y  security |
| `-m command -a`       | Envía un comando sin acceder a la VM |



----





## 🛠️ Script Auxiliar para Ejecución Selectiva

```bash

nano  run-update.sh
# pega el contenido del script `run-update.sh`:
```



```
#!/bin/bash
# Script para ejecutar actualizaciones selectivas

INVENTORY="inventory.ini"
PLAYBOOK="update_system.yml"

case "$1" in
  "prod")
    echo "Actualizando servidores de producción..."
    ansible-playbook -i $INVENTORY $PLAYBOOK --limit alma-rhcsa,alma-target-02
    ;;
  "sec")
    echo "Actualizando servidor de seguridad..."
    ansible-playbook -i $INVENTORY $PLAYBOOK --limit alma-alma-security
    ;;
  "all")
    echo "Actualizando TODOS los servidores..."
    ansible-playbook -i $INVENTORY $PLAYBOOK
    ;;
  "test")
    echo "Ejecutando prueba en alma-target-02..."
    ansible-playbook -i $INVENTORY $PLAYBOOK --limit alma-target-02 --check
    ;;
  *)
    echo "Uso: $0 {prod|sec|all|test}"
    exit 1
    ;;
esac
```



```
chmod +x run-update.sh
./run-update.sh prod  # Actualiza solo producción
./run-update.sh test  # Prueba en alma-target-02
```



------

## ✅ Resumen

Con tu inventario actual, ya puedes ejecutar en hosts específicos usando `--limit`. Lo que necesitas **definir** es:

1. **Estrategia de actualización**: ¿Todos? ¿Uno a uno? ¿Grupos?
2. **Ventanas de mantenimiento**: ¿Cuándo actualizar qué servidores?
3. **Tags**: Para tener control granular de qué tareas ejecutar

¿Te gustaría que cree un inventario más detallado con grupos específicos para tu caso de uso?
