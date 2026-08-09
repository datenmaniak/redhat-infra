#  Preparación del Host Proxmox: El Cimiento de tu Laboratorio

Antes de crear una sola VM, el hypervisor debe ser una fortaleza. Si comprometen el host, todas las VMs caen. Vamos paso a paso.


## 1. Post-Instalación Inmediata

Asumo que ya instalaste Proxmox VE (última versión estable, basada en Debian 12). Estos son los pasos **antes de tocar la interfaz web**.

### 1.1 Actualización y Repositorios



```bash
# Accede por SSH al nodo Proxmox (no uses la consola web para esto)
ssh root@<IP_DEL_PROXMOX>

# Desactivar el repositorio de suscripción (enterprise)
sed -i 's/^deb/#deb/' /etc/apt/sources.list.d/pve-enterprise.list

# Activar el repositorio community (no-suscription)
echo "deb http://download.proxmox.com/debian/pve bookworm pve-no-subscription" \
  > /etc/apt/sources.list.d/pve-no-subscription.list

# Actualizar todo el sistema
apt update && apt full-upgrade -y

# Instalar herramientas esenciales
apt install -y vim htop iotop iftop net-tools dnsutils \
  fail2ban sudo tmux curl wget git
```

### 1.2 Crear un Usuario Administrativo (No uses root para todo)



```bash
# Crear usuario admin con sudo
useradd -m -s /bin/bash labadmin
usermod -aG sudo labadmin

# Configurar sudo sin contraseña para operaciones de proxmox
echo "labadmin ALL=(ALL) NOPASSWD: /usr/bin/pvesh, /usr/sbin/pveum, /usr/bin/qm, /usr/sbin/vzdump" \
  > /etc/sudoers.d/labadmin

# Copiar tu clave SSH pública
mkdir -p /home/labadmin/.ssh
echo "ssh-ed25519 AAAA... tu-clave-publica" > /home/labadmin/.ssh/authorized_keys
chmod 700 /home/labadmin/.ssh
chmod 600 /home/labadmin/.ssh/authorized_keys
chown -R labadmin:labadmin /home/labadmin/.ssh

# Bloquear acceso root por SSH
sed -i 's/^#*PermitRootLogin.*/PermitRootLogin no/' /etc/ssh/sshd_config
sed -i 's/^#*PasswordAuthentication.*/PasswordAuthentication no/' /etc/ssh/sshd_config
systemctl restart sshd
```

------

## 2. Red del Laboratorio: Aislamiento y Segmentación

Necesitas **al menos 3 bridges** para simular una arquitectura de red real:



| Bridge  | Propósito                  | Red sugerida                      |
| :------ | :------------------------- | :-------------------------------- |
| `vmbr0` | LAN de gestión (ya existe) | Tu red local (ej. 192.168.1.0/24) |
| `vmbr1` | DMZ / Servicios expuestos  | 10.0.100.0/24                     |
| `vmbr2` | Red interna / Backend      | 10.0.200.0/24 (sin gateway)       |

### Configuración en `/etc/network/interfaces`



```bash
# Hacer backup primero
cp /etc/network/interfaces /etc/network/interfaces.bak.$(date +%Y%m%d)

# Editar
cat > /etc/network/interfaces << 'EOF'
auto lo
iface lo inet loopback

# Bridge de gestión (conectado a tu LAN física)
auto vmbr0
iface vmbr0 inet static
    address 192.168.1.10/24
    gateway 192.168.1.1
    bridge-ports enp3s0
    bridge-stp off
    bridge-fd 0

# DMZ - Solo entre VMs, sin acceso directo a LAN (salvo reglas firewall)
auto vmbr1
iface vmbr1 inet manual
    bridge-ports none
    bridge-stp off
    bridge-fd 0

# Red interna - Aislada, sin gateway, para backend/DBs
auto vmbr2
iface vmbr2 inet manual
    bridge-ports none
    bridge-stp off
    bridge-fd 0
EOF

# Aplicar
systemctl restart networking
```

> **Nota:** Si tu interfaz física no se llama `enp3s0`, cámbiala por la tuya (`ip link show` para verificar).

------

## 3. Firewall del Host (Proxmox usa iptables/nftables internamente)

No confíes solo en el firewall de Proxmox GUI. Usa **nftables** en el host para proteger el hypervisor mismo.



