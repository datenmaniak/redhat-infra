# Cómo funciona los brigdes pra KVM/QEMU.



Hola. Como tu tutor, te explicaré cómo funciona el puente de red (bridge) para KVM/QEMU. Piensa en un bridge como un **conmutador (switch) virtual** dentro de tu host físico. Su función es conectar las máquinas virtuales (VMs) a la misma red física que tu host, haciendo que las VMs sean un "ciudadano más" en tu red local.

Esto es distinto a la red NAT (Network Address Translation) que usa `virbr0` por defecto, donde las VMs están en una red privada y aislada .

### ¿Cómo funciona un bridge?

El bridge se conecta a tu red física a través de una interfaz de red de tu host (por ejemplo, `eth0`, `eno1`, o un adaptador WiFi). Luego, para cada VM, se crea una interfaz **TAP** (Network TAP) que actúa como el cable de red virtual que conecta la VM al bridge . A continuación, un ejemplo visual de la arquitectura:





------

### Creación de redes bridge

Hay dos formas principales de crear un bridge: "a mano" para pruebas rápidas, o de forma persistente para que sobreviva a reinicios.

#### 1. Creación temporal (no persistente) con `ip`

Este método es útil para pruebas, pero la configuración desaparecerá al reiniciar el host .

bash

```
# 1. Crear el bridge (ej. nombre 'br0')
sudo ip link add name br0 type bridge

# 2. Activar la interfaz del bridge
sudo ip link set dev br0 up

# 3. Asignar una dirección IP (opcional, puede obtenerla por DHCP)
sudo ip addr add 192.168.1.100/24 dev br0

# 4. Añadir tu interfaz física (ej. 'eth0') al bridge
#   ¡PRECAUCIÓN! Esto desconectará tu host de la red si estás
#   conectado por SSH a través de eth0.
sudo ip link set eth0 master br0
```



Tras estos pasos, el bridge `br0` actúa como la nueva interfaz de red de tu host. Las VMs que se conecten a `br0` compartirán la red .

#### 2. Creación persistente con `nmcli` (en sistemas con NetworkManager)

Esta es la manera recomendada en distribuciones como Fedora, RHEL o Ubuntu con NetworkManager .

bash

```
# 1. Crear el bridge (ej. 'br0')
sudo nmcli connection add type bridge ifname br0 con-name br0

# 2. Configurar el bridge para obtener IP automáticamente (DHCP)
sudo nmcli connection modify br0 ipv4.method auto

# 3. Activar el bridge
sudo nmcli connection up br0

# 4. Mover tu interfaz física (ej. 'Wired connection 1') al bridge
sudo nmcli connection modify "Wired connection 1" master br0
sudo nmcli connection up "Wired connection 1"
```



#### 3. Creación y gestión con `virsh` (mediante XML)

`virsh` también permite definir redes persistentes usando archivos XML. La definición se guarda en `/etc/libvirt/qemu/networks/` .

bash

```
# 1. Crear un archivo XML (ej. hostbridge.xml)
cat > hostbridge.xml << EOF
<network>
  <name>hostbridge</name>
  <forward mode='bridge'/>
  <bridge name='br0'/>
</network>
EOF

# 2. Definir y activar la red en libvirt
sudo virsh net-define hostbridge.xml
sudo virsh net-start hostbridge
sudo virsh net-autostart hostbridge   # Para que inicie con el sistema
```



------

### Edición de redes bridge

- **Con `nmcli`**: Puedes modificar parámetros de la conexión, como la configuración IP o el Spanning Tree Protocol (STP). Por ejemplo, para desactivar STP (a veces recomendado en entornos virtuales simples ): `sudo nmcli con modify br0 bridge.stp no`.
- **Con `virsh`**: Para editar la definición XML de una red de libvirt, usa: `sudo virsh net-edit hostbridge`. Esto abrirá el archivo XML en un editor para que puedas modificarlo .
- **Con archivos de configuración**: En sistemas que no usan NetworkManager (o para configuraciones estáticas), puedes editar los archivos en `/etc/network/interfaces` (Debian/Ubuntu) o en `/etc/sysconfig/network-scripts/ifcfg-*` (RHEL/Fedora) y reiniciar el servicio de red.

------

### Listado de redes bridge

Para ver qué bridges existen y su estado, puedes usar varios comandos:

bash

```
# Comando universal de Linux para ver interfaces de red
ip link show type bridge

# Si usas nmcli (NetworkManager)
nmcli con show --active   # Muestra conexiones activas, incluyendo bridges

# Si usas virsh (para redes definidas en libvirt)
sudo virsh net-list --all   # Lista todas las redes de libvirt
sudo virsh net-info hostbridge   # Muestra información detallada de una red
```



------

### Eliminación definitiva de redes bridge

**¡IMPORTANTE!** Asegúrate de que ninguna VM esté usando el bridge antes de eliminarlo .

#### 1. Eliminar un bridge temporal creado con `ip`

bash

```
# 1. Bajar la interfaz del bridge
sudo ip link set br0 down

# 2. Eliminar el bridge
sudo ip link delete br0 type bridge
```



Esto elimina el bridge, pero es posible que debas reasignar la IP a tu interfaz física (`eth0`) para recuperar la conectividad de red .

#### 2. Eliminar un bridge persistente creado con `nmcli`

bash

```
# Eliminar la conexión del bridge (ej. 'br0')
sudo nmcli connection delete br0
```



Si tu interfaz física estaba "esclavizada" al bridge, deberías reactivar su conexión original para que el host recupere la red .

#### 3. Eliminar una red definida en `virsh`

bash

```
# 1. Detener la red (si está activa)
sudo virsh net-destroy hostbridge

# 2. Eliminar la definición de la red
sudo virsh net-undefine hostbridge
```



Esto eliminará la configuración de libvirt, pero el bridge subyacente (si se creó con otro método) puede persistir y necesitar ser eliminado con los comandos anteriores .

### Notas adicionales para tu aprendizaje

- **Rendimiento**: El modelo de dispositivo `virtio` para las interfaces de red de las VMs es el que ofrece mejor rendimiento .
- **Firewall**: En algunos sistemas, el firewall (`iptables`) puede interferir con el tráfico del bridge. Puedes necesitar ajustar reglas o desactivar la comprobación del firewall para el bridge (parámetros `net.bridge.bridge-nf-call-iptables`) .
- **Permisos**: Para que un usuario normal pueda usar la red en modo bridge con QEMU, es posible que necesites configurar el archivo `/etc/qemu/bridge.conf` para permitirlo .

Espero que esta explicación te haya sido de gran ayuda. Como tutor, te recomiendo practicar estos comandos en un entorno de pruebas para familiarizarte con su funcionamiento.