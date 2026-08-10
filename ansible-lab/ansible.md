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

## 🎯 Conclusión 

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
alma-alma-security ansible_host=192.168.122.149

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

#### inventory.ini      

```
[targets]
alma-rhcsa ansible_host=192.168.122.193
alma-target-02 ansible_host=192.168.122.67
alma-alma-security ansible_host=192.168.122.149

[production]
alma-rhcsa
alma-target-02

[security]
alma-alma-security

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



**Uso con grupos:**

```
# Actualizar solo producción
ansible-playbook -i inventory.ini update_system.yml -l production

# Actualizar solo servidores de seguridad
ansible-playbook -i inventory.ini update_system.yml -l security

# Actualizar todos
ansible-playbook -i inventory.ini update_system.yml
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

## 📝 Playbook Modificado para Soporte de Tags

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
ansible-playbook -i inventory.ini update_repos.yml --limit alma-target-02 --check

# 2. Ejecutar en modo prueba (dry-run)
ansible-playbook -i inventory.ini update_system.yml --limit alma-target-02 --check

# 3. Si todo OK, ejecutar en producción
ansible-playbook -i inventory.ini update_system.yml --limit alma-rhcsa,alma-target-02
```



### Escenario 2: Actualizar solo un host específico



```
# Actualizar solo el servidor de seguridad
ansible-playbook -i inventory.ini update_system.yml --limit alma-alma-security
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

------

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