```bash
# Crear tabla y reglas base
cat > /etc/nftables.conf << 'EOF'
#!/usr/sbin/nft -f

flush ruleset

table inet filter {
    chain input {
        type filter hook input priority 0; policy drop;
        
        # Permitir loopback
        iif "lo" accept
        
        # Permitir tráfico relacionado/establecido
        ct state established,related accept
        
        # Permitir ICMP (ping) limitado
        ip protocol icmp icmp type { echo-request, destination-unreachable, time-exceeded } limit rate 5/second accept
        ip6 nexthdr icmpv6 icmpv6 type { echo-request, destination-unreachable, time-exceeded } limit rate 5/second accept
        
        # SSH solo desde tu red de gestión
        ip saddr 192.168.1.0/24 tcp dport 22 accept
        
        # Proxmox Web GUI (8006) solo desde LAN de gestión
        ip saddr 192.168.1.0/24 tcp dport 8006 accept
        
        # Proxmox VNC (5900-5999) solo desde LAN
        ip saddr 192.168.1.0/24 tcp dport 5900-5999 accept
        
        # Spice (3128) solo desde LAN
        ip saddr 192.168.1.0/24 tcp dport 3128 accept
        
        # COROSYNC (si cluster, solo entre nodos)
        # ip saddr { 192.168.1.11, 192.168.1.12 } udp dport 5404-5405 accept
        
        # Loggear y droppear el resto
        log prefix "nftables dropped: " limit rate 5/minute
        drop
    }
    
    chain forward {
        type filter hook forward priority 0; policy accept;
        
        # Permitir forwarding entre bridges para las VMs (Proxmox lo gestiona)
        # Pero bloquear DMZ -> LAN directo (lo hará el firewall de cada VM)
        iifname "vmbr1" oifname "vmbr0" drop
    }
    
    chain output {
        type filter hook output priority 0; policy accept;
    }
}
EOF

chmod +x /etc/nftables.conf
systemctl enable nftables
systemctl restart nftables

# Verificar
nft list ruleset
```

### fail2ban para SSH



```bash
cat > /etc/fail2ban/jail.local << 'EOF'
[sshd]
enabled = true
port = ssh
filter = sshd
logpath = /var/log/auth.log
maxretry = 3
bantime = 3600
findtime = 600
EOF

systemctl enable fail2ban
systemctl restart fail2ban
```

------

## 4. Almacenamiento: ZFS o LVM-thin

Para un lab de seguridad con snapshots frecuentes, **ZFS** es superior. Si no puedes usar ZFS, LVM-thin funciona.

### Opción A: ZFS (Recomendado)



```bash
# Identificar el disco para VMs (ej. /dev/sdb - ¡NO el disco del SO!)
lsblk

# Crear pool ZFS
zpool create -f rpool /dev/sdb

# Activar compresión y deduplicación (opcional, consume RAM)
zfs set compression=lz4 rpool
zfs set atime=off rpool

# Crear datasets
zfs create rpool/vm-storage
zfs create rpool/vm-backups

# Montar en Proxmox
# En la GUI: Datacenter > Storage > Add > ZFS
# ID: zfs-vmstorage
# ZFS Pool: rpool/vm-storage
# Content: Disk image, Container
```

### Opción B: LVM-thin (Si ya tienes LVM)



```bash
# Crear thin pool (asumiendo /dev/sdb1 como PV)
pvcreate /dev/sdb1
vgcreate vg-vm /dev/sdb1

# Thin pool con metadata
lvcreate -L 200G -T vg-vm/vm-thin

# En GUI: Datacenter > Storage > Add > LVM-Thin
# ID: lvmthin-vm
# Volume group: vg-vm
# Thin pool: vm-thin
```

------

## 5. Configuración de vTPM 2.0 y UEFI

Esto es **crítico** para practicar LUKS2 + TPM2 en tus VMs AlmaLinux.

### Instalar el software de vTPM



```bash
apt install -y swtpm swtpm-tools ovmf
```

### Verificar que OVMF (UEFI firmware) está disponible



```bash
ls /usr/share/pve-edk2-firmware/
# Debe mostrar: OVMF_CODE.fd, OVMF_VARS.fd, etc.
```

### Configurar almacenamiento para vTPM states

