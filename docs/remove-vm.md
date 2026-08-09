# Eliminar todas las VMs de KVM/QEMU

Se desea comenzar con un despliegue limpio. Se debe eliminar todas las VMs y  absolutamente las configuraciones asociadas con el usuario, incluyendo la del sistema.

## VMS

```bash
❯ virsh list --all
 Id   Name             State
---------------------------------
 -    alma-rhcsa       shut off
 -    alma-security    shut off
 -    alma-target-02   shut off
 -    freeipa-lab      shut off

```

## Directorios asociados 


- /opt/VMs
- /tmp

```bash
❯ ls -la /opt/VMs
Permissions Size User Date Modified Name
.rw-r--r--@ 197k root  9 Aug 12:11   alma-rhcsa.qcow2
.rw-r--r--@ 747M root  9 Aug 12:11   alma9-seed.qcow2
```

## Resultado esperado

El comando `virsh list --all` no debe mostrar resultados.



## Recomendaciones

