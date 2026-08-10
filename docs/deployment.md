# Despliegue de servidores
Bitácora de la implementación documentada  paso a paso para desplegar una escenario conformado por varios servidores. Se utiliza KVM/QEMU para crear 4 maquinas virtuales y segmentación de dos redes.

Tal como ya se ha mencionado antes, su objetivo  es la capacitación en las tecnologías de los sistemas  basado en `Red Hat Linux Enterprise` en el contexto de las certificaciones `RHCSA/RHCE/RHCSS`.




## 1. Preparar Fedora Bazzite para Virtualización



### Paso 1: Instalar el stack de virtualización

```bash
# En Bazzite, como usuario con privilegios (usa sudo o pkexec)
rpm-ostree install libvirt-daemon-kvm qemu-kvm virt-manager virt-install \
  virt-viewer swtpm swtpm-tools edk2-ovmf

# Reiniciar para aplicar la capa ostree
systemctl reboot
```

### Paso 2: Habilitar servicios

```bash
sudo systemctl enable --now libvirtd
sudo usermod -aG libvirt,kvm $USER

# Relogear (cerrar sesión y volver a entrar) para que tome los grupos
```


#### Validación de comandos

En Fedora Bazzite, ejecuto este comando, cierro la sesión e inicio nuevamente:

```bash
sudo usermod -aG libvirt,kvm $USER
```

Sin embargo, al revisar observo que el usuario no fue afiliado a los grupos:

```bash
 id
uid=1000(dk) gid=1000(dk) groups=1000(dk),10(wheel) context=unconfined_u:unconfined_r:unconfined_t:s0-s0:c0.c1023

```

### Cual es la solucion?

El problema que experimentas es muy común y tiene una explicación sencilla, pero en sistemas como **Fedora Bazzite** (basado en rpm-ostree) hay un detalle adicional que lo complica.

La causa principal es que los cambios en los grupos de un usuario **no se aplican a las sesiones que ya están abiertas** . Al cerrar sesión e iniciar una nueva, los grupos deberían actualizarse, pero en Bazzite no ocurre debido a una característica (o "bug") del sistema base inmutable.

### ✅ La solución efectiva para Bazzite

Para solucionarlo, debes forzar la creación de los grupos `libvirt` y `kvm` en el archivo de configuración del sistema (`/etc/group`), ya que el comando `usermod` no logra hacerlo correctamente en este tipo de distribuciones .

Ejecuta los siguientes pasos en la terminal:

**1. Agrega los grupos al sistema:**
Este comando copia la definición de los grupos desde el directorio base (que es de solo lectura) al archivo de configuración del sistema, haciéndolos persistentes.


```bash
grep -E '^kvm:' /usr/lib/group | sudo tee -a /etc/group && sudo usermod -aG kvm $USER
grep -E '^libvirt:' /usr/lib/group | sudo tee -a /etc/group && sudo usermod -aG libvirt $USER
```

**2. Verifica que los cambios se hayan aplicado:**
Puedes comprobar que el usuario ha sido añadido correctamente revisando el archivo de grupos.


```bash
grep $USER /etc/group
```

Deberías ver una línea que incluye `kvm` y `libvirt` .

**3. Reinicia el sistema:**
En este punto, un simple cierre de sesión puede no ser suficiente. **Reinicia el equipo** para que los cambios de grupo se carguen completamente en tu sesión .

### ⚠️ Solución temporal (si no quieres reiniciar ahora)

Si necesitas usar los permisos de inmediato y no puedes reiniciar, puedes usar el comando `newgrp` para iniciar una nueva shell con el grupo activado. Sin embargo, **esto solo es temporal** y los cambios no persistirán al cerrar la terminal .


```bash
newgrp libvirt
```


Al ejecutar esto, se abrirá una nueva shell donde tu usuario tendrá los permisos del grupo `libvirt` de forma inmediata .

------

En resumen, la solución para Bazzite (y otros sistemas rpm-ostree) es ejecutar los comandos `grep` para definir los grupos en `/etc/group` y luego **reiniciar el sistema**. Con esto, al iniciar sesión nuevamente, `id` te mostrará los grupos `kvm` y `libvirt`.



