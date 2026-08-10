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
ansible-playbook -i inventory.yml update_repos.yml
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
ansible-playbook -i inventory.yml update_system.yml
```



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