En la GUI de Proxmox:

1. **Datacenter > Storage**
2. Asegúrate de que tu storage (ZFS o LVM-thin) tenga marcado **"Container"** y **"VM Disk"** en el campo **Content**.

------

## 6. Plantilla de VM Base (para clonar)

En lugar de instalar AlmaLinux desde ISO cada vez, crea una **VM template** clonable.

### Crear la VM base por CLI



```bash
# Crear VM
qm create 9000 --name alma-9-template --memory 2048 --cores 2 \
  --cpu x86-64-v2-AES --net0 virtio,bridge=vmbr0,tag=100 \
  --bios ovmf --efidisk0 local-lvm:1 \
  --tpmstate0 local-lvm:1,version=v2.0 \
  --scsi0 local-lvm:32,ssd=1,discard=on,iothread=1 \
  --ide2 none --boot order=scsi0

# Descargar la imagen cloud de AlmaLinux
cd /var/lib/vz/template/iso/
wget https://repo.almalinux.org/almalinux/9/cloud/x86_64/images/AlmaLinux-9-GenericCloud-latest.x86_64.qcow2

# Importar el disco a la VM
qm importdisk 9000 AlmaLinux-9-GenericCloud-latest.x86_64.qcow2 local-lvm
qm set 9000 --scsi0 local-lvm:vm-9000-disk-1,ssd=1,discard=on,iothread=1

# Configurar cloud-init
qm set 9000 --ide2 local-lvm:cloudinit
qm set 9000 --serial0 socket --vga serial0
qm set 9000 --ipconfig0 ip=dhcp

# Convertir a template (¡no encender todavía!)
qm template 9000
```

### Configurar cloud-init por GUI (una vez)

1. Selecciona la VM 9000 (ahora es template)
2. Ve a **Cloud-Init**
3. Configura:
   - **User:** `labadmin`
   - **Password:** (genera una fuerte) o mejor: pega tu **SSH Public Key**
   - **DNS:** 1.1.1.1, 8.8.8.8
   - **IP Config:** DHCP (para el template; las clonadas usarán estático)

------

## 7. Script de Creación Rápida de VMs del Laboratorio

Guarda esto como `/root/create-lab-vms.sh` y ejecútalo:

```bash
#!/bin/bash
# create-lab-vms.sh

TEMPLATE_ID=9000
STORAGE="local-lvm"

# Función para clonar y configurar
create_vm() {
    local vmid=$1
    local name=$2
    local memory=$3
    local cores=$4
    local disk_size=$5
    local bridge=$6
    local ip=$7
    
    echo "Creando VM $name (ID: $vmid)..."
    
    # Clonar del template
    qm clone $TEMPLATE_ID $vmid --name $name --full
    
    # Configurar recursos
    qm set $vmid --memory $memory --cores $cores
    
    # Redimensionar disco
    qm resize $vmid scsi0 +${disk_size}G
    
    # Configurar red
    qm set $vmid --net0 virtio,bridge=$bridge
    
    # Configurar IP estática vía cloud-init
    qm set $vmid --ipconfig0 ip=$ip/24,gw=10.0.100.1
    
    echo "VM $name creada. IP: $ip"
}

# Crear las VMs del laboratorio
create_vm 101 "alma-security-master" 16384 4 60 "vmbr0" "192.168.1.101"
create_vm 102 "alma-security-dmz"     8192  2 40 "vmbr1" "10.0.100.10"
create_vm 103 "rocky-hardening-lab"   4096  2 40 "vmbr0" "192.168.1.103"
create_vm 104 "freeipa-server"        4096  2 30 "vmbr0" "192.168.1.104"

echo ""
echo "Laboratorio creado. VMs:"
echo "  101 - alma-security-master (192.168.1.101) - PRINCIPAL"
echo "  102 - alma-security-dmz    (10.0.100.10)    - DMZ"
echo "  103 - rocky-hardening-lab  (192.168.1.103)  - COMPARATIVA"
echo "  104 - freeipa-server       (192.168.1.104)  - IDM"
echo ""
echo "Iniciar: qm start 101"
```



```bash
chmod +x /root/create-lab-vms.sh
/root/create-lab-vms.sh
```

------

## 8. Estrategia de Snapshots (Crítico para un Lab de Seguridad)

