#!/bin/bash
# Script de limpieza forzada para KVM

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

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

  # echo "[$timestamp] [$level] $message" >>"$LOG_FILE"
}


if [[ $EUID -ne 0 ]]; then
    log "ERROR" "Este script debe ejecutarse como root (sudo)"
    exit 1
  fi

log() {
  echo -e "${2:-}${1}${NC}"
}

cleanup_vm() {
  local vm=$1
  log "=== Procesando VM: $vm ===" "$YELLOW"

  # 1. Detener la VM
  virsh destroy "$vm" 2>/dev/null && log "✓ VM detenida" "$GREEN" || log "ℹ VM ya detenida" "$YELLOW"

  # 2. Desconectar discos ISO (cidata)
  log "Desconectando discos ISO..." "$YELLOW"
  virsh detach-disk "$vm" sda --config 2>/dev/null && log "✓ Disco sda desconectado" "$GREEN" || true
  virsh detach-disk "$vm" sdb --config 2>/dev/null && log "✓ Disco sdb desconectado" "$GREEN" || true

  # 3. Eliminar la VM con todas las opciones
  log "Eliminando VM..." "$YELLOW"
  virsh undefine "$vm" --remove-all-storage --managed-save --snapshots-metadata --nvram --checkpoints-metadata 2>/dev/null && {
    log "✓ VM $vm eliminada correctamente" "$GREEN"
    return 0
  }

  virsh undefine "$vm" --remove-all-storage --nvram 2>/dev/null && {
    log "✓ VM $vm eliminada (con discos y NVRAM)" "$GREEN"
    return 0
  }

  virsh undefine "$vm" --remove-all-storage 2>/dev/null && {
    log "✓ VM $vm eliminada (con discos)" "$GREEN"
    return 0
  }

  virsh undefine "$vm" 2>/dev/null && {
    log "✓ VM $vm eliminada (solo definición)" "$GREEN"
    return 0
  }

  # 4. Eliminación manual (último recurso)
  log "Intentando eliminación manual..." "$YELLOW"
  rm -f /etc/libvirt/qemu/${vm}.xml 2>/dev/null
  rm -f /var/lib/libvirt/qemu/nvram/${vm}_VARS.fd 2>/dev/null
  find /opt/VMs /var/lib/libvirt/images /tmp -name "*${vm}*.qcow2" -o -name "*${vm}*.iso" -o -name "*${vm}*.img" 2>/dev/null | while read disk; do
    rm -f "$disk" && log "✓ Disco eliminado: $disk" "$GREEN"
  done

  log "✓ Limpieza manual completada para $vm" "$GREEN"
}

# Eliminar pools de almacenamiento problemáticos
cleanup_pools() {
  log "=== Limpiando pools de almacenamiento ===" "$YELLOW"

  for pool in VMs VMs-1; do
    if virsh pool-info "$pool" &>/dev/null; then
      log "Procesando pool: $pool" "$YELLOW"
      virsh pool-destroy "$pool" 2>/dev/null && log "✓ Pool $pool destruido" "$GREEN" || true
      virsh pool-undefine "$pool" 2>/dev/null && log "✓ Pool $pool eliminado" "$GREEN" || true
    else
      log "ℹ Pool $pool no existe" "$YELLOW"
    fi
  done
}

# Limpiar archivos remanentes
cleanup_orphans() {
  log "=== Limpiando archivos huérfanos ===" "$YELLOW"

  # Eliminar discos de las VMs específicas
  for vm in alma-rhcsa alma-security alma-target-02 freeipa-lab; do
    find /opt/VMs /var/lib/libvirt/images /tmp -name "*${vm}*.qcow2" -o -name "*${vm}*.iso" -o -name "*${vm}*.img" 2>/dev/null | while read disk; do
      rm -f "$disk" && log "✓ Disco huérfano eliminado: $disk" "$GREEN"
    done
  done

  # Limpiar directorio /opt/VMs completamente
  if [[ -d /opt/VMs ]]; then
    log "Limpiando /opt/VMs..." "$YELLOW"
    rm -f /opt/VMs/*.qcow2 /opt/VMs/*.iso /opt/VMs/*.img 2>/dev/null
    log "✓ /opt/VMs limpiado" "$GREEN"
  fi
}

# Función principal
main() {
  log "=== LIMPIEZA FORZADA DE KVM/QEMU ===" "$YELLOW"
  log "Iniciando limpieza completa..." "$YELLOW"

  # Lista de VMs a eliminar
  VMS=("alma-rhcsa" "alma-security" "alma-target-02" "freeipa-lab")

  # Eliminar cada VM
  for vm in "${VMS[@]}"; do
    cleanup_vm "$vm"
    echo "---"
  done

  # Limpiar pools
  cleanup_pools

  # Limpiar archivos huérfanos
  cleanup_orphans

  # Reiniciar libvirtd
  log "Reiniciando libvirtd..." "$YELLOW"
  systemctl restart libvirtd

  # Verificación final
  log "=== VERIFICACIÓN FINAL ===" "$YELLOW"
  echo -e "\n${GREEN}VMs en el sistema:${NC}"
  virsh list --all
  echo -e "\n${GREEN}Pools de almacenamiento:${NC}"
  virsh pool-list --all
  echo -e "\n${GREEN}Discos en /opt/VMs:${NC}"
  ls -la /opt/VMs/ 2>/dev/null || echo "Directorio vacío o no existe"

  log "✅ LIMPIEZA COMPLETADA" "$GREEN"
}

# Ejecutar
main