### Paso 3: Verificar que KVM funciona

```bash
# Debe decir "KVM acceleration can be used"
virt-host-validate qemu

# O más simple:
lsmod | grep kvm
# Debe mostrar kvm y kvm_amd
```

**Resultado:**

```bash
❯ virt-host-validate qemu
  QEMU: Checking for hardware virtualization                                 : PASS (SVM)
  QEMU: Checking if device '/dev/kvm' exists                                 : PASS
  QEMU: Checking if device '/dev/kvm' is accessible                          : PASS
  QEMU: Checking if device '/dev/vhost-net' exists                           : PASS
  QEMU: Checking if device '/dev/net/tun' exists                             : PASS
  QEMU: Checking for cgroup 'cpu' controller support                         : PASS
  QEMU: Checking for cgroup 'cpuacct' controller support                     : PASS
  QEMU: Checking for cgroup 'cpuset' controller support                      : PASS
  QEMU: Checking for cgroup 'memory' controller support                      : PASS
  QEMU: Checking for cgroup 'devices' controller support                     : WARN (Enable 'devices' in kernel Kconfig file or mount/enable cgroup controller in your system)
  QEMU: Checking for cgroup 'blkio' controller support                       : PASS
  QEMU: Checking for device assignment IOMMU support                         : PASS (IVRS)
  QEMU: Checking if IOMMU is enabled by kernel                               : PASS
  QEMU: Checking for secure guest support                                    : WARN (None of SEV, SEV-ES, SEV-SNP, TDX available)

```


> **Revisión de resultados, Paso 3: Que ocurre si se presentan estos warnings?**



## ⚠️ Análisis de Warnings en `virt-host-validate`

Esos dos mensajes son **warnings**, no errores. Tus VMs **arrancarán y funcionarán perfectamente**. Pero es importante entender qué significan para saber si debes actuar.

------

## Warning 1: `cgroup 'devices' controller support`

### ¿Qué significa?

Fedora Bazzite usa **cgroups v2** (la versión moderna del kernel). En cgroups v2, el controlador `devices` legacy de cgroups v1 **no existe como tal**. En su lugar, el control de acceso a dispositivos se maneja mediante **eBPF (bpf device cgroup)**.

El validador de QEMU está buscando la interfaz antigua (cgroups v1) y no la encuentra, por eso lanza el warning.

### ¿Afecta tu laboratorio?

**No.** Para tus VMs de estudio, esto es irrelevante. Las VMs arrancan, corren y se apagan sin problemas. La única diferencia es que libvirt no podrá aplicar restricciones de dispositivos a nivel de cgroup de la forma antigua, pero usa eBPF automáticamente en versiones modernas.

### ¿Solucionarlo?

No es necesario, pero si quieres eliminar el warning, verifica que libvirt esté usando cgroups v2 correctamente:



```bash
# Verificar que el sistema usa cgroups v2
mount | grep cgroup
# Debe mostrar: cgroup2 on /sys/fs/cgroup type cgroup2

# Verificar que libvirt está configurado para cgroups v2
grep cgroup_controllers /etc/libvirt/qemu.conf
# Si está comentado o no existe, libvirt usa autodetección (correcto)

# Reiniciar libvirtd por si acaso
sudo systemctl restart libvirtd
```

**Veredicto:** Ignóralo. Es un falso positivo del validador en sistemas modernos con cgroups v2.

------

## Warning 2: `secure guest support (SEV, SEV-ES, SEV-SNP, TDX)`

### ¿Qué significa?

- **SEV** (Secure Encrypted Virtualization) es una tecnología de **AMD EPYC** (procesadores de servidor) que encripta la memoria RAM de las VMs a nivel hardware.
- **TDX** es la equivalente de Intel (Xeon de última generación).
- Tu **Ryzen 5 5600GT** es un procesador de escritorio/consumer. No tiene SEV ni TDX.

### ¿Afecta tu laboratorio?

**Absolutamente no.** Esto es como quejarse de que tu auto no tiene parachoques de camión de carga. No es su función, ni la necesitas.

