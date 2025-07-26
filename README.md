# Linux Kernel Development Environment on Mac using limactl

## Overview
Easily setup a Linux Kernel development environment on `mac` M1 processors using [limactl](https://lima-vm.io/docs/reference/limactl/) and based on [FlorentRevest](https://github.com/FlorentRevest/linux-kernel-vscode)'s work

## Prerequisites

- an arm64 mac
-  [limactl](https://lima-vm.io/docs/reference/limactl/)
- 8GB memory for the lima vm
- 50GB free disk

## Setup

```
./setup_kernel_dev_env.sh
```

### Configuration

Default values

```
VM_NAME=kernel-dev-vm
VM_TEMPLATE=ubuntu-24.10
VM_CPUS=6
VM_MEMORY_GB=8
VM_DISK_GB=50
```

can be changed by passing any of the above `env` variables

e.g.
```
VM_NAME=another_name VM_CPUS=4 ./setup_kernel_dev_env.sh
```
## Debugging using gdb

### Find a break point

Let's find a break point in the networking stack by running a `trace-cmd`
```
sudo trace-cmd record \
    -p function_graph \
    -g net_rx_action  \
    -- curl -s -o /dev/null https://example.com
```

and then display the call-graph

```
sudo trace-cmd report --align-ts| less
```

and you'll see something like:
```
cpus=6
            curl-125402 [001]     0.000000: funcgraph_entry:                   |  net_rx_action() {
            curl-125402 [001]     0.000000: funcgraph_entry:        0.167 us   |    __usecs_to_jiffies();
            curl-125402 [001]     0.000001: funcgraph_entry:        0.125 us   |    _raw_spin_lock();
            curl-125402 [001]     0.000001: funcgraph_entry:        0.083 us   |    _raw_spin_unlock();
            curl-125402 [001]     0.000001: funcgraph_entry:                   |    napi_consume_skb() {
            curl-125402 [001]     0.000001: funcgraph_entry:        0.083 us   |      skb_release_head_state();
            curl-125402 [001]     0.000002: funcgraph_entry:                   |      skb_release_data() {
            curl-125402 [001]     0.000002: funcgraph_entry:                   |        __folio_put() {
            curl-125402 [001]     0.000002: funcgraph_entry:        0.083 us   |          __mem_cgroup_uncharge();
            curl-125402 [001]     0.000002: funcgraph_entry:                   |          free_unref_page() {
            curl-125402 [001]     0.000002: funcgraph_entry:        0.083 us   |            free_tail_page_prepare();
            curl-125402 [001]     0.000002: funcgraph_entry:        0.083 us   |            free_tail_page_prepare();
            ....
            curl-125402 [001]     0.000004: funcgraph_exit:         1.667 us   |          }
            curl-125402 [001]     0.000004: funcgraph_exit:         1.958 us   |        }
            curl-125402 [001]     0.000004: funcgraph_entry:                   |        skb_free_head() {
            curl-125402 [001]     0.000004: funcgraph_entry:        0.084 us   |          kmem_cache_free();
            curl-125402 [001]     0.000004: funcgraph_exit:         0.250 us   |        }
            curl-125402 [001]     0.000004: funcgraph_exit:         2.625 us   |      }
            curl-125402 [001]     0.000004: funcgraph_entry:                   |      kfree_skbmem() {
            curl-125402 [001]     0.000004: funcgraph_entry:        0.208 us   |        kmem_cache_free();
            curl-125402 [001]     0.000005: funcgraph_exit:         0.375 us   |      }
            curl-125402 [001]     0.000005: funcgraph_exit:         3.333 us   |    }
            curl-125402 [001]     0.000005: funcgraph_entry:                   |    __napi_poll() {
            curl-125402 [001]     0.000005: funcgraph_entry:                   |      process_backlog() {
            curl-125402 [001]     0.000005: funcgraph_entry:        0.083 us   |        _raw_spin_lock_irq();
            curl-125402 [001]     0.000005: funcgraph_entry:        0.083 us   |        _raw_spin_unlock_irq();
            curl-125402 [001]     0.000005: funcgraph_entry:        0.083 us   |        __rcu_read_lock();
            curl-125402 [001]     0.000005: funcgraph_entry:                   |        __netif_receive_skb() {
```

We want to break on [net_rx_action](https://tldp.org/HOWTO/KernelAnalysis-HOWTO-8.html)

### Launch vng

```
limactl shell $VM_NAME <<'EOF'
cd ~/dev/linux
vng --debug --network user
EOF
```

```
➜  scripts git:(main) ✗ limactl shell test-script-2 <<'EOF'
cd ~/dev/linux
vng --debug --network user
EOF
          _      _
   __   _(_)_ __| |_ _ __ ___   ___       _ __   __ _
   \ \ / / |  __| __|  _   _ \ / _ \_____|  _ \ / _  |
    \ V /| | |  | |_| | | | | |  __/_____| | | | (_| |
     \_/ |_|_|   \__|_| |_| |_|\___|     |_| |_|\__  |
                                                |___/
   kernel version: 6.11.0 aarch64
   (CTRL+d to exit)

filippo@virtme-ng:~/dev/linux$
```

### Launch gdb

```
limactl shell $VM_NAME
```

```
export TERM=xterm-256color
cd ~/dev/linux/
gdb -tui ./vmlinux \
  --eval-command="target remote :1234" \
  --eval-command="break net_rx_action" \
  --eval-command="continue"

```

## Debugging using Visual Studio Code

### Launch Visual Studio Code

### Set a remote connection

### Launch vng

# linux-kernel-debugging-on-mac
