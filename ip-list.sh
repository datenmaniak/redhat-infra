for vm in alma-rhcsa alma-target-02 alma-security freeipa-lab; do
  virsh domifaddr $vm
done
