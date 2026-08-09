# Verificar que el comando virsh existe
if ! command -v virsh &>/dev/null; then
  echo "ERROR: virsh no está instalado o no está en el PATH"
  exit 1
fi

# Verificar que la red 'default' existe (coincidencia exacta)
if ! sudo virsh net-list --all | awk '{print $1}' | grep -qx "default"; then
  echo "ERROR: La red 'default' no existe. Créala primero:"
  echo "  sudo virsh net-define /usr/share/libvirt/networks/default.xml"
  echo "  sudo virsh net-start default"
  echo "  sudo virsh net-autostart default"
  exit 1
fi

# Verificar que la red está activa
if sudo virsh net-list --inactive | awk '{print $1}' | grep -qx "default"; then
  echo "INFO: La red 'default' existe pero no está activa. Iniciándola..."
  sudo virsh net-start default
  sudo virsh net-autostart default
fi

echo "✅ Red 'default' está lista para usar"