Para el estudio de RHCSA/RHCE/RHCSS, la encriptación de memoria de VM (SEV/TDX) no aparece en ningún objetivo de examen. Es tecnología de nube privada/hiperscalares con hardware EPYC/Xeon Platinum.

### ¿Solucionarlo?

Ninguna. Es una limitación física del hardware. No hay forma de habilitar SEV en un 5600GT.



---

## 2. Arquitectura de VMs para 16 GB RAM / 6 Cores



| VM               | RAM  | vCPU | Disco | Rol                                         | Estado                |
| :--------------- | :--- | :--- | :---- | :------------------------------------------ | :-------------------- |
| `alma-rhcsa`     | 3 GB | 2    | 40 GB | RHCSA diario + target RHCE                  | **Siempre encendida** |
| `alma-target-02` | 2 GB | 1    | 30 GB | 2do nodo para Ansible                       | Solo para RHCE        |
| `alma-security`  | 4 GB | 2    | 50 GB | RHCSS: STIG, FIPS, SELinux custom           | Bajo demanda          |
| `freeipa-lab`    | 2 GB | 1    | 20 GB | Servidor FreeIPA para autenticación central | Solo para RHCSS       |

**Total asignado:** 11 GB (dejando 5 GB para Bazzite).
**Alternativa sin FreeIPA:** Usa el host Bazzite como nodo de control Ansible y ahorra 2 GB.

### Red recomendada

Crea dos redes virtuales en libvirt:



| Red             | Tipo        | Propósito                                |
| :-------------- | :---------- | :--------------------------------------- |
| `default` (NAT) | Ya existe   | Salida a internet, gestión               |
| `lab-internal`  | Red aislada | Practicar firewalld entre VMs sin salida |


### Crear red interna aislada
```bash
mkdir net
cat > ./net/lab-internal.xml << 'EOF'
<network>
  <name>lab-internal</name>
  <bridge name='virbr11' stp='on' delay='0'/>
  <ip address='10.10.10.1' netmask='255.255.255.0'>
    <dhcp>
      <range start='10.10.10.10' end='10.10.10.50'/>
    </dhcp>
  </ip>
</network>
EOF
```



```bash
sudo virsh net-define ./net/lab-internal.xml
sudo virsh net-start lab-internal
sudo virsh net-autostart lab-internal
```



## 3. Script de Creación de VMs (Copiar y Pegar)

### 1. Instalar dependencias (antes de correr script: importante!)

 ```bash
 rpm-ostree install genisoimage
 # o si no está disponible:
 sudo dnf install genisoimage  # dentro de un toolbox, o buscar alternativa
 ```

### 2. Uso del  script:

#### Descarga el script:

####  [setup.sh](/main/setup.sh)

Utiliza `nano`,  `vim` o su editor favorito

```bash
nano setup.sh
# pega el contenido del script
```

### 3.  Creación y arranque  de las VMS

Ejecuta 

```bash
./setup.sh
```



## 4. Gestión Diaria con virsh


```bash
# Ver estado
virsh list --all
```
```text
 Id   Name             State
---------------------------------
 -    alma-rhcsa       shut off
 -    alma-security    shut off
 -    alma-target-02   shut off
 -    freeipa-lab      shut off
```

```bash
# Encender / apagar
virsh start alma-rhcsa
virsh shutdown alma-rhcsa      # graceful
virsh destroy alma-rhcsa       # fuerza (como pull del cable)

# Consola (salir con Ctrl+] )
virsh console alma-rhcsa

# Ver IP asignada
virsh domifaddr alma-rhcsa

# Snapshot antes de romper algo
virsh snapshot-create-as alma-rhcsa clean-install --description "Post cloud-init"

# Rollback
virsh snapshot-revert alma-rhcsa clean-install

# Liberar RAM para estudiar RHCSS
virsh shutdown alma-rhcsa
virsh shutdown alma-target-02
virsh start alma-security
```



#### Mostrar todas la VMs con sus IP:

```bash
nano show-ip.sh
# pega el script 
```

