#!/bin/bash
# ============================================================
# Script: cleanup-kvm-vms.sh
# Descripción: Elimina todas las VMs KVM/QEMU y sus
#              configuraciones asociadas
# Uso: sudo ./cleanup-kvm-vms.sh
# ============================================================

set -euo pipefail

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Archivo de log
LOG_FILE="/tmp/kvm-cleanup-$(date +%Y%m%d-%H%M%S).log"

# Variables de estado
EXIT_CODE=0
VMS_DELETED=0
VMS_FAILED=0
STORAGE_DELETED=0
STORAGE_FAILED=0
NETWORKS_DELETED=0
NETWORKS_FAILED=0

# ============================================================
# Funciones de utilidad
# ============================================================

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

  echo "[$timestamp] [$level] $message" >>"$LOG_FILE"
}

check_root() {
  if [[ $EUID -ne 0 ]]; then
    log "ERROR" "Este script debe ejecutarse como root (sudo)"
    exit 1
  fi
}

check_dependencies() {
  local deps=("virsh" "systemctl" "ls" "rm" "grep" "awk")
  local missing=()

  for cmd in "${deps[@]}"; do
    if ! command -v "$cmd" &>/dev/null; then
      missing+=("$cmd")
    fi
  done

  if [[ ${#missing[@]} -gt 0 ]]; then
    log "ERROR" "Faltan dependencias: ${missing[*]}"
    exit 1
  fi
}

check_libvirtd() {
  if ! systemctl is-active --quiet libvirtd; then
    log "ERROR" "El servicio libvirtd no está en ejecución"
    log "INFO" "Ejecuta: systemctl start libvirtd"
    exit 1
  fi
  log "INFO" "Servicio libvirtd activo"
}

confirm_action() {
  local vm_list=$(virsh list --all --name | grep -v '^$' | wc -l)

  if [[ $vm_list -eq 0 ]]; then
    log "WARN" "No se encontraron VMs para eliminar"
    read -p "¿Deseas continuar con la limpieza de archivos? (s/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Ss]$ ]]; then
      log "INFO" "Operación cancelada por el usuario"
      exit 0
    fi
    return
  fi

  log "WARN" "Se eliminarán todas las VMs y sus configuraciones"
  log "WARN" "Esta acción NO se puede deshacer"
  echo
  virsh list --all
  echo
  read -p "¿Estás seguro de continuar? (escribe 'YES' para confirmar): " confirmation

  if [[ "$confirmation" != "YES" ]]; then
    log "INFO" "Operación cancelada por el usuario"
    exit 0
  fi
}

# ============================================================
# Funciones principales
# ============================================================

delete_vms() {
  log "STEP" "=== Eliminando VMs ==="

  local vms=$(virsh list --all --name | grep -v '^$')

  if [[ -z "$vms" ]]; then
    log "INFO" "No hay VMs para eliminar"
    return
  fi

  while IFS= read -r vm; do
    if [[ -z "$vm" ]]; then
      continue
    fi

    log "INFO" "Procesando VM: $vm"

    # Verificar estado de la VM
    local state=$(virsh domstate "$vm" 2>/dev/null || echo "unknown")

    # Si está en ejecución, apagarla
    if [[ "$state" == "running" ]]; then
      log "INFO" "Apagando VM $vm..."
      if virsh destroy "$vm" &>/dev/null; then
        log "INFO" "VM $vm apagada correctamente"
      else
        log "WARN" "No se pudo apagar la VM $vm, intentando forzar..."
        virsh destroy "$vm" --graceful &>/dev/null || true
      fi
    fi

    # Intentar eliminar con --remove-all-storage
    log "INFO" "Eliminando VM $vm con sus discos..."
    if virsh undefine "$vm" --remove-all-storage &>/dev/null; then
      log "INFO" "✓ VM $vm eliminada correctamente"
      ((VMS_DELETED++))
    else
      log "WARN" "Fallo al eliminar con --remove-all-storage, intentando sin eliminar discos..."
      if virsh undefine "$vm" &>/dev/null; then
        log "INFO" "✓ VM $vm eliminada (discos conservados)"
        ((VMS_DELETED++))
        # Marcar para limpieza manual de discos
        STORAGE_FAILED=$((STORAGE_FAILED + 1))
      else
        log "ERROR" "✗ No se pudo eliminar la VM $vm"
        ((VMS_FAILED++))
        EXIT_CODE=1
      fi
    fi
  done <<<"$vms"
}

delete_storage() {
  log "STEP" "=== Eliminando discos virtuales ==="

  local storage_paths=(
    "/opt/VMs"
    "/var/lib/libvirt/images"
    "/tmp"
  )

  for path in "${storage_paths[@]}"; do
    if [[ ! -d "$path" ]]; then
      log "INFO" "Directorio $path no existe, omitiendo..."
      continue
    fi

    log "INFO" "Verificando discos en $path..."
    local disks=$(find "$path" -maxdepth 1 -type f \( -name "*.qcow2" -o -name "*.img" -o -name "*.raw" \) 2>/dev/null || true)

    if [[ -z "$disks" ]]; then
      log "INFO" "No se encontraron discos en $path"
      continue
    fi

    while IFS= read -r disk; do
      if [[ -z "$disk" ]]; then
        continue
      fi

      log "INFO" "Eliminando disco: $disk"
      if rm -f "$disk" 2>/dev/null; then
        log "INFO" "✓ Disco eliminado: $(basename "$disk")"
        ((STORAGE_DELETED++))
      else
        log "ERROR" "✗ No se pudo eliminar: $disk"
        ((STORAGE_FAILED++))
        EXIT_CODE=1
      fi
    done <<<"$disks"
  done

  # Buscar discos huérfanos en otros directorios comunes
  log "INFO" "Buscando discos huérfanos..."
  local orphan_disks=$(find / -name "*.qcow2" -o -name "*.img" -o -name "*.raw" 2>/dev/null | grep -E "(VMs|images|tmp)" | head -20 || true)
  if [[ -n "$orphan_disks" ]]; then
    log "WARN" "Se encontraron discos potencialmente huérfanos:"
    echo "$orphan_disks"
    read -p "¿Eliminar estos discos? (s/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Ss]$ ]]; then
      echo "$orphan_disks" | while read -r disk; do
        rm -f "$disk" 2>/dev/null && log "INFO" "✓ Eliminado: $disk"
      done
    fi
  fi
}

delete_networks() {
  log "STEP" "=== Eliminando redes virtuales ==="

  local networks=$(virsh net-list --all --name | grep -v '^$' | grep -v '^default$' || true)

  if [[ -z "$networks" ]]; then
    log "INFO" "No hay redes para eliminar (red 'default' conservada)"
    return
  fi

  while IFS= read -r net; do
    if [[ -z "$net" ]]; then
      continue
    fi

    log "INFO" "Procesando red: $net"

    # Verificar si está activa
    if virsh net-info "$net" 2>/dev/null | grep -q "Active:.*yes"; then
      log "INFO" "Destruyendo red $net..."
      virsh net-destroy "$net" &>/dev/null || true
    fi

    if virsh net-undefine "$net" &>/dev/null; then
      log "INFO" "✓ Red $net eliminada"
      ((NETWORKS_DELETED++))
    else
      log "ERROR" "✗ No se pudo eliminar la red $net"
      ((NETWORKS_FAILED++))
      EXIT_CODE=1
    fi
  done <<<"$networks"
}

clean_nvram() {
  log "STEP" "=== Limpiando archivos NVRAM ==="

  local nvram_files=$(find /var/lib/libvirt/qemu/nvram -name "*.fd" 2>/dev/null || true)

  if [[ -n "$nvram_files" ]]; then
    for nvram in $nvram_files; do
      log "INFO" "Eliminando NVRAM: $nvram"
      rm -f "$nvram" 2>/dev/null && log "INFO" "✓ Eliminado: $(basename "$nvram")"
    done
  else
    log "INFO" "No se encontraron archivos NVRAM"
  fi
}

# ============================================================
# Función de reporte
# ============================================================

generate_report() {
  log "STEP" "=== REPORTE FINAL ==="
  echo
  echo "=========================================="
  echo "   REPORTE DE LIMPIEZA KVM/QEMU"
  echo "=========================================="
  echo "Fecha: $(date)"
  echo "Log: $LOG_FILE"
  echo "------------------------------------------"
  echo "RESUMEN DE OPERACIONES:"
  echo "  VMs eliminadas:        $VMS_DELETED"
  echo "  VMs con error:         $VMS_FAILED"
  echo "  Discos eliminados:     $STORAGE_DELETED"
  echo "  Discos con error:      $STORAGE_FAILED"
  echo "  Redes eliminadas:      $NETWORKS_DELETED"
  echo "  Redes con error:       $NETWORKS_FAILED"
  echo "------------------------------------------"

  # Verificación final
  echo "VERIFICACIÓN FINAL:"
  local remaining_vms=$(virsh list --all --name | grep -v '^$' | wc -l)
  if [[ $remaining_vms -eq 0 ]]; then
    echo -e "  ${GREEN}✓${NC} No quedan VMs registradas"
  else
    echo -e "  ${RED}✗${NC} Quedan $remaining_vms VMs registradas"
    EXIT_CODE=1
  fi

  local remaining_disks=$(find /opt/VMs /var/lib/libvirt/images /tmp -maxdepth 1 -type f \( -name "*.qcow2" -o -name "*.img" -o -name "*.raw" \) 2>/dev/null | wc -l)
  if [[ $remaining_disks -eq 0 ]]; then
    echo -e "  ${GREEN}✓${NC} No quedan discos virtuales en directorios principales"
  else
    echo -e "  ${YELLOW}⚠${NC} Quedan $remaining_disks discos virtuales"
  fi

  echo "------------------------------------------"
  echo "Estado del servicio libvirtd:"
  systemctl status libvirtd --no-pager | head -3
  echo "=========================================="

  if [[ $EXIT_CODE -eq 0 ]]; then
    log "INFO" "✅ LIMPIEZA COMPLETADA CON ÉXITO"
  else
    log "WARN" "⚠ LIMPIEZA COMPLETADA CON ADVERTENCIAS"
    log "INFO" "Revisa el log para más detalles: $LOG_FILE"
  fi
}

# ============================================================
# Función principal
# ============================================================

main() {
  echo "=========================================="
  echo "   LIMPIEZA DE VMS KVM/QEMU"
  echo "=========================================="
  echo "Log: $LOG_FILE"
  echo "=========================================="
  echo

  # Validaciones iniciales
  check_root
  check_dependencies
  check_libvirtd

  # Mostrar VMs actuales
  log "STEP" "VMs actuales en el sistema:"
  virsh list --all || true
  echo

  # Confirmación del usuario
  confirm_action

  # Ejecutar limpieza
  delete_vms
  delete_storage
  delete_networks
  clean_nvram

  # Generar reporte
  generate_report

  exit $EXIT_CODE
}

# ============================================================
# Ejecución
# ============================================================

main "$@"
