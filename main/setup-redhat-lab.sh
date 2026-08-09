#!/bin/bash
# setup-redhat-lab.sh
# Ejecutar en Bazzite después de instalar libguestfs-tools y genisoimage

set -euo pipefail

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log() {
  local level=$1
  local message=$2
  local timestamp=$(date '+%Y-%m-%d %H:%M:%S')

  case $level in
  "INFO") echo -e "${GREEN}[INFO]${NC} $message" ;;
  "WARN") echo -e "${YELLOW}[WARN]${NC} $message" ;;
  "ERROR") echo -e "${RED}[ERROR]${NC} $message" ;;
  "STEP") echo -e "${BLUE}[STEP]${NC} $message" ;;
  *) echo "$message" ;;
  esac

}

VM_DIR="/opt/VMs"
ALMA_URL="https://repo.almalinux.org/almalinux/9/cloud/x86_64/images/AlmaLinux-9-GenericCloud-latest.x86_64.qcow2"
# SSH_KEY="$HOME/.ssh/datenmaniak.pub"
SSH_KEY="/home/dk/.ssh/datenmaniak.pub"     # <--- Se ajusta a ruta absoluta, y se ejecuta con sudo
                                            # para mantener los permisos de QEMU de los .ISO/.qcow2 
                                            # 
                                            #  sudo ./setup-redhat-lab-fixed.sh

if [[ $EUID -ne 0 ]]; then
  log "ERROR" "Este script debe ejecutarse como root (sudo)"
  exit 1
fi

# --- Validaciones previas ---
command -v virsh >/dev/null 2>&1 || {
  echo "ERROR: virsh no encontrado. Instala @virtualization"
  exit 1
}
command -v virt-sysprep >/dev/null 2>&1 || {
  echo "ERROR: virt-sysprep no encontrado. Ejecuta: rpm-ostree install libguestfs-tools"
  exit 1
}
command -v genisoimage >/dev/null 2>&1 || {
  echo "ERROR: genisoimage no encontrado. Ejecuta: rpm-ostree install genisoimage"
  exit 1
}


# Verificar que la red 'default' existe (coincidencia exacta)
if ! virsh net-list --all | awk '{print $1}' | grep -qx "default"; then
  echo "ERROR: La red 'default' no existe. Créala primero:"
  echo "  virsh ./default.xml"
  echo "  virsh net-start default"
  echo "  virsh net-autostart default"
  exit 1
fi

if [ ! -d "${VM_DIR}" ]; then
  echo ">>> VM directory created at ${VM_DIR}"
  mkdir -p "$VM_DIR"
  chown -R qemu:qemu ${VM_DIR}
fi
# cd "$VM_DIR"

# Generar clave SSH si no existe
#if [ ! -f "$HOME/.ssh/id_ed25519" ]; then
#  echo "Generando clave SSH..."
#  ssh-keygen -t ed25519 -N "" -f "$HOME/.ssh/id_ed25519"
#fi

# Descargar imagen base
if [ ! -f alma9-base.qcow2 ]; then
  echo "Descargando imagen base de AlmaLinux 9..."
  wget -O alma9-base.qcow2 "$ALMA_URL"
fi

# Crear imagen semilla limpia
echo ">>> Preparando imagen semilla con virt-sysprep..."
# if [ ! -f ${VM_DIR}/alma9-seed.qcow2 ]; then
  sudo cp -f alma9-base.qcow2 ${VM_DIR}/alma9-seed.qcow2
# else
#   echo "[OK] Seed found as ${VM_DIR}/alma9-seed.qcow2 "
# fi
sudo virt-sysprep -a ${VM_DIR}/alma9-seed.qcow2
echo ">>> Customizing seed..."
sudo virt-customize -a ${VM_DIR}/alma9-seed.qcow2 \
  --install qemu-guest-agent \
  --ssh-inject root:file:"$SSH_KEY" \
  --firstboot-command 'growpart /dev/sda 4 && xfs_growfs /'


# --- Función de validación pre-creación ---
validate_and_cleanup_vm() {
    local name=$1
    local qcow2_path="$VM_DIR/${name}.qcow2"
    local iso_path="$VM_DIR/${name}-cidata.iso"
    local vm_exists=false
    local disk_exists=false
    local iso_exists=false

    # Verificar si la VM existe en libvirt
    if virsh dominfo "$name" &>/dev/null; then
        vm_exists=true
    fi

    # Verificar si los archivos existen en disco
    [ -f "$qcow2_path" ] && disk_exists=true
    [ -f "$iso_path" ] && iso_exists=true

    # Si nada existe, salir limpio
    if [ "$vm_exists" = false ] && [ "$disk_exists" = false ] && [ "$iso_exists" = false ]; then
        return 0
    fi

    echo ""
    echo "⚠️  Conflicto detectado para VM '$name':"
    [ "$vm_exists" = true ] && echo "   • VM definida en libvirt"
    [ "$disk_exists" = true ] && echo "   • Disco: $qcow2_path"
    [ "$iso_exists" = true ] && echo "   • ISO: $iso_path"
    echo ""

    read -rp "¿Destruir VM existente y recrear? [s/N]: " choice
    case "$choice" in
        [sS])
            echo "   Destruyendo VM y archivos huérfanos..."
            if [ "$vm_exists" = true ]; then
                virsh destroy "$name" &>/dev/null || true
                virsh undefine "$name" --remove-all-storage &>/dev/null || true
            fi
            [ -f "$qcow2_path" ] && rm -f "$qcow2_path"
            [ -f "$iso_path" ] && rm -f "$iso_path"
            sleep 1
            echo "   ✓ Limpieza completada."
            ;;
        *)
            echo "   ⊘ Saltando '$name'. No se modificó nada."
            return 1
            ;;
    esac

    return 0
}