```bash
for vm in alma-rhcsa alma-target-02 alma-security freeipa-lab; do
  echo  "${vm}
    $(virsh domifaddr $vm)
    "
done
```

#### Acceder a la VMs:

```bash
# Conectar por consola: 
virsh console alma-rhcsa"

# Conectar por SSH:
ssh -i ~/.ssh/id_ed25519 labadmin@IP 
```
```bash
# Ejemplo: en mi caso utilizando mi propia llave SSH | datenmaniak 
ssh -i ~/.ssh/datenmaniak labadmin@192.168.122.193

```

#### Antes de ejecutar `setup.sh` 

Ajuste la variable en `setup.sh` :

Declare su llave SSH personalizada o utilice la llave que se genera por defecto:

```shell
SSH_KEY="/home/dk/.ssh/id_ed25519.pub"  
```

### Si todavía no tienes una llave SSH

1. Abra Terminal.

2. Pegue el texto siguiente y reemplace el correo electrónico usado en el ejemplo por su dirección de correo electrónico de  GitHub.

   ```shell
   ssh-keygen -t ed25519 -C "your_email@example.com"
   ```






------

## 5. Roadmap Ajustado a Este Hardware



| Fase                   | Semanas | VMs Activas                                 | RAM Usada | Acción                                    |
| :--------------------- | :------ | :------------------------------------------ | :-------- | :---------------------------------------- |
| **0: Infraestructura** | 1       | 0                                           | 0 GB      | Instalar KVM, crear VMs, snapshots base   |
| **1: RHCSA**           | 2-6     | `alma-rhcsa`                                | 3 GB      | Romper y reparar. Un snapshot por semana. |
| **2: RHCE**            | 7-11    | `alma-rhcsa` + `alma-target-02`             | 5 GB      | Host Bazzite = nodo de control Ansible    |
| **3: RHCSS**           | 12-15   | `alma-security` (+ `freeipa-lab` ocasional) | 4-6 GB    | Apagar las otras dos VMs                  |

### Comandos para cambiar de fase rápido:


```bash
# Modo RHCSA
virsh start alma-rhcsa
virsh shutdown alma-target-02 alma-security freeipa-lab

# Modo RHCE
virsh start alma-rhcsa
virsh start alma-target-02
virsh shutdown alma-security freeipa-lab

# Modo RHCSS
virsh shutdown alma-rhcsa alma-target-02
virsh start alma-security
# virsh start freeipa-lab  # solo cuando practiques SSSD/FreeIPA
```

------

#### 6. Usar el mismo host Fedora Bazzite como Control Ansible

No desperdicies 2 GB en una VM de control. Tu Bazzite host puede ser el control node:

### Alternativa 1: crear un contenedor con Distrobox
```bash
distrobox create --image quay.io/fedora/fedora:latest ansible-lab
distrobox enter ansible-lab

sudo dnf install -y ansible-core sshpass
```


### Alternativa 2: instalar en el host vía rpm-ostree

Utiliza solo si es sumamente necesario por razones fallidas de otras. Recarga el sistema.

### Alternativa 3: instalar con `brew`  (Recomendada)
```bash
brew install ansible
```


### Crear inventario
```bash
mkdir -p ~/ansible-lab && cd ~/ansible-lab
```
```bash
cat > inventory.ini << 'EOF'
[targets]
alma-rhcsa ansible_host=192.168.122.XXX
alma-target-02 ansible_host=192.168.122.YYY

[targets:vars]
ansible_user=labadmin
ansible_ssh_private_key_file=~/.ssh/id_ed25519
ansible_python_interpreter=/usr/bin/python3
EOF
```

### Probar conexión
```bash
ansible -i inventory.ini all -m ping
```

> Las IPs las obtienes con `virsh domifaddr <vm-name>`.

------

## 7. Verificación antes de Crear las VMs

### Ejecuta este checklist:

```bash
nano checklist.sh
# Pegar el contenido del script
```