Nunca apliques STIG o FIPS sin snapshot. Nunca.



| VM    | Snapshot             | Momento                                       |
| :---- | :------------------- | :-------------------------------------------- |
| Todas | `fresh-install`      | Después del primer boot + update + cloud-init |
| 101   | `pre-stig`           | Antes de `oscap --remediate`                  |
| 101   | `pre-fips`           | Antes de `fips-mode-setup --enable`           |
| 101   | `pre-luks`           | Antes de encriptar discos adicionales         |
| 101   | `pre-selinux-custom` | Antes de compilar tu primera política .te     |

Comandos útiles:



```bash
# Crear snapshot
qm snapshot 101 pre-stig --description "Antes de aplicar STIG DISA"

# Listar snapshots
qm listsnapshot 101

# Rollback
qm rollback 101 pre-stig

# Eliminar snapshot viejo
qm delsnapshot 101 old-snapshot-name
```

------

## 9. Checklist Final del Host

Antes de encender tu primera VM, verifica:



```bash
echo "=== CHECKLIST HOST PROXMOX ==="
echo "[ ] Repositorios: community activo, enterprise desactivado"
echo "[ ] Sistema actualizado: $(cat /etc/debian_version)"
echo "[ ] Usuario labadmin creado con sudo y SSH key"
echo "[ ] Root SSH deshabilitado"
echo "[ ] Firewall nftables activo y funcionando"
echo "[ ] fail2ban activo"
echo "[ ] Bridges creados: vmbr0, vmbr1, vmbr2"
echo "[ ] Almacenamiento ZFS/LVM-thin configurado"
echo "[ ] swtpm y ovmf instalados"
echo "[ ] Template AlmaLinux 9 creado (ID 9000)"
echo "[ ] VMs del lab clonadas y configuradas"
echo "[ ] Snapshots base creados en todas las VMs"
echo "[ ] Backup de /etc/network/interfaces guardado"
echo ""
echo "Estado actual:"
nft list ruleset | head -5
systemctl is-active fail2ban
systemctl is-active nftables
zpool list 2>/dev/null || lvs 2>/dev/null | head -5
```



## 10. Diagrama de Red del Laboratorio



```plain
                    INTERNET
                       │
                       ▼
              ┌─────────────┐
              │   Router    │
              │ 192.168.1.1 │
              └──────┬──────┘
                     │
         ┌───────────┴───────────┐
         │       vmbr0           │
         │   LAN GESTIÓN         │
         │  192.168.1.0/24       │
         └───────────┬───────────┘
                     │
    ┌────────────────┼────────────────┐
    │                │                │
    ▼                ▼                ▼
┌────────┐    ┌────────────┐    ┌──────────┐
│  101   │    │    103     │    │   104    │
│ Alma   │    │   Rocky    │    │ FreeIPA  │
│ Master │    │  Hardening │    │  Server  │
│.1.101  │    │   .1.103   │    │  .1.104  │
└────────┘    └────────────┘    └──────────┘
    │                                  │
    │         ┌──────────┐            │
    └────────►│  vmbr1   │◄───────────┘
              │   DMZ    │
              │10.0.100.0│
              └────┬─────┘
                   │
                   ▼
              ┌────────┐
              │  102   │
              │ Alma   │
              │  DMZ   │
              │.100.10 │
              └────────┘
                   │
              ┌────┴─────┐
              │  vmbr2   │
              │  BACKEND │
              │10.0.200.0│
              │ (aislado)│
              └──────────┘
```

------

## ¿Está listo tu host?

Si completaste los pasos 1-10, tu Proxmox es ahora un **hypervisor hardeneado** con:

- Acceso SSH solo con clave, root bloqueado
- Firewall host-level con segmentación de red
- Almacenamiento optimizado para snapshots
- VMs pre-clonadas con vTPM, UEFI y cloud-init
- Estrategia de snapshots documentada

**El siguiente paso** es encender la VM 101 (`qm start 101`), conectarte por SSH (`ssh labadmin@192.168.1.101`) y comenzar con la post-instalación de AlmaLinux (FIPS, STIG, SELinux, etc.).

¿Quieres que te dé el **script de post-instalación automatizada** para la VM 101, o prefieres hacerlo manual paso a paso como parte del aprendizaje?



