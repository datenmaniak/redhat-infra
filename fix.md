❯ ansible-playbook -i inventory-grouped.ini -l rhcsa setup_basic_tools_epel.yml

PLAY [Configuración Inicial - Actualizar Sistema e Instalar Herramientas Esenciales] *************

TASK [Gathering Facts] ***************************************************************************
ok: [alma-rhcsa]

TASK [1. Mostrar información del sistema] ********************************************************
[WARNING]: Deprecation warnings can be disabled by setting `deprecation_warnings=False` in ansible.cfg.
[DEPRECATION WARNING]: INJECT_FACTS_AS_VARS default to `True` is deprecated, top-level facts will not be auto injected after the change. This feature will be removed from ansible-core version 2.24.
Origin: /var/home/dk/proyectos/redhat-infra/ansible-lab/setup_basic_tools_epel.yml:30:14

28     - name: 1. Mostrar información del sistema
29       debug:
30         msg: |
                ^ column 14

Use `ansible_facts["fact_name"]` (no `ansible_` prefix) instead.

ok: [alma-rhcsa] => {
    "msg": "📋 Configurando: alma-rhcsa\n🖥️  Distribución: AlmaLinux 9.8\n"
}

TASK [2. Verificar si EPEL está instalado] *******************************************************
ok: [alma-rhcsa]

TASK [3. Instalar EPEL repository] ***************************************************************
changed: [alma-rhcsa]

TASK [4. Habilitar EPEL repository (si es necesario)] ********************************************
changed: [alma-rhcsa]

TASK [5. Actualizar caché de repositorios (con EPEL)] ********************************************
ok: [alma-rhcsa]

TASK [6. Instalar paquetes base] *****************************************************************
changed: [alma-rhcsa]

TASK [7. Instalar paquetes desde EPEL] ***********************************************************
[ERROR]: Task failed: Module failed: argument 'name' is of type NoneType and we were unable to convert to list: <class 'NoneType'> cannot be converted to a list
Origin: /var/home/dk/proyectos/redhat-infra/ansible-lab/setup_basic_tools_epel.yml:68:7

66       tags: [install, base]
67
68     - name: 7. Instalar paquetes desde EPEL
         ^ column 7

fatal: [alma-rhcsa]: FAILED! => {"changed": false, "msg": "argument 'name' is of type NoneType and we were unable to convert to list: <class 'NoneType'> cannot be converted to a list"}
...ignoring

TASK [8. Verificar instalación completa] *********************************************************
[ERROR]: Task failed: Finalization of task args for 'ansible.builtin.debug' failed: Error while resolving value for 'msg': Error rendering template: 'NoneType' object is not iterable

Task failed.
Origin: /var/home/dk/proyectos/redhat-infra/ansible-lab/setup_basic_tools_epel.yml:76:7

74       tags: [install, epel]
75
76     - name: 8. Verificar instalación completa
         ^ column 7

<<< caused by >>>

Finalization of task args for 'ansible.builtin.debug' failed.
Origin: /var/home/dk/proyectos/redhat-infra/ansible-lab/setup_basic_tools_epel.yml:77:7

75
76     - name: 8. Verificar instalación completa
77       debug:
         ^ column 7

<<< caused by >>>

Error while resolving value for 'msg': Error rendering template: 'NoneType' object is not iterable
Origin: /var/home/dk/proyectos/redhat-infra/ansible-lab/setup_basic_tools_epel.yml:78:14

76     - name: 8. Verificar instalación completa
77       debug:
78         msg: |
                ^ column 14

fatal: [alma-rhcsa]: FAILED! => {"msg": "Task failed: Finalization of task args for 'ansible.builtin.debug' failed: Error while resolving value for 'msg': Error rendering template: 'NoneType' object is not iterable"}

PLAY RECAP ***************************************************************************************
alma-rhcsa                 : ok=8    changed=3    unreachable=0    failed=1    skipped=0    rescued=0    ignored=1