```bash
echo "=== CHECKLIST PRE-VM ==="
echo "[ ] libvirtd activo: $(sudo systemctl is-active libvirtd)"
echo "[ ] Red default activa: $(sudo virsh net-info default 2>/dev/null | grep 'Active:' | awk '{print $2}')"
echo "[ ] Red default autostart: $(sudo virsh net-info default 2>/dev/null | grep 'Autostart:' | awk '{print $2}')"
echo "[ ] Red lab-internal activa: $(sudo virsh net-info lab-internal 2>/dev/null | grep 'Active:' | awk '{print $2}')"
echo "[ ] virt-sysprep disponible: $(command -v virt-sysprep >/dev/null 2>&1 && echo 'SI' || echo 'NO')"
echo "[ ] genisoimage disponible: $(command -v genisoimage >/dev/null 2>&1 && echo 'SI' || echo 'NO')"
echo "[ ] Espacio en disco: $(df -h $HOME | tail -1 | awk '{print $4}') libres en $HOME"
```

**Salida:**

```bash
❯ ./checklist.sh
=== CHECKLIST PRE-VM ===
[ ] libvirtd activo: active
[ ] Red default activa: yes
[ ] Red default autostart: yes
[ ] Red lab-internal activa:
[ ] virt-sysprep disponible: SI
[ ] genisoimage disponible: SI
[ ] Espacio en disco: 112G libres en /home/dk

```

### Después de crear las VMs

Siga esta pista para comprobar 

```bash
nano verify.sh
# Pegar el contenido del script
```

```bash
echo "=== CHECKLIST BAZZITE LAB ==="
echo "[ ] rpm-ostree install aplicado y sistema reiniciado"
echo "[ ] libvirtd activo: $(systemctl is-active libvirtd)"
echo "[ ] Usuario en grupos libvirt,kvm: $(groups | grep -o 'libvirt\|kvm')"
echo "[ ] virsh list funciona sin sudo"
echo "[ ] vTPM disponible: $(ls /usr/share/swtpm/swtpm-create-user-config-files 2>/dev/null && echo 'OK' || echo 'FALTA SWTPM')"
echo "[ ] OVMF disponible: $(ls /usr/share/edk2/ovmf/OVMF_CODE.fd 2>/dev/null && echo 'OK' || echo 'FALTA OVMF')"
echo "[ ] Red lab-internal creada: $(sudo virsh net-list --all | grep lab-internal | awk '{print $2,$3}')"
echo "[ ] alma-rhcsa creada y accesible por SSH"
echo "[ ] Snapshots base creados en todas las VMs"
echo "[ ] Toolbox ansible creado y funcionando"
```
**Resultado:**
```text
❯ ./verify.sh
=== CHECKLIST BAZZITE LAB ===
[ ] rpm-ostree install aplicado y sistema reiniciado
[ ] libvirtd activo: active
[ ] Usuario en grupos libvirt,kvm: kvm
libvirt
[ ] virsh list funciona sin sudo
[ ] vTPM disponible: /usr/share/swtpm/swtpm-create-user-config-files OK
[ ] OVMF disponible: /usr/share/edk2/ovmf/OVMF_CODE.fd OK
[ ] Red lab-internal creada:
[ ] alma-rhcsa creada y accesible por SSH
[ ] Snapshots base creados en todas las VMs
[ ] Toolbox ansible creado y funcionando

```

------


## 8. Ventajas de Esta Arquitectura



| Aspecto               | Por qué funciona bien                                        |
| :-------------------- | :----------------------------------------------------------- |
| **Bazzite inmutable** | Tu host no se rompe por instalar paquetes. Las VMs están aisladas en `~/VMs`. |
| **Ryzen 5600GT**      | 6c/12t da margen real. Puedes tener 3 VMs sin que Bazzite se trabe. |
| **Vega integrada**    | Bazzite usa la GPU para el desktop. Las VMs usan virtio (sin GPU), ahorrando recursos. |
| **Separación física** | Tu lab no compite con pfSense/K3s en el ThinkCentre. Estudias sin miedo a romper producción. |
| **KVM nativo**        | Mismo stack que RHEL. Lo que aprendas en `virsh` aplica directo a `qemu-kvm` en empresas. |

---



---

## Errores durante el despliegue 

### Errors log:

