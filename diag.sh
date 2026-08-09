# Verificar si la VM existe
echo ">> VM list"
virsh list --all

# Ver detalles de la VM problemática
echo ">> Dominfo"
virsh dominfo alma-rhcsa

# Ver si hay discos asociados
echo ">> Disks"
virsh domblklist alma-rhcsa

# Verificar permisos
echo ">> Permissions"
ls -la /opt/VMs/

# Ver si el almacenamiento está definido
echo ">> Pool list"
virsh pool-list --all