# Función crear VM
create_vm() {
  local name=$1
  local ram=$2
  local vcpu=$3
  local disk=$4
  local networks=$5
  local ip=$6

  # Validar y limpiar si existe
  validate_and_cleanup_vm "$name" || return 0

  echo ""
  echo ">>> Creando VM: $name (RAM: ${ram}MB, vCPU: $vcpu, Disk: ${disk}GB)"

  # Crear disco QCOW2 con backing file
  #qemu-img create -f qcow2 -b alma9-seed.qcow2 -F qcow2 "$VM_DIR/${name}.qcow2" "${disk}G"
  sudo qemu-img create -f qcow2 -b ${VM_DIR}/alma9-seed.qcow2 -F qcow2 "$VM_DIR/${name}.qcow2" "${disk}G"

  # Preparar cloud-init
  local cidata_dir="/tmp/cidata-$name"
  echo ">>> Cloud-init..."
  rm -rf "$cidata_dir"
  mkdir -p "$cidata_dir"

  cat >"$cidata_dir/meta-data" <<EOF
instance-id: $name
local-hostname: $name
EOF

  cat >"$cidata_dir/user-data" <<EOF
#cloud-config
users:
  - name: labadmin
    sudo: ALL=(ALL) NOPASSWD:ALL
    ssh_authorized_keys:
      - $(cat "$SSH_KEY")
    shell: /bin/bash
chpasswd:
  list: |
    root:changeme
    labadmin:changeme
  expire: False
package_update: true
packages:
  - vim
  - tmux
  - htop
  - bash-completion
EOF

  # Crear ISO de cloud-init (solo con los archivos que existan)
  local iso_files=("$cidata_dir/meta-data" "$cidata_dir/user-data")

  if [ -n "$ip" ]; then
    cat >"$cidata_dir/network-config" <<EOF
version: 2
ethernets:
  eth0:
    dhcp4: true
  eth1:
    addresses:
      - $ip/24
EOF
    iso_files+=("$cidata_dir/network-config")
  fi

  genisoimage -output "$VM_DIR/${name}-cidata.iso" -volid cidata -joliet -rock \
    "${iso_files[@]}" 2>/dev/null

  # Construir argumentos de red
  local net_args="--network network=default,model=virtio"
  if [ -n "$networks" ]; then
    net_args="$net_args $networks"
  fi

  # Instalar VM
  virt-install \
    --name "$name" \
    --ram "$ram" \
    --vcpus "$vcpu" \
    --disk path="$VM_DIR/${name}.qcow2",format=qcow2,bus=virtio,cache=none,discard=unmap \
    --disk path="$VM_DIR/${name}-cidata.iso",device=cdrom \
    $net_args \
    --os-variant almalinux9 \
    --graphics none \
    --console pty,target_type=serial \
    --import \
    --noautoconsole \
    --tpm emulator,model=tpm-crb,version=2.0 \
    --boot uefi \
    --rng /dev/urandom

  echo "VM $name creada exitosamente."
}

# --- Crear VMs ---

# 1. alma-rhcsa: Principal para RHCSA + target RHCE
create_vm "alma-rhcsa" 2072 2 40 "" ""

# 2. alma-target-02: 2do nodo para Ansible (RHCE)
create_vm "alma-target-02" 2048 1 30 "--network network=lab-internal,model=virtio" "10.10.10.11"

# 3. alma-security: Para RHCSS (STIG, FIPS, SELinux)
create_vm "alma-security" 2096 2 50 "" ""

# 4. freeipa-lab: Bajo demanda
create_vm "freeipa-lab" 2048 1 20 "" ""

echo ""
echo "=== LAB CREADO EXITOSAMENTE ==="
echo ""
echo "Espera 30-60 segundos para que cloud-init termine, luego verifica:"
echo ""
for vm in alma-rhcsa alma-target-02 alma-security freeipa-lab; do
  echo "  virsh domifaddr $vm"
done
echo ""
echo "Conectar por consola: virsh console alma-rhcsa"
echo "Conectar por SSH:     ssh labadmin@<IP>"
echo ""
echo "Snapshots base (ejecuta ANTES de empezar a romper cosas):"
echo "  virsh snapshot-create-as alma-rhcsa clean-install"