```text
Saving 'alma9-base.qcow2'
HTTP response 200  [https://repo.almalinux.org/almalinux/9.8/cloud/x86_64/images/AlmaLinux-9-Generalma9-base.qcow2     100% [===============================================>]  549.46M  749.16KB/s
                          [Files: 1  Bytes: 549.46M [726.30KB/s] Redirects:]
./setup.sh: line 21: virt-sysprep: command not found
./setup.sh: line 22: virt-customize: command not found
Formatting '/home/dk/VMs/alma-rhcsa.qcow2', fmt=qcow2 cluster_size=65536 extended_l2=off compression_type=zlib size=42949672960 backing_file=alma9-seed.qcow2 backing_fmt=qcow2 lazy_refcounts=off refcount_bits=16
xorriso 1.5.8.pl02 : RockRidge filesystem manipulator, libburnia project.

Drive current: -outdev 'stdio:/home/dk/VMs/alma-rhcsa-cidata.iso'
Media current: stdio file, overwriteable
Media status : is blank
Media summary: 0 sessions, 0 data blocks, 0 data,  114g free
xorriso : WARNING : -volid text does not comply to ISO 9660 / ECMA 119 rules
Added to ISO image: file '/meta-data'='/tmp/cidata-alma-rhcsa/meta-data'
xorriso : UPDATE :       1 files added in 1 seconds
Added to ISO image: file '/user-data'='/tmp/cidata-alma-rhcsa/user-data'
xorriso : FAILURE : Cannot determine attributes of source file '/tmp/cidata-alma-rhcsa/network-config' : No such file or directory
xorriso : UPDATE :       2 files added in 1 seconds
xorriso : aborting : -abort_on 'FAILURE' encountered 'FAILURE'
ERROR    Error: --disk path=/home/dk/VMs/alma-rhcsa-cidata.iso,device=cdrom: Size must be specified for non existent volume 'alma-rhcsa-cidata.iso'
VM alma-rhcsa creada. IP en default: virsh domifaddr alma-rhcsa
Formatting '/home/dk/VMs/alma-target-02.qcow2', fmt=qcow2 cluster_size=65536 extended_l2=off compression_type=zlib size=32212254720 backing_file=alma9-seed.qcow2 backing_fmt=qcow2 lazy_refcounts=off refcount_bits=16

Starting install...
ERROR    Network not found: no network with matching name 'default'
Domain installation does not appear to have been successful.
If it was, you can restart your domain by running:
  virsh --connect qemu:///session start alma-target-02
otherwise, please restart your installation.
VM alma-target-02 creada. IP en default: virsh domifaddr alma-target-02
Formatting '/home/dk/VMs/alma-security.qcow2', fmt=qcow2 cluster_size=65536 extended_l2=off compression_type=zlib size=53687091200 backing_file=alma9-seed.qcow2 backing_fmt=qcow2 lazy_refcounts=off refcount_bits=16
xorriso 1.5.8.pl02 : RockRidge filesystem manipulator, libburnia project.

Drive current: -outdev 'stdio:/home/dk/VMs/alma-security-cidata.iso'
Media current: stdio file, overwriteable
Media status : is blank
Media summary: 0 sessions, 0 data blocks, 0 data,  114g free
xorriso : WARNING : -volid text does not comply to ISO 9660 / ECMA 119 rules
Added to ISO image: file '/meta-data'='/tmp/cidata-alma-security/meta-data'
xorriso : UPDATE :       1 files added in 1 seconds
Added to ISO image: file '/user-data'='/tmp/cidata-alma-security/user-data'
xorriso : FAILURE : Cannot determine attributes of source file '/tmp/cidata-alma-security/network-config' : No such file or directory
xorriso : UPDATE :       2 files added in 1 seconds
xorriso : aborting : -abort_on 'FAILURE' encountered 'FAILURE'
ERROR    Error: --disk path=/home/dk/VMs/alma-security-cidata.iso,device=cdrom: Size must be specified for non existent volume 'alma-security-cidata.iso'
VM alma-security creada. IP en default: virsh domifaddr alma-security
Formatting '/home/dk/VMs/freeipa-lab.qcow2', fmt=qcow2 cluster_size=65536 extended_l2=off compression_type=zlib size=21474836480 backing_file=alma9-seed.qcow2 backing_fmt=qcow2 lazy_refcounts=off refcount_bits=16
xorriso 1.5.8.pl02 : RockRidge filesystem manipulator, libburnia project.

Drive current: -outdev 'stdio:/home/dk/VMs/freeipa-lab-cidata.iso'
Media current: stdio file, overwriteable
Media status : is blank
Media summary: 0 sessions, 0 data blocks, 0 data,  114g free
xorriso : WARNING : -volid text does not comply to ISO 9660 / ECMA 119 rules
Added to ISO image: file '/meta-data'='/tmp/cidata-freeipa-lab/meta-data'
xorriso : UPDATE :       1 files added in 1 seconds
Added to ISO image: file '/user-data'='/tmp/cidata-freeipa-lab/user-data'
xorriso : FAILURE : Cannot determine attributes of source file '/tmp/cidata-freeipa-lab/network-config' : No such file or directory
xorriso : UPDATE :       2 files added in 1 seconds
xorriso : aborting : -abort_on 'FAILURE' encountered 'FAILURE'
ERROR    Error: --disk path=/home/dk/VMs/freeipa-lab-cidata.iso,device=cdrom: Size must be specified for non existent volume 'freeipa-lab-cidata.iso'
VM freeipa-lab creada. IP en default: virsh domifaddr freeipa-lab

=== VMs Creadas ===
Conectar: virsh console alma-rhcsa
Ver IPs: virsh domifaddr alma-rhcsa
SSH: ssh labadmin@<IP>

Para iniciar: virsh start alma-rhcsa
````



### 🔍 Análisis del Output: 4 Errores Críticos y 1 Advertencia

Tu script **no creó VMs funcionales**. Se reportaron como "creadas" pero fallaron silenciosamente. Aquí el diagnóstico exacto:

------

###  Error 1: `virt-sysprep: command not found` / `virt-customize: command not found`

**Qué pasó:** Falta el paquete `libguestfs-tools` (herramientas de manipulación de imágenes de disco).

**Impacto:** La imagen base no se limpió ni se inyectó la clave SSH. El script continuó usando una imagen "sucia" (puede tener MAC address o hostname fijos de la imagen cloud).

**Solución en Bazzite:**


```bash
rpm-ostree install libguestfs-tools
# Reiniciar
systemctl reboot
```

------

### Error 2: `Cannot determine attributes of source file 'network-config'`

**Qué pasó:** El script intenta incluir `network-config` en el ISO de cloud-init **siempre**, pero solo lo crea cuando `$ip` no está vacío. Para `alma-rhcsa`, `$ip` es `""`, así que el archivo no existe y `genisoimage`/`mkisofs` aborta.

**Impacto:** El ISO de cloud-init no se generó. La VM se creó **sin cloud-init**, así que no tendrá usuario `labadmin`, ni clave SSH, ni red configurada.

------

### Error 3: `Size must be specified for non existent volume 'alma-rhcsa-cidata.iso'`

**Qué pasó:** Como el ISO falló en crearse (Error 2), `virt-install` recibió un path a un archivo inexistente.

**Impacto:** `virt-install` falló. La VM no se instaló correctamente.

------

### Error 4: `Network not found: no network with matching name 'default'`

**Qué pasó:** En tu Bazzite, la red `default` de libvirt **no existe**. Fedora/Bazzite no la crea automáticamente si usas `qemu:///session`, o puede no estar activa.

**Impacto:** `alma-target-02` (y posiblemente las demás si usan red default) no pueden arrancar porque no tienen interfaz de red.

------

### Advertencia: `volid text does not comply to ISO 9660`

**Qué pasó:** El nombre del volumen `cidata` cumple, pero `genisoimage`/`xorriso` advierte sobre reglas ECMA-119. Es cosmético, no afecta el funcionamiento.

------

### Resumen de Estado Actual


| VM               | Estado Real | Razón                                         |
| :--------------- | :---------- | :-------------------------------------------- |
| `alma-rhcsa`     | ❌ **Rota**  | Sin cloud-init, sin red funcional garantizada |
| `alma-target-02` | ❌ **Rota**  | Sin red `default`, sin cloud-init             |
| `alma-security`  | ❌ **Rota**  | Sin cloud-init                                |
| `freeipa-lab`    | ❌ **Rota**  | Sin cloud-init                                |

------

### Pasos de Reparación 🔧

Léase un poco acerca de las redes  [bridges](/docs/about-bridges.md)



#### Paso 1: Instalar dependencias faltantes

```bash
rpm-ostree install libguestfs-tools genisoimage
systemctl reboot
```

#### Paso 2: Crear la red `default` de libvirt




```bash
# Verificar si existe
virsh net-list --all

mkdir net

# Si NO aparece 'default', créala:
cat > ./net/default-net.xml << 'EOF'
<network>
  <name>default</name>
  <forward mode='nat'/>
  <bridge name='virbr10' stp='on' delay='0'/>
  <ip address='192.168.122.1' netmask='255.255.255.0'>
    <dhcp>
      <range start='192.168.122.2' end='192.168.122.254'/>
    </dhcp>
  </ip>
</network>
EOF

virsh net-define ./net/default-net.xml
virsh net-start default
virsh net-autostart default
```

#### Paso 3: Limpiar el desastre anterior


```bash
cd ~/opt/VMs

# Destruir VMs fantasmas (si existen)
for vm in alma-rhcsa alma-target-02 alma-security freeipa-lab; do
  virsh destroy $vm 2>/dev/null
  virsh undefine $vm --remove-all-storage 2>/dev/null
done

# Borrar archivos huérfanos
rm -f *.iso *.qcow2
```



#### Si este script no funciona, descargue estos:

- [Elimina todas las VMs y sus configuraciones **KVM/QEMU** ](/clean/cleanup-kvm-vms.sh)
- [Limpieza forzada para KVM](/clean/cleanup-force.sh)



## Reiniciar bootstraping 

En este punto con las dependencias listas  y las redes activas, el arranque de las VMs debe completar exitosamente.

```bash
./setup.sh

```

### Errors log:

```bash
Starting install...
ERROR    Requested operation is not valid: network 'default' is not active
Domain installation does not appear to have been successful.
If it was, you can restart your domain by running:
  virsh --connect qemu:///session start alma-rhcsa
otherwise, please restart your installation.
```



## 🔴 Error: La red `default` existe pero está inactiva

El mensaje cambió: antes era *"not found"*, ahora es *"is not active"*. La red está definida pero no está corriendo.

------

## Diagnóstico Rápido


```bash
# Ver estado de todas las redes
virsh net-list --all

# Probablemente verás:
#  Name      State      Autostart   Persistent
# ----------------------------------------------
#  default   inactive   no          yes
#  lab-internal  inactive   no      yes
```

La red está **inactive** y probablemente **Autostart = no**.

------

## Solución: Activar y Persistir


```bash
# 1. Activar la red ahora
virsh net-start default

# 2. Hacer que arranque automáticamente tras cada boot
virsh net-autostart default

# 3. Lo mismo para lab-internal (si la creaste)
virsh net-start lab-internal
virsh net-autostart lab-internal

# 4. Verificar
virsh net-list --all
```

Debe mostrar:


```plain
 Name           State    Autostart   Persistent
------------------------------------------------
 default        active   yes         yes
 lab-internal   active   yes         yes
```

------

## Si `virsh net-start default` falla

Puede que haya un conflicto con `virbr0` (bridge ya existe por NetworkManager o docker):


```bash
# Verificar si el bridge ya existe
ip link show virbr0

# Si existe pero no está asociado a libvirt, destruirlo
sudo ip link delete virbr0

# O reiniciar libvirtd para que reclame el bridge
sudo systemctl restart libvirtd

# Intentar de nuevo
virsh net-start default
```

------

## Re-ejecutar el script

Una vez que `virsh net-list --all` muestre **active + yes** en ambas redes:


```bash
./setup.sh
```

---



